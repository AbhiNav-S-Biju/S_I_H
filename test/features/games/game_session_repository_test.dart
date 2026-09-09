// ==============================================================================
// NIRVANA - Game Session Repository Unit Tests
// Description: Tests GameSession persistence, patient ID scoping, and sync queue.
// ==============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/database/adapters/hive_adapters.dart';
import 'package:nirvana/database/hive_boxes.dart';
import 'package:nirvana/database/hive_database.dart';
import 'package:nirvana/database/models/hive_sync_event.dart';
import 'package:nirvana/features/games/games.dart';

class MockOfflineConnectivityMonitor implements IConnectivityMonitor {
  @override
  Stream<NetworkStatus> get statusStream => const Stream.empty();

  @override
  Future<NetworkStatus> checkStatus() async => NetworkStatus.offline;
}

void main() {
  late Directory tempDir;
  late IGameSessionRepository repository;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('nirvana_game_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveSyncEvent)) {
      Hive.registerAdapter(HiveSyncEventAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    if (!Hive.isBoxOpen(HiveBoxes.syncQueue)) {
      await Hive.openBox<HiveSyncEvent>(HiveBoxes.syncQueue);
    }

    repository = SupabaseGameSessionRepository(
      connectivityMonitor: MockOfflineConnectivityMonitor(),
    );
  });

  group('GameSessionRepository Tests', () {
    test('recordGameSession stores sync event with correct patientId in offline mode', () async {
      const testPatientId = '33333333-3333-4333-8333-333333333333';
      final session = GameSession(
        id: 'test-session-001',
        gameType: GameType.rememberObjects,
        difficulty: GameDifficulty.easy,
        score: 350,
        correctAnswers: 3,
        totalQuestions: 3,
        hintsUsed: 0,
        durationSeconds: 45,
        completedAt: DateTime.now(),
        activityMetadata: {'test': true},
      );

      await repository.recordGameSession(
        session: session,
        patientId: testPatientId,
      );

      // Verify sync event was enqueued with the correct patientId
      final syncEvents = HiveDatabase.syncQueueBox.values.toList();
      expect(syncEvents, isNotEmpty);

      final matchingEvent = syncEvents.firstWhere(
        (e) => e.entityId == 'test-session-001',
      );
      expect(matchingEvent.patientId, equals(testPatientId));
      expect(matchingEvent.entityType, equals('game_session'));
      expect(matchingEvent.payload['patient_id'], equals(testPatientId));
      expect(matchingEvent.payload['game_type'], equals('remember_objects'));
      expect(matchingEvent.payload['successful_trials'], equals(3));
      expect(matchingEvent.payload['total_trials'], equals(3));
      expect(matchingEvent.payload['difficulty_level'], equals(1));
    });

    test('getRecentGameSessions returns empty list when offline without client', () async {
      final sessions = await repository.getRecentGameSessions(
        '33333333-3333-4333-8333-333333333333',
      );
      expect(sessions, isEmpty);
    });
  });
}
