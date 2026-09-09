// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Domain Models
// Description: Structured intent model covering elder voice & text interactions:
// Stories, Reminders, Routine, Date/Day/Time, Games, Family, Memories,
// Activity, Help, Greetings, Gratitude, Goodbye, and AI General Conversation.
// ==============================================================================

import 'package:flutter/foundation.dart';

/// Supported elder intent types
enum NirvanaIntent {
  /// "Tell me a story", "Can you read me a story?"
  tellStory,

  /// "Another one", "Tell me another story", "One more story"
  tellAnotherStory,

  /// "When is my medicine?", "What is my next reminder?"
  getNextReminder,

  /// "What reminders do I have today?", "Show me today's reminders"
  getTodaysReminders,

  /// "What do I have to do today?", "What is next?", "What is my routine?"
  getDailyRoutine,

  /// "What is today's date?", "What date is it?"
  getDate,

  /// "What day is today?", "What day is it?", "Which day is it?"
  getDay,

  /// "What time is it?", "What is the time?"
  getTime,

  /// "I want to play a game", "Let's play a game"
  startGame,

  /// "Recommend a game", "What game should I play?", "I'm bored"
  recommendGame,

  /// "Who is visiting me?", "Who is my daughter?", "Show me my family"
  familyQuery,

  /// "Tell me about my memories", "Show me my family memories"
  memoryQuery,

  /// "What did I do today?", "What have I done today?", "My activity"
  getTodaysActivity,

  /// "What can you do?", "Help me", "How can you help?"
  help,

  /// "Hello", "Good morning", "Hi Nirvana", "Namaste"
  greeting,

  /// "Thank you", "Thanks a lot", "Dhanyawad"
  gratitude,

  /// "Goodbye", "Bye", "Good night", "See you later"
  goodbye,

  /// Unmapped or general conversational query requiring AI fallback
  generalConversation;

  // ---------------------------------------------------------------------------
  // Backward compatibility aliases
  // ---------------------------------------------------------------------------
  static const NirvanaIntent nextReminder = NirvanaIntent.getNextReminder;
  static const NirvanaIntent todaysReminders = NirvanaIntent.getTodaysReminders;
  static const NirvanaIntent dailyRoutine = NirvanaIntent.getDailyRoutine;
  static const NirvanaIntent familyInfo = NirvanaIntent.familyQuery;
  static const NirvanaIntent memories = NirvanaIntent.memoryQuery;
  static const NirvanaIntent games = NirvanaIntent.startGame;
  static const NirvanaIntent orientation = NirvanaIntent.getTime;
  static const NirvanaIntent activity = NirvanaIntent.getTodaysActivity;
  static const NirvanaIntent fallback = NirvanaIntent.generalConversation;
}

enum GameIntentAction { startGame, recommendGame, boredChoice }

/// Time of day periods for daily routine queries
enum RoutinePeriod { morning, afternoon, evening, allDay, nextUp }

/// Orientation query target
enum OrientationTarget { time, date, dayOfWeek, full }

/// Structured result of intent classification
@immutable
class NirvanaIntentResult {
  final NirvanaIntent intent;
  final String rawQuery;
  final String? specificRelation; // e.g., 'daughter', 'son', 'granddaughter', 'pet', 'visitor'
  final RoutinePeriod routinePeriod;
  final OrientationTarget orientationTarget;
  final bool isMedicineSpecific;
  final GameIntentAction? gameAction;
  final String? storyCategory; // 'nature', 'family', 'funny', 'calm', 'morning'
  final bool isBoredQuery;

  const NirvanaIntentResult({
    required this.intent,
    required this.rawQuery,
    this.specificRelation,
    this.routinePeriod = RoutinePeriod.allDay,
    this.orientationTarget = OrientationTarget.full,
    this.isMedicineSpecific = false,
    this.gameAction,
    this.storyCategory,
    this.isBoredQuery = false,
  });

  @override
  String toString() =>
      'NirvanaIntentResult(intent: $intent, relation: $specificRelation, period: $routinePeriod, category: $storyCategory)';
}
