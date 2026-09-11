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
import 'ai_assistant_service.dart';
import 'nirvana_intent_router.dart';
import 'nirvana_story_service.dart';

class NirvanaDataResponder {
  final Ref _ref;
  final NirvanaIntentRouter _router;
  final IAiAssistantService? _aiService;
  final NirvanaStoryService? _storyService;

  const NirvanaDataResponder(
    this._ref, [
    this._router = const NirvanaIntentRouter(),
    this._aiService,
    this._storyService,
  ]);

  static const unavailable = "I don't have that information right now.";

  Future<String> respond(
    String query,
    String langCode, {
    List<Map<String, String>> conversation = const [],
  }) async {
    final result = _router.route(query);
    debugPrint('Ask NIRVANA intent: ${result.intent}');
    switch (result.intent) {
      // 1. Stories
      case NirvanaIntent.tellStory:
      case NirvanaIntent.tellAnotherStory:
        return _storyResponse(result, langCode, query);

      // 2. Reminders & Medicine
      case NirvanaIntent.getNextReminder:
        return _reminderResponse(result.isMedicineSpecific, false, langCode);
      case NirvanaIntent.getTodaysReminders:
        return _reminderResponse(result.isMedicineSpecific, true, langCode);

      // 3. Daily Routine
      case NirvanaIntent.getDailyRoutine:
        return _routineResponse(result.routinePeriod);

      // 4. Family & Relatives
      case NirvanaIntent.familyQuery:
        return _familyResponse(result.specificRelation);

      // 5. Memories
      case NirvanaIntent.memoryQuery:
        return _memoryResponse();

      // 6. Games & Boredom
      case NirvanaIntent.startGame:
        return _gameResponse(GameIntentAction.startGame, false, langCode);
      case NirvanaIntent.recommendGame:
        return _gameResponse(result.gameAction, result.isBoredQuery, langCode);

      // 7. Orientation: Time, Day, Date
      case NirvanaIntent.getTime:
        return _orientationResponse(OrientationTarget.time);
      case NirvanaIntent.getDay:
        return _orientationResponse(OrientationTarget.dayOfWeek);
      case NirvanaIntent.getDate:
        return _orientationResponse(result.orientationTarget);

      // 8. Activity
      case NirvanaIntent.getTodaysActivity:
        return _activityResponse();

      // 9. Social: Greeting, Gratitude, Goodbye
      case NirvanaIntent.greeting:
        return _greetingResponse(langCode);
      case NirvanaIntent.gratitude:
        return _gratitudeResponse(langCode);
      case NirvanaIntent.goodbye:
        return _goodbyeResponse(langCode);

      // 10. Help
      case NirvanaIntent.help:
        return _helpResponse();

      // 11. General Conversation -> AI Fallback
      case NirvanaIntent.generalConversation:
        final IAiAssistantService aiService =
            _aiService ?? _ref.read(aiAssistantServiceProvider);
        final advancedService = aiService is IAdvancedNirvanaAiService
            ? aiService as IAdvancedNirvanaAiService
            : null;
        if (advancedService != null) {
          return advancedService.getAiResponse(
            query: query,
            languageCode: langCode,
            toolExecutor: executeTool,
            conversation: conversation,
          );
        }
        return aiService.getAiFallbackResponse(
          query: query,
          languageCode: langCode,
        );
    }
  }

  String get _patientId =>
      HiveDatabase.pairedPatientId ??
      HiveDatabase.currentPatientSession?.patientId ??
      '';

  Future<String> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'get_next_reminder':
        return _reminderResponse(false, false, 'en');
      case 'get_today_reminders':
        return _reminderResponse(false, true, 'en');
      case 'get_daily_routine':
        return _routineResponse(RoutinePeriod.allDay);
      case 'get_family_members':
        return _familyResponse(arguments['relation'] as String?);
      case 'get_family_memories':
        return _memoryResponse();
      case 'get_recent_activity':
        return _activityResponse();
      case 'get_available_games':
        return 'Available games include Remember Objects, Who Is This?, Grocery Memory, and Familiar Jigsaw.';
      case 'start_game':
        return _gameResponse(GameIntentAction.startGame, false, 'en');
      case 'get_current_date':
        return _orientationResponse(OrientationTarget.date);
      case 'get_current_time':
        return _orientationResponse(OrientationTarget.time);
      default:
        return unavailable;
    }
  }

  // ---------------------------------------------------------------------------
  // Story handler
  // ---------------------------------------------------------------------------
  Future<String> _storyResponse(
    NirvanaIntentResult result,
    String langCode,
    String query,
  ) async {
    final NirvanaStoryService storyService =
        _storyService ?? _ref.read(nirvanaStoryServiceProvider);
    if (await _ref.read(connectivityMonitorProvider).checkStatus() ==
        NetworkStatus.online) {
      final IAiAssistantService resolvedAiService =
          _aiService ?? _ref.read(aiAssistantServiceProvider);
      final advancedService = resolvedAiService is IAdvancedNirvanaAiService
          ? resolvedAiService as IAdvancedNirvanaAiService
          : null;
      final remote = advancedService != null
          ? await advancedService.getAiResponse(
              query: query,
              languageCode: langCode,
            )
          : await resolvedAiService.getAiFallbackResponse(
              query: query,
              languageCode: langCode,
            );
      if (remote.isNotEmpty &&
          !remote.startsWith("I can't connect right now")) {
        return remote;
      }
    }
    final story = storyService.getStory(
      languageCode: langCode,
      category: result.storyCategory,
      isAnother: result.intent == NirvanaIntent.tellAnotherStory,
    );
    return storyService.formatStoryResponse(story, langCode);
  }

  // ---------------------------------------------------------------------------
  // Reminder handler
  // ---------------------------------------------------------------------------
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
            text.contains('dose') ||
            text.contains('दवा') ||
            text.contains('औषध') ||
            text.contains('ঔষধ');
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

  // ---------------------------------------------------------------------------
  // Routine handler
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Family & Memories handler
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Games & Boredom handler
  // ---------------------------------------------------------------------------
  String _gameResponse(
    GameIntentAction? action,
    bool isBored,
    String langCode,
  ) {
    if (isBored) {
      const boredMessages = {
        'en':
            'We can play a memory game, look at your memories, or I can tell you a story. What would you like?',
        'hi':
            'हम एक मेमोरी गेम खेल सकते हैं, आपकी पुरानी यादें देख सकते हैं, या मैं आपको एक कहानी सुना सकता हूँ। आप क्या पसंद करेंगे?',
        'bn':
            'আমরা একটি মেমরি গেম খেলতে পারি, আপনার স্মৃতি দেখতে পারি, অথবা আমি আপনাকে একটি গল্প বলতে পারি। আপনি কী চান?',
        'as':
            'আমি এটা স্মৃতিৰ খেল খেলিব পাৰোঁ, আপোনাৰ পুৰণি স্মৃতি চাব পাৰোঁ, নাইবা মই এটি সাধু ক’ব পাৰোঁ। আপুনি কি বিচাৰে?',
        'ne':
            'हामी एउटा मेमोरी गेम खेल्न सक्छौं, तपाईंका सम्झनाहरू हेर्न सक्छौं, वा म तपाईंलाई एउटा कथा सुनाउन सक्छु। तपाईं के चाहनुहुन्छ?',
      };
      return boredMessages[langCode] ?? boredMessages['en']!;
    }

    if (action == GameIntentAction.startGame) {
      return 'START_GAME: Opening Games.';
    }

    return 'RECOMMEND_GAME: I recommend Who Is This? or Remember Objects. Open Games to choose one.';
  }

  // ---------------------------------------------------------------------------
  // Orientation handler
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Activity handler
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Social handler: Greeting, Gratitude, Goodbye
  // ---------------------------------------------------------------------------
  String _greetingResponse(String langCode) {
    const greetings = {
      'en':
          'Hello! It is wonderful to talk with you. How can I help you today?',
      'hi':
          'नमस्ते! आपसे बात करके बहुत अच्छा लगा। आज मैं आपकी क्या मदद कर सकता हूँ?',
      'bn':
          'নমস্কার! আপনার সাথে কথা বলে খুব ভালো লাগছে। আজ আমি আপনাকে কিভাবে সাহায্য করতে পারি?',
      'as':
          'নমস্কাৰ! আপোনাৰ লগত কথা পাতি বৰ ভাল লাগিছে। মই আজি আপোনাক কি সহায় কৰিব পাৰোঁ?',
      'ne':
          'नमस्ते! तपाईंसँग कुरा गर्न पाउँदा धेरै खुसी लाग्यो। आज म तपाईंलाई के मद्दत गर्न सक्छु?',
    };
    return greetings[langCode] ?? greetings['en']!;
  }

  String _gratitudeResponse(String langCode) {
    const responses = {
      'en': 'You are always welcome. I am right here with you.',
      'hi': 'आपका हमेशा स्वागत है। मैं हमेशा आपके साथ हूँ।',
      'bn': 'আপনাকে সবসময় স্বাগতম। আমি আপনার সাথেই আছি।',
      'as': 'আপোনাক সদায় স্বাগতম। মই আপোনাৰ লগতেই আছোঁ।',
      'ne': 'तपाईंलाई सधैं स्वागत छ। म तपाईंसँगै छु।',
    };
    return responses[langCode] ?? responses['en']!;
  }

  String _goodbyeResponse(String langCode) {
    const goodbyes = {
      'en':
          'Take care and rest well. I will be right here whenever you need me.',
      'hi': 'अपना ख्याल रखिए और आराम कीजिए। जब भी जरूरत हो, मैं यहीं हूँ।',
      'bn':
          'নিজের খেয়াল রাখুন এবং বিশ্রাম নিন। যখনই প্রয়োজন হবে আমি এখানেই আছি।',
      'as': 'নিজৰ যত্ন লওক আৰু বিশ্ৰাম কৰক। প্ৰয়োজন হ’লেই মই ইয়াতেই আছোঁ।',
      'ne':
          'आफ्नो ख्याल राख्नुहोस् र आराम गर्नुहोस्। तपाईंलाई आवश्यक पर्दा म यहीँ हुनेछु।',
    };
    return goodbyes[langCode] ?? goodbyes['en']!;
  }

  // ---------------------------------------------------------------------------
  // Help handler
  // ---------------------------------------------------------------------------
  String _helpResponse() =>
      'I am NIRVANA. I can tell stories, check reminders, your daily routine, family photos and memories, games, the date and time, and recorded activity.';

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
