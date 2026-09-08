// ==============================================================================
// NIRVANA - Sync Engine Unit & Integration Tests
// Description: Tests queueing, synchronization, duplicate event handling,
// retries with exponential backoff, and dead-letter classification.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/core/network/sync_engine.dart';
import 'package:nirvana/database/adapters/hive_adapters.dart';
import 'package:nirvana/database/hive_boxes.dart';
import 'package:nirvana/database/models/hive_sync_event.dart';
import 'package:nirvana/core/contracts/supabase_repository_contracts.dart';

class MockConnectivityMonitor implements IConnectivityMonitor {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus currentStatus = NetworkStatus.offline;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  @override
  Future<NetworkStatus> checkStatus() async => currentStatus;

  void emit(NetworkStatus status) {
    currentStatus = status;
    _controller.add(status);
  }

  void dispose() {
    _controller.close();
  }
}

class MockSupabaseSyncRepository implements ISupabaseSyncRepository {
  final List<Map<String, dynamic>> receivedCalls = [];
  bool shouldFail = false;
  bool returnDuplicate = false;
  String? failMessage;

  @override
  Future<Map<String, dynamic>> processSyncEvent({
    required String eventId,
    required String patientId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
  }) async {
    receivedCalls.add({
      'event_id': eventId,
      'patient_id': patientId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'created_at': createdAt,
    });

    if (shouldFail) {
      throw Exception(failMessage ?? 'Network connection timeout');
    }

    if (returnDuplicate) {
      return {
        'status': 'duplicate',
        'message': 'Event already applied idempotently',
      };
    }

    return {'status': 'success', 'applied': true};
  }

  @override
  Future<Map<String, dynamic>> processSyncEventsBatch({
    required List<Map<String, dynamic>> events,
  }) async {
    return {'status': 'success', 'count': events.length};
  }
}

void main() {
  late Directory tempDir;
  late Box<HiveSyncEvent> syncBox;
  late MockConnectivityMonitor mockMonitor;
  late MockSupabaseSyncRepository mockSyncRepo;
  late SyncEngine syncEngine;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('nirvana_sync_test_');
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
    syncBox = await Hive.openBox<HiveSyncEvent>(
      'sync_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    mockMonitor = MockConnectivityMonitor();
    mockSyncRepo = MockSupabaseSyncRepository();
    syncEngine = SyncEngine(
      syncQueueBox: syncBox,
      syncRepository: mockSyncRepo,
      connectivityMonitor: mockMonitor,
      maxRetries: 3,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    mockMonitor.dispose();
    await syncBox.close();
  });

  group('SyncEngine Offline & Queueing Tests', () {
    test(
      'enqueues event offline without throwing and stores status as pending',
      () async {
        mockMonitor.currentStatus = NetworkStatus.offline;

        final event = HiveSyncEvent(
          eventId: 'event-offline-1',
          entityType: 'reminder',
          entityId: 'rem-1',
          operation: 'create',
          payload: {'title': 'Hydration'},
          createdAt: DateTime.now(),
          patientId: 'pat-1',
        );

        await syncEngine.enqueueEvent(event);

        expect(syncBox.length, equals(1));
        final stored = syncBox.get('event-offline-1');
        expect(stored, isNotNull);
        expect(stored!.syncStatus, equals(SyncStatus.pending));
        expect(stored.retryCount, equals(0));
        expect(mockSyncRepo.receivedCalls.isEmpty, isTrue);
      },
    );

    test('calculates exponential backoff correctly', () {
      expect(syncEngine.calculateBackoff(0), equals(Duration.zero));
      expect(
        syncEngine.calculateBackoff(1),
        equals(const Duration(seconds: 2)),
      );
      expect(
        syncEngine.calculateBackoff(2),
        equals(const Duration(seconds: 4)),
      );
      expect(
        syncEngine.calculateBackoff(3),
        equals(const Duration(seconds: 8)),
      );
      expect(
        syncEngine.calculateBackoff(4),
        equals(const Duration(seconds: 16)),
      );
      expect(
        syncEngine.calculateBackoff(5),
        equals(const Duration(seconds: 32)),
      );
      expect(
        syncEngine.calculateBackoff(6),
        equals(const Duration(seconds: 60)),
      ); // Capped at 60
    });
  });

  group('SyncEngine Synchronization & Idempotency Tests', () {
    test(
      'processes pending queue successfully when online and marks events synced',
      () async {
        mockMonitor.currentStatus = NetworkStatus.online;

        final event1 = HiveSyncEvent(
          eventId: 'event-1',
          entityType: 'reminder',
          entityId: 'rem-1',
          operation: 'create',
          payload: {'title': 'Meds'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          patientId: 'pat-1',
        );

        final event2 = HiveSyncEvent(
          eventId: 'event-2',
          entityType: 'reminder_log',
          entityId: 'log-1',
          operation: 'create',
          payload: {'action': 'done'},
          createdAt: DateTime.now(),
          patientId: 'pat-1',
        );

        await syncBox.put(event1.eventId, event1);
        await syncBox.put(event2.eventId, event2);

        final result = await syncEngine.processQueue();

        expect(result.totalProcessed, equals(2));
        expect(result.succeeded, equals(2));
        expect(result.failed, equals(0));

        expect(syncBox.get('event-1')!.syncStatus, equals(SyncStatus.synced));
        expect(syncBox.get('event-2')!.syncStatus, equals(SyncStatus.synced));
        expect(mockSyncRepo.receivedCalls.length, equals(2));
      },
    );

    test('handles duplicate event IDs idempotently without error', () async {
      mockMonitor.currentStatus = NetworkStatus.online;
      mockSyncRepo.returnDuplicate = true;

      final event = HiveSyncEvent(
        eventId: 'event-duplicate-1',
        entityType: 'reminder',
        entityId: 'rem-1',
        operation: 'create',
        payload: {'title': 'Already in cloud'},
        createdAt: DateTime.now(),
        patientId: 'pat-1',
      );

      await syncBox.put(event.eventId, event);
      final result = await syncEngine.processQueue();

      expect(result.succeeded, equals(1));
      expect(
        syncBox.get('event-duplicate-1')!.syncStatus,
        equals(SyncStatus.synced),
      );
    });
  });

  group('SyncEngine Retry & Dead Letter Tests', () {
    test(
      'increments retry count on network failure and preserves pending status',
      () async {
        mockMonitor.currentStatus = NetworkStatus.online;
        mockSyncRepo.shouldFail = true;

        final event = HiveSyncEvent(
          eventId: 'event-fail-1',
          entityType: 'reminder',
          entityId: 'rem-1',
          operation: 'create',
          payload: {},
          createdAt: DateTime.now(),
          patientId: 'pat-1',
        );

        await syncBox.put(event.eventId, event);
        final result = await syncEngine.processQueue();

        expect(result.failed, equals(1));
        expect(result.succeeded, equals(0));

        final stored = syncBox.get('event-fail-1')!;
        expect(stored.retryCount, equals(1));
        expect(stored.syncStatus, equals(SyncStatus.pending));
      },
    );

    test(
      'marks event as dead_letter when retry count reaches maxRetries',
      () async {
        mockMonitor.currentStatus = NetworkStatus.online;
        mockSyncRepo.shouldFail = true;

        final event = HiveSyncEvent(
          eventId: 'event-deadletter-1',
          entityType: 'reminder',
          entityId: 'rem-1',
          operation: 'create',
          payload: {},
          createdAt: DateTime.now(),
          patientId: 'pat-1',
          retryCount: 2, // maxRetries is 3 in setUp
        );

        await syncBox.put(event.eventId, event);

        // Attempt 3: should increment to 3 and mark deadLetter
        final result = await syncEngine.processQueue();

        expect(result.deadLettered, equals(1));
        final stored = syncBox.get('event-deadletter-1')!;
        expect(stored.retryCount, equals(3));
        expect(stored.syncStatus, equals(SyncStatus.deadLetter));
      },
    );
  });
}
