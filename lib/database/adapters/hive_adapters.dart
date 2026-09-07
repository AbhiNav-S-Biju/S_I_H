// ==============================================================================
// NIRVANA - Hive Adapters
// Description: Hand-crafted TypeAdapters for Hive models, ensuring zero
// dependency on build_runner code generation.
// ==============================================================================

import 'package:hive/hive.dart';
import '../hive_boxes.dart';
import '../models/hive_reminder.dart';
import '../models/hive_reminder_log.dart';
import '../models/hive_sync_event.dart';

class HiveSyncEventAdapter extends TypeAdapter<HiveSyncEvent> {
  @override
  final int typeId = HiveTypeIds.hiveSyncEvent;

  @override
  HiveSyncEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSyncEvent(
      eventId: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      operation: fields[3] as String,
      payload: (fields[4] as Map).cast<String, dynamic>(),
      createdAt: DateTime.parse(fields[5] as String),
      retryCount: fields[6] as int? ?? 0,
      syncStatus: fields[7] as String? ?? SyncStatus.pending,
      patientId: fields[8] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, HiveSyncEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operation)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.patientId);
  }
}

class HiveReminderAdapter extends TypeAdapter<HiveReminder> {
  @override
  final int typeId = HiveTypeIds.hiveReminder;

  @override
  HiveReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveReminder(
      id: fields[0] as String,
      patientId: fields[1] as String,
      title: fields[2] as String,
      body: fields[3] as String,
      scheduledAt: DateTime.parse(fields[4] as String),
      isActive: fields[5] as bool? ?? true,
      isCompleted: fields[6] as bool? ?? false,
      createdAt: DateTime.parse(fields[7] as String),
      completedAt: fields[8] != null ? DateTime.parse(fields[8] as String) : null,
      snoozedUntil: fields[9] != null ? DateTime.parse(fields[9] as String) : null,
      notificationId: fields[10] as int? ?? 0,
      recurrenceRule: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveReminder obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.scheduledAt.toIso8601String())
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(8)
      ..write(obj.completedAt?.toIso8601String())
      ..writeByte(9)
      ..write(obj.snoozedUntil?.toIso8601String())
      ..writeByte(10)
      ..write(obj.notificationId)
      ..writeByte(11)
      ..write(obj.recurrenceRule);
  }
}

class HiveReminderLogAdapter extends TypeAdapter<HiveReminderLog> {
  @override
  final int typeId = HiveTypeIds.hiveReminderLog;

  @override
  HiveReminderLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveReminderLog(
      id: fields[0] as String,
      reminderId: fields[1] as String,
      patientId: fields[2] as String,
      action: fields[3] as String,
      actionTimestamp: DateTime.parse(fields[4] as String),
      createdAt: DateTime.parse(fields[5] as String),
      metadata: fields[6] != null ? (fields[6] as Map).cast<String, dynamic>() : const {},
    );
  }

  @override
  void write(BinaryWriter writer, HiveReminderLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reminderId)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.actionTimestamp.toIso8601String())
      ..writeByte(5)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(6)
      ..write(obj.metadata);
  }
}
