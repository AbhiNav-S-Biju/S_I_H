// ==============================================================================
// NIRVANA - Game Session Providers
// Description: Riverpod providers for recording and fetching game sessions.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../repositories/game_session_repository.dart';
import '../repositories/supabase_game_session_repository.dart';

/// Provider for Game Session Repository
final gameSessionRepositoryProvider = Provider<IGameSessionRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabaseGameSessionRepository(connectivityMonitor: monitor);
});
