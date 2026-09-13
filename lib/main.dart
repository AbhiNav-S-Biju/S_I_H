import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/providers/accessibility_providers.dart';
import 'app/router/app_router.dart';
import 'app/theme/elder_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/network/audio_service.dart';
import 'core/network/connectivity_monitor.dart';
import 'core/network/supabase_sync_repository.dart';
import 'core/network/sync_engine.dart';
import 'database/hive_database.dart';
import 'features/caregiver/caregiver.dart';
import 'features/reminders/repositories/hive_reminder_repository.dart';
import 'features/reminders/services/notification_service.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive offline database
  try {
    await HiveDatabase.init().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('⚠️ HiveDatabase initialization error: $e');
  }

  // 2. Initialize local notification service
  //
  // The service is given a reminder repository so that tapping/closing a
  // reminder alarm or its "Done" action can mark the reminder complete and
  // push the completion to the caregiver portal, even when the app is cold-
  // started straight from the notification.
  try {
    final connectivity = ConnectivityMonitor();
    final syncEngine = SyncEngine(
      syncQueueBox: HiveDatabase.syncQueueBox,
      syncRepository: SupabaseSyncRepository(),
      connectivityMonitor: connectivity,
    );
    final reminderRepository = HiveReminderRepository(
      remindersBox: HiveDatabase.remindersBox,
      reminderLogsBox: HiveDatabase.reminderLogsBox,
      syncEngine: syncEngine,
      eventNotificationService: CaregiverEventNotificationService(
        repository: SupabaseCaregiverNotificationRepository(
          connectivityMonitor: connectivity,
        ),
      ),
    );
    final notificationService = NotificationService(
      reminderRepository: reminderRepository,
    );
    await notificationService.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('⚠️ NotificationService initialization error: $e');
  }

  // 3. Initialize audio service for voice-assisted interaction
  try {
    final audioService = AudioService();
    await audioService.initialize();
  } catch (e) {
    debugPrint('⚠️ AudioService initialization error: $e');
  }

  // 4. Safely initialize Caregiver Push Notification Service
  try {
    final pushService = CaregiverPushNotificationService();
    await pushService.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('⚠️ CaregiverPushNotificationService initialization warning: $e');
  }

  // Initialize Supabase if credentials are provided in SupabaseConfig
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 5));
      debugPrint('✅ Supabase initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ Supabase init warning (running in offline mode): $e');
    }
  } else {
    debugPrint(
      'ℹ️ Supabase not configured yet. App is operating in 100% Offline Mode.',
    );
  }

  runApp(const ProviderScope(child: NirvanaApp()));
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
