// ==============================================================================
// NIRVANA - Game Level & Journey Models
// Description: Multi-level progressive game journeys for dementia-friendly activities
// ==============================================================================

import 'package:flutter/material.dart';
import 'game_enums.dart';
import 'puzzle_item.dart';

/// Represents an individual level along a game's journey map.
class GameLevel {
  final int levelNumber; // 1 to 8
  final String title;
  final String description;
  final GameDifficulty difficulty;
  final GameType gameType;
  final IconData icon;
  final Color themeColor;
  final Map<String, dynamic> config;

  const GameLevel({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.gameType,
    this.icon = Icons.star_rounded,
    this.themeColor = const Color(0xFF0F766E),
    this.config = const {},
  });

  /// Localized title for level
  String localizedTitle(String langCode) {
    final map = _levelTitles['${gameType.name}_$levelNumber'];
    if (map != null && map.containsKey(langCode)) {
      return map[langCode]!;
    }
    return title;
  }

  /// Localized description/objective for level
  String localizedDescription(String langCode) {
    final map = _levelDescriptions['${gameType.name}_$levelNumber'];
    if (map != null && map.containsKey(langCode)) {
      return map[langCode]!;
    }
    return description;
  }

  /// Journey Map Title for this game
  static String getJourneyTitle(GameType type, String langCode) {
    switch (type) {
      case GameType.jigsawPuzzle:
        if (langCode == 'as') return 'উত্তৰ-পূব যাত্ৰা মানচিত্ৰ';
        if (langCode == 'hi') return 'पूर्वोत्तर भारत यात्रा';
        if (langCode == 'bn') return 'উত্তর-পূর্ব ভারত ভ্রমণ';
        return 'North East Expedition';
      case GameType.rememberObjects:
        if (langCode == 'as') return 'মনৰ বাগিচাৰ বাট';
        if (langCode == 'hi') return 'स्मृति उपवन यात्रा';
        if (langCode == 'bn') return 'স্মৃতি উদ্যান পরিক্রমা';
        return 'Mind Garden Path';
      case GameType.whoIsThis:
        if (langCode == 'as') return 'পৰিয়ালৰ স্মৃতি পদযাত্ৰা';
        if (langCode == 'hi') return 'पारिवारिक यादों का सफर';
        if (langCode == 'bn') return 'পারিবারিক স্মৃতির সরণি';
        return 'Family Tree Walk';
      case GameType.groceryMemory:
        if (langCode == 'as') return 'বজাৰৰ সুন্দৰ ভ্ৰমণ';
        if (langCode == 'hi') return 'बाज़ार की सैर';
        if (langCode == 'bn') return 'বাজারের রঙিন সফর';
        return 'Bazaar Market Stroll';
    }
  }

  /// Journey Map Subtitle for this game
  static String getJourneySubtitle(GameType type, String langCode) {
    switch (type) {
      case GameType.jigsawPuzzle:
        if (langCode == 'as') return '৮ টা স্তৰত ধুনীয়া ছবিবোৰ সম্পূৰ্ণ কৰক';
        if (langCode == 'hi') return '8 स्तरों में पूर्वोत्तर के सुंदर दृश्यों को जोड़ें';
        if (langCode == 'bn') return '৮টি ধাপে সুন্দর দৃশ্যগুলো মিলিয়ে তুলুন';
        return 'Piece together North East wonders across 8 gentle milestones';
      case GameType.rememberObjects:
        if (langCode == 'as') return 'চিনাকি সামগ্ৰীবোৰ মনত ৰাখি আনন্দ লওক';
        if (langCode == 'hi') return '8 स्तरों में अपनी याददाश्त को तरोताज़ा करें';
        if (langCode == 'bn') return '৮টি ধাপে চেনা জিনিস মনে রাখার মিষ্টি খেলা';
        return 'Nurture calm memory recall across 8 blooming steps';
      case GameType.whoIsThis:
        if (langCode == 'as') return 'মৰমৰ পৰিয়ালৰ মুখবোৰ চিনাক্ত কৰক';
        if (langCode == 'hi') return 'अपनों के प्यारे चेहरों और रिश्तों को पहचानें';
        if (langCode == 'bn') return 'আপনজনদের চেনা মুখ ও সম্পর্কের সুন্দর যাত্রা';
        return 'Celebrate beloved family bonds across 8 cherished steps';
      case GameType.groceryMemory:
        if (langCode == 'as') return 'দৈনন্দিন বজাৰৰ তালিকা মনত ৰাখি সামগ্ৰী বাছক';
        if (langCode == 'hi') return 'सामान की सूची याद रखें और बाज़ार से चुनें';
        if (langCode == 'bn') return 'ফর্দ মনে রেখে বাজার করার মিষ্টি খেলা';
        return 'Practice market shopping lists across 8 friendly stalls';
    }
  }

  /// Retrieves the 8 curated levels for a given game type
  static List<GameLevel> getLevelsForGame(GameType type) {
    switch (type) {
      case GameType.jigsawPuzzle:
        return _jigsawLevels;
      case GameType.rememberObjects:
        return _rememberObjectsLevels;
      case GameType.whoIsThis:
        return _whoIsThisLevels;
      case GameType.groceryMemory:
        return _groceryMemoryLevels;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Familiar Jigsaw Levels (North East Expedition)
  // ---------------------------------------------------------------------------
  static final List<GameLevel> _jigsawLevels = [
    GameLevel(
      levelNumber: 1,
      title: 'Kaziranga Gentle Start',
      description: 'Piece together 2 large pieces of the majestic one-horned rhino.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.grass_rounded,
      themeColor: const Color(0xFF15803D),
      config: {
        'image': PuzzleImage.kazirangaRhino,
        'rows': 1,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 2,
      title: 'Sacred Monastery Sanctuary',
      description: 'Assemble 2 pieces of the golden Buddha and prayer wheels.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.self_improvement_rounded,
      themeColor: const Color(0xFF991B1B),
      config: {
        'image': PuzzleImage.monasteryPrayer,
        'rows': 1,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 3,
      title: 'Tawang Morning Mist',
      description: 'Connect 2 pieces of the historic Himalayan monastery.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.fort_rounded,
      themeColor: const Color(0xFFB45309),
      config: {
        'image': PuzzleImage.tawangMonastery,
        'rows': 1,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 4,
      title: 'Seven Sisters Attire (Milestone)',
      description: 'Match 4 quadrants celebrating the handloom unity of the Northeast.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.emoji_events_rounded,
      themeColor: const Color(0xFF6B21A8),
      config: {
        'image': PuzzleImage.sevenSisters,
        'rows': 2,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 5,
      title: 'Cherrapunji Living Waters',
      description: 'Assemble 4 quadrants of the breathtaking mountain waterfalls.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.water_rounded,
      themeColor: const Color(0xFF0284C7),
      config: {
        'image': PuzzleImage.meghalayaFalls,
        'rows': 2,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 6,
      title: 'Assam Wetland Sunset',
      description: 'Piece together 4 pieces of Kaziranga’s golden evening horizon.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.wb_twilight_rounded,
      themeColor: const Color(0xFFD97706),
      config: {
        'image': PuzzleImage.kazirangaRhino,
        'rows': 2,
        'cols': 2,
      },
    ),
    GameLevel(
      levelNumber: 7,
      title: 'Sacred Meditation Hall',
      description: 'A 6-piece challenge revealing the serene temple sanctuary.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.spa_rounded,
      themeColor: const Color(0xFF7C2D12),
      config: {
        'image': PuzzleImage.monasteryPrayer,
        'rows': 2,
        'cols': 3,
      },
    ),
    GameLevel(
      levelNumber: 8,
      title: 'Himalayan Summit Champion',
      description: 'Master the 6-piece grand vista of snow-capped Tawang heights.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.jigsawPuzzle,
      icon: Icons.military_tech_rounded,
      themeColor: const Color(0xFFB45309),
      config: {
        'image': PuzzleImage.tawangMonastery,
        'rows': 2,
        'cols': 3,
      },
    ),
  ];

  // ---------------------------------------------------------------------------
  // 2. Remember Objects Levels (Mind Garden Path)
  // ---------------------------------------------------------------------------
  static final List<GameLevel> _rememberObjectsLevels = [
    GameLevel(
      levelNumber: 1,
      title: 'Morning Orchard',
      description: 'Observe and recall 3 fresh fruits in the sunny orchard.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.rememberObjects,
      icon: Icons.park_rounded,
      themeColor: const Color(0xFF16A34A),
      config: {'targetCount': 3, 'category': 'fruits'},
    ),
    GameLevel(
      levelNumber: 2,
      title: 'Breakfast Table',
      description: 'Memorize 3 familiar morning breakfast items.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.rememberObjects,
      icon: Icons.coffee_rounded,
      themeColor: const Color(0xFFD97706),
      config: {'targetCount': 3, 'category': 'breakfast'},
    ),
    GameLevel(
      levelNumber: 3,
      title: 'Quiet Study',
      description: 'Remember 3 everyday reading and writing companions.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.rememberObjects,
      icon: Icons.menu_book_rounded,
      themeColor: const Color(0xFF0F766E),
      config: {'targetCount': 3, 'category': 'study'},
    ),
    GameLevel(
      levelNumber: 4,
      title: 'Garden Verandah (Milestone)',
      description: 'Recall 4 blooming flower and plant items on the verandah.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.rememberObjects,
      icon: Icons.emoji_events_rounded,
      themeColor: const Color(0xFF0D9488),
      config: {'targetCount': 4, 'category': 'garden'},
    ),
    GameLevel(
      levelNumber: 5,
      title: 'Cozy Living Room',
      description: 'Take your time memorizing 4 comforting home items.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.rememberObjects,
      icon: Icons.weekend_rounded,
      themeColor: const Color(0xFF7C3AED),
      config: {'targetCount': 4, 'category': 'home'},
    ),
    GameLevel(
      levelNumber: 6,
      title: 'Afternoon Stroll',
      description: 'Remember 4 essentials taken on a peaceful walk.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.rememberObjects,
      icon: Icons.directions_walk_rounded,
      themeColor: const Color(0xFF0284C7),
      config: {'targetCount': 4, 'category': 'outdoors'},
    ),
    GameLevel(
      levelNumber: 7,
      title: 'Family Treasure Box',
      description: 'Remember 5 cherished keepsakes from the family memory chest.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.rememberObjects,
      icon: Icons.inventory_2_rounded,
      themeColor: const Color(0xFFEA580C),
      config: {'targetCount': 5, 'category': 'keepsakes'},
    ),
    GameLevel(
      levelNumber: 8,
      title: 'Festival Celebration',
      description: 'Recall 5 joyful festive items celebrating family togetherness.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.rememberObjects,
      icon: Icons.military_tech_rounded,
      themeColor: const Color(0xFFB45309),
      config: {'targetCount': 5, 'category': 'festival'},
    ),
  ];

  // ---------------------------------------------------------------------------
  // 3. Who Is This? Levels (Family Tree Walk)
  // ---------------------------------------------------------------------------
  static final List<GameLevel> _whoIsThisLevels = [
    GameLevel(
      levelNumber: 1,
      title: 'Grandchildren’s Smiles',
      description: 'Recognize the happy little grandchild with 2 gentle choices.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.whoIsThis,
      icon: Icons.child_care_rounded,
      themeColor: const Color(0xFF0284C7),
      config: {'choiceCount': 2, 'focus': 'grandchild'},
    ),
    GameLevel(
      levelNumber: 2,
      title: 'Loving Daughter & Son',
      description: 'Identify your grown children with 2 clear photo options.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.whoIsThis,
      icon: Icons.family_restroom_rounded,
      themeColor: const Color(0xFF16A34A),
      config: {'choiceCount': 2, 'focus': 'children'},
    ),
    GameLevel(
      levelNumber: 3,
      title: 'Life Partner',
      description: 'Celebrate the comforting warmth and smile of your spouse.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.whoIsThis,
      icon: Icons.favorite_rounded,
      themeColor: const Color(0xFFBE123C),
      config: {'choiceCount': 2, 'focus': 'spouse'},
    ),
    GameLevel(
      levelNumber: 4,
      title: 'Siblings & Cousins (Milestone)',
      description: 'Identify brothers and sisters with 3 relationship choices.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.whoIsThis,
      icon: Icons.emoji_events_rounded,
      themeColor: const Color(0xFF7C3AED),
      config: {'choiceCount': 3, 'focus': 'siblings'},
    ),
    GameLevel(
      levelNumber: 5,
      title: 'Extended Family Bonds',
      description: 'Recognize in-laws and cherished relatives from photos.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.whoIsThis,
      icon: Icons.people_outline_rounded,
      themeColor: const Color(0xFF0F766E),
      config: {'choiceCount': 3, 'focus': 'extended'},
    ),
    GameLevel(
      levelNumber: 6,
      title: 'Generations Together',
      description: 'Connect familial relationships across 3 generations.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.whoIsThis,
      icon: Icons.groups_rounded,
      themeColor: const Color(0xFFD97706),
      config: {'choiceCount': 3, 'focus': 'multi_gen'},
    ),
    GameLevel(
      levelNumber: 7,
      title: 'Cherished Memories',
      description: 'Identify family members and their voice note memories with 4 choices.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.whoIsThis,
      icon: Icons.record_voice_over_rounded,
      themeColor: const Color(0xFF4338CA),
      config: {'choiceCount': 4, 'focus': 'memories'},
    ),
    GameLevel(
      levelNumber: 8,
      title: 'Family Heritage Champion',
      description: 'Celebrate your complete family album in the grand heritage walk.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.whoIsThis,
      icon: Icons.military_tech_rounded,
      themeColor: const Color(0xFFB45309),
      config: {'choiceCount': 4, 'focus': 'heritage'},
    ),
  ];

  // ---------------------------------------------------------------------------
  // 4. Grocery Memory Levels (Bazaar Market Stroll)
  // ---------------------------------------------------------------------------
  static final List<GameLevel> _groceryMemoryLevels = [
    GameLevel(
      levelNumber: 1,
      title: 'Fruit Stand',
      description: 'Remember 2 fresh fruits and locate them on the wooden cart.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.groceryMemory,
      icon: Icons.shopping_basket_rounded,
      themeColor: const Color(0xFF16A34A),
      config: {'itemCount': 2, 'shelfCount': 4},
    ),
    GameLevel(
      levelNumber: 2,
      title: 'Morning Dairy & Bakery',
      description: 'Keep 2 essentials in mind: fresh milk and warm bread.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.groceryMemory,
      icon: Icons.breakfast_dining_rounded,
      themeColor: const Color(0xFFD97706),
      config: {'itemCount': 2, 'shelfCount': 4},
    ),
    GameLevel(
      levelNumber: 3,
      title: 'Green Vegetable Corner',
      description: 'Recall 3 green vegetables and fill your basket.',
      difficulty: GameDifficulty.easy,
      gameType: GameType.groceryMemory,
      icon: Icons.eco_rounded,
      themeColor: const Color(0xFF0F766E),
      config: {'itemCount': 3, 'shelfCount': 6},
    ),
    GameLevel(
      levelNumber: 4,
      title: 'Pantry Essentials (Milestone)',
      description: 'Remember 3 pantry grains and spices on the wooden shelves.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.groceryMemory,
      icon: Icons.emoji_events_rounded,
      themeColor: const Color(0xFF6B21A8),
      config: {'itemCount': 3, 'shelfCount': 6},
    ),
    GameLevel(
      levelNumber: 5,
      title: 'Fragrant Spice Bazaar',
      description: 'Keep 4 traditional spices in mind as you browse the market.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.groceryMemory,
      icon: Icons.grain_rounded,
      themeColor: const Color(0xFFEA580C),
      config: {'itemCount': 4, 'shelfCount': 8},
    ),
    GameLevel(
      levelNumber: 6,
      title: 'Tea & Snacks Counter',
      description: 'Recall 4 beloved teatime biscuits and refreshments.',
      difficulty: GameDifficulty.medium,
      gameType: GameType.groceryMemory,
      icon: Icons.emoji_food_beverage_rounded,
      themeColor: const Color(0xFF0284C7),
      config: {'itemCount': 4, 'shelfCount': 8},
    ),
    GameLevel(
      levelNumber: 7,
      title: 'Festive Feast Shopping',
      description: 'Remember 5 festive feast ingredients across the market stalls.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.groceryMemory,
      icon: Icons.storefront_rounded,
      themeColor: const Color(0xFF7C2D12),
      config: {'itemCount': 5, 'shelfCount': 9},
    ),
    GameLevel(
      levelNumber: 8,
      title: 'Master Shopper Champion',
      description: 'Complete the grand 5-item market expedition with flying colors.',
      difficulty: GameDifficulty.hard,
      gameType: GameType.groceryMemory,
      icon: Icons.military_tech_rounded,
      themeColor: const Color(0xFFB45309),
      config: {'itemCount': 5, 'shelfCount': 9},
    ),
  ];

  // ---------------------------------------------------------------------------
  // Localization Dictionaries for Level Titles & Descriptions
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, String>> _levelTitles = {
    // Jigsaw
    'jigsawPuzzle_1': {'en': 'Kaziranga Gentle Start', 'as': 'কাজিৰঙাৰ শান্ত আৰম্ভণি', 'hi': 'काजीरंगा सरल शुरुआत', 'bn': 'কাজিরাঙার সহজ সূচনা'},
    'jigsawPuzzle_2': {'en': 'Sacred Sanctuary', 'as': 'পবিত্ৰ প্ৰাৰ্থনা গৃহ', 'hi': 'पवित्र बौद्ध गर्भगृह', 'bn': 'পবিত্র উপাসনালয়'},
    'jigsawPuzzle_3': {'en': 'Tawang Morning Mist', 'as': 'টাৱাং কুঁৱলীভৰা পুৱা', 'hi': 'तवांग की सुबह', 'bn': 'তাওয়াং ভোরের কুয়াশা'},
    'jigsawPuzzle_4': {'en': 'Seven Sisters Attire', 'as': 'সাত ভগ্নীৰ বয়নশিল্প', 'hi': 'सात बहनों की वेशभूषा', 'bn': 'সাত বোনের পোশাক'},
    'jigsawPuzzle_5': {'en': 'Cherrapunji Falls', 'as': 'চেৰাপুঞ্জীৰ জলপ্ৰপাত', 'hi': 'चेरापूंजी के झरने', 'bn': 'চেরাপুঞ্জির ঝরনা'},
    'jigsawPuzzle_6': {'en': 'Assam Sunset', 'as': 'অসমৰ সোণালী সূৰ্যাস্ত', 'hi': 'असम की सुनहरी शाम', 'bn': 'আসামের সোনালী সন্ধ্যা'},
    'jigsawPuzzle_7': {'en': 'Sacred Meditation Hall', 'as': 'ধ্যানমগ্ন মঠ ভৱন', 'hi': 'शांतिमय ध्यान कक्ष', 'bn': 'শান্ত ধ্যান কক্ষ'},
    'jigsawPuzzle_8': {'en': 'Himalayan Summit Champion', 'as': 'হিমালয়ৰ শুভ্ৰ শিখৰ বিজয়ী', 'hi': 'हिमालय शिखर विजेता', 'bn': 'হিমালয় শিখর বিজয়ী'},
  };

  static const Map<String, Map<String, String>> _levelDescriptions = {
    'jigsawPuzzle_1': {
      'en': 'Piece together 2 large pieces of the majestic one-horned rhino.',
      'as': 'সুন্দৰ এশিঙীয়া গঁড়টোৰ ২ টা ডাঙৰ টুকুৰা মিলাওক।',
      'hi': 'शानदार एक-सींग वाले गैंडे के 2 बड़े टुकड़े जोड़ें।',
      'bn': 'একশৃঙ্গ গণ্ডারের ২টি বড় টুকরো মিলিয়ে তুলুন।',
    },
  };
}

/// Tracks the player's progress on a specific level
class GameLevelProgress {
  final int levelNumber;
  final bool isCompleted;
  final int starsEarned; // 1 to 3
  final int bestScore;
  final int timesPlayed;
  final DateTime? completedAt;

  const GameLevelProgress({
    required this.levelNumber,
    required this.isCompleted,
    required this.starsEarned,
    required this.bestScore,
    this.timesPlayed = 0,
    this.completedAt,
  });

  factory GameLevelProgress.initial(int levelNumber) {
    return GameLevelProgress(
      levelNumber: levelNumber,
      isCompleted: false,
      starsEarned: 0,
      bestScore: 0,
      timesPlayed: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelNumber': levelNumber,
      'isCompleted': isCompleted,
      'starsEarned': starsEarned,
      'bestScore': bestScore,
      'timesPlayed': timesPlayed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory GameLevelProgress.fromMap(Map<String, dynamic> map) {
    return GameLevelProgress(
      levelNumber: map['levelNumber'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
      starsEarned: map['starsEarned'] as int? ?? 0,
      bestScore: map['bestScore'] as int? ?? 0,
      timesPlayed: map['timesPlayed'] as int? ??
          ((map['isCompleted'] as bool? ?? false) ? 1 : 0),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }
}
