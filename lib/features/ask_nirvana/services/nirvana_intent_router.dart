// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Router
// Description: Multi-lingual intent router that parses elder speech / typed prompts
// and classifies them into structured domain intents (Reminders, Routine, Family,
// Memories, Games, Orientation, Activity, and Help) without external API dependencies.
// ==============================================================================

import '../domain/ask_nirvana_intent.dart';

class NirvanaIntentRouter {
  const NirvanaIntentRouter();

  /// Classifies user query into a structured NirvanaIntentResult
  NirvanaIntentResult route(String text) {
    final clean = text.trim().toLowerCase();
    if (clean.isEmpty) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.fallback,
        rawQuery: text,
      );
    }

    // 1. Orientation (Time, Date, Day)
    final orientationResult = _matchOrientation(clean, text);
    if (orientationResult != null) return orientationResult;

    // 2. Activity ("What did I do today?", "My activity")
    if (_matchActivity(clean)) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.activity,
        rawQuery: text,
      );
    }

    // 3. Reminders & Medicine
    final reminderResult = _matchReminders(clean, text);
    if (reminderResult != null) return reminderResult;

    // 4. Daily Routine ("What do I have to do today?", "What is next?")
    final routineResult = _matchDailyRoutine(clean, text);
    if (routineResult != null) return routineResult;

    // 5. Memories ("Tell me about my memories", "Show family memories")
    if (_matchMemories(clean)) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.memories,
        rawQuery: text,
      );
    }

    // 6. Family & Visitors
    final familyResult = _matchFamily(clean, text);
    if (familyResult != null) return familyResult;

    // 7. Games ("I want to play a game", "What game should I play", "I'm bored")
    final gameAction = _matchGames(clean);
    if (gameAction != null) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.games,
        rawQuery: text,
        gameAction: gameAction,
      );
    }

    // 8. Help ("What can you do?", "Help me")
    if (_matchHelp(clean)) {
      return NirvanaIntentResult(intent: NirvanaIntent.help, rawQuery: text);
    }

    return NirvanaIntentResult(intent: NirvanaIntent.fallback, rawQuery: text);
  }

  // ---------------------------------------------------------------------------
  // 1. Orientation matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchOrientation(String clean, String raw) {
    final isTime =
        clean.contains('what time') ||
        clean.contains('time is it') ||
        clean.contains('current time') ||
        clean.contains('समय') ||
        clean.contains('वक़्त') ||
        clean.contains('বাজে') ||
        clean.contains('কিমান বাজিছে') ||
        clean.contains('कति बज्यो');

    final isDay =
        clean.contains('what day') ||
        clean.contains('which day') ||
        clean.contains('what day is it') ||
        clean.contains('कौन सा दिन') ||
        clean.contains('কোন বার') ||
        clean.contains('কি বাৰ') ||
        clean.contains('कुन दिन');

    final isDate =
        clean.contains('date') ||
        clean.contains('today\'s date') ||
        clean.contains('what is today') ||
        clean.contains('तारीख') ||
        clean.contains('तिथि') ||
        clean.contains('তারিখ') ||
        clean.contains('তাৰিখ') ||
        clean.contains('मिति');

    if (isTime && !isDate && !isDay) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.orientation,
        rawQuery: raw,
        orientationTarget: OrientationTarget.time,
      );
    }
    if (isDay && !isTime) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.orientation,
        rawQuery: raw,
        orientationTarget: OrientationTarget.dayOfWeek,
      );
    }
    if (isDate) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.orientation,
        rawQuery: raw,
        orientationTarget: OrientationTarget.date,
      );
    }
    if (clean == 'what is today' || clean == 'today' || clean == 'आज क्या है') {
      return NirvanaIntentResult(
        intent: NirvanaIntent.orientation,
        rawQuery: raw,
        orientationTarget: OrientationTarget.full,
      );
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. Activity matching
  // ---------------------------------------------------------------------------
  bool _matchActivity(String clean) {
    return clean.contains('what did i do') ||
        clean.contains('what have i done') ||
        clean.contains('my activity') ||
        clean.contains('activities today') ||
        clean.contains('did i do anything') ||
        clean.contains('मैंने क्या किया') ||
        clean.contains('आज क्या क्या हुआ') ||
        clean.contains('আমি কি করেছি') ||
        clean.contains('মই কি কৰিলোঁ') ||
        clean.contains('मैले के गरे') ||
        clean.contains(
          '\u0906\u091c \u092e\u0948\u0902\u0928\u0947 \u0915\u094d\u092f\u093e',
        );
  }

  // ---------------------------------------------------------------------------
  // 3. Reminder matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchReminders(String clean, String raw) {
    final isMedQuery =
        clean.contains('medicine') ||
        clean.contains('medication') ||
        clean.contains('pill') ||
        clean.contains('tablet') ||
        clean.contains('दवाई') ||
        clean.contains('दवा') ||
        clean.contains('औषध') ||
        clean.contains('ঔষধ') ||
        clean.contains('ওষুধ');

    final isNextPrompt =
        clean.contains('when is my') ||
        clean.contains('next reminder') ||
        clean.contains('next medicine') ||
        clean.contains('when do i take') ||
        clean.contains('upcoming reminder') ||
        clean.contains('next') && isMedQuery ||
        clean.contains('अगली') ||
        clean.contains('कब लेनी') ||
        clean.contains('পরের') ||
        clean.contains('পৰৰ') ||
        clean.contains('अर्को');

    final isTodaysPrompt =
        clean.contains('what reminders do i have today') ||
        clean.contains('reminders today') ||
        clean.contains('today\'s reminders') ||
        clean.contains('all reminders') ||
        clean.contains('reminders for today') ||
        clean.contains('आज के रिमाइंडर') ||
        clean.contains('आज की दवा') ||
        clean.contains('আজকের রিমাইন্ডার') ||
        clean.contains('আজিৰ সোঁৱৰণী') ||
        clean.contains('आजका रिमाइन्डरहरू');

    if (isNextPrompt) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.nextReminder,
        rawQuery: raw,
        isMedicineSpecific: isMedQuery,
      );
    }

    if (isTodaysPrompt ||
        (clean.contains('reminder') && !clean.contains('clear'))) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.todaysReminders,
        rawQuery: raw,
        isMedicineSpecific: isMedQuery,
      );
    }

    if (isMedQuery) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.nextReminder,
        rawQuery: raw,
        isMedicineSpecific: true,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. Daily Routine matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchDailyRoutine(String clean, String raw) {
    final isRoutineKeyword =
        clean.contains('routine') ||
        clean.contains('schedule') ||
        clean.contains('what do i have to do') ||
        clean.contains('what do i do') ||
        clean.contains('what should i do') ||
        clean.contains('what am i doing') ||
        clean.contains('what is next') ||
        clean.contains('what\'s next') ||
        clean.contains('plans today') ||
        clean.contains('दिनचर्या') ||
        clean.contains('आज क्या करना है') ||
        clean.contains('\u0906\u091c \u0938\u0941\u092c\u0939') ||
        clean.contains('आगे क्या है') ||
        clean.contains('আজ কি করতে হবে') ||
        clean.contains('আজি কি কৰিব লাগে') ||
        clean.contains('आज के गर्नुपर्छ');

    if (!isRoutineKeyword) return null;

    RoutinePeriod period = RoutinePeriod.allDay;
    if (clean.contains('this morning') ||
        clean.contains('morning') ||
        clean.contains('सुबह') ||
        clean.contains('সকাল') ||
        clean.contains('ৰাতিপুৱা')) {
      period = RoutinePeriod.morning;
    } else if (clean.contains('afternoon') ||
        clean.contains('lunch') ||
        clean.contains('दोपहर') ||
        clean.contains('দুপুর') ||
        clean.contains('দুপৰীয়া')) {
      period = RoutinePeriod.afternoon;
    } else if (clean.contains('evening') ||
        clean.contains('tonight') ||
        clean.contains('night') ||
        clean.contains('शाम') ||
        clean.contains('রাত') ||
        clean.contains('সন্ধিয়া')) {
      period = RoutinePeriod.evening;
    } else if (clean.contains('what is next') ||
        clean.contains('what\'s next') ||
        clean.contains('आगे क्या')) {
      period = RoutinePeriod.nextUp;
    }

    return NirvanaIntentResult(
      intent: NirvanaIntent.dailyRoutine,
      rawQuery: raw,
      routinePeriod: period,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Family matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchFamily(String clean, String raw) {
    final isFamilyKeyword =
        clean.contains('family') ||
        clean.contains('daughter') ||
        clean.contains('son') ||
        clean.contains('granddaughter') ||
        clean.contains('grandson') ||
        clean.contains('child') ||
        clean.contains('children') ||
        clean.contains('pet') ||
        clean.contains('dog') ||
        clean.contains('visiting') ||
        clean.contains('visitor') ||
        clean.contains('coming to see me') ||
        clean.contains('परिवार') ||
        clean.contains('बेटी') ||
        clean.contains('बेटा') ||
        clean.contains('पोती') ||
        clean.contains('पालतू') ||
        clean.contains('मिलने कौन आ रहा') ||
        clean.contains('পরিবার') ||
        clean.contains('মেয়ে') ||
        clean.contains('ছেলে') ||
        clean.contains('পৰিয়াল') ||
        clean.contains('ছোৱালী') ||
        clean.contains('ল’ৰা') ||
        clean.contains('छोरी') ||
        clean.contains('छोरा');

    if (!isFamilyKeyword) return null;

    String? relation;
    if (clean.contains('daughter') ||
        clean.contains('बेटी') ||
        clean.contains('মেয়ে') ||
        clean.contains('ছোৱালী') ||
        clean.contains('छोरी')) {
      relation = 'daughter';
    } else if (clean.contains('son') ||
        clean.contains('बेटा') ||
        clean.contains('ছেলে') ||
        clean.contains('ল’ৰা') ||
        clean.contains('छोरा')) {
      relation = 'son';
    } else if (clean.contains('granddaughter') ||
        clean.contains('पोती') ||
        clean.contains('নাতনি')) {
      relation = 'granddaughter';
    } else if (clean.contains('pet') ||
        clean.contains('dog') ||
        clean.contains('पालतू') ||
        clean.contains('কুকুর')) {
      relation = 'pet';
    } else if (clean.contains('visiting') ||
        clean.contains('visitor') ||
        clean.contains('मिलने')) {
      relation = 'visitor';
    }

    return NirvanaIntentResult(
      intent: NirvanaIntent.familyInfo,
      rawQuery: raw,
      specificRelation: relation,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Memories matching
  // ---------------------------------------------------------------------------
  bool _matchMemories(String clean) {
    return clean.contains('memories') ||
        clean.contains('memory') && !clean.contains('game') ||
        clean.contains('remember when') ||
        clean.contains('reminisce') ||
        clean.contains('यादें') ||
        clean.contains('पुरानी बातें') ||
        clean.contains('স্মৃতি') ||
        clean.contains('সোঁৱৰণী') ||
        clean.contains('सम्झना');
  }

  // ---------------------------------------------------------------------------
  // 7. Games matching
  // ---------------------------------------------------------------------------
  GameIntentAction? _matchGames(String clean) {
    if (clean.contains('play a game') ||
        clean.contains('want to play') ||
        clean.contains('let\'s play') ||
        clean.contains('lets play')) {
      return GameIntentAction.startGame;
    }
    if (clean.contains('recommend a game') ||
        clean.contains('what game') ||
        clean.contains('i\'m bored') ||
        clean.contains('im bored') ||
        clean.contains('game') && !clean.contains('history') ||
        clean.contains('खेल') ||
        clean.contains('बोर') ||
        clean.contains('গেম') ||
        clean.contains('খেল')) {
      return GameIntentAction.recommendGame;
    }
    return null;
    /*
    return clean.contains('play a game') ||
        clean.contains('want to play') ||
        clean.contains('recommend a game') ||
        clean.contains('what game') ||
        clean.contains('i\'m bored') ||
        clean.contains('im bored') ||
        clean.contains('let\'s play') ||
        clean.contains('game') && !clean.contains('history') ||
        clean.contains('खेल') ||
        clean.contains('बोर') ||
        clean.contains('गেম') ||
        clean.contains('খেল');*/
  }

  // ---------------------------------------------------------------------------
  // 8. Help matching
  // ---------------------------------------------------------------------------
  bool _matchHelp(String clean) {
    return clean.contains('what can you do') ||
        clean.contains('help me') ||
        clean.contains('how can you help') ||
        clean.contains('what do you do') ||
        clean.contains('who are you') ||
        clean.contains('capabilities') ||
        clean.contains('मदद') ||
        clean.contains('सहायता') ||
        clean.contains('आप क्या कर सकते हैं') ||
        clean.contains('সাহায্য') ||
        clean.contains('সহায়') ||
        clean.contains('सहयोग');
  }
}
