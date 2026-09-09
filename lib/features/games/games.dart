// ==============================================================================
// NIRVANA - Games Module Barrel Export
// Description: Clean public interface for cognitive engagement games
// ==============================================================================

// Models
export 'models/game_enums.dart';
export 'models/game_session.dart';
export 'models/game_item.dart';
export 'models/family_member_item.dart';
export 'models/puzzle_item.dart';
export 'models/game_level.dart';

// Controllers
export 'controllers/remember_objects_controller.dart';
export 'controllers/who_is_this_controller.dart';
export 'controllers/grocery_memory_controller.dart';
export 'controllers/jigsaw_puzzle_controller.dart';

// Services, Repositories & Providers
export 'services/game_progress_service.dart';
export 'repositories/game_session_repository.dart';
export 'repositories/supabase_game_session_repository.dart';
export 'providers/game_session_providers.dart';

// Presentation
export 'presentation/game_level_map_screen.dart';
export 'presentation/remember_objects/remember_objects_screen.dart';
export 'presentation/who_is_this/who_is_this_screen.dart';
export 'presentation/grocery_memory/grocery_memory_screen.dart';
export 'presentation/jigsaw_puzzle/jigsaw_puzzle_screen.dart';
export 'presentation/games_hub_screen.dart';
export 'presentation/widgets/elder_game_button.dart';
export 'presentation/widgets/elder_game_card.dart';
export 'presentation/widgets/game_header.dart';
export 'presentation/widgets/game_completion_dialog.dart';
export 'presentation/widgets/game_level_map_path.dart';
export 'presentation/widgets/level_preview_sheet.dart';
