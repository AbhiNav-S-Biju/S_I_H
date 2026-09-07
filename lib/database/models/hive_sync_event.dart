// ==============================================================================
// NIRVANA - HiveSyncEvent Model
// Description: Local sync queue event that carries every cloud-bound mutation
// until Supabase becomes reachable. Matches the idempotent RPC contract.
// ==============================================================================

import 'package:hive/hive.dart';

/// Sync status values for a queued event.
class SyncStatus {
  static const String pending = 'pending';
  static const String synced = 'synced';
  static const String deadLetter = 'dead_letter';
}

class HiveSyncEvent extends HiveObject {
  String eventId; // UUID v4 — idempotency key
  String entityType; // 'reminder' | 'reminder_log'
  String entityId; // UUID of the target entity
  String operation; // 'create' | 'update' | 'delete'
  Map<String, dynamic> payload; // Full entity snapshot
  DateTime createdAt; // Local device time of event creation
  int retryCount; // Number of failed upload attempts
  String syncStatus;
  String patientId; // Required by Supabase RPC

  HiveSyncEvent({
    required this.eventId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.patientId,
    this.retryCount = 0,
    this.syncStatus = SyncStatus.pending,
  });

  Map<String, dynamic> toRpcPayload() => {
        'event_id': eventId,
        'patient_id': patientId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
