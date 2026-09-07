// ==============================================================================
// NIRVANA - HiveDatabase Initializer
// Description: Manages Hive initialization, adapter registration, and box opening.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/hive_adapters.dart';
import 'hive_boxes.dart';
import 'models/hive_reminder.dart';
import 'models/hive_reminder_log.dart';
import 'models/hive_sync_event.dart';

class HiveDatabase {
  HiveDatabase._();

  static bool _isInitialized = false;

  /// Initializes Hive, registers TypeAdapters, and opens standard boxes.
  static Future<void> init({String? subDir}) async {
    if (_isInitialized) return;

    await Hive.initFlutter(subDir);
    registerAdapters();
    await openBoxes();

    _isInitialized = true;
    debugPrint('✅ HiveDatabase initialized successfully with boxes: '
        '${HiveBoxes.reminders}, ${HiveBoxes.reminderLogs}, ${HiveBoxes.syncQueue}');
  }

  /// Registers TypeAdapters if not already registered.
  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveSyncEvent)) {
      Hive.registerAdapter(HiveSyncEventAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveReminder)) {
      Hive.registerAdapter(HiveReminderAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveReminderLog)) {
      Hive.registerAdapter(HiveReminderLogAdapter());
    }
  }

  /// Opens the core Hive boxes required for offline-first operation.
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<HiveReminder>(HiveBoxes.reminders),
      Hive.openBox<HiveReminderLog>(HiveBoxes.reminderLogs),
      Hive.openBox<HiveSyncEvent>(HiveBoxes.syncQueue),
    ]);
  }

  /// Helper getters for typed boxes
  static Box<HiveReminder> get remindersBox =>
      Hive.box<HiveReminder>(HiveBoxes.reminders);

  static Box<HiveReminderLog> get reminderLogsBox =>
      Hive.box<HiveReminderLog>(HiveBoxes.reminderLogs);

  static Box<HiveSyncEvent> get syncQueueBox =>
      Hive.box<HiveSyncEvent>(HiveBoxes.syncQueue);

  /// Close boxes (e.g. for testing cleanup)
  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
