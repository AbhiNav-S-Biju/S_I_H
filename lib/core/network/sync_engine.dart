// ==============================================================================
// NIRVANA - Sync Engine
// Description: Offline-first sync engine. Queues all locally generated mutations
// into Hive and synchronizes them idempotently to Supabase via RPC with
// exponential backoff, retry management, and network state monitoring.
// ==============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../database/hive_database.dart';
import '../../database/models/hive_sync_event.dart';
import '../contracts/supabase_repository_contracts.dart';
import 'connectivity_monitor.dart';
import 'supabase_sync_repository.dart';

class SyncResult {
  final int totalProcessed;
  final int succeeded;
  final int failed;
  final int deadLettered;

  const SyncResult({
    required this.totalProcessed,
    required this.succeeded,
    required this.failed,
    required this.deadLettered,
  });

  @override
  String toString() =>
      'SyncResult(total: $totalProcessed, succeeded: $succeeded, failed: $failed, deadLettered: $deadLettered)';
}

class SyncEngine {
  final Box<HiveSyncEvent> _syncQueueBox;
  final ISupabaseSyncRepository _syncRepository;
  final IConnectivityMonitor _connectivityMonitor;
  final int maxRetries;
  final void Function(int syncedCount, String? patientId)? onSyncRestored;
  final void Function(String error, String? patientId)? onSyncError;

  StreamSubscription<NetworkStatus>? _connectivitySub;
  bool _isProcessing = false;

  SyncEngine({
    required Box<HiveSyncEvent> syncQueueBox,
    required ISupabaseSyncRepository syncRepository,
    required IConnectivityMonitor connectivityMonitor,
    this.onSyncRestored,
    this.onSyncError,
    this.maxRetries = 8,
  }) : _syncQueueBox = syncQueueBox,
       _syncRepository = syncRepository,
       _connectivityMonitor = connectivityMonitor {
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySub = _connectivityMonitor.statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        debugPrint(
          '🌐 Network online detected. Triggering sync queue processing...',
        );
        processQueue();
      }
    });
  }

  /// Calculates exponential backoff duration based on retry count.
  Duration calculateBackoff(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    final delaySeconds = math.min(math.pow(2, retryCount).toInt(), 60);
    return Duration(seconds: delaySeconds);
  }

  /// Enqueues a new sync event locally and attempts immediate sync if online.
  Future<void> enqueueEvent(HiveSyncEvent event) async {
    await _syncQueueBox.put(event.eventId, event);
    debugPrint(
      '📥 Enqueued sync event: ${event.eventId} (${event.entityType}:${event.operation})',
    );

    // Attempt sync in background if online
    final status = await _connectivityMonitor.checkStatus();
    if (status == NetworkStatus.online) {
      unawaited(processQueue());
    }
  }

  /// Retrieves all pending events sorted by creation date.
  List<HiveSyncEvent> getPendingEvents() {
    final events = _syncQueueBox.values
        .where((e) => e.syncStatus == SyncStatus.pending)
        .toList();
    events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return events;
  }

  /// Processes all pending events in the sync queue.
  Future<SyncResult> processQueue() async {
    if (_isProcessing) {
      debugPrint(
        '⏳ SyncEngine is already processing. Skipping duplicate trigger.',
      );
      return const SyncResult(
        totalProcessed: 0,
        succeeded: 0,
        failed: 0,
        deadLettered: 0,
      );
    }

    _isProcessing = true;
    int succeeded = 0;
    int failed = 0;
    int deadLettered = 0;

    try {
      final pendingEvents = getPendingEvents();
      if (pendingEvents.isEmpty) {
        return const SyncResult(
          totalProcessed: 0,
          succeeded: 0,
          failed: 0,
          deadLettered: 0,
        );
      }

      debugPrint(
        '🚀 Processing ${pendingEvents.length} pending sync events...',
      );

      for (final event in pendingEvents) {
        // Dead letter check
        if (event.retryCount >= maxRetries) {
          event.syncStatus = SyncStatus.deadLetter;
          await event.save();
          deadLettered++;
          continue;
        }

        try {
          final response = await _syncRepository.processSyncEvent(
            eventId: event.eventId,
            patientId: event.patientId,
            entityType: event.entityType,
            entityId: event.entityId,
            operation: event.operation,
            payload: event.payload,
            createdAt: event.createdAt,
          );

          // If the server returns success (or duplicate already processed)
          final isSuccess =
              response['status'] == 'success' ||
              response['status'] == 'duplicate' ||
              response['result'] != null ||
              !response.containsKey('error');

          if (isSuccess) {
            event.syncStatus = SyncStatus.synced;
            await event.save();
            succeeded++;
            debugPrint('✅ Synced event: ${event.eventId}');
          } else {
            throw Exception(
              response['error'] ?? 'Sync RPC returned error status',
            );
          }
        } catch (e) {
          failed++;
          event.retryCount += 1;
          if (event.retryCount >= maxRetries) {
            event.syncStatus = SyncStatus.deadLetter;
            deadLettered++;
            debugPrint(
              '⚠️ Event ${event.eventId} marked DEAD LETTER after $maxRetries retries.',
            );
          } else {
            debugPrint(
              '❌ Failed syncing event ${event.eventId} (retry: ${event.retryCount}): $e',
            );
          }
          await event.save();
        }
      }

      final pId = pendingEvents.isNotEmpty ? pendingEvents.first.patientId : null;
      if (succeeded > 0) {
        onSyncRestored?.call(succeeded, pId);
      }
      if (deadLettered > 0) {
        onSyncError?.call('$deadLettered item(s) exceeded max retry limit.', pId);
      }

      return SyncResult(
        totalProcessed: pendingEvents.length,
        succeeded: succeeded,
        failed: failed,
        deadLettered: deadLettered,
      );
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}

/// Riverpod Providers
final syncRepositoryProvider = Provider<ISupabaseSyncRepository>((ref) {
  return SupabaseSyncRepository();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  final monitor = ref.watch(connectivityMonitorProvider);
  final box = HiveDatabase.syncQueueBox;

  final engine = SyncEngine(
    syncQueueBox: box,
    syncRepository: repository,
    connectivityMonitor: monitor,
  );

  ref.onDispose(engine.dispose);
  return engine;
});
