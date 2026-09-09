// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_database.dart';
import '../../caregiver/providers/caregiver_providers.dart';
import '../../caregiver/repositories/caregiver_repository.dart';
import '../../games/providers/game_session_providers.dart';
import '../../reminders/models/reminder.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../domain/ask_nirvana_intent.dart';
import 'nirvana_intent_router.dart';

class NirvanaDataResponder {
  final Ref _ref;
  final NirvanaIntentRouter _router;

  const NirvanaDataResponder(
    this._ref, [
    this._router = const NirvanaIntentRouter(),
  ]);

  static const unavailable = "I don't have that information right now.";

  Future<String> respond(String query, String langCode) async {
    final result = _router.route(query);
    debugPrint('Ask NIRVANA intent: ${result.intent}');
    switch (result.intent) {
      case NirvanaIntent.nextReminder:
        return _reminderResponse(result.isMedicineSpecific, false, langCode);
      case NirvanaIntent.todaysReminders:
        return _reminderResponse(result.isMedicineSpecific, true, langCode);
      case NirvanaIntent.dailyRoutine:
        return _routineResponse(result.routinePeriod);
      case NirvanaIntent.familyInfo:
        return _familyResponse(result.specificRelation);
      case NirvanaIntent.memories:
        return _memoryResponse();
      case NirvanaIntent.games:
        return _gameResponse(result.gameAction);
      case NirvanaIntent.orientation:
        return _orientationResponse(result.orientationTarget);
      case NirvanaIntent.activity:
        return _activityResponse();
      case NirvanaIntent.help:
        return _helpResponse();
      case NirvanaIntent.fallback:
        return unavailable;
    }
  }

  String get _patientId =>
      HiveDatabase.pairedPatientId ??
      HiveDatabase.currentPatientSession?.patientId ??
      '';

  Future<List<Reminder>> _reminders() async {
    final local = await _ref
        .read(reminderRepositoryProvider)
        .getActiveReminders(_patientId);
    if (local.isNotEmpty) return local;
    if (_patientId.isEmpty ||
        await _ref.read(connectivityMonitorProvider).checkStatus() !=
            NetworkStatus.online) {
      return [];
    }
    try {
      final remote = await _ref
          .read(caregiverRepositoryProvider)
          .getReminderStatus(_patientId);
      return remote
          .where((r) => r.isActive && !r.isCompleted && r.status != 'completed')
          .map(
            (r) => Reminder(
              id: r.id,
              patientId: r.patientId,
              title: r.title,
              body: r.description ?? '',
              scheduledAt: r.scheduledAt,
              createdAt: DateTime.now(),
              notificationId: r.id.hashCode,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> _reminderResponse(
    bool medicineOnly,
    bool today,
    String langCode,
  ) async {
    var reminders = await _reminders();
    if (medicineOnly) {
      reminders = reminders.where((r) {
        final text = '${r.title} ${r.body}'.toLowerCase();
        return text.contains('med') ||
            text.contains('pill') ||
            text.contains('tablet') ||
            text.contains('dose');
      }).toList();
    }
    final now = DateTime.now();
    if (today) {
      reminders = reminders.where((r) => _sameDay(r.scheduledAt, now)).toList();
    }
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (reminders.isEmpty) {
      return today ? 'You have no reminders scheduled for today.' : unavailable;
    }
    if (!today) {
      final r = reminders.first;
      return 'Your next reminder is ${r.title} at ${DateFormat.jm().format(r.scheduledAt)}.';
    }
    return 'Today you have ${reminders.length} reminder(s): ${reminders.map((r) => '${r.title} at ${DateFormat.jm().format(r.scheduledAt)}').join(', ')}.';
  }

  Future<String> _routineResponse(RoutinePeriod period) async {
    final now = DateTime.now();
    var items = (await _reminders())
        .where((r) => _sameDay(r.scheduledAt, now))
        .toList();
    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (period == RoutinePeriod.morning)
      items = items.where((r) => r.scheduledAt.hour < 12).toList();
    if (period == RoutinePeriod.afternoon)
      items = items
          .where((r) => r.scheduledAt.hour >= 12 && r.scheduledAt.hour < 17)
          .toList();
    if (period == RoutinePeriod.evening)
      items = items.where((r) => r.scheduledAt.hour >= 17).toList();
    if (period == RoutinePeriod.nextUp) {
      items = items.where((r) => r.scheduledAt.isAfter(now)).toList();
      if (items.isNotEmpty) items = [items.first];
    }
    if (items.isEmpty)
      return "You don't have any scheduled tasks or routine items for today.";
    return 'Here is your routine: ${items.map((r) => '${DateFormat.jm().format(r.scheduledAt)} - ${r.title}').join(', ')}.';
  }

  Future<List<Map<String, dynamic>>> _familyPhotos() async {
    if (_patientId.isEmpty) return [];
    try {
      final repository = _ref.read(caregiverRepositoryProvider);
      if (repository is! IFamilyPhotoReader) return [];
      return await (repository as IFamilyPhotoReader).getFamilyPhotos(
        _patientId,
      );
    } catch (_) {
      return [];
    }
  }

  Future<String> _familyResponse(String? relation) async {
    final records = await _familyPhotos();
    if (records.isEmpty) return unavailable;
    if (relation != null) {
      final matches = records.where(
        (r) => (r['relationship'] as String? ?? '').toLowerCase().contains(
          relation,
        ),
      );
      if (matches.isEmpty) return unavailable;
      return 'Your $relation is ${matches.map(_recordName).join(', ')}.';
    }
    return 'Your family includes: ${records.map((r) => '${_recordName(r)} (${r['relationship'] ?? 'family member'})').join(', ')}.';
  }

  Future<String> _memoryResponse() async {
    final records = await _familyPhotos();
    if (records.isEmpty) return unavailable;
    return 'I found ${records.length} family memory photo(s): ${records.map(_recordName).join(', ')}.';
  }

  String _gameResponse(GameIntentAction? action) =>
      action == GameIntentAction.startGame
      ? 'START_GAME: Opening Games.'
      : 'RECOMMEND_GAME: I recommend Who Is This? or Remember Objects. Open Games to choose one.';

  String _orientationResponse(OrientationTarget target) {
    final now = DateTime.now();
    final time = DateFormat.jm().format(now);
    final day = DateFormat('EEEE').format(now);
    final date = DateFormat.yMMMMd().format(now);
    switch (target) {
      case OrientationTarget.time:
        return 'The time is $time.';
      case OrientationTarget.dayOfWeek:
        return 'Today is $day.';
      case OrientationTarget.date:
        return "Today's date is $date.";
      case OrientationTarget.full:
        return 'Today is $day, $date, and the time is $time.';
    }
  }

  Future<String> _activityResponse() async {
    final now = DateTime.now();
    var reminders = 0;
    try {
      reminders = HiveDatabase.reminderLogsBox.values
          .where(
            (log) =>
                (log.action == 'done' || log.action == 'completed') &&
                _sameDay(log.actionTimestamp, now),
          )
          .length;
    } catch (_) {}
    var games = 0;
    if (_patientId.isNotEmpty) {
      try {
        final sessions = await _ref
            .read(gameSessionRepositoryProvider)
            .getRecentGameSessions(_patientId, limit: 50);
        games = sessions
            .where((session) => _sameDay(session.completedAt, now))
            .length;
      } catch (_) {}
    }
    if (reminders == 0 && games == 0)
      return 'I have no recorded activity for today.';
    return 'Today you completed $reminders reminder(s) and played $games game(s).';
  }

  String _helpResponse() =>
      'I am NIRVANA. I can check reminders, your daily routine, family photos and memories, games, the date and time, and recorded activity.';

  String _recordName(Map<String, dynamic> record) {
    final title = record['title'] as String?;
    final relationship = record['relationship'] as String?;
    return title?.trim().isNotEmpty == true
        ? title!.trim()
        : relationship ?? 'family member';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final nirvanaDataResponderProvider = Provider<NirvanaDataResponder>(
  (ref) => NirvanaDataResponder(ref),
);
