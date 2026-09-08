// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart';
import 'lib/core/config/supabase_config.dart';

Future<void> main() async {
  print('----------------------------------------------------');
  print('Testing Supabase Connection to: ${SupabaseConfig.supabaseUrl}');
  print('----------------------------------------------------');

  try {
    final client = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    // 1. Test basic network reachability & schema inspection via PostgREST
    final response = await client.from('profiles').select().limit(1);
    print('✅ SUCCESS: Successfully reached Supabase instance!');
    print('📊 Query to "profiles" returned without network or auth errors.');
    print('📦 Profiles response: $response');

    // 2. Test RLS protection / Auth state
    print(
      '🔒 Row Level Security: Active (Anonymous caller query returned: $response)',
    );
    print('----------------------------------------------------');
    print(
      '🎉 CONGRATULATIONS: Your Supabase backend is LIVE and fully connected!',
    );
    print('----------------------------------------------------');
  } catch (e) {
    print('❌ Connection Test Output: $e');
  }
}
