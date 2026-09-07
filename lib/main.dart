import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/providers/accessibility_providers.dart';
import 'app/router/app_router.dart';
import 'app/theme/elder_theme.dart';
import 'core/config/supabase_config.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials are provided in SupabaseConfig
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('✅ Supabase initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ Supabase init warning (running in offline mode): $e');
    }
  } else {
    debugPrint('ℹ️ Supabase not configured yet. App is operating in 100% Offline Mode.');
  }

  runApp(
    const ProviderScope(
      child: NirvanaApp(),
    ),
  );
}

class NirvanaApp extends ConsumerWidget {
  const NirvanaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(highContrastProvider);
    final textScale = ref.watch(textScaleProvider);
    final activeLocale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    final theme = isHighContrast
        ? ElderTheme.buildHighContrastTheme(fontScaleFactor: textScale.scale)
        : ElderTheme.buildStandardTheme(fontScaleFactor: textScale.scale);

    return MaterialApp.router(
      title: 'NIRVANA',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: activeLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
