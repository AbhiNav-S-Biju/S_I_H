// ==============================================================================
// NIRVANA - Supabase Sync Repository
// Description: Implementation of ISupabaseSyncRepository for cloud synchronization.
// Calls the idempotent PostgreSQL RPC functions defined in Supabase migrations.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../contracts/supabase_repository_contracts.dart';

class SupabaseSyncRepository implements ISupabaseSyncRepository {
  final SupabaseClient? _client;

  SupabaseSyncRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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
    final activeClient = client;
    if (activeClient == null) {
      throw const PostgrestException(
        message: 'Supabase client is not initialized.',
      );
    }

    try {
      final response = await activeClient.rpc(
        'process_sync_event',
        params: {
          'p_event_id': eventId,
          'p_patient_id': patientId,
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_operation': operation,
          'p_payload': payload,
          'p_created_at': createdAt.toUtc().toIso8601String(),
        },
      );

      if (response is Map) {
        return response.cast<String, dynamic>();
      }
      return {'status': 'success', 'result': response};
    } catch (e) {
      debugPrint('❌ SupabaseSyncRepository error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> processSyncEventsBatch({
    required List<Map<String, dynamic>> events,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      throw const PostgrestException(
        message: 'Supabase client is not initialized.',
      );
    }

    try {
      final response = await activeClient.rpc(
        'process_sync_events_batch',
        params: {'p_events': events},
      );

      if (response is Map) {
        return response.cast<String, dynamic>();
      }
      return {'status': 'success', 'result': response};
    } catch (e) {
      debugPrint('❌ SupabaseSyncRepository batch error: $e');
      rethrow;
    }
  }
}
