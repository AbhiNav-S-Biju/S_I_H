// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Router
// Description: Multi-lingual intent router that normalizes text (lowercase,
// punctuation stripping, contraction expansion) and accurately classifies queries
// into structured NIRVANA domain intents before invoking AI fallback.
// ==============================================================================

import '../domain/ask_nirvana_intent.dart';

class NirvanaIntentRouter {
  const NirvanaIntentRouter();

  /// Normalizes raw user speech or text input for robust matching
  static String normalize(String text) {
    var cleaned = text.trim().toLowerCase();
    if (cleaned.isEmpty) return '';

    // 1. Expand common contractions
    cleaned = cleaned
        .replaceAll("what's", 'what is')
        .replaceAll("whats", 'what is')
        .replaceAll("i'm", 'i am')
        .replaceAll("im ", 'i am ')
        .replaceAll("can't", 'cannot')
        .replaceAll("cant", 'cannot')
        .replaceAll("don't", 'do not')
        .replaceAll("dont", 'do not')
        .replaceAll("let's", 'let us')
        .replaceAll("lets ", 'let us ')
        .replaceAll("who's", 'who is')
        .replaceAll("whos", 'who is')
        .replaceAll("it's", 'it is')
        .replaceAll("today's", 'todays');

    // 2. Remove punctuation
    cleaned = cleaned.replaceAll(RegExp(r'[.,?!;:_"\-\\\/(){}\[\]]'), ' ');

    // 3. Collapse multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Classifies user query into a structured NirvanaIntentResult
  NirvanaIntentResult route(String text) {
    final clean = normalize(text);
    if (clean.isEmpty) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.generalConversation,
        rawQuery: text,
      );
    }

    // 1. Stories & Follow-up Stories ("Tell me a story", "Another one")
    final storyResult = _matchStory(clean, text);
    if (storyResult != null) return storyResult;

    // 2. Boredom & Games ("I'm bored", "Play a game", "Recommend a game")
    final gameResult = _matchGamesAndBoredom(clean, text);
    if (gameResult != null) return gameResult;

    // 3. Orientation: Time, Day, Date
    final orientationResult = _matchOrientation(clean, text);
    if (orientationResult != null) return orientationResult;

    // 4. Reminders & Medicine ("When is my medicine?", "Today's reminders")
    final reminderResult = _matchReminders(clean, text);
    if (reminderResult != null) return reminderResult;

    // 5. Daily Routine ("What is my routine?", "What do I have to do today?")
    final routineResult = _matchDailyRoutine(clean, text);
    if (routineResult != null) return routineResult;

    // 6. Family & Relatives ("Who is my daughter?", "Who is visiting me?")
    final familyResult = _matchFamily(clean, text);
    if (familyResult != null) return familyResult;

    // 7. Memories ("Show my memories", "Tell me about my memories")
    if (_matchMemories(clean)) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.memoryQuery,
        rawQuery: text,
      );
    }

    // 8. Activity ("What did I do today?", "My activity")
    if (_matchActivity(clean)) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getTodaysActivity,
        rawQuery: text,
      );
    }

    // 9. Social & Conversational: Greeting, Gratitude, Goodbye
    final socialResult = _matchSocial(clean, text);
    if (socialResult != null) return socialResult;

    // 10. Help ("What can you do?", "Help me")
    if (_matchHelp(clean)) {
      return NirvanaIntentResult(intent: NirvanaIntent.help, rawQuery: text);
    }

    // 11. General Conversation (Unmapped -> AI Fallback)
    return NirvanaIntentResult(
      intent: NirvanaIntent.generalConversation,
      rawQuery: text,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Story matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchStory(String clean, String raw) {
    // Follow-up / Rotation
    final isAnother = clean == 'another one' ||
        clean == 'another story' ||
        clean == 'one more' ||
        clean == 'one more story' ||
        clean.contains('tell me another') ||
        clean.contains('next story') ||
        clean.contains('different story') ||
        clean.contains('एक और कहानी') ||
        clean.contains('एक और') ||
        clean.contains('আৰু এটা সাধু') ||
        clean.contains('অন্য গল্প');

    if (isAnother) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.tellAnotherStory,
        rawQuery: raw,
      );
    }

    final isStoryQuery = clean.contains('story') ||
        clean.contains('stories') ||
        clean.contains('कहानी') ||
        clean.contains('किस्सा') ||
        clean.contains('\u0997\u09b2\u09cd\u09aa') || // Bengali গল্প
        clean.contains('গল্প') ||
        clean.contains('\u09b8\u09be\u09a7\u09c1') || // Assamese সাধু
        clean.contains('সাধু') ||
        clean.contains('कथा');

    if (!isStoryQuery) return null;

    // Detect category if requested
    String? category;
    if (clean.contains('funny') || clean.contains('humor') || clean.contains('मजेदार') || clean.contains('হাস্যকর')) {
      category = 'funny';
    } else if (clean.contains('family') || clean.contains('परिवार') || clean.contains('পরিবার')) {
      category = 'family';
    } else if (clean.contains('nature') || clean.contains('प्रकृति') || clean.contains('পাখি')) {
      category = 'nature';
    } else if (clean.contains('calm') || clean.contains('peace') || clean.contains('शांत')) {
      category = 'calm';
    }

    return NirvanaIntentResult(
      intent: NirvanaIntent.tellStory,
      rawQuery: raw,
      storyCategory: category,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Boredom & Games matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchGamesAndBoredom(String clean, String raw) {
    final isBored = clean.contains('i am bored') ||
        clean.contains('feeling bored') ||
        clean.contains('get bored') ||
        clean.contains('बोर') ||
        clean.contains('बोर लग रहा') ||
        clean.contains('বোর হচ্ছি') ||
        clean.contains('আমনি লাগিছে') ||
        clean.contains('बोर भयो');

    if (isBored) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.recommendGame,
        rawQuery: raw,
        gameAction: GameIntentAction.boredChoice,
        isBoredQuery: true,
      );
    }

    final isPlayGame = clean.contains('play a game') ||
        clean.contains('want to play') ||
        clean.contains('let us play') ||
        clean.contains('start game') ||
        clean.contains('open game') ||
        clean.contains('game play') ||
        clean.contains('खेलना चाहता') ||
        clean.contains('खेल शुरू') ||
        clean.contains('গেম খেলব') ||
        clean.contains('খেল খেলিম');

    if (isPlayGame) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.startGame,
        rawQuery: raw,
        gameAction: GameIntentAction.startGame,
      );
    }

    final isRecommendGame = clean.contains('recommend a game') ||
        clean.contains('what game') ||
        clean.contains('which game') ||
        clean.contains('suggest a game') ||
        (clean.contains('game') && !clean.contains('history') && !clean.contains('score')) ||
        clean.contains('खेल') ||
        clean.contains('গেম') ||
        clean.contains('খেল');

    if (isRecommendGame) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.recommendGame,
        rawQuery: raw,
        gameAction: GameIntentAction.recommendGame,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 3. Orientation matching: Time, Day, Date
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchOrientation(String clean, String raw) {
    final isTime = clean.contains('what time') ||
        clean.contains('time is it') ||
        clean.contains('what is the time') ||
        clean.contains('tell me the time') ||
        clean.contains('current time') ||
        clean.contains('time now') ||
        clean.contains('time please') ||
        clean.contains('समय') ||
        clean.contains('वक़्त') ||
        clean.contains('कितने बजे') ||
        clean.contains('বাজে') ||
        clean.contains('কিমান বাজিছে') ||
        clean.contains('कति बज्यो');

    final isDay = clean.contains('what day') ||
        clean.contains('which day') ||
        clean.contains('day is it') ||
        clean.contains('day is today') ||
        clean.contains('कौन सा दिन') ||
        clean.contains('आज कौन सा दिन') ||
        clean.contains('কোন বার') ||
        clean.contains('কি বাৰ') ||
        clean.contains('कुन दिन');

    final isDate = clean.contains('todays date') ||
        clean.contains('today date') ||
        clean.contains('what date') ||
        clean.contains('what is the date') ||
        clean.contains('date today') ||
        clean.contains('what is today date') ||
        clean.contains('तारीख') ||
        clean.contains('तिथि') ||
        clean.contains('आज की तारीख') ||
        clean.contains('তারিখ') ||
        clean.contains('তাৰিখ') ||
        clean.contains('मिति');

    if (isTime && !isDate && !isDay) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getTime,
        rawQuery: raw,
        orientationTarget: OrientationTarget.time,
      );
    }

    if (isDay && !isTime) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getDay,
        rawQuery: raw,
        orientationTarget: OrientationTarget.dayOfWeek,
      );
    }

    if (isDate) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getDate,
        rawQuery: raw,
        orientationTarget: OrientationTarget.date,
      );
    }

    if (clean == 'what is today' || clean == 'today' || clean == 'आज क्या है') {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getDate,
        rawQuery: raw,
        orientationTarget: OrientationTarget.full,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. Reminder matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchReminders(String clean, String raw) {
    final isMedQuery = clean.contains('medicine') ||
        clean.contains('medication') ||
        clean.contains('pill') ||
        clean.contains('tablet') ||
        clean.contains('दवाई') ||
        clean.contains('दवा') ||
        clean.contains('औषध') ||
        clean.contains('ঔষধ') ||
        clean.contains('ওষুধ');

    final isNextPrompt = clean.contains('when is my') ||
        clean.contains('next reminder') ||
        clean.contains('next medicine') ||
        clean.contains('when do i take') ||
        clean.contains('upcoming reminder') ||
        (clean.contains('next') && isMedQuery) ||
        clean.contains('अगली') ||
        clean.contains('कब लेनी') ||
        clean.contains('পরের') ||
        clean.contains('পৰৰ') ||
        clean.contains('अर्को');

    final isTodaysPrompt = clean.contains('what reminders do i have today') ||
        clean.contains('reminders today') ||
        clean.contains('todays reminders') ||
        clean.contains('all reminders') ||
        clean.contains('reminders for today') ||
        clean.contains('show today reminders') ||
        clean.contains('आज के रिमाइंडर') ||
        clean.contains('आज की दवा') ||
        clean.contains('আজকের রিমাইন্ডার') ||
        clean.contains('আজিৰ সোঁৱৰণী') ||
        clean.contains('आजका रिमाइन्डरहरू');

    if (isNextPrompt) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getNextReminder,
        rawQuery: raw,
        isMedicineSpecific: isMedQuery,
      );
    }

    if (isTodaysPrompt || (clean.contains('reminder') && !clean.contains('clear'))) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getTodaysReminders,
        rawQuery: raw,
        isMedicineSpecific: isMedQuery,
      );
    }

    if (isMedQuery) {
      return NirvanaIntentResult(
        intent: NirvanaIntent.getNextReminder,
        rawQuery: raw,
        isMedicineSpecific: true,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 5. Daily Routine matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchDailyRoutine(String clean, String raw) {
    final isRoutineKeyword = clean.contains('routine') ||
        clean.contains('schedule') ||
        clean.contains('what do i have to do') ||
        clean.contains('what do i do') ||
        clean.contains('what should i do') ||
        clean.contains('what am i doing') ||
        clean.contains('what is next') ||
        clean.contains('plans today') ||
        clean.contains('दिनचर्या') ||
        clean.contains('आज क्या करना है') ||
        clean.contains('आज सुबह') ||
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
    } else if (clean.contains('what is next') || clean.contains('आगे क्या')) {
      period = RoutinePeriod.nextUp;
    }

    return NirvanaIntentResult(
      intent: NirvanaIntent.getDailyRoutine,
      rawQuery: raw,
      routinePeriod: period,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Family matching
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchFamily(String clean, String raw) {
    final isFamilyKeyword = clean.contains('family') ||
        clean.contains('daughter') ||
        clean.contains('son') ||
        clean.contains('granddaughter') ||
        clean.contains('grandson') ||
        clean.contains('child') ||
        clean.contains('children') ||
        clean.contains('pet') ||
        clean.contains('dog') ||
        clean.contains('cat') ||
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
      intent: NirvanaIntent.familyQuery,
      rawQuery: raw,
      specificRelation: relation,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Memories matching
  // ---------------------------------------------------------------------------
  bool _matchMemories(String clean) {
    return clean.contains('memories') ||
        (clean.contains('memory') && !clean.contains('game')) ||
        clean.contains('show memories') ||
        clean.contains('remember when') ||
        clean.contains('reminisce') ||
        clean.contains('यादें') ||
        clean.contains('पुरानी बातें') ||
        clean.contains('স্মৃতি') ||
        clean.contains('সোঁৱৰণী') ||
        clean.contains('सम्झना');
  }

  // ---------------------------------------------------------------------------
  // 8. Activity matching
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
        clean.contains('मैले के गरे');
  }

  // ---------------------------------------------------------------------------
  // 9. Social matching: Greeting, Gratitude, Goodbye
  // ---------------------------------------------------------------------------
  NirvanaIntentResult? _matchSocial(String clean, String raw) {
    // Gratitude
    if (clean.contains('thank you') ||
        clean == 'thanks' ||
        clean.contains('thanks a lot') ||
        clean.contains('धन्यवाद') ||
        clean.contains('शुक्रिया') ||
        clean.contains('ধন্যবাদ') ||
        clean.contains('ধন্যবাদ')) {
      return NirvanaIntentResult(intent: NirvanaIntent.gratitude, rawQuery: raw);
    }

    // Goodbye
    if (clean == 'goodbye' ||
        clean == 'bye' ||
        clean == 'bye bye' ||
        clean.contains('see you later') ||
        clean.contains('good night') ||
        clean.contains('अलविदा') ||
        clean.contains('বিদায়') ||
        clean.contains('शुभ रात्रि')) {
      return NirvanaIntentResult(intent: NirvanaIntent.goodbye, rawQuery: raw);
    }

    // Greeting
    if (clean == 'hello' ||
        clean == 'hi' ||
        clean == 'hey' ||
        clean.contains('hello nirvana') ||
        clean.contains('hi nirvana') ||
        clean.contains('good morning') ||
        clean.contains('good afternoon') ||
        clean.contains('good evening') ||
        clean.contains('namaste') ||
        clean.contains('नमस्ते') ||
        clean.contains('নমস্কার') ||
        clean.contains('নমস্কাৰ')) {
      return NirvanaIntentResult(intent: NirvanaIntent.greeting, rawQuery: raw);
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 10. Help matching
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
