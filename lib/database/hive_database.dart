// ==============================================================================
// NIRVANA - HiveDatabase Initializer
// Description: Manages Hive initialization, adapter registration, and box opening.
// Supports offline patient session persistence and device pairing.
// ==============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/hive_adapters.dart';
import 'hive_boxes.dart';
import 'models/hive_patient_session.dart';
import 'models/hive_difficulty_stats.dart';
import 'models/hive_reminder.dart';
import 'models/hive_reminder_log.dart';
import 'models/hive_sync_event.dart';

class HiveDatabase {
  HiveDatabase._();

  static bool _isInitialized = false;
  static const String _sessionKey = 'current_patient_session';

  /// Initializes Hive, registers TypeAdapters, and opens standard boxes.
  static Future<void> init({String? subDir}) async {
    if (_isInitialized) return;

    await Hive.initFlutter(subDir);
    registerAdapters();
    await openBoxes();

    _isInitialized = true;
    debugPrint(
      '✅ HiveDatabase initialized successfully with boxes: '
      '${HiveBoxes.reminders}, ${HiveBoxes.reminderLogs}, '
      '${HiveBoxes.syncQueue}, ${HiveBoxes.patientSession}, '
      '${HiveBoxes.difficultyStats}',
    );
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
    if (!Hive.isAdapterRegistered(HiveTypeIds.hivePatientDeviceSession)) {
      Hive.registerAdapter(HivePatientDeviceSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveDifficultyStats)) {
      Hive.registerAdapter(HiveDifficultyStatsAdapter());
    }
  }

  /// Opens the core Hive boxes required for offline-first operation.
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<HiveReminder>(HiveBoxes.reminders),
      Hive.openBox<HiveReminderLog>(HiveBoxes.reminderLogs),
      Hive.openBox<HiveSyncEvent>(HiveBoxes.syncQueue),
      Hive.openBox<HivePatientDeviceSession>(HiveBoxes.patientSession),
      Hive.openBox<dynamic>(HiveBoxes.settings),
      Hive.openBox<HiveDifficultyStats>(HiveBoxes.difficultyStats),
    ]);
  }

  static Box<HiveDifficultyStats> get difficultyStatsBox =>
      Hive.box<HiveDifficultyStats>(HiveBoxes.difficultyStats);

  /// Helper getters for typed boxes
  static Box<HiveReminder> get remindersBox =>
      Hive.box<HiveReminder>(HiveBoxes.reminders);

  static Box<HiveReminderLog> get reminderLogsBox =>
      Hive.box<HiveReminderLog>(HiveBoxes.reminderLogs);

  static Box<HiveSyncEvent> get syncQueueBox =>
      Hive.box<HiveSyncEvent>(HiveBoxes.syncQueue);

  static Box<HivePatientDeviceSession> get patientSessionBox =>
      Hive.box<HivePatientDeviceSession>(HiveBoxes.patientSession);

  /// Settings box — stores primitive key-value preferences (language, etc.)
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveBoxes.settings);

  /// Returns the current locally stored patient session, if any
  static HivePatientDeviceSession? get currentPatientSession {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.patientSession)) return null;
      return patientSessionBox.get(_sessionKey);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the device has a valid, active paired session
  static bool get isDevicePaired {
    final session = currentPatientSession;
    return session != null && session.isPaired && session.isActive;
  }

  /// Returns the paired patient ID if an active paired session exists
  static String? get pairedPatientId => currentPatientSession?.patientId;

  /// Saves or updates the patient session locally
  static Future<void> savePatientSession(
    HivePatientDeviceSession session,
  ) async {
    await patientSessionBox.put(_sessionKey, session);
  }

  /// Clears or unpairs the local patient session
  static Future<void> clearPatientSession() async {
    await patientSessionBox.delete(_sessionKey);
  }

  /// Gets or generates a stable unique device ID
  static String getOrCreateDeviceId() {
    final existingSession = currentPatientSession;
    if (existingSession != null && existingSession.deviceId.isNotEmpty) {
      return existingSession.deviceId;
    }

    final rand = Random.secure();
    final randomHex = List.generate(
      16,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return 'device-$randomHex';
  }

  /// Close boxes (e.g. for testing cleanup)
  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
