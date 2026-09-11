// ==============================================================================
// NIRVANA - Supabase & Offline Caregiver Repository Implementation
// Description: Implements ICaregiverRepository with full offline fallback,
// patient-scoped security, patient onboarding, and adherence tracking.
// ==============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_boxes.dart';
import '../../../database/hive_database.dart';
import '../../../database/models/hive_reminder.dart';
import '../../../database/models/hive_sync_event.dart';
import '../../reminders/models/reminder.dart';
import '../../reminders/services/notification_service.dart';
import '../../family_photos/models/family_photo.dart';
import '../../family_photos/repositories/family_photo_repository.dart';
import '../../../database/models/hive_family_photo.dart';
import '../../../core/network/sync_engine.dart';
import 'package:uuid/uuid.dart';
import '../models/caregiver_models.dart';
import 'caregiver_repository.dart';

class SupabaseCaregiverRepository
    implements
        ICaregiverRepository,
        IFamilyPhotoReader,
        IFamilyPhotoRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;
  final SyncEngine? _syncEngine;

  static CaregiverProfile? _cachedProfile;
  static final List<PatientSummary> _offlinePatients = [];
  static final Map<String, List<Map<String, dynamic>>> _offlineFamilyPhotos =
      {};
  static const _familyPhotoBucket = 'family-photos';

  SupabaseCaregiverRepository({
    SupabaseClient? client,
    IConnectivityMonitor? connectivityMonitor,
    SyncEngine? syncEngine,
  }) : _client = client,
       _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor(),
       _syncEngine = syncEngine;

  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final activeClient = client;

    if (activeClient != null) {
      try {
        // 1. Create the auth.users entry via Supabase Auth
        final response = await activeClient.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName},
        );

        final user = response.user;
        if (user != null) {
          // 2. Upsert into public.profiles (trigger may have already created it)
          await activeClient.from('profiles').upsert({
            'id': user.id,
            'email': email.trim(),
            'full_name': fullName,
            'phone': phone,
            'role': 'caregiver',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });

          _cachedProfile = CaregiverProfile(
            id: user.id,
            email: user.email ?? email,
            fullName: fullName,
            phone: phone,
            role: 'caregiver',
          );
          return _cachedProfile!;
        }
        throw Exception('Registration succeeded but user object was null.');
      } catch (e) {
        // Rethrow to allow the provider/UI to display the error
        debugPrint('⚠️ Registration error: $e');
        rethrow;
      }
    }

    // Offline fallback: create a local-only caregiver profile
    debugPrint('⚠️ Supabase unavailable. Registering in offline demo mode.');
    _cachedProfile = CaregiverProfile(
      id: 'caregiver-local-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      phone: phone,
      role: 'caregiver',
    );
    return _cachedProfile!;
  }

  @override
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  }) async {
    final activeClient = client;
    final cleanEmail = email.trim();

    if (activeClient != null) {
      try {
        final response = await activeClient.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        final user = response.user;
        if (user != null) {
          // Fetch profile details from profiles table
          Map<String, dynamic>? profileData = await activeClient
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          // Self-heal: If profile record is missing, create it
          if (profileData == null) {
            try {
              final fullName =
                  user.userMetadata?['full_name'] as String? ?? 'Caregiver';
              final profileInsert = {
                'id': user.id,
                'email': user.email ?? cleanEmail,
                'full_name': fullName,
                'role': 'caregiver',
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              };
              await activeClient.from('profiles').upsert(profileInsert);
              profileData = profileInsert;
            } catch (profileErr) {
              debugPrint('⚠️ Non-fatal profile creation warning: $profileErr');
            }
          }

          _cachedProfile = CaregiverProfile(
            id: user.id,
            email: user.email ?? cleanEmail,
            fullName:
                profileData?['full_name'] as String? ??
                user.userMetadata?['full_name'] as String? ??
                'Caregiver',
            phone: profileData?['phone'] as String?,
            role: profileData?['role'] as String? ?? 'primary_caregiver',
          );
          return _cachedProfile!;
        }
      } catch (e) {
        debugPrint('⚠️ Supabase login exception: $e');
        final status = await _connectivityMonitor.checkStatus();
        if (status == NetworkStatus.online) {
          rethrow;
        }
      }
    }

    // Offline / Demo Caregiver Mode (strictly when offline)
    _cachedProfile = CaregiverProfile(
      id: 'caregiver-local-001',
      email: cleanEmail.isEmpty ? 'caregiver@nirvana.care' : cleanEmail,
      fullName: 'Sarah Jenkins',
      role: 'primary_caregiver',
    );
    return _cachedProfile!;
  }

  @override
  Future<void> logout() async {
    final activeClient = client;
    if (activeClient != null) {
      try {
        await activeClient.auth.signOut();
      } catch (_) {}
    }
    _cachedProfile = null;
  }

  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async {
    if (_cachedProfile != null) return _cachedProfile;
    final activeClient = client;
    final user = activeClient?.auth.currentUser;
    if (user != null) {
      try {
        final profileData = await activeClient
            ?.from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        _cachedProfile = CaregiverProfile(
          id: user.id,
          email: user.email ?? '',
          fullName:
              profileData?['full_name'] as String? ??
              user.userMetadata?['full_name'] as String? ??
              'Caregiver',
          phone: profileData?['phone'] as String?,
          role: profileData?['role'] as String? ?? 'primary_caregiver',
        );
        return _cachedProfile;
      } catch (_) {
        return CaregiverProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String? ?? 'Caregiver',
        );
      }
    }
    return null;
  }

  static String _generateUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async {
    final activeClient = client;
    final currentUser = activeClient?.auth.currentUser;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null && status == NetworkStatus.online) {
      if (currentUser == null) {
        throw Exception(
          'Authentication required: Please sign in with a valid caregiver account before creating a patient.',
        );
      }

      try {
        // 1. Try atomic RPC create_patient_with_caregiver
        try {
          final rpcResult = await activeClient.rpc(
            'create_patient_with_caregiver',
            params: {
              'p_display_name': input.fullName.trim(),
              'p_preferred_name': input.preferredName.trim().isNotEmpty
                  ? input.preferredName.trim()
                  : input.fullName.trim(),
              'p_relationship_label': input.relationship.trim(),
              if (input.dateOfBirth != null)
                'p_date_of_birth': input.dateOfBirth!
                    .toIso8601String()
                    .split('T')
                    .first,
              if (input.emergencyContactPhone != null &&
                  input.emergencyContactPhone!.trim().isNotEmpty)
                'p_emergency_contact_phone': input.emergencyContactPhone!
                    .trim(),
              'p_accessibility_settings': input.toAccessibilitySettings(),
              'p_initial_reminders': input.initialReminders
                  .where((r) => r.isEnabled)
                  .map((r) => r.toMap('00000000-0000-0000-0000-000000000000'))
                  .toList(),
            },
          );

          if (rpcResult != null) {
            final data = Map<String, dynamic>.from(rpcResult as Map);
            final createdSummary = PatientSummary(
              id: data['id'] as String,
              fullName:
                  data['display_name'] as String? ?? input.fullName.trim(),
              preferredName:
                  data['preferred_name'] as String? ??
                  input.preferredName.trim(),
              relationship:
                  data['relationship_label'] as String? ??
                  input.relationship.trim(),
              primaryCaregiverId: currentUser.id,
              emergencyContactPhone:
                  data['emergency_contact_phone'] as String? ??
                  input.emergencyContactPhone?.trim(),
              lastActiveAt: DateTime.now(),
            );

            _offlinePatients.insert(0, createdSummary);
            return createdSummary;
          }
        } on PostgrestException catch (rpcError) {
          // PostgREST returns 'PGRST202' when the function is not found in the
          // schema cache (i.e. migration hasn't been applied yet).
          // Raw PostgreSQL would return '42883'. Handle both so the direct-insert
          // fallback triggers correctly in either case.
          final isFunctionNotFound =
              rpcError.code == 'PGRST202' || rpcError.code == '42883';
          if (!isFunctionNotFound) {
            rethrow;
          }
          debugPrint(
            'ℹ️ RPC create_patient_with_caregiver not found (${rpcError.code}), '
            'falling back to direct table inserts.',
          );
        }

        // Direct table inserts fallback under RLS
        // Ensure profile exists in profiles table
        try {
          await activeClient.from('profiles').upsert({
            'id': currentUser.id,
            'email': currentUser.email ?? '',
            'full_name':
                currentUser.userMetadata?['full_name'] as String? ??
                _cachedProfile?.fullName ??
                'Caregiver',
            'role': 'caregiver',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (profileErr) {
          debugPrint('⚠️ Warning during profile sync: $profileErr');
        }

        // 1. Create patients record in Supabase
        final patientInsertData = {
          'primary_caregiver_id': currentUser.id,
          'display_name': input.fullName.trim(),
          'preferred_name': input.preferredName.trim().isNotEmpty
              ? input.preferredName.trim()
              : input.fullName.trim(),
          if (input.dateOfBirth != null)
            'date_of_birth': input.dateOfBirth!
                .toIso8601String()
                .split('T')
                .first,
          if (input.emergencyContactPhone != null &&
              input.emergencyContactPhone!.trim().isNotEmpty)
            'emergency_contact_phone': input.emergencyContactPhone!.trim(),
          'accessibility_settings': input.toAccessibilitySettings(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        final patientResponse = await activeClient
            .from('patients')
            .insert(patientInsertData)
            .select()
            .single();

        final patientId = patientResponse['id'] as String;

        // 2. Create caregiver_patient_links record
        await activeClient.from('caregiver_patient_links').upsert({
          'caregiver_id': currentUser.id,
          'patient_id': patientId,
          'relationship_label': input.relationship.trim(),
          'access_role': 'primary',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });

        // 3. Create initial reminders if configured
        if (input.initialReminders.isNotEmpty) {
          final reminderInserts = input.initialReminders
              .where((r) => r.isEnabled)
              .map((r) => r.toMap(patientId))
              .toList();

          if (reminderInserts.isNotEmpty) {
            try {
              await activeClient.from('reminders').insert(reminderInserts);
            } catch (reminderErr) {
              debugPrint('⚠️ Non-fatal: Reminder insert issue: $reminderErr');
            }
          }
        }

        final createdSummary = PatientSummary(
          id: patientId,
          fullName: input.fullName.trim(),
          preferredName: input.preferredName.trim().isNotEmpty
              ? input.preferredName.trim()
              : input.fullName.trim(),
          relationship: input.relationship.trim(),
          primaryCaregiverId: currentUser.id,
          emergencyContactPhone: input.emergencyContactPhone?.trim(),
          lastActiveAt: DateTime.now(),
        );

        _offlinePatients.insert(0, createdSummary);
        return createdSummary;
      } catch (e) {
        debugPrint('⚠️ Remote patient creation error: $e');
        rethrow;
      }
    }

    // Offline / Demo fallback patient creation with standard UUID format (strictly offline)
    final fallbackId = _generateUuid();
    final fallbackSummary = PatientSummary(
      id: fallbackId,
      fullName: input.fullName.trim(),
      preferredName: input.preferredName.trim().isNotEmpty
          ? input.preferredName.trim()
          : input.fullName.trim(),
      relationship: input.relationship.trim(),
      primaryCaregiverId:
          caregiverId ??
          _cachedProfile?.id ??
          '00000000-0000-0000-0000-000000000000',
      emergencyContactPhone: input.emergencyContactPhone?.trim(),
      lastActiveAt: DateTime.now(),
    );

    _offlinePatients.insert(0, fallbackSummary);
    return fallbackSummary;
  }

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();
    final currentUser = activeClient?.auth.currentUser;

    if (activeClient != null &&
        status == NetworkStatus.online &&
        currentUser != null) {
      try {
        // Query assigned patients via links
        final response = await activeClient
            .from('patients')
            .select(
              '*, caregiver_patient_links(relationship_label, access_role, caregiver_id)',
            );

        final remoteList = (response as List)
            .map((item) => PatientSummary.fromMap(item as Map<String, dynamic>))
            .toList();

        // Merge any locally created patients that might not be in remote yet
        final combined = <PatientSummary>[
          ..._offlinePatients.where(
            (op) => !remoteList.any((rp) => rp.id == op.id),
          ),
          ...remoteList,
        ];

        if (combined.isNotEmpty) return combined;

        // Fallback to direct query by primary_caregiver_id
        final directResponse = await activeClient
            .from('patients')
            .select()
            .eq('primary_caregiver_id', caregiverId);

        final directList = (directResponse as List)
            .map((item) => PatientSummary.fromMap(item as Map<String, dynamic>))
            .toList();

        final combinedDirect = <PatientSummary>[
          ..._offlinePatients.where(
            (op) => !directList.any((rp) => rp.id == op.id),
          ),
          ...directList,
        ];

        if (combinedDirect.isNotEmpty) return combinedDirect;
      } catch (e) {
        debugPrint('⚠️ Failed to fetch remote patients: $e');
      }
    }

    if (_offlinePatients.isNotEmpty) {
      final matching = _offlinePatients
          .where(
            (p) => caregiverId.isEmpty || p.primaryCaregiverId == caregiverId,
          )
          .toList();
      return List.unmodifiable(matching);
    }

    // No remote data and no offline patients
    return [];
  }

  @override
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty) {
      try {
        final response = await activeClient.rpc(
          'get_caregiver_game_history',
          params: {'p_patient_id': patientId, 'p_limit': 20},
        );

        return (response as List).map((item) {
          final map = item as Map<String, dynamic>;
          final type = map['game_type'] as String? ?? 'remember_objects';
          final diffLevel = (map['difficulty_level'] as num?)?.toInt() ?? 1;
          return CaregiverGameRecord(
            id: map['id'] as String? ?? '',
            gameTitle: _formatGameTitle(type),
            gameType: type,
            difficulty: _difficultyLevelToString(diffLevel),
            score:
                0, // No score column in schema; computed client-side if needed
            durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
            correctCount: (map['successful_trials'] as num?)?.toInt() ?? 0,
            totalCount: (map['total_trials'] as num?)?.toInt() ?? 0,
            playedAt:
                DateTime.tryParse(map['completed_at'] as String? ?? '') ??
                DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now(),
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Remote game history fetch error: $e');
        rethrow;
      }
    }

    // Hive fallback: reminder logs only (no Hive box for game sessions)
    // Return empty list — the widget shows a clean empty state
    return [];
  }

  static final List<CaregiverReminderRecord> _offlineReminders = [];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(
    String patientId,
  ) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty) {
      try {
        // Query reminders for this patient with latest log status
        final response = await activeClient
            .from('reminders')
            .select('*, reminder_logs(status, acknowledged_at, snoozed_until)')
            .eq('patient_id', patientId)
            .eq('is_deleted', false)
            .order('schedule_time', ascending: true);

        final remoteList = (response as List).map((item) {
          final map = item as Map<String, dynamic>;

          // Extract latest log status if available
          String logStatus = 'pending';
          DateTime? acknowledgedAt;
          DateTime? snoozedUntil;
          if (map['reminder_logs'] is List &&
              (map['reminder_logs'] as List).isNotEmpty) {
            final latestLog =
                (map['reminder_logs'] as List).last as Map<String, dynamic>;
            logStatus = latestLog['status'] as String? ?? 'pending';
            acknowledgedAt = latestLog['acknowledged_at'] != null
                ? DateTime.tryParse(latestLog['acknowledged_at'] as String)
                : null;
            snoozedUntil = latestLog['snoozed_until'] != null
                ? DateTime.tryParse(latestLog['snoozed_until'] as String)
                : null;
          }

          return CaregiverReminderRecord.fromMap({
            ...map,
            'status': logStatus,
            'acknowledged_at': acknowledgedAt?.toIso8601String(),
            'snoozed_until': snoozedUntil?.toIso8601String(),
            'is_completed': logStatus == 'acknowledged',
            'last_action': logStatus == 'acknowledged'
                ? 'done'
                : (logStatus == 'snoozed' ? 'snoozed' : null),
          });
        }).toList();

        // Merge any locally created reminders not yet synced
        final combined = <CaregiverReminderRecord>[
          ..._offlineReminders.where(
            (or) =>
                or.patientId == patientId &&
                !remoteList.any((rr) => rr.id == or.id),
          ),
          ...remoteList,
        ];

        return combined;
      } catch (e) {
        debugPrint('⚠️ Remote reminder fetch error: $e');
      }
    }

    // Hive fallback
    try {
      final localReminders = HiveDatabase.remindersBox.values.where((r) {
        return (patientId.isEmpty || r.patientId == patientId) && r.isActive;
      }).toList();

      if (localReminders.isNotEmpty) {
        return localReminders.map((r) {
          return CaregiverReminderRecord(
            id: r.id,
            patientId: r.patientId,
            title: r.title,
            scheduledAt: r.scheduledAt,
            isCompleted: r.isCompleted,
            completedAt: r.completedAt,
            snoozedUntil: r.snoozedUntil,
            lastAction: r.isCompleted
                ? 'done'
                : (r.snoozedUntil != null ? 'snoozed' : null),
          );
        }).toList();
      }
    } catch (_) {}

    // Offline-created reminders for this patient
    final patientOffline = _offlineReminders
        .where((r) => r.patientId == patientId)
        .toList();
    if (patientOffline.isNotEmpty) return patientOffline;

    // No remote data and no Hive data — return empty list.
    // The widget renders a clean empty state with an "Add Reminder" prompt.
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyPhotos(String patientId) async {
    if (patientId.isEmpty) return [];
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();
    if (activeClient != null && status == NetworkStatus.online) {
      try {
        final response = await activeClient
            .from('family_photos')
            .select(
              'id, patient_id, title, relationship, photo_url, audio_note_url, display_order, is_active, is_deleted, created_at, updated_at',
            )
            .eq('patient_id', patientId)
            .eq('is_active', true)
            .eq('is_deleted', false)
            .order('display_order', ascending: true);
        final photos = (response as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _offlineFamilyPhotos[patientId] = photos;
        return photos;
      } catch (e) {
        debugPrint('Family photo fetch error: $e');
      }
    }
    return _offlineFamilyPhotos[patientId] ?? const [];
  }

  @override
  Future<List<FamilyPhoto>> getFamilyPhotoModels(String patientId) async {
    final status = await _connectivityMonitor.checkStatus();
    if (status == NetworkStatus.online &&
        Hive.isBoxOpen(HiveBoxes.familyPhotos)) {
      final pendingLocal = HiveDatabase.familyPhotosBox.values.where(
        (photo) =>
            photo.patientId == patientId &&
            !photo.isDeleted &&
            photo.photoUrl.isEmpty &&
            (photo.localPath?.isNotEmpty == true ||
                photo.localBytes?.isNotEmpty == true),
      );
      for (final localPhoto in pendingLocal) {
        try {
          await saveFamilyPhoto(
            photo: FamilyPhoto.fromHive(localPhoto),
            image: localPhoto.localBytes != null
                ? XFile.fromData(
                    localPhoto.localBytes!,
                    name: '${localPhoto.id}.jpg',
                  )
                : XFile(localPhoto.localPath!),
          );
        } catch (error) {
          debugPrint('Pending family photo upload skipped: $error');
        }
      }
    }
    final records = await getFamilyPhotos(patientId);
    if (records.isEmpty && Hive.isBoxOpen(HiveBoxes.familyPhotos)) {
      final cached = HiveDatabase.familyPhotosBox.values
          .where((photo) => photo.patientId == patientId && !photo.isDeleted)
          .map(FamilyPhoto.fromHive)
          .toList(growable: false);
      final hydratedCached = <FamilyPhoto>[];
      for (final photo in cached) {
        hydratedCached.add(await _hydratePhotoUrl(photo));
      }
      return hydratedCached;
    }
    final hydrated = <FamilyPhoto>[];
    for (final record in records) {
      final photo = FamilyPhoto.fromMap(record);
      final cached = Hive.isBoxOpen(HiveBoxes.familyPhotos)
          ? HiveDatabase.familyPhotosBox.get(photo.id)
          : null;
      final merged = cached == null
          ? photo
          : photo.copyWith(
              localPath: cached.localPath,
              localBytes: cached.localBytes,
            );
      final hydratedPhoto = await _hydratePhotoUrl(merged);
      hydrated.add(hydratedPhoto);
    }
    return hydrated;
  }

  @override
  Future<FamilyPhoto> saveFamilyPhoto({
    required FamilyPhoto photo,
    XFile? image,
  }) async {
    final now = DateTime.now();
    var saved = photo.copyWith(updatedAt: now);
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (image != null &&
        activeClient != null &&
        status == NetworkStatus.online) {
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final storagePath = '${photo.patientId}/${photo.id}.$extension';
      final imageBytes = await image.readAsBytes();
      try {
        await activeClient.storage
            .from(_familyPhotoBucket)
            .uploadBinary(
              storagePath,
              imageBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: 'image/$extension',
              ),
            );
        saved = saved.copyWith(
          photoUrl: storagePath,
          localPath: image.path,
          localBytes: imageBytes,
        );
      } catch (error) {
        debugPrint('Family photo storage upload deferred: $error');
        saved = saved.copyWith(localPath: image.path, localBytes: imageBytes);
      }
    } else if (image != null) {
      saved = saved.copyWith(
        localPath: image.path,
        localBytes: await image.readAsBytes(),
      );
    }

    if (activeClient != null &&
        status == NetworkStatus.online &&
        saved.photoUrl.isNotEmpty) {
      try {
        await activeClient.from('family_photos').upsert({
          'id': saved.id,
          'patient_id': saved.patientId,
          'title': saved.name,
          'relationship': saved.relationship,
          'photo_url': saved.photoUrl,
          'audio_note_url': saved.audioNoteUrl,
          'display_order': saved.displayOrder,
          'is_active': true,
          'is_deleted': false,
          'created_at': saved.createdAt.toUtc().toIso8601String(),
          'updated_at': saved.updatedAt.toUtc().toIso8601String(),
        });
      } catch (error) {
        debugPrint('Family photo metadata sync deferred: $error');
      }
    }

    await _cacheFamilyPhoto(saved);
    if (_syncEngine != null && saved.photoUrl.isNotEmpty) {
      await _syncEngine.enqueueEvent(
        HiveSyncEvent(
          eventId: const Uuid().v4(),
          entityType: 'family_photo',
          entityId: saved.id,
          operation: 'update',
          payload: saved.toMap(),
          createdAt: saved.updatedAt,
          patientId: saved.patientId,
        ),
      );
    }
    return saved;
  }

  @override
  Future<void> softDeleteFamilyPhoto({
    required String patientId,
    required String photoId,
  }) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();
    if (activeClient != null && status == NetworkStatus.online) {
      await activeClient
          .from('family_photos')
          .update({'is_active': false, 'is_deleted': true})
          .eq('id', photoId)
          .eq('patient_id', patientId);
    }
    await HiveDatabase.familyPhotosBox.delete(photoId);
    _offlineFamilyPhotos[patientId] = (_offlineFamilyPhotos[patientId] ?? [])
        .where((item) => item['id'] != photoId)
        .toList();
    if (_syncEngine != null) {
      await _syncEngine.enqueueEvent(
        HiveSyncEvent(
          eventId: const Uuid().v4(),
          entityType: 'family_photo',
          entityId: photoId,
          operation: 'delete',
          payload: {'is_deleted': true, 'is_active': false},
          createdAt: DateTime.now(),
          patientId: patientId,
        ),
      );
    }
  }

  Future<FamilyPhoto> _hydratePhotoUrl(FamilyPhoto photo) async {
    if (photo.photoUrl.isEmpty || photo.photoUrl.startsWith('http')) {
      return photo;
    }
    final activeClient = client;
    if (activeClient == null) return photo;
    try {
      final signedUrl = await activeClient.storage
          .from(_familyPhotoBucket)
          .createSignedUrl(photo.photoUrl, 3600);
      return photo.copyWith(photoUrl: signedUrl);
    } catch (e) {
      debugPrint('Family photo URL error: $e');
      return photo;
    }
  }

  Future<void> _cacheFamilyPhoto(FamilyPhoto photo) async {
    if (!Hive.isBoxOpen(HiveBoxes.familyPhotos)) return;
    await HiveDatabase.familyPhotosBox.put(
      photo.id,
      HiveFamilyPhoto(
        id: photo.id,
        patientId: photo.patientId,
        name: photo.name,
        relationship: photo.relationship,
        photoUrl: photo.photoUrl,
        localPath: photo.localPath,
        localBytes: photo.localBytes,
        displayOrder: photo.displayOrder,
        isDeleted: photo.isDeleted,
        createdAt: photo.createdAt,
        updatedAt: photo.updatedAt,
      ),
    );
  }

  void _syncToHiveAndNotifications({
    required String reminderId,
    required String patientId,
    required String title,
    String? description,
    required String scheduleTime,
    required List<String> recurrenceDays,
    required bool isActive,
    bool isDeleted = false,
  }) {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.reminders)) return;
      final box = HiveDatabase.remindersBox;

      final parts = scheduleTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final now = DateTime.now();
      final scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);

      final notifService = NotificationService();

      if (isDeleted) {
        final existing = box.get(reminderId);
        if (existing != null) {
          notifService.cancelReminder(existing.notificationId);
          box.delete(reminderId);
        }
        return;
      }

      final existing = box.get(reminderId);
      final notificationId =
          existing?.notificationId ?? (reminderId.hashCode.abs() % 100000);

      // Cancel old notification before updating
      notifService.cancelReminder(notificationId);

      final hiveReminder = HiveReminder(
        id: reminderId,
        patientId: patientId,
        title: title,
        body: description ?? '',
        scheduledAt: scheduledAt,
        isActive: isActive,
        isCompleted: existing?.isCompleted ?? false,
        createdAt: existing?.createdAt ?? now,
        completedAt: existing?.completedAt,
        snoozedUntil: existing?.snoozedUntil,
        notificationId: notificationId,
        recurrenceRule: recurrenceDays.join(','),
      );

      box.put(reminderId, hiveReminder);

      // Reschedule new notification if active and not already completed
      if (isActive && !(existing?.isCompleted ?? false)) {
        notifService.scheduleReminder(Reminder.fromHive(hiveReminder));
      }
    } catch (e) {
      debugPrint('⚠️ Local Hive/Notification sync exception: $e');
    }
  }

  @override
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  ) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    CaregiverReminderRecord record;

    if (activeClient != null && status == NetworkStatus.online) {
      try {
        final insertData = input.toMap();
        insertData['created_at'] = DateTime.now().toUtc().toIso8601String();
        insertData['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await activeClient
            .from('reminders')
            .insert(insertData)
            .select()
            .single();

        record = CaregiverReminderRecord.fromMap(response);
        _offlineReminders.add(record);

        // Sync to local Hive and schedule notification
        _syncToHiveAndNotifications(
          reminderId: record.id,
          patientId: record.patientId,
          title: record.title,
          description: record.description,
          scheduleTime: record.scheduleTime,
          recurrenceDays: record.recurrenceDays,
          isActive: record.isActive,
        );

        return record;
      } catch (e) {
        debugPrint('⚠️ Remote reminder creation error: $e');
      }
    }

    // Offline fallback
    final fallbackId = _generateUuid();
    final now = DateTime.now();
    final parts = input.scheduleTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    record = CaregiverReminderRecord(
      id: fallbackId,
      patientId: input.patientId,
      title: input.title,
      description: input.description,
      reminderType: input.reminderType,
      scheduleTime: input.scheduleTime,
      scheduledAt: DateTime(now.year, now.month, now.day, hour, minute),
      recurrenceDays: input.recurrenceDays,
      isActive: input.isActive,
      isCompleted: false,
      status: 'pending',
    );
    _offlineReminders.add(record);

    // Sync to local Hive and schedule notification
    _syncToHiveAndNotifications(
      reminderId: record.id,
      patientId: record.patientId,
      title: record.title,
      description: record.description,
      scheduleTime: record.scheduleTime,
      recurrenceDays: record.recurrenceDays,
      isActive: record.isActive,
    );

    // Queue sync event
    try {
      final syncEvent = HiveSyncEvent(
        eventId: _generateUuid(),
        entityType: 'reminder',
        entityId: fallbackId,
        operation: 'create',
        payload: input.toMap(),
        createdAt: now,
        patientId: input.patientId,
      );
      HiveDatabase.syncQueueBox.put(syncEvent.eventId, syncEvent);
    } catch (_) {}

    return record;
  }

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    CaregiverReminderRecord record;

    if (activeClient != null && status == NetworkStatus.online) {
      try {
        final updateData = <String, dynamic>{
          'title': input.title.trim(),
          'reminder_type': input.reminderType,
          'schedule_time': input.scheduleTime.length == 5
              ? '${input.scheduleTime}:00'
              : input.scheduleTime,
          'recurrence_days': input.recurrenceDays,
          'is_active': input.isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (input.description != null) {
          updateData['description'] = input.description!.trim();
        }

        final response = await activeClient
            .from('reminders')
            .update(updateData)
            .eq('id', reminderId)
            .select()
            .single();

        record = CaregiverReminderRecord.fromMap(response);

        // Update offline cache
        _offlineReminders.removeWhere((r) => r.id == reminderId);
        _offlineReminders.add(record);

        // Sync to Hive and reschedule local notification
        _syncToHiveAndNotifications(
          reminderId: record.id,
          patientId: record.patientId,
          title: record.title,
          description: record.description,
          scheduleTime: record.scheduleTime,
          recurrenceDays: record.recurrenceDays,
          isActive: record.isActive,
        );

        return record;
      } catch (e) {
        debugPrint('⚠️ Remote reminder update error: $e');
      }
    }

    // Offline fallback: update in-memory
    final idx = _offlineReminders.indexWhere((r) => r.id == reminderId);
    final now = DateTime.now();
    final parts = input.scheduleTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    record = CaregiverReminderRecord(
      id: reminderId,
      patientId: input.patientId,
      title: input.title,
      description: input.description,
      reminderType: input.reminderType,
      scheduleTime: input.scheduleTime,
      scheduledAt: DateTime(now.year, now.month, now.day, hour, minute),
      recurrenceDays: input.recurrenceDays,
      isActive: input.isActive,
      isCompleted: idx >= 0 ? _offlineReminders[idx].isCompleted : false,
      status: idx >= 0 ? _offlineReminders[idx].status : 'pending',
    );

    if (idx >= 0) {
      _offlineReminders[idx] = record;
    } else {
      _offlineReminders.add(record);
    }

    // Sync to Hive and reschedule local notification
    _syncToHiveAndNotifications(
      reminderId: record.id,
      patientId: record.patientId,
      title: record.title,
      description: record.description,
      scheduleTime: record.scheduleTime,
      recurrenceDays: record.recurrenceDays,
      isActive: record.isActive,
    );

    // Queue sync event
    try {
      final syncEvent = HiveSyncEvent(
        eventId: _generateUuid(),
        entityType: 'reminder',
        entityId: reminderId,
        operation: 'update',
        payload: input.toMap(),
        createdAt: now,
        patientId: input.patientId,
      );
      HiveDatabase.syncQueueBox.put(syncEvent.eventId, syncEvent);
    } catch (_) {}

    return record;
  }

  @override
  Future<void> toggleReminderActive(String reminderId, bool isActive) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null && status == NetworkStatus.online) {
      try {
        await activeClient
            .from('reminders')
            .update({
              'is_active': isActive,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', reminderId);
      } catch (e) {
        debugPrint('⚠️ Remote toggle error: $e');
      }
    }

    // Update offline cache
    final idx = _offlineReminders.indexWhere((r) => r.id == reminderId);
    if (idx >= 0) {
      _offlineReminders[idx] = _offlineReminders[idx].copyWith(
        isActive: isActive,
      );
      final r = _offlineReminders[idx];
      _syncToHiveAndNotifications(
        reminderId: r.id,
        patientId: r.patientId,
        title: r.title,
        description: r.description,
        scheduleTime: r.scheduleTime,
        recurrenceDays: r.recurrenceDays,
        isActive: isActive,
      );
    } else if (Hive.isBoxOpen(HiveBoxes.reminders)) {
      final existing = HiveDatabase.remindersBox.get(reminderId);
      if (existing != null) {
        existing.isActive = isActive;
        existing.save();
        if (!isActive) {
          NotificationService().cancelReminder(existing.notificationId);
        } else if (!existing.isCompleted) {
          NotificationService().scheduleReminder(Reminder.fromHive(existing));
        }
      }
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null && status == NetworkStatus.online) {
      try {
        await activeClient
            .from('reminders')
            .update({
              'is_deleted': true,
              'is_active': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', reminderId);
      } catch (e) {
        debugPrint('⚠️ Remote delete error: $e');
      }
    }

    _offlineReminders.removeWhere((r) => r.id == reminderId);

    // Cancel notification and remove from Hive
    _syncToHiveAndNotifications(
      reminderId: reminderId,
      patientId: '',
      title: '',
      scheduleTime: '08:00',
      recurrenceDays: [],
      isActive: false,
      isDeleted: true,
    );
  }

  @override
  Future<List<DailyActivitySummary>> getSevenDayActivity(
    String patientId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Range: start of 6 days ago → end of today (UTC-aligned)
    final rangeStart = today.subtract(const Duration(days: 6)).toUtc();
    final rangeEnd = today.add(const Duration(days: 1)).toUtc();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Per-day counters keyed by "YYYY-MM-DD" in local time
    final Map<String, int> gamesPerDay = {};
    final Map<String, int> remindersPerDay = {};

    // Pre-fill 7 days with zeros
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      gamesPerDay[key] = 0;
      remindersPerDay[key] = 0;
    }

    final activeClient = client;
    final status = await _connectivityMonitor.checkStatus();

    if (activeClient != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty) {
      try {
        // 1. Count game sessions per day using completed_at
        final gamesResponse = await activeClient
            .from('game_sessions')
            .select('completed_at')
            .eq('patient_id', patientId)
            .gte('completed_at', rangeStart.toIso8601String())
            .lt('completed_at', rangeEnd.toIso8601String());

        for (final item in (gamesResponse as List)) {
          final map = item as Map<String, dynamic>;
          final completedAt = DateTime.tryParse(
            map['completed_at'] as String? ?? '',
          );
          if (completedAt != null) {
            final local = completedAt.toLocal();
            final key =
                '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
            if (gamesPerDay.containsKey(key)) {
              gamesPerDay[key] = (gamesPerDay[key] ?? 0) + 1;
            }
          }
        }

        // 2. Count acknowledged reminder logs per day using scheduled_for
        final logsResponse = await activeClient
            .from('reminder_logs')
            .select('scheduled_for, status')
            .eq('patient_id', patientId)
            .eq('status', 'acknowledged')
            .gte('scheduled_for', rangeStart.toIso8601String())
            .lt('scheduled_for', rangeEnd.toIso8601String());

        for (final item in (logsResponse as List)) {
          final map = item as Map<String, dynamic>;
          final scheduledFor = DateTime.tryParse(
            map['scheduled_for'] as String? ?? '',
          );
          if (scheduledFor != null) {
            final local = scheduledFor.toLocal();
            final key =
                '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
            if (remindersPerDay.containsKey(key)) {
              remindersPerDay[key] = (remindersPerDay[key] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Remote 7-day activity fetch error: $e');
        // Fall through — zeros are already populated, chart shows real zeros
      }
    } else {
      // Offline: also try Hive reminder logs for acknowledged reminders
      try {
        final localLogs = HiveDatabase.reminderLogsBox.values.where((log) {
          return log.patientId == patientId &&
              log.action == 'done' &&
              log.actionTimestamp.isAfter(rangeStart) &&
              log.actionTimestamp.isBefore(rangeEnd);
        });
        for (final log in localLogs) {
          final local = log.actionTimestamp.toLocal();
          final key =
              '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
          if (remindersPerDay.containsKey(key)) {
            remindersPerDay[key] = (remindersPerDay[key] ?? 0) + 1;
          }
        }
      } catch (_) {}
    }

    // Build ordered list from 6 days ago → today
    final List<DailyActivitySummary> summaries = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final games = gamesPerDay[key] ?? 0;
      final reminders = remindersPerDay[key] ?? 0;
      summaries.add(
        DailyActivitySummary(
          date: date,
          dayLabel: dayNames[date.weekday - 1],
          gamesCompleted: games,
          remindersCompleted: reminders,
          totalActivities: games + reminders,
        ),
      );
    }

    return summaries;
  }

  @override
  Future<CaregiverSyncInfo> getSyncStatus(String patientId) async {
    final networkStatus = await _connectivityMonitor.checkStatus();
    final isOnline = networkStatus == NetworkStatus.online;

    int pendingCount = 0;
    DateTime? lastSyncedAt;

    try {
      final events = HiveDatabase.syncQueueBox.values;
      pendingCount = events
          .where((e) => e.syncStatus == SyncStatus.pending)
          .length;

      // Derive last sync time from the most recently processed (non-pending) event
      final processedEvents = events
          .where((e) => e.syncStatus != SyncStatus.pending)
          .toList();
      if (processedEvents.isNotEmpty) {
        processedEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        lastSyncedAt = processedEvents.first.createdAt;
      } else if (isOnline && pendingCount == 0) {
        // Online with no pending events — consider freshly synced at session start
        lastSyncedAt = null;
      }
    } catch (_) {}

    return CaregiverSyncInfo(
      pendingEventsCount: pendingCount,
      isOnline: isOnline,
      lastSyncedAt: lastSyncedAt,
      statusLabel: isOnline
          ? (pendingCount == 0
                ? 'All activities synchronized'
                : '$pendingCount pending updates syncing...')
          : 'Operating Offline — records queued locally',
    );
  }

  static String _formatGameTitle(String type) {
    switch (type) {
      case 'remember_objects':
        return 'Remember Objects';
      case 'who_is_this':
        return 'Who Is This?';
      case 'grocery_memory':
        return 'Grocery Memory';
      default:
        return type
            .split('_')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
    }
  }

  /// Converts an integer difficulty_level (1–5) to a display string.
  /// Level 1 → easy, 2 → medium, 3+ → hard.
  static String _difficultyLevelToString(int level) {
    switch (level) {
      case 1:
        return 'easy';
      case 2:
        return 'medium';
      default:
        return 'hard';
    }
  }
}
