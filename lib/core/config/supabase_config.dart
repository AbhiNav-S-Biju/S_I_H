// ==============================================================================
// NIRVANA - Supabase Client Configuration
// Description: Credentials are injected at build time, never committed.
//
// Copy `.env.example` to `.env`, fill in your values, then run/build with:
//   flutter run --dart-define-from-file=.env
//   flutter build apk --dart-define-from-file=.env
// ==============================================================================

class SupabaseConfig {
  /// Supabase Project URL (Dashboard -> Project Settings -> API -> Project URL)
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase 'anon' (public) key
  /// (Dashboard -> Project Settings -> API -> Project API Keys -> 'anon' 'public')
  /// IMPORTANT: NEVER use the 'service_role' key in Flutter!
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True once both values were supplied via --dart-define / --dart-define-from-file
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
