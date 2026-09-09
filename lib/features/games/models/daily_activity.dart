// ==============================================================================
// NIRVANA - DailyActivity Model
// Description: Familiar routine activities for the My Days engagement game.
// Data is kept separate from widgets so new activities can be added later.
// ==============================================================================

import 'package:flutter/material.dart';

import 'game_enums.dart';

enum TimeOfDayPeriod { morning, afternoon, evening, night }

enum MyDaysMode { whatComesNext, putInOrder, rememberMyDay }

enum MyDaysPhase { modeSelect, memorizing, playing, feedback, results }

enum MyDaysFeedbackKind {
  none,
  nextCorrect,
  nextIncorrect,
  orderCorrect,
  orderIncorrect,
  rememberCorrect,
  rememberIncorrect,
}

class DailyActivity {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final IconData icon;
  final Color tintColor;
  final TimeOfDayPeriod timeOfDay;
  final int orderInPeriod;

  const DailyActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.tintColor,
    required this.timeOfDay,
    required this.orderInPeriod,
  });

  String localizedTitle(String languageCode) {
    final trans = _localizedTitles[id];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return title;
  }

  String localizedDescription(String languageCode) {
    final trans = _localizedDescriptions[id];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return description;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DailyActivity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static List<DailyActivity> forPeriod(TimeOfDayPeriod period) {
    final items = catalogue.where((a) => a.timeOfDay == period).toList()
      ..sort((a, b) => a.orderInPeriod.compareTo(b.orderInPeriod));
    return items;
  }

  static const List<DailyActivity> catalogue = [
    // Morning
    DailyActivity(
      id: 'wake_up',
      title: 'Wake Up',
      description: 'Start the day gently.',
      emoji: '🌅',
      icon: Icons.wb_sunny_rounded,
      tintColor: Color(0xFFD97706),
      timeOfDay: TimeOfDayPeriod.morning,
      orderInPeriod: 1,
    ),
    DailyActivity(
      id: 'brush_teeth',
      title: 'Brush Teeth',
      description: 'Fresh and clean for the morning.',
      emoji: '🪥',
      icon: Icons.mood_rounded,
      tintColor: Color(0xFF0F766E),
      timeOfDay: TimeOfDayPeriod.morning,
      orderInPeriod: 2,
    ),
    DailyActivity(
      id: 'drink_water',
      title: 'Drink Water',
      description: 'A glass of water to begin.',
      emoji: '💧',
      icon: Icons.water_drop_rounded,
      tintColor: Color(0xFF0284C7),
      timeOfDay: TimeOfDayPeriod.morning,
      orderInPeriod: 3,
    ),
    DailyActivity(
      id: 'breakfast',
      title: 'Have Breakfast',
      description: 'A familiar morning meal.',
      emoji: '🍳',
      icon: Icons.free_breakfast_rounded,
      tintColor: Color(0xFFB45309),
      timeOfDay: TimeOfDayPeriod.morning,
      orderInPeriod: 4,
    ),
    DailyActivity(
      id: 'morning_walk',
      title: 'Take a Walk',
      description: 'A calm walk in the morning.',
      emoji: '🚶',
      icon: Icons.directions_walk_rounded,
      tintColor: Color(0xFF15803D),
      timeOfDay: TimeOfDayPeriod.morning,
      orderInPeriod: 5,
    ),
    // Afternoon
    DailyActivity(
      id: 'lunch',
      title: 'Have Lunch',
      description: 'A comfortable midday meal.',
      emoji: '🍽',
      icon: Icons.lunch_dining_rounded,
      tintColor: Color(0xFFC2410C),
      timeOfDay: TimeOfDayPeriod.afternoon,
      orderInPeriod: 1,
    ),
    DailyActivity(
      id: 'newspaper',
      title: 'Read Newspaper',
      description: 'Look through the daily paper.',
      emoji: '📰',
      icon: Icons.newspaper_rounded,
      tintColor: Color(0xFF334155),
      timeOfDay: TimeOfDayPeriod.afternoon,
      orderInPeriod: 2,
    ),
    DailyActivity(
      id: 'talk_family',
      title: 'Talk with Family',
      description: 'A warm chat with loved ones.',
      emoji: '📞',
      icon: Icons.phone_in_talk_rounded,
      tintColor: Color(0xFF7C3AED),
      timeOfDay: TimeOfDayPeriod.afternoon,
      orderInPeriod: 3,
    ),
    DailyActivity(
      id: 'rest',
      title: 'Rest',
      description: 'A quiet rest in the afternoon.',
      emoji: '🛋',
      icon: Icons.weekend_rounded,
      tintColor: Color(0xFF0369A1),
      timeOfDay: TimeOfDayPeriod.afternoon,
      orderInPeriod: 4,
    ),
    DailyActivity(
      id: 'tea',
      title: 'Have Tea',
      description: 'A familiar cup of tea.',
      emoji: '🍵',
      icon: Icons.emoji_food_beverage_rounded,
      tintColor: Color(0xFF0F766E),
      timeOfDay: TimeOfDayPeriod.afternoon,
      orderInPeriod: 5,
    ),
    // Evening
    DailyActivity(
      id: 'evening_walk',
      title: 'Go for a Walk',
      description: 'An easy evening stroll.',
      emoji: '🌇',
      icon: Icons.directions_walk_rounded,
      tintColor: Color(0xFFEA580C),
      timeOfDay: TimeOfDayPeriod.evening,
      orderInPeriod: 1,
    ),
    DailyActivity(
      id: 'music',
      title: 'Listen to Music',
      description: 'Enjoy a favourite song.',
      emoji: '🎵',
      icon: Icons.music_note_rounded,
      tintColor: Color(0xFF7C3AED),
      timeOfDay: TimeOfDayPeriod.evening,
      orderInPeriod: 2,
    ),
    DailyActivity(
      id: 'dinner',
      title: 'Have Dinner',
      description: 'A calm evening meal.',
      emoji: '🍲',
      icon: Icons.dinner_dining_rounded,
      tintColor: Color(0xFFB45309),
      timeOfDay: TimeOfDayPeriod.evening,
      orderInPeriod: 3,
    ),
    DailyActivity(
      id: 'medicine',
      title: 'Take Medicine',
      description: 'A gentle reminder for medicine.',
      emoji: '💊',
      icon: Icons.medication_rounded,
      tintColor: Color(0xFF0F766E),
      timeOfDay: TimeOfDayPeriod.evening,
      orderInPeriod: 4,
    ),
    DailyActivity(
      id: 'prepare_bed',
      title: 'Prepare for Bed',
      description: 'Get ready for a restful night.',
      emoji: '🛏️',
      icon: Icons.hotel_rounded,
      tintColor: Color(0xFF1D4ED8),
      timeOfDay: TimeOfDayPeriod.evening,
      orderInPeriod: 5,
    ),
    // Night
    DailyActivity(
      id: 'night_brush',
      title: 'Brush Teeth',
      description: 'Brush before bedtime.',
      emoji: '🪥',
      icon: Icons.mood_rounded,
      tintColor: Color(0xFF0F766E),
      timeOfDay: TimeOfDayPeriod.night,
      orderInPeriod: 1,
    ),
    DailyActivity(
      id: 'change_clothes',
      title: 'Change Clothes',
      description: 'Put on comfortable night clothes.',
      emoji: '👕',
      icon: Icons.checkroom_rounded,
      tintColor: Color(0xFF0369A1),
      timeOfDay: TimeOfDayPeriod.night,
      orderInPeriod: 2,
    ),
    DailyActivity(
      id: 'lights_off',
      title: 'Turn Off Lights',
      description: 'Make the room calm and dark.',
      emoji: '💡',
      icon: Icons.light_mode_rounded,
      tintColor: Color(0xFFCA8A04),
      timeOfDay: TimeOfDayPeriod.night,
      orderInPeriod: 3,
    ),
    DailyActivity(
      id: 'go_to_bed',
      title: 'Go to Bed',
      description: 'Settle in for the night.',
      emoji: '😴',
      icon: Icons.bedtime_rounded,
      tintColor: Color(0xFF4F46E5),
      timeOfDay: TimeOfDayPeriod.night,
      orderInPeriod: 4,
    ),
    DailyActivity(
      id: 'goodnight',
      title: 'Say Goodnight',
      description: 'A peaceful goodnight.',
      emoji: '🌙',
      icon: Icons.nights_stay_rounded,
      tintColor: Color(0xFF1E3A8A),
      timeOfDay: TimeOfDayPeriod.night,
      orderInPeriod: 5,
    ),
  ];

  static const Map<String, Map<String, String>> _localizedTitles = {
    'wake_up': {
      'en': 'Wake Up',
      'hi': 'जागना',
      'bn': 'ঘুম থেকে ওঠা',
      'as': 'সাৰ পোৱা',
      'ne': 'बिउँझनु',
    },
    'brush_teeth': {
      'en': 'Brush Teeth',
      'hi': 'दांत साफ करना',
      'bn': 'দাঁত ব্রাশ করা',
      'as': 'দাঁত ঘঁহা',
      'ne': 'दाँत माझ्नु',
    },
    'drink_water': {
      'en': 'Drink Water',
      'hi': 'पानी पीना',
      'bn': 'জল খাওয়া',
      'as': 'পানী খোৱা',
      'ne': 'पानी खानु',
    },
    'breakfast': {
      'en': 'Have Breakfast',
      'hi': 'नाश्ता करना',
      'bn': 'নাস্তা করা',
      'as': 'নাস্তা খোৱা',
      'ne': 'बिहानको खाजा',
    },
    'morning_walk': {
      'en': 'Take a Walk',
      'hi': 'सुबह की सैर',
      'bn': 'সকালের হাঁটা',
      'as': 'ৰাতিপুৱা খোজ কঢ়া',
      'ne': 'बिहानको हिँडाइ',
    },
    'lunch': {
      'en': 'Have Lunch',
      'hi': 'दोपहर का भोजन',
      'bn': 'দুপুরের খাবার',
      'as': 'দুপৰীয়াৰ আহাৰ',
      'ne': 'दिउँसोको खाना',
    },
    'newspaper': {
      'en': 'Read Newspaper',
      'hi': 'अखबार पढ़ना',
      'bn': 'খবরের কাগজ পড়া',
      'as': 'বাতৰি কাকত পঢ়া',
      'ne': 'अखबार पढ्नु',
    },
    'talk_family': {
      'en': 'Talk with Family',
      'hi': 'परिवार से बात',
      'bn': 'পরিবারের সাথে কথা',
      'as': 'পৰিয়ালৰ সৈতে কথা',
      'ne': 'परिवारसँग कुरा',
    },
    'rest': {
      'en': 'Rest',
      'hi': 'आराम करना',
      'bn': 'বিশ্রাম',
      'as': 'জীৰণি লোৱা',
      'ne': 'आराम गर्नु',
    },
    'tea': {
      'en': 'Have Tea',
      'hi': 'चाय पीना',
      'bn': 'চা খাওয়া',
      'as': 'চাহ খোৱা',
      'ne': 'चिया खानु',
    },
    'evening_walk': {
      'en': 'Go for a Walk',
      'hi': 'शाम की सैर',
      'bn': 'সন্ধ্যার হাঁটা',
      'as': 'গধূলি খোজ কঢ়া',
      'ne': 'साँझको हिँडाइ',
    },
    'music': {
      'en': 'Listen to Music',
      'hi': 'संगीत सुनना',
      'bn': 'গান শোনা',
      'as': 'সংগীত শুনা',
      'ne': 'संगीत सुन्नु',
    },
    'dinner': {
      'en': 'Have Dinner',
      'hi': 'रात का खाना',
      'bn': 'রাতের খাবার',
      'as': 'ৰাতিৰ আহাৰ',
      'ne': 'बेलुकाको खाना',
    },
    'medicine': {
      'en': 'Take Medicine',
      'hi': 'दवाई लेना',
      'bn': 'ওষুধ খাওয়া',
      'as': 'ঔষধ লোৱা',
      'ne': 'औषधि खानु',
    },
    'prepare_bed': {
      'en': 'Prepare for Bed',
      'hi': 'सोने की तैयारी',
      'bn': 'ঘুমানোর প্রস্তুতি',
      'as': 'শুবলৈ সাজু হোৱা',
      'ne': 'सुत्न तयार हुनु',
    },
    'night_brush': {
      'en': 'Brush Teeth',
      'hi': 'दांत साफ करना',
      'bn': 'দাঁত ব্রাশ করা',
      'as': 'দাঁত ঘঁহা',
      'ne': 'दाँत माझ्नु',
    },
    'change_clothes': {
      'en': 'Change Clothes',
      'hi': 'कपड़े बदलना',
      'bn': 'জামা বদলানো',
      'as': 'কাপোৰ সলোৱা',
      'ne': 'लुगा फेर्नु',
    },
    'lights_off': {
      'en': 'Turn Off Lights',
      'hi': 'बत्तियाँ बंद करना',
      'bn': 'লাইট নিভিয়ে দেওয়া',
      'as': 'লাইট বন্ধ কৰা',
      'ne': 'बत्ती निभाउनु',
    },
    'go_to_bed': {
      'en': 'Go to Bed',
      'hi': 'सो जाना',
      'bn': 'ঘুমাতে যাওয়া',
      'as': 'শুবলৈ যোৱা',
      'ne': 'सुत्नु',
    },
    'goodnight': {
      'en': 'Say Goodnight',
      'hi': 'शुभ रात्रि कहना',
      'bn': 'শুভ রাত্রি বলা',
      'as': 'শুভ ৰাতি কোৱা',
      'ne': 'शुभ रात्री भन्नु',
    },
  };

  static const Map<String, Map<String, String>> _localizedDescriptions = {
    'wake_up': {
      'en': 'Start the day gently.',
      'hi': 'दिन की शांत शुरुआत।',
    },
    'breakfast': {
      'en': 'A familiar morning meal.',
      'hi': 'परिचित सुबह का भोजन।',
    },
    'tea': {
      'en': 'A familiar cup of tea.',
      'hi': 'परिचित चाय का कप।',
    },
  };
}

class MyDaysRound {
  final String id;
  final MyDaysMode mode;
  final GameDifficulty difficulty;
  final TimeOfDayPeriod period;
  final List<DailyActivity> activities;
  final List<DailyActivity> prefix;
  final DailyActivity? correctAnswer;
  final List<DailyActivity> choices;
  final List<DailyActivity> orderedActivities;
  final DailyActivity? mentionedActivity;

  const MyDaysRound({
    required this.id,
    required this.mode,
    required this.difficulty,
    required this.period,
    required this.activities,
    this.prefix = const [],
    this.correctAnswer,
    this.choices = const [],
    this.orderedActivities = const [],
    this.mentionedActivity,
  });
}
