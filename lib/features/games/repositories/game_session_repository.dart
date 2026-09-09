// ==============================================================================
// NIRVANA - Game Session Repository Contract
// Description: Defines operations for recording completed cognitive activities
// and fetching historical activity sessions for elders.
// ==============================================================================

import '../models/game_session.dart';

abstract class IGameSessionRepository {
  /// Records a completed game session for the given patient.
  /// Automatically stores in Supabase game_sessions table and queues sync event.
  Future<void> recordGameSession({
    required GameSession session,
    String? patientId,
  });

  /// Retrieves historical game sessions for a patient.
  Future<List<GameSession>> getRecentGameSessions(
    String patientId, {
    int limit = 50,
  });
}
