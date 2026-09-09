// ==============================================================================
// NIRVANA - Hive Box Constants
// Description: Type IDs and box names for all Hive models used in offline-first
// persistence. TypeIDs must be unique across the entire app.
// ==============================================================================

class HiveBoxes {
  HiveBoxes._();

  // Box names
  static const String reminders = 'nirvana_reminders';
  static const String reminderLogs = 'nirvana_reminder_logs';
  static const String syncQueue = 'nirvana_sync_queue';
  static const String patientSession = 'nirvana_patient_session';
  static const String settings = 'nirvana_settings';

  // Settings keys
  static const String settingsKeyLocale = 'locale_language_code';
}

class HiveTypeIds {
  HiveTypeIds._();

  static const int hiveSyncEvent = 1;
  static const int hiveReminder = 2;
  static const int hiveReminderLog = 3;
  static const int hivePatientDeviceSession = 4;
}
