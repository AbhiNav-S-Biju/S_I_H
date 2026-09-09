// ==============================================================================
// NIRVANA - Supabase Caregiver Notification Repository Implementation
// Description: Implements ICaregiverNotificationRepository with Supabase Realtime
// stream subscriptions and offline-first cache fallback.
// ==============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../models/caregiver_models.dart';
import 'caregiver_notification_repository.dart';

class SupabaseCaregiverNotificationRepository
    implements ICaregiverNotificationRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;

  // In-memory cache for offline resilience & immediate reactive UI
  static final List<CaregiverNotification> _localNotifications = [];
  static final StreamController<List<CaregiverNotification>> _localStreamController =
      StreamController<List<CaregiverNotification>>.broadcast();

  SupabaseCaregiverNotificationRepository({
    SupabaseClient? client,
    IConnectivityMonitor? connectivityMonitor,
  })  : _client = client,
        _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor();

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CaregiverNotification>> getNotifications(
    String caregiverId, {
    String? patientId,
    int limit = 100,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online && caregiverId.isNotEmpty) {
      try {
        var query = client
            .from('caregiver_notifications')
            .select('*, patients(display_name, preferred_name)')
            .eq('caregiver_id', caregiverId);

        if (patientId != null && patientId.isNotEmpty) {
          query = query.eq('patient_id', patientId);
        }

        final response = await query
            .order('created_at', ascending: false)
            .limit(limit);

        final remoteList = (response as List).map((item) {
          final map = item as Map<String, dynamic>;
          String? patientName;
          if (map['patients'] is Map) {
            final pMap = map['patients'] as Map;
            patientName = (pMap['preferred_name'] as String?) ??
                (pMap['display_name'] as String?);
          }
          return CaregiverNotification.fromMap({
            ...map,
            if (patientName != null) 'patient_name': patientName,
          });
        }).toList();

        // Update local cache
        for (final item in remoteList) {
          final idx = _localNotifications.indexWhere((n) => n.id == item.id);
          if (idx >= 0) {
            _localNotifications[idx] = item;
          } else {
            _localNotifications.add(item);
          }
        }
        _notifyLocalStream();

        return remoteList;
      } catch (e) {
        debugPrint('⚠️ Error fetching caregiver notifications: $e');
      }
    }

    // Offline / fallback cache
    final filtered = _localNotifications.where((n) {
      final matchesCaregiver = caregiverId.isEmpty || n.caregiverId == caregiverId;
      final matchesPatient =
          patientId == null || patientId.isEmpty || n.patientId == patientId;
      return matchesCaregiver && matchesPatient;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(filtered);
  }

  @override
  Stream<List<CaregiverNotification>> getNotificationsStream(
    String caregiverId, {
    String? patientId,
  }) async* {
    List<CaregiverNotification> filter(List<CaregiverNotification> list) {
      final filtered = list.where((n) {
        final matchesCaregiver =
            caregiverId.isEmpty || n.caregiverId == caregiverId;
        final matchesPatient =
            patientId == null || patientId.isEmpty || n.patientId == patientId;
        return matchesCaregiver && matchesPatient;
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(filtered);
    }

    // Immediately yield initial cache so StreamProvider has data on first frame
    yield filter(_localNotifications);

    // Try to fetch current data from Supabase (non-realtime) and merge
    try {
      final freshData = await getNotifications(caregiverId, patientId: patientId);
      if (freshData.isNotEmpty) {
        yield filter(_localNotifications);
      }
    } catch (e) {
      debugPrint('⚠️ Initial notification fetch failed: $e');
    }

    final client = _activeClient;
    if (client != null && caregiverId.isNotEmpty) {
      // Attempt Supabase Realtime — but handle async errors gracefully
      // by catching them within the stream rather than letting them propagate
      var realtimeSucceeded = false;
      try {
        final realtimeStream = client
            .from('caregiver_notifications')
            .stream(primaryKey: ['id'])
            .eq('caregiver_id', caregiverId)
            .order('created_at', ascending: false)
            .map((rows) {
              final list = rows
                  .map((r) => CaregiverNotification.fromMap(r))
                  .where((n) {
                    if (patientId == null || patientId.isEmpty) return true;
                    return n.patientId == patientId;
                  })
                  .toList();

              for (final item in list) {
                final idx =
                    _localNotifications.indexWhere((n) => n.id == item.id);
                if (idx >= 0) {
                  _localNotifications[idx] = item;
                } else {
                  _localNotifications.add(item);
                }
              }

              return list;
            })
            .handleError((Object error) {
              debugPrint(
                '⚠️ Supabase Realtime stream error (falling back to polling): $error',
              );
            });

        await for (final data in realtimeStream) {
          realtimeSucceeded = true;
          yield data;
        }
        if (realtimeSucceeded) return;
      } catch (e) {
        debugPrint('⚠️ Supabase Realtime stream subscription error: $e');
      }
    }

    // Fallback: local stream controller for offline / Realtime-disabled setups
    yield* _localStreamController.stream.map(filter);
  }

  @override
  Future<void> createNotification(CaregiverNotification notification) async {
    // 1. Add to local cache immediately
    final idx = _localNotifications.indexWhere((n) => n.id == notification.id);
    if (idx >= 0) {
      _localNotifications[idx] = notification;
    } else {
      _localNotifications.insert(0, notification);
    }
    _notifyLocalStream();

    // 2. Persist to Supabase if online
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online) {
      try {
        await client.from('caregiver_notifications').upsert(notification.toMap());
        debugPrint('🔔 Caregiver notification created in Supabase: ${notification.title}');
      } catch (e) {
        debugPrint('⚠️ Error persisting caregiver notification: $e');
      }
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // Update local cache
    final idx = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      _localNotifications[idx] = _localNotifications[idx].copyWith(isRead: true);
      _notifyLocalStream();
    }

    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online) {
      try {
        await client
            .from('caregiver_notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      } catch (e) {
        debugPrint('⚠️ Error marking notification as read: $e');
      }
    }
  }

  @override
  Future<void> markAllAsRead(String caregiverId) async {
    // Update local cache
    for (int i = 0; i < _localNotifications.length; i++) {
      if (caregiverId.isEmpty || _localNotifications[i].caregiverId == caregiverId) {
        _localNotifications[i] = _localNotifications[i].copyWith(isRead: true);
      }
    }
    _notifyLocalStream();

    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online && caregiverId.isNotEmpty) {
      try {
        await client
            .from('caregiver_notifications')
            .update({'is_read': true})
            .eq('caregiver_id', caregiverId)
            .eq('is_read', false);
      } catch (e) {
        debugPrint('⚠️ Error marking all notifications as read: $e');
      }
    }
  }

  @override
  Future<int> getUnreadCount(String caregiverId) async {
    final list = await getNotifications(caregiverId);
    return list.where((n) => !n.isRead).length;
  }

  static void _notifyLocalStream() {
    if (!_localStreamController.isClosed) {
      _localStreamController.add(List.unmodifiable(_localNotifications));
    }
  }
}
