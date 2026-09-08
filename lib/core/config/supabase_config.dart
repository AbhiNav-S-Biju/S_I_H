// ==============================================================================
// NIRVANA - Supabase Client Configuration
// Description: Place your Supabase project credentials here
// ==============================================================================

class SupabaseConfig {
  /// 1. Replace with your Supabase Project URL
  /// Found in: Supabase Dashboard -> Project Settings -> API -> Project URL
  /// Example: 'https://abcdefghijklm.supabase.co'
  static const String supabaseUrl = 'https://hclnjdhnvyhiwsdtcakw.supabase.co';

  /// 2. Replace with your Supabase 'anon' (public) key
  /// Found in: Supabase Dashboard -> Project Settings -> API -> Project API Keys -> 'anon' 'public'
  /// IMPORTANT: NEVER use the 'service_role' key in Flutter!
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjbG5qZGhudnloaXdzZHRjYWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3OTg0MjAsImV4cCI6MjEwNDM3NDQyMH0.hgKVpw0DM1F41xU_TTPMI1o-yV20UwRwjL_WnkFMVG0';

  /// Helper flag to check if the user has replaced placeholder credentials
  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT_ID.supabase.co' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
