// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Domain Models
// Description: Structured intents capturing elder voice queries mapped to real
// data layer features (Reminders, Routine, Family, Memories, Games, Orientation,
// Activity, and Help).
// ==============================================================================

import 'package:flutter/foundation.dart';

/// Supported elder intent types
enum NirvanaIntent {
  /// "When is my medicine?", "What is my next reminder?"
  nextReminder,

  /// "What reminders do I have today?", "Show me today's reminders"
  todaysReminders,

  /// "What do I have to do today?", "What is next?", "What am I doing this morning?"
  dailyRoutine,

  /// "Who is visiting me?", "Who is my daughter?", "Show me my family."
  familyInfo,

  /// "Tell me about my memories.", "Show me my family memories."
  memories,

  /// "I want to play a game.", "What game should I play?", "I'm bored."
  games,

  /// "What day is it?", "What is today's date?", "What time is it?"
  orientation,

  /// "What did I do today?", "What have I done today?"
  activity,

  /// "What can you do?", "Help me."
  help,

  /// Unmapped or general conversational query
  fallback,
}

enum GameIntentAction { startGame, recommendGame }

/// Time of day periods for daily routine queries
enum RoutinePeriod { morning, afternoon, evening, allDay, nextUp }

/// Orientation query target
enum OrientationTarget { time, date, dayOfWeek, full }

/// Structured result of intent classification
@immutable
class NirvanaIntentResult {
  final NirvanaIntent intent;
  final String rawQuery;
  final String?
  specificRelation; // e.g., 'daughter', 'son', 'granddaughter', 'pet'
  final RoutinePeriod routinePeriod;
  final OrientationTarget orientationTarget;
  final bool isMedicineSpecific;
  final GameIntentAction? gameAction;

  const NirvanaIntentResult({
    required this.intent,
    required this.rawQuery,
    this.specificRelation,
    this.routinePeriod = RoutinePeriod.allDay,
    this.orientationTarget = OrientationTarget.full,
    this.isMedicineSpecific = false,
    this.gameAction,
  });

  @override
  String toString() =>
      'NirvanaIntentResult(intent: $intent, relation: $specificRelation, period: $routinePeriod, orientation: $orientationTarget)';
}
