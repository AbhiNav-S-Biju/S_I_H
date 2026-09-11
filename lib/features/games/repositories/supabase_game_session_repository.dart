// ==============================================================================
// NIRVANA - Supabase Game Session Repository Implementation
// Description: Implements IGameSessionRepository to persist completed game sessions
// directly into Supabase game_sessions table and local Hive sync queue.
// ==============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_database.dart';
import '../../../database/models/hive_sync_event.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import 'game_session_repository.dart';

class SupabaseGameSessionRepository implements IGameSessionRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;

  SupabaseGameSessionRepository({
    SupabaseClient? client,
    IConnectivityMonitor? connectivityMonitor,
  }) : _client = client,
       _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor();

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String _generateUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  int _difficultyToInt(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 1;
      case GameDifficulty.medium:
        return 2;
      case GameDifficulty.hard:
        return 3;
    }
  }

  @override
  Future<void> recordGameSession({
    required GameSession session,
    String? patientId,
    String? deviceId,
  }) async {
    final effectivePatientId =
        patientId ??
        HiveDatabase.pairedPatientId ??
        HiveDatabase.currentPatientSession?.patientId;

    if (effectivePatientId == null || effectivePatientId.isEmpty) {
      debugPrint(
        '⚠️ Warning: No active patient ID found for recording game session.',
      );
      return;
    }

    final sessionId = session.id.isNotEmpty ? session.id : _generateUuid();
    final effectiveDeviceId = deviceId ?? HiveDatabase.getOrCreateDeviceId();
    final startedAt = session.completedAt
        .subtract(Duration(seconds: session.durationSeconds))
        .toUtc();
    final completedAt = session.completedAt.toUtc();

    final payload = <String, dynamic>{
      'id': sessionId,
      'patient_id': effectivePatientId,
      'game_type': session.gameType.id,
      'difficulty_level': _difficultyToInt(session.difficulty),
      'total_trials': session.totalQuestions,
      'successful_trials': session.correctAnswers,
      'duration_seconds': session.durationSeconds,
      'activity_metadata': session.activityMetadata,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'device_id': effectiveDeviceId,
    };

    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    // Patient devices use the anonymous Supabase role. Write through the
    // device-authorized RPC instead of attempting a caregiver-only RLS insert.
    if (client != null && status == NetworkStatus.online) {
      final isAuthenticated = client.auth.currentUser != null;
      if (!isAuthenticated) {
        try {
          await client.rpc(
            'record_patient_game_session',
            params: {
              'p_patient_id': effectivePatientId,
              'p_device_id': effectiveDeviceId,
              'p_session': payload,
            },
          );
          debugPrint(
            '✅ Patient game session recorded through paired-device RPC for patient: $effectivePatientId',
          );
          return;
        } catch (e) {
          debugPrint(
            '⚠️ Patient game session RPC failed; queueing sync event: $e',
          );
        }
      }

      if (isAuthenticated) {
        // Caregiver-authenticated clients can use the existing RLS insert.
        try {
          await client.from('game_sessions').upsert(payload);
          debugPrint(
            '✅ Game session successfully recorded in Supabase for patient: $effectivePatientId',
          );
        } catch (e) {
          debugPrint(
            '⚠️ Failed to directly insert game session to Supabase: $e',
          );
        }
      }
    }

    // 2. Offline sync event queue for local resilience
    try {
      final syncEvent = HiveSyncEvent(
        eventId: _generateUuid(),
        entityType: 'game_session',
        entityId: sessionId,
        operation: 'create',
        payload: payload,
        createdAt: session.completedAt,
        patientId: effectivePatientId,
      );
      await HiveDatabase.syncQueueBox.put(syncEvent.eventId, syncEvent);
      debugPrint('📥 Enqueued game session sync event: ${syncEvent.eventId}');
    } catch (e) {
      debugPrint('⚠️ Could not enqueue game session sync event: $e');
    }
  }

  @override
  Future<List<GameSession>> getRecentGameSessions(
    String patientId, {
    int limit = 50,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty) {
      try {
        final response = await client
            .from('game_sessions')
            .select()
            .eq('patient_id', patientId)
            .order('completed_at', ascending: false)
            .limit(limit);

        return (response as List).map((item) {
          final map = item as Map<String, dynamic>;
          final typeId = map['game_type'] as String? ?? 'remember_objects';
          final diffLevel = (map['difficulty_level'] as num?)?.toInt() ?? 1;

          final gameType = GameType.values.firstWhere(
            (g) => g.id == typeId || g.name == typeId,
            orElse: () => GameType.rememberObjects,
          );

          final difficulty = diffLevel <= 1
              ? GameDifficulty.easy
              : (diffLevel == 2 ? GameDifficulty.medium : GameDifficulty.hard);

          return GameSession(
            id: map['id'] as String? ?? '',
            gameType: gameType,
            difficulty: difficulty,
            score: 0,
            correctAnswers: (map['successful_trials'] as num?)?.toInt() ?? 0,
            totalQuestions: (map['total_trials'] as num?)?.toInt() ?? 0,
            hintsUsed: 0,
            durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
            completedAt:
                DateTime.tryParse(map['completed_at'] as String? ?? '') ??
                DateTime.now(),
            activityMetadata:
                (map['activity_metadata'] as Map<String, dynamic>?) ?? {},
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Failed to fetch recent game sessions: $e');
      }
    }

    return [];
  }
}
