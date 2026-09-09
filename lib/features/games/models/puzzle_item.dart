// ==============================================================================
// NIRVANA - PuzzleItem & PuzzleImage Models
// Description: Dementia-friendly familiar images with semantic landmark guidance
// Featuring culturally cherished scenes from North Eastern India
// ==============================================================================

import 'package:flutter/material.dart';

/// Represents a dementia-friendly, familiar scene for the Jigsaw Puzzle activity.
class PuzzleImage {
  final String id;
  final String title;
  final String description;
  final String assetPath;
  final bool isCaregiverUpload;
  final Color themeColor;
  final IconData categoryIcon;

  const PuzzleImage({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
    this.isCaregiverUpload = false,
    this.themeColor = const Color(0xFF0F766E),
    this.categoryIcon = Icons.photo_rounded,
  });

  /// Localized title
  String localizedTitle(String langCode) {
    final map = _localizedTitles[id];
    if (map != null && map.containsKey(langCode)) {
      return map[langCode]!;
    }
    return title;
  }

  /// Localized description
  String localizedDescription(String langCode) {
    final map = _localizedDescriptions[id];
    if (map != null && map.containsKey(langCode)) {
      return map[langCode]!;
    }
    return description;
  }

  /// Returns a specific landmark clue for a piece at (row, col)
  String getLandmarkClue({
    required int row,
    required int col,
    required int totalRows,
    required int totalCols,
    required String langCode,
  }) {
    // 1. Check for bespoke semantic landmark
    final imageLandmarks = _semanticLandmarks[id];
    if (imageLandmarks != null) {
      final key = '${totalRows}x${totalCols}_r${row}_c$col';
      if (imageLandmarks.containsKey(key)) {
        final locMap = imageLandmarks[key];
        if (locMap != null && locMap.containsKey(langCode)) {
          return locMap[langCode]!;
        } else if (locMap != null && locMap.containsKey('en')) {
          return locMap['en']!;
        }
      }

      // Fallback to coarse left/right landmarks for 1x2
      if (totalCols == 2 && totalRows == 1) {
        final coarseKey = col == 0 ? 'left' : 'right';
        final coarseMap = imageLandmarks[coarseKey];
        if (coarseMap != null && coarseMap.containsKey(langCode)) {
          return coarseMap[langCode]!;
        } else if (coarseMap != null && coarseMap.containsKey('en')) {
          return coarseMap['en']!;
        }
      }
    }

    // 2. Engaging visual content fallback (never clinical positions or coordinates)
    switch (langCode) {
      case 'as':
        return 'ছবিখনৰ ধুনীয়া ৰং আৰু চিনাকি প্ৰাকৃতিক দৃশ্যবোৰ মন দি চাওক।';
      case 'hi':
        return 'तस्वीर में रंगों और सुंदर आकृतियों को ध्यान से देखें।';
      case 'bn':
        return 'ছবির সুন্দর রং এবং চেনা রূপগুলো মনোযোগ দিয়ে দেখুন।';
      case 'ne':
        return 'तस्वीरका सुन्दर रङहरू र परिचित रूपहरू ध्यान दिएर हेर्नुहोस्।';
      default:
        return 'Notice the warm colors and familiar natural shapes in this part of the picture.';
    }
  }

  // ---------------------------------------------------------------------------
  // North Eastern India Curated Scenes
  // ---------------------------------------------------------------------------
  static const PuzzleImage kazirangaRhino = PuzzleImage(
    id: 'puzzle_kaziranga_rhino',
    title: 'Kaziranga One-Horned Rhino',
    description: 'The majestic rhinoceros grazing at sunset in the lush grasslands of Assam',
    assetPath: 'assets/images/puzzle/puzzle_kaziranga_rhino.png',
    themeColor: Color(0xFF15803D), // Assam Forest Green
    categoryIcon: Icons.pets_rounded,
  );

  static const PuzzleImage tawangMonastery = PuzzleImage(
    id: 'puzzle_tawang_monastery',
    title: 'Tawang Himalayan Monastery',
    description: 'Historic Buddhist monastery in Arunachal Pradesh against snow-capped peaks',
    assetPath: 'assets/images/puzzle/puzzle_tawang_monastery.png',
    themeColor: Color(0xFFB45309), // Himalayan Amber Gold
    categoryIcon: Icons.fort_rounded,
  );

  static const PuzzleImage monasteryPrayer = PuzzleImage(
    id: 'puzzle_monastery_prayer',
    title: 'Sacred Monastery Sanctuary',
    description: 'A serene monk in meditation before the radiant golden Buddha and thangkas',
    assetPath: 'assets/images/puzzle/puzzle_monastery_prayer.png',
    themeColor: Color(0xFF991B1B), // Monastic Maroon
    categoryIcon: Icons.self_improvement_rounded,
  );

  static const PuzzleImage sevenSisters = PuzzleImage(
    id: 'puzzle_seven_sisters',
    title: 'Seven Sisters Heritage',
    description: 'Celebrating the vibrant handloom attires, harvest, and unity of Northeast India',
    assetPath: 'assets/images/puzzle/puzzle_seven_sisters.png',
    themeColor: Color(0xFF6B21A8), // Royal Indigo & Silk Purple
    categoryIcon: Icons.groups_rounded,
  );

  static const PuzzleImage meghalayaFalls = PuzzleImage(
    id: 'puzzle_meghalaya_falls',
    title: 'Cherrapunji Waterfalls',
    description: 'Breathtaking green canyons and cascading waterfalls of Sohra, Meghalaya',
    assetPath: 'assets/images/puzzle/puzzle_meghalaya_falls.png',
    themeColor: Color(0xFF0284C7), // Cascading River Blue
    categoryIcon: Icons.water_rounded,
  );

  // Legacy scenes preserved for backwards compatibility
  static const PuzzleImage morningTea = PuzzleImage(
    id: 'puzzle_morning_tea',
    title: 'Morning Tea & Marigolds',
    description: 'A comforting cup of morning chai with fresh flowers',
    assetPath: 'assets/images/puzzle/puzzle_morning_tea.jpg',
    themeColor: Color(0xFFD97706),
    categoryIcon: Icons.coffee_rounded,
  );

  static const PuzzleImage courtyardGarden = PuzzleImage(
    id: 'puzzle_courtyard_garden',
    title: 'Courtyard Tulsi & Rose',
    description: 'A peaceful home garden with sacred Tulsi and blooming roses',
    assetPath: 'assets/images/puzzle/puzzle_courtyard_garden.jpg',
    themeColor: Color(0xFF16A34A),
    categoryIcon: Icons.yard_rounded,
  );

  static const PuzzleImage homeKitchen = PuzzleImage(
    id: 'puzzle_home_kitchen',
    title: 'Cozy Home Kitchen',
    description: 'Golden sweet mangoes and earthen clay cups in the kitchen',
    assetPath: 'assets/images/puzzle/puzzle_home_kitchen.jpg',
    themeColor: Color(0xFFEA580C),
    categoryIcon: Icons.restaurant_rounded,
  );

  static const PuzzleImage familyGathering = PuzzleImage(
    id: 'puzzle_family_gathering',
    title: 'Loving Family Time',
    description: 'Grandparents and grandchild sharing a cherished photo album',
    assetPath: 'assets/images/puzzle/puzzle_family_gathering.jpg',
    themeColor: Color(0xFF7C3AED),
    categoryIcon: Icons.family_restroom_rounded,
  );

  /// Default active scenes presented in the Familiar Jigsaw activity
  static const List<PuzzleImage> defaultFamiliarImages = [
    kazirangaRhino,
    tawangMonastery,
    monasteryPrayer,
    sevenSisters,
    meghalayaFalls,
  ];

  // ---------------------------------------------------------------------------
  // Localization Dictionaries
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, String>> _localizedTitles = {
    'puzzle_kaziranga_rhino': {
      'en': 'Kaziranga One-Horned Rhino',
      'as': 'কাজিৰঙাৰ এশিঙীয়া গঁড়',
      'hi': 'काजीरंगा एक-सींग वाला गैंडा',
      'bn': 'কাজিরাঙার একশৃঙ্গ গণ্ডার',
      'ne': 'काजिरङ्गा एक-सिङ्गे गैँडा',
    },
    'puzzle_tawang_monastery': {
      'en': 'Tawang Himalayan Monastery',
      'as': 'টাৱাং বৌদ্ধ মঠ',
      'hi': 'तवांग हिमालयी बौद्ध मठ',
      'bn': 'তাওয়াং হিমালয় বৌদ্ধ মঠ',
      'ne': 'तवाङ हिमाली गुम्बा',
    },
    'puzzle_monastery_prayer': {
      'en': 'Sacred Monastery Sanctuary',
      'as': 'পবিত্ৰ বৌদ্ধ প্ৰাৰ্থনা গৃহ',
      'hi': 'पवित्र बौद्ध मठ गर्भगृह',
      'bn': 'পবিত্র বৌদ্ধ উপাসনালয়',
      'ne': 'पवित्र गुम्बा प्रार्थना कक्ष',
    },
    'puzzle_seven_sisters': {
      'en': 'Seven Sisters Heritage',
      'as': 'উত্তৰ-পূবৰ সাত ভগ্নীৰ ঐতিহ্য',
      'hi': 'पूर्वोत्तर की सात बहनें',
      'bn': 'উত্তর-পূর্বের সাত বোন ও ঐতিহ্য',
      'ne': 'पूर्वोत्तरका सात बहिनीहरू',
    },
    'puzzle_meghalaya_falls': {
      'en': 'Cherrapunji Waterfalls',
      'as': 'চেৰাপুঞ্জীৰ জলপ্ৰপাত আৰু সেউজ উপত্যকা',
      'hi': 'चेरापूंजी के मनमोहक झरने',
      'bn': 'চেরাপুঞ্জির জলপ্রপাত ও সবুজ উপত্যকা',
      'ne': 'चेरापुन्जीका छाँगाहरू',
    },
    'puzzle_morning_tea': {
      'en': 'Morning Tea & Marigolds',
      'hi': 'सुबह की चाय और गेंदे के फूल',
      'bn': 'সকালের চা ও গাঁদা ফুল',
      'as': 'ৰাতিপুৱাৰ চাহ আৰু গেন্দা ফুল',
      'ne': 'बिहानको चिया र सयपत्री फूल',
    },
    'puzzle_courtyard_garden': {
      'en': 'Courtyard Tulsi & Rose',
      'hi': 'आंगन में तुलसी और गुलाब',
      'bn': 'উঠানের তুলসী ও গোলাপ',
      'as': 'চোতালৰ তুলসী আৰু গোলাপ',
      'ne': 'आँगनको तुलसी र गुलाब',
    },
    'puzzle_home_kitchen': {
      'en': 'Cozy Home Kitchen',
      'hi': 'प्यारा घरेलू रसोईघर',
      'bn': 'ঘরের মিষ্টি রান্নাঘর',
      'as': 'ঘৰৰ মৰমলগা পাকঘৰ',
      'ne': 'न्यानो घरेलु भान्छा',
    },
    'puzzle_family_gathering': {
      'en': 'Loving Family Time',
      'hi': 'प्यारा पारिवारिक पल',
      'bn': 'ভালোবাসাময় পারিবারিক সময়',
      'as': 'মৰমৰ পাৰিবাৰিক সময়',
      'ne': 'मायालु पारिवारिक क्षण',
    },
  };

  static const Map<String, Map<String, String>> _localizedDescriptions = {
    'puzzle_kaziranga_rhino': {
      'en': 'The majestic rhinoceros grazing at sunset in the lush grasslands of Assam',
      'as': 'অসমৰ কাজিৰঙাৰ সেউজীয়া জলাশয় আৰু ঘাঁহনিত চৰি থকা এশিঙীয়া গঁড়',
      'hi': 'असम के हरे-भरे घास के मैदानों में शाम को चरता एक-सींग वाला गैंडा',
      'bn': 'আসামের কাজিরাঙার সবুজ জলাভূমিতে বিকেলে ঘাস খাওয়া একশৃঙ্গ গণ্ডার',
      'ne': 'असमको हरियो घाँसे मैदानमा साँझ चरिरहेको एक-सिङ्गे गैँडा',
    },
    'puzzle_tawang_monastery': {
      'en': 'Historic Buddhist monastery in Arunachal Pradesh against snow-capped peaks',
      'as': 'বৰফেৰে আবৃত হিমালয়ৰ শৃংগৰ তলত অৰুণাচল প্ৰদেশৰ ঐতিহাসিক টাৱাং মঠ',
      'hi': 'बर्फ से ढकी हिमालय की चोटियों तले अरुणाचल का ऐतिहासिक तवांग मठ',
      'bn': 'বরফে ঢাকা হিমালয়ের কোলে অরুণাচল প্রদেশের ঐতিহাসিক তাওয়াং মঠ',
      'ne': 'हिउँले ढाकिएका हिमालहरूको फेदमा अरुणाचलको ऐतिहासिक तवाङ गुम्बा',
    },
    'puzzle_monastery_prayer': {
      'en': 'A serene monk in meditation before the radiant golden Buddha and thangkas',
      'as': 'উজ্জ্বল সোণালী বুদ্ধ মূৰ্তি আৰু প্ৰাৰ্থনা চকাৰ আগত ধ্যানমগ্ন শান্ত ভিক্খু',
      'hi': 'चमकती सुनहरी बुद्ध प्रतिमा और प्रार्थना चक्रों के आगे शांत ध्यानमग्न भिक्षु',
      'bn': 'উজ্জ্বল সোনালী বুদ্ধমূর্তি ও প্রার্থনার চাকার সামনে ধ্যানে মগ্ন সন্ন্যাসী',
      'ne': 'सुनौलो बुद्ध प्रतिमा र प्रार्थना चक्र अगाडि ध्यानमग्न शान्त भिक्षु',
    },
    'puzzle_seven_sisters': {
      'en': 'Celebrating the vibrant handloom attires, harvest, and unity of Northeast India',
      'as': 'উত্তৰ-পূবৰ সাতখন ৰাজ্যৰ বয়নশিল্প, পৰম্পৰাগত সাজ আৰু কৃষিসম্পদৰ উদযাপন',
      'hi': 'पूर्वोत्तर भारत की पारंपरिक हथकरघा वेशभूषा, संस्कृति और एकता की झलक',
      'bn': 'উত্তর-পূর্ব ভারতের ঐতিহ্যবাহী তাঁতবস্ত্র, সংস্কৃতি ও ঐক্যের সুন্দর দৃশ্য',
      'ne': 'पूर्वोत्तर भारतका परम्परागत पहिरन, संस्कृति र एकताको उत्सव',
    },
    'puzzle_meghalaya_falls': {
      'en': 'Breathtaking green canyons and cascading waterfalls of Sohra, Meghalaya',
      'as': 'মেঘালয়ৰ চেৰাপুঞ্জীৰ গভীৰ সেউজীয়া উপত্যকা আৰু আকাশলংঘী বগা জলপ্ৰপাত',
      'hi': 'मेघालय के चेरापूंजी की हरी-भरी गहरी घाटियां और दूधिया सुंदर झरने',
      'bn': 'মেঘালয়ের চেরাপুঞ্জির সবুজ উপত্যকা এবং পাহাড় থেকে নেমে আসা জলপ্রপাত',
      'ne': 'मेघालयको चेरापुन्जीका मनमोहक हरिया उपत्यका र छाँगाहरू',
    },
    'puzzle_morning_tea': {
      'en': 'A comforting cup of morning chai with fresh flowers',
      'hi': 'ताजे फूलों के साथ सुबह की गर्मागर्म चाय',
      'bn': 'তাজা ফুলের সাথে সকালের আরামদায়ক চা',
      'as': 'সতেজ ফুলৰ সৈতে পুৱাৰ আৰামদায়ক চাহ',
      'ne': 'ताजा फूलहरूसँग बिहानको मीठो चिया',
    },
    'puzzle_courtyard_garden': {
      'en': 'A peaceful home garden with sacred Tulsi and blooming roses',
      'hi': 'तुलसी के पौधे और खिलते गुलाबों से महकता आंगन',
      'bn': 'তুলসী গাছ ও ফুটে থাকা গোলাপের শান্ত উঠোন',
      'as': 'তুলসী গছ আৰু গোলাপ ফুলৰ শান্ত চোতাল',
      'ne': 'तुलसीको बोट र फुलेका गुलाबहरू भएको आँगन',
    },
    'puzzle_home_kitchen': {
      'en': 'Golden sweet mangoes and earthen clay cups in the kitchen',
      'hi': 'रसोईघर में सजे पके मीठे आम और मिट्टी के कुल्हड़',
      'bn': 'রান্নাঘরে সাজানো পাকা সোনালী আম ও মাটির চায়ের কাপ',
      'as': 'পাকঘৰত সজোৱা পকা মিঠা আম আৰু মাটিৰ কাপ',
      'ne': 'भान्छामा राखिएका पाकेका आँप र माटाका कपहरू',
    },
    'puzzle_family_gathering': {
      'en': 'Grandparents and grandchild sharing a cherished photo album',
      'hi': 'दादा-दादी और पोती के बीच पुरानी तस्वीरों की प्यारी यादें',
      'bn': 'দাদু-দিদিমার সাথে নাতনির পারিবারিক ছবির অ্যালবাম দেখা',
      'as': 'ককা-আইতা আৰু নাতিনীৰ পুৰণি ফটো এলবামৰ মৰমৰ স্মৃতি',
      'ne': 'हजुरबुबा-हजुरआमा र नातिनी मिलेर पुरानो फोटो हेर्दै',
    },
  };

  // ---------------------------------------------------------------------------
  // Rich Semantic Landmarks - Image Content Descriptions (No Spatial Coordinates)
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, Map<String, String>>> _semanticLandmarks = {
    // =========================================================================
    // 1. Kaziranga One-Horned Rhino (Assam)
    // =========================================================================
    'puzzle_kaziranga_rhino': {
      'left': {
        'en': 'Look for the strong body and folded armor-like skin of the rhinoceros resting in the tall grassland.',
        'as': 'ওখ ঘাঁহনিত চৰি থকা গঁড়টোৰ শক্তিশালী গা আৰু ডাঠ চামৰাৰ অংশটো বিচাৰক।',
        'hi': 'घांस के मैदान में खड़े गैंडे के मजबूत शरीर और मुड़ी हुई खाल वाला हिस्सा देखें।',
        'bn': 'ঘাসের প্রান্তরে দাঁড়িয়ে থাকা গণ্ডারের শক্তিশালী শরীর ও চামড়ার ভাঁজগুলো দেখুন।',
      },
      'right': {
        'en': 'Find the prominent single horn and gentle face of the rhinoceros grazing near the golden wetland.',
        'as': 'সোণালী জলাশয়ৰ কাষত ঘাঁহ খাই থকা গঁড়টোৰ উজ্জ্বল একশিঙ আৰু শান্ত মুখখন বিচাৰক।',
        'hi': 'सुनहरी झील के पास घास चर रहे गैंडे का प्रसिद्ध एक सींग और शांत चेहरा देखें।',
        'bn': 'জলাভূমির পাশে ঘাস খাওয়া গণ্ডারের বিখ্যাত একটি শিং এবং শান্ত মুখটি দেখুন।',
      },
      '2x2_r0_c0': {
        'en': 'Notice the calm wetlands and distant wild buffaloes grazing under the evening sky.',
        'as': 'সন্ধিয়াৰ আকাশৰ তলত চৰি থকা বনৰীয়া মঁহ আৰু শান্ত জলাশয়ৰ দৃশ্যটো চাওক।',
        'hi': 'शाम के आकाश के नीचे शांत जल और दूर चरती जंगली भैंसों को देखें।',
        'bn': 'সন্ধ্যার আকাশের নিচে শান্ত জলাভূমি এবং দূরে চরে বেড়ানো বুনো মোষগুলো দেখুন।',
      },
      '2x2_r0_c1': {
        'en': 'Look for the warm golden sunset glowing over the misty green hills and quiet riverbanks.',
        'as': 'কুঁৱলীভৰা পাহাৰ আৰু নদীৰ পাৰত বিয়পি পৰা আবেলিৰ সোণালী ৰ’দজাক চাওক।',
        'hi': 'धुंधली पहाड़ियों और नदी किनारे चमकती शाम की सुनहरी धूप देखें।',
        'bn': 'পাহাড়ের চূড়া ও নদীর তীরে ছড়িয়ে পড়া সন্ধ্যার সোনালী রোদ্দুর দেখুন।',
      },
      '2x2_r1_c0': {
        'en': 'Find the sturdy hind legs and thick protective skin of the rhinoceros planted in the grass.',
        'as': 'ঘাঁহনিত দৃঢ়ভাৱে থিয় হৈ থকা গঁড়টোৰ পিছফালৰ ভৰি আৰু ডাঠ চামৰাখিনি বিচাৰক।',
        'hi': 'घास में मजबूती से जमे गैंडे के पिछले पैर और उसकी भारी सुरक्षात्मक खाल खोजें।',
        'bn': 'ঘাসের উপর মজবুতভাবে দাঁড়িয়ে থাকা গণ্ডারের পেছনের পা ও চওড়া চামড়াটি দেখুন।',
      },
      '2x2_r1_c1': {
        'en': 'Look for the iconic curved horn and snout of the rhino as it feeds on fresh green shoots.',
        'as': 'সতেজ সেউজীয়া ঘাঁহ খাই থকা গঁড়টোৰ ধুনীয়া শিং আৰু মুখৰ অংশটো বিচাৰক।',
        'hi': 'ताजी हरी घास खा रहे गैंडे का खूबसूरत मुड़ा हुआ सींग और चेहरा खोजें।',
        'bn': 'তাজা সবুজ ঘাস খাওয়া গণ্ডারের সুন্দর বাঁকানো শিং ও মুখটি খুঁজুন।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the soft blue mountain ridges and the peaceful shallow water pools.',
        'as': 'দূৰণিৰ নীলা পাহাৰৰ শাৰী আৰু শান্ত পানীৰ সৰু বিলখন চাওক।',
        'hi': 'दूर की नीली पहाड़ियों और शांत पानी के छोटे तालों वाला हिस्सा देखें।',
        'bn': 'দূরের নীল পাহাড়ের রেখা এবং শান্ত জলের অগভীর জলাশয়টি দেখুন।',
      },
      '2x3_r0_c1': {
        'en': 'Look for the wild water buffaloes grazing together peacefully in the wide marshes.',
        'as': 'বহল জলাশয়ত একেলগে শান্তভাৱে চৰি থকা বনৰীয়া মঁহৰ জাকটো চাওক।',
        'hi': 'विस्तृत दलदल में एक साथ शांति से चरती जंगली भैंसों को देखें।',
        'bn': 'বিশাল জলাভূমিতে একসাথে চরে বেড়ানো বুনো মোষের পালটি দেখুন।',
      },
      '2x3_r0_c2': {
        'en': 'Find the radiant sunset sky casting a warm golden light over the grasslands.',
        'as': 'ঘাঁহনিত বিয়পি পৰা সূৰ্যাস্তৰ সোণালী আকাশ আৰু মৃদু পোহৰ বিচাৰক।',
        'hi': 'घास के मैदान पर सुनहरी किरणें बिखेरता डूबते सूरज का सुंदर आकाश देखें।',
        'bn': 'ঘাসের প্রান্তরে সোনালী আলো ছড়ানো সূর্যাস্তের সুন্দর আকাশটি দেখুন।',
      },
      '2x3_r1_c0': {
        'en': 'Look for the back legs and short tail of the rhino surrounded by lush wetland reeds.',
        'as': 'জলাশয়ৰ ওখ নলী-খাগৰিৰ মাজত থকা গঁড়টোৰ পিছফাল আৰু নেজডাল বিচাৰক।',
        'hi': 'ऊंची घास और सरकंडों के बीच गैंडे के पिछले पैर और छोटी पूंछ देखें।',
        'bn': 'উঁচু ঘাসের মাঝে গণ্ডারের পেছনের পা ও ছোট লেজের অংশটি দেখুন।',
      },
      '2x3_r1_c1': {
        'en': 'Notice the massive armored shoulder and textured gray back of the rhinoceros.',
        'as': 'গঁড়টোৰ শক্তিশালী ডাঠ কান্ধ আৰু বলিষ্ঠ পিঠিৰ অংশটো লক্ষ্য কৰক।',
        'hi': 'गैंडे के भारी कंधे और कवच जैसी मजबूत स्लेटी पीठ को देखें।',
        'bn': 'গণ্ডারের বিশাল কাঁধ এবং শক্ত বর্মের মতো পিঠের অংশটি লক্ষ্য করুন।',
      },
      '2x3_r1_c2': {
        'en': 'Find the magnificent curved horn, gentle eyes, and snout of the rhino grazing on green grass.',
        'as': 'কোমল সেউজীয়া ঘাঁহ খাই থকা গঁড়টোৰ সুন্দৰ একশিঙ, চকুজুৰি আৰু মুখখন বিচাৰক।',
        'hi': 'हरी घास चरते गैंडे का राजसी सींग, शांत आंखें और उसका मुंह खोजें।',
        'bn': 'সবুজ ঘাস খাওয়া গণ্ডারের অপূর্ব শিং, শান্ত চোখ ও মুখটি খুঁজুন।',
      },
    },

    // =========================================================================
    // 2. Tawang Himalayan Monastery (Arunachal Pradesh)
    // =========================================================================
    'puzzle_tawang_monastery': {
      'left': {
        'en': 'Notice the snow-capped Himalayan mountain peaks rising above the golden-roofed buildings of the monastery.',
        'as': 'মঠৰ সোণালী চালৰ ওপৰত জিলিকি থকা বৰফেৰে আবৃত হিমালয়ৰ শৃংগবোৰ চাওক।',
        'hi': 'मठ की सुनहरी छतों के पीछे चमकती बर्फ से ढकी हिमालय की पर्वत चोटियां देखें।',
        'bn': 'মঠের সোনালী ছাদের পেছনে দৃশ্যমান বরফে ঢাকা হিমালয়ের পর্বতমালা দেখুন।',
      },
      'right': {
        'en': 'Look for the sacred central prayer shrine and colorful Buddhist prayer flags fluttering along the hill trail.',
        'as': 'পাহাৰীয়া বাটত উৰি থকা ৰঙীন বৌদ্ধ প্ৰাৰ্থনাৰ পতাকা আৰু মূল মন্দিৰটো বিচাৰক।',
        'hi': 'पहाड़ी रास्ते पर लहराती रंग-बिरंगी बौद्ध प्रार्थना पताकाएं और मुख्य मंदिर भवन देखें।',
        'bn': 'পাহাড়ের পথে উড়তে থাকা রঙিন বৌদ্ধ প্রার্থনার পতাকা এবং মূল মন্দিরটি দেখুন।',
      },
      '2x2_r0_c0': {
        'en': 'Find the sharp, glistening snow peaks standing tall against the deep blue mountain sky.',
        'as': 'নীলা আকাশৰ বুকুত জিলিকি থকা বৰফৰ শুভ্ৰ পৰ্বতমালাৰ শৃংগবোৰ বিচাৰক।',
        'hi': 'गहरे नीले आकाश के सामने खड़ी तीखी बर्फ से ढकी सफेद पर्वत चोटियां खोजें।',
        'bn': 'নীল আকাশের বুকে মাথা তুলে দাঁড়ানো শুভ্র বরফাবৃত পর্বতের চূড়াগুলো দেখুন।',
      },
      '2x2_r0_c1': {
        'en': 'Notice the majestic high-altitude snowy crests touched by soft wandering clouds.',
        'as': 'বগা ডাৱৰে চুই যোৱা ওখ বৰফাবৃত পৰ্বতৰ শিখৰবোৰ লক্ষ্য কৰক।',
        'hi': 'हल्के बादलों से घिरी हिमालय की ऊंची बर्फीली चोटियों वाला हिस्सा देखें।',
        'bn': 'হালকা মেঘের ছোঁয়া পাওয়া বরফে মোড়া হিমালয়ের সুউচ্চ শৃঙ্গগুলো দেখুন।',
      },
      '2x2_r1_c0': {
        'en': 'Look for the tiered whitewashed buildings with bright yellow roofs perched on the green slope.',
        'as': 'সেউজীয়া পাহাৰৰ গাত থকা বগা দেৱাল আৰু হালধীয়া চালৰ বৌদ্ধ আশ্ৰমবোৰ চাওক।',
        'hi': 'पहाड़ी ढलान पर बनी सफेद दीवारों और पीली छतों वाली बौद्ध भिक्षुओं की कुटियां देखें।',
        'bn': 'পাহাড়ের গায়ে ধাপে ধাপে সাজানো সাদা দেয়াল ও হলুদ ছাদের মঠগুলো দেখুন।',
      },
      '2x2_r1_c1': {
        'en': 'Find the grand central monastery assembly hall and the strings of vibrant prayer flags.',
        'as': 'মঠৰ মূল প্ৰাৰ্থনা ভৱন আৰু বতাহত উৰি থকা ৰঙীন পতাকাৰ শাৰীটো বিচাৰক।',
        'hi': 'मठ का मुख्य प्रार्थना भवन और हवा में लहराती रंगीन पताकाओं की लड़ियां खोजें।',
        'bn': 'মঠের মূল প্রার্থনা ভবন এবং বাতাসে দুলতে থাকা রঙিন পতাকার মালাটি দেখুন।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the jagged snowy mountain ridge rising majestically above the forested valley.',
        'as': 'বননিৰে ভৰা উপত্যকাৰ ওপৰত উঠি অহা তীক্ষ্ণ বৰফৰ পাহাৰৰ শিখৰবোৰ চাওক।',
        'hi': 'जंगलों से भरी घाटी के ऊपर उठती बर्फीली पहाड़ी चोटियों को देखें।',
        'bn': 'সবুজ উপত্যকার ওপর জেগে থাকা খাঁজকাটা বরফের পর্বতচূড়া দেখুন।',
      },
      '2x3_r0_c1': {
        'en': 'Find the towering white summit of the Himalayas glistening brilliantly in the sunshine.',
        'as': 'ৰ’দত জিলিকি থকা হিমালয়ৰ সৰ্বোচ্চ বৰফাবৃত শুভ্ৰ শিখৰটো বিচাৰক।',
        'hi': 'धूप में चमकती हिमालय की सबसे ऊंची बर्फ से ढकी विशाल चोटी खोजें।',
        'bn': 'রোদে ঝিকমিক করতে থাকা হিমালয়ের সর্বোচ্চ শুভ্র তুষারশৃঙ্গটি দেখুন।',
      },
      '2x3_r0_c2': {
        'en': 'Look for the serene alpine ridges fading into the clear blue morning sky.',
        'as': 'নিৰ্মল পুৱাৰ নীলা আকাশৰ বুকুত মিলি যোৱা ওখ পাহাৰৰ ঢালবোৰ চাওক।',
        'hi': 'साफ नीले आसमान में मिलती हुई दूर की शांत पहाड़ी चोटियां देखें।',
        'bn': 'নির্মল নীল আকাশের কোলে মিলিয়ে যাওয়া দূরের শান্ত শৈলশিরা দেখুন।',
      },
      '2x3_r1_c0': {
        'en': 'Look for the rows of traditional white monastic buildings with bright yellow rooftops.',
        'as': 'হালধীয়া চাল আৰু বগা দেৱালৰ ঐতিহ্যমণ্ডিত বৌদ্ধ গৃহবোৰৰ শাৰীটো চাওক।',
        'hi': 'चमकीली पीली छतों और सफेद दीवारों वाली पारंपरिक इमारतों की कतार देखें।',
        'bn': 'উজ্জ্বল হলুদ ছাদ ও সাদা দেয়ালের ঐতিহ্যবাহী মঠের সারিটি দেখুন।',
      },
      '2x3_r1_c1': {
        'en': 'Find the grand historic temple hall with its terracotta-tiled roof and carved wooden windows.',
        'as': 'ঐতিহাসিক মূল মন্দিৰৰ চাল আৰু কাঠৰ নক্সা কটা খিৰিকীবোৰ বিচাৰক।',
        'hi': 'सुंदर नक्काशीदार खिड़कियों और लाल छत वाला ऐतिहासिक मुख्य मंदिर खोजें।',
        'bn': 'সুন্দর কারুকাজ করা জানালা ও লাল ছাদের ঐতিহাসিক মূল মন্দিরটি খুঁজুন।',
      },
      '2x3_r1_c2': {
        'en': 'Notice the colorful Buddhist prayer flags fluttering along the dirt mountain trail.',
        'as': 'মাটিৰ পাহাৰীয়া বাটৰ কাষত বতাহত উৰি থকা উজ্জ্বল ৰঙৰ প্ৰাৰ্থনাৰ পতাকাবোৰ চাওক।',
        'hi': 'पहाड़ी पगडंडी के किनारे हवा में फहराती रंग-बिरंगी पवित्र प्रार्थना ध्वज देखें।',
        'bn': 'পাহাড়ের মেঠো পথের ধারে বাতাসে উড়তে থাকা রঙিন প্রার্থনার পতাকাগুলো দেখুন।',
      },
    },

    // =========================================================================
    // 3. Sacred Monastery Sanctuary (Arunachal / Sikkim)
    // =========================================================================
    'puzzle_monastery_prayer': {
      'left': {
        'en': 'Look for the golden embossed prayer wheels and richly painted Buddhist thangka murals.',
        'as': 'সোণালী প্ৰাৰ্থনাৰ চকা আৰু দেৱালত অঁকা ধুনীয়া বৌদ্ধ চিত্ৰবোৰৰ অংশটো চাওক।',
        'hi': 'सुनहरे प्रार्थना चक्र और दीवार पर बने रंग-बिरंगे पारंपरिक थंगका चित्र देखें।',
        'bn': 'সোনালী প্রার্থনার চাকা এবং দেয়ালে আঁকা সুন্দর ঐতিহ্যবাহী থাংকা চিত্রগুলো দেখুন।',
      },
      'right': {
        'en': 'Find the serene monk seated in peaceful meditation before the luminous golden Buddha statue.',
        'as': 'উজ্জ্বল সোণালী বুদ্ধ মূৰ্তিৰ সন্মুখত গভীৰ ধ্যানত মগ্ন হৈ থকা শান্ত ভিক্খুজনক বিচাৰক।',
        'hi': 'चमकती सुनहरी बुद्ध प्रतिमा के आगे शांत ध्यान में बैठे भिक्षु को देखें।',
        'bn': 'উজ্জ্বল সোনালী বুদ্ধমূর্তির সামনে শান্ত ধ্যানে বসা বৌদ্ধ সন্ন্যাসীটিকে দেখুন।',
      },
      '2x2_r0_c0': {
        'en': 'Notice the intricately carved temple pillar tops and the painted halo of the sacred deity.',
        'as': 'মন্দিৰৰ স্তম্ভৰ ওপৰৰ খোদিত নক্সা আৰু দেৱালত অঁকা বুদ্ধৰ পবিত্ৰ প্ৰভামণ্ডল চাওক।',
        'hi': 'खंभों पर नक्काशीदार सोने का काम और दीवार पर चित्रित पवित्र बुद्ध का प्रभामंडल देखें।',
        'bn': 'স্তম্ভের ওপর সুন্দর খোদাই করা কারুকাজ এবং দেয়ালে আঁকা পবিত্র বুদ্ধের জ্যোতির্বলয় দেখুন।',
      },
      '2x2_r0_c1': {
        'en': 'Look for the ornate ceiling beams with lotus carvings and traditional Tibetan wall frescoes.',
        'as': 'পদ্মফুলৰ নক্সা থকা চিলিঙৰ কাঠ আৰু পৰম্পৰাগত তিব্বতী দেৱাল চিত্ৰবোৰ চাওক।',
        'hi': 'कमल की नक्काशी वाली छत की बल्लियां और पारंपरिक तिब्बती भित्तिचित्र देखें।',
        'bn': 'পদ্মের কারুকাজ করা ছাদের বিম এবং ঐতিহ্যবাহী তিব্বতি দেয়ালচিত্রগুলো দেখুন।',
      },
      '2x2_r1_c0': {
        'en': 'Find the row of brass prayer cylinders and the carved wooden sanctuary pillars.',
        'as': 'পিতলৰ সোণালী প্ৰাৰ্থনা চকাবোৰ আৰু কাঠৰ খোদিত স্তম্ভকেইটা বিচাৰক।',
        'hi': 'पीतल के प्रार्थना चक्रों की कतार और नक्काशीदार लकड़ी के खंभे खोजें।',
        'bn': 'পিতলের প্রার্থনার চাকার সারি এবং কারুকাজ করা কাঠের থামগুলো খুঁজুন।',
      },
      '2x2_r1_c1': {
        'en': 'Look for the peaceful monk sitting in meditation on the white steps before Lord Buddha.',
        'as': 'ভগৱান বুদ্ধৰ আগত বগা খটখটিত শান্তভাৱে ধ্যানত বহা সন্ন্যাসীজনক চাওক।',
        'hi': 'भगवान बुद्ध के सामने सफेद सीढ़ियों पर शांत ध्यानमग्न बैठे भिक्षु को देखें।',
        'bn': 'ভগবান বুদ্ধের সামনে সাদা সিঁড়িতে শান্ত ধ্যানে বসা সন্ন্যাসীটিকে দেখুন।',
      },
      '2x3_r0_c0': {
        'en': 'Look for the painted temple archway with gold floral borders and colorful frescoes.',
        'as': 'সোণালী ফুলৰ নক্সা আৰু ৰঙীন চিত্ৰৰে সজোৱা মন্দিৰৰ তোৰণৰ অংশটো চাওক।',
        'hi': 'सुनहरी पुष्प नक्काशी और सुंदर रंगों से सजा मंदिर के प्रवेश का तोरण देखें।',
        'bn': 'সোনালী ফুলের কারুকাজ ও রঙিন চিত্রে সাজানো মন্দিরের খিলানটি দেখুন।',
      },
      '2x3_r0_c1': {
        'en': 'Find the radiant golden Buddha statue seated with hand in the earth-touching gesture.',
        'as': 'ভূমিস্পৰ্শ মুদ্ৰাত শান্তভাৱে বহি থকা উজ্জ্বল সোণালী বুদ্ধ মূৰ্তিটো বিচাৰক।',
        'hi': 'भूमिस्पर्श मुद्रा में विराजमान चमकती सुनहरी बुद्ध प्रतिमा को खोजें।',
        'bn': 'ভূমি স্পর্শ মুদ্রায় শান্তভাবে বসে থাকা উজ্জ্বল সোনালী বুদ্ধমূর্তিটি খুঁজুন।',
      },
      '2x3_r0_c2': {
        'en': 'Notice the colorful mural of the compassionate Bodhisattva painted on the temple wall.',
        'as': 'মন্দিৰৰ দেৱালত অঁকা কৰুণাময় বোধিসত্ত্বৰ ৰঙীন দেৱাল চিত্ৰখন লক্ষ্য কৰক।',
        'hi': 'मंदिर की दीवार पर चित्रित करुणामयी बोधिसत्व का सुंदर रंगीन रूप देखें।',
        'bn': 'মন্দিরের দেয়ালে আঁকা করুণাময় বোধিসত্ত্বের রঙিন রূপটি লক্ষ্য করুন।',
      },
      '2x3_r1_c0': {
        'en': 'Look for the large golden prayer cylinders set into the wooden temple frame.',
        'as': 'কাঠৰ ফ্ৰেমৰ মাজত থকা ডাঙৰ সোণালী প্ৰাৰ্থনাৰ চকাবোৰ বিচাৰক।',
        'hi': 'लकड़ी के चौखट में लगे बड़े सुनहरे प्रार्थना चक्रों वाला हिस्सा देखें।',
        'bn': 'কাঠের ফ্রেমের ভেতর বসানো বড় সোনালী প্রার্থনার চাকাগুলো দেখুন।',
      },
      '2x3_r1_c1': {
        'en': 'Find the young monk draped in traditional maroon robes sitting peacefully in meditation.',
        'as': 'ৰঙচুৱা বস্ত্ৰ পৰিহিত হৈ গভীৰ ধ্যানত নিমগ্ন শান্ত তৰুণ সন্ন্যাসীজনক বিচাৰক।',
        'hi': 'पारंपरिक गहरे लाल वस्त्र पहने शांत भाव से ध्यान में लीन भिक्षु को खोजें।',
        'bn': 'ঐতিহ্যবাহী গাঢ় লাল পোশাক পরা শান্ত মনে ধ্যানে মগ্ন তরুণ সন্ন্যাসীটিকে খুঁজুন।',
      },
      '2x3_r1_c2': {
        'en': 'Notice the decorated monastery entrance pillars and the sacred prayer wheels.',
        'as': 'সজাই তোলা মন্দিৰৰ স্তম্ভ আৰু পবিত্ৰ প্ৰাৰ্থনাৰ ঘূৰ্ণন চকাবোৰ লক্ষ্য কৰক।',
        'hi': 'सजाए गए मंदिर के खंभे और उनके पास लगे पवित्र प्रार्थना चक्र देखें।',
        'bn': 'সুন্দর করে সাজানো মন্দিরের স্তম্ভ এবং পাশে থাকা পবিত্র প্রার্থনার চাকাগুলো দেখুন।',
      },
    },

    // =========================================================================
    // 4. Seven Sisters Heritage (Northeast India)
    // =========================================================================
    'puzzle_seven_sisters': {
      'left': {
        'en': 'Look for the women from Arunachal, Assam, and Manipur dressed in golden Muga silk, traditional shawls, and beaded necklaces.',
        'as': 'সোণালী মুগাৰ মেখেলা চাদৰ, পৰম্পৰাগত চাদৰ আৰু মণিৰে সজা অৰুণাচল, অসম আৰু মণিপুৰৰ বোৱাৰী-ছোৱালীকেইগৰাকীক চাওক।',
        'hi': 'अरुणाचल, असम और मणिपुर की महिलाओं को उनके सुनहरे मूंगा सिल्क, पारंपरिक शॉल और मोतियों के हार में देखें।',
        'bn': 'অরুণাচল, আসাম ও মণিপুরের মহিলাদের সোনালী মুগা সিল্কের শাড়ি, ঐতিহ্যবাহী শাল ও গহনায় দেখুন।',
      },
      'right': {
        'en': 'Find the women from Meghalaya, Mizoram, Nagaland, and Tripura in their vivid red handwoven skirts and traditional headdresses.',
        'as': 'মেঘালয়, মিজোৰাম, নাগালেণ্ড আৰু ত্ৰিপুৰাৰ ধুনীয়া ৰঙা আৰু ক’লা বোৱা সাজ পৰিহিত মহিলাসকলক বিচাৰক।',
        'hi': 'मेघालय, मिजोरम, नागालैंड और त्रिपुरा की महिलाओं को उनकी चमकीली लाल हथकरघा पोशाकों और मुकुटों में देखें।',
        'bn': 'মেঘালয়, মিজোরাম, নাগাল্যান্ড ও ত্রিপুরার মহিলাদের উজ্জ্বল লাল তাঁতের পোশাক ও সুন্দর সাজে দেখুন।',
      },
      '2x2_r0_c0': {
        'en': 'Notice the warm smiles of the sisters from Arunachal, Assam, and Manipur with lush green bamboo hills behind them.',
        'as': 'সেউজীয়া বাঁহনি আৰু পাহাৰৰ পটভূমিত অৰুণাচল, অসম আৰু মণিপুৰৰ হাঁহিমুখীয়া জীয়ৰীসকলক চাওক।',
        'hi': 'हरे-भरे बांस के जंगलों और पहाड़ियों के सामने अरुणाचल, असम और मणिपुर की बहनों के मुस्कुराते चेहरे देखें।',
        'bn': 'সবুজ বাঁশবন ও পাহাড়ের সামনে অরুণাচল, আসাম ও মণিপুরের বোনদের স্নিগ্ধ হাসিটি দেখুন।',
      },
      '2x2_r0_c1': {
        'en': 'Look for the smiling faces of the sisters representing Meghalaya, Mizoram, Nagaland, and Tripura against the misty rainforest.',
        'as': 'কুঁৱলীভৰা অৰণ্যৰ সন্মুখত মেঘালয়, মিজোৰাম, নাগালেণ্ড আৰু ত্ৰিপুৰাৰ মৰমলগা হাঁহিবোৰ চাওক।',
        'hi': 'धुंधली पहाड़ियों के आगे मेघालय, मिजोरम, नागालैंड और त्रिपुरा की मुस्कुराती बहनों को देखें।',
        'bn': 'কুয়াশাচ্ছন্ন পাহাড়ের কোলে মেঘালয়, মিজোরাম, নাগাল্যান্ড ও ত্রিপুরার হাসিমুখ বোনেরা।',
      },
      '2x2_r1_c0': {
        'en': 'Find the golden Assamese Mekhela Chador with red borders and woven bamboo baskets of fresh indigenous rice and fish.',
        'as': 'ৰঙা ফুল কটা অসমৰ সোণালী মেখেলা চাদৰ আৰু বাঁহৰ পাচিত থকা স্থানীয় ধান আৰু মাছখিনি বিচাৰক।',
        'hi': 'असम की लाल किनारी वाली सुनहरी मेखेला चादोर और बांस की टोकरियों में रखा स्थानीय अनाज व मछली खोजें।',
        'bn': 'আসামের লাল পাড়ের সোনালী মেখেলা চাদর এবং বাঁশের ডালায় রাখা দেশীয় ধান ও মাছের অংশটি দেখুন।',
      },
      '2x2_r1_c1': {
        'en': 'Look for the woven bamboo bowls filled with tender bamboo shoots, fresh local produce, and vibrant tribal handloom fabrics.',
        'as': 'বাঁহৰ গাঁজ, শাক-পাচলি আৰু ৰঙীন জনজাতীয় বোৱা কাপোৰৰ অংশটো বিচাৰক।',
        'hi': 'बांस के करील, ताजी पहाड़ी सब्जियां और रंग-बिरंगे पारंपरिक वस्त्रों वाला हिस्सा देखें।',
        'bn': 'বাঁশের কোঁড়ল, তাজা শাকসবজি এবং রঙিন ঐতিহ্যবাহী তাঁতের পোশাকের অংশটি খুঁজুন।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the maiden of Arunachal in her silver bead necklace and the Assamese sister in golden silk.',
        'as': 'ৰূপালী মণি পিন্ধা অৰুণাচলৰ জীয়ৰী আৰু সোণালী ৰেচমৰ সাজত অসমৰ জীয়ৰীগৰাকীক চাওক।',
        'hi': 'मोतियों के हार में अरुणाचल की कन्या और सुनहरे रेशम में असम की बहन का रूप देखें।',
        'bn': 'সুন্দর গহনা পরা অরুণাচলের কন্যা এবং সোনালী রেশমি পোশাকে আসামের বোনকে দেখুন।',
      },
      '2x3_r0_c1': {
        'en': 'Look for the graceful sisters of Manipur and Meghalaya with traditional neckpieces and soft shawls.',
        'as': 'মণিপুৰ আৰু মেঘালয়ৰ সুন্দৰ পৰম্পৰাগত মালা আৰু চাদৰ পৰিহিতা জীয়ৰীসকলক চাওক।',
        'hi': 'मणिपुर और मेघालय की बहनों के पारंपरिक हार और सुंदर वस्त्रों वाला हिस्सा देखें।',
        'bn': 'মণিপুর ও মেঘালয়ের সুন্দর ঐতিহ্যবাহী গহনা ও পোশাক পরা বোনেদের দেখুন।',
      },
      '2x3_r0_c2': {
        'en': 'Find the sisters from Mizoram, Nagaland, and Tripura adorned in striking tribal headwear and woven regalia.',
        'as': 'মিজোৰাম, নাগালেণ্ড আৰু ত্ৰিপুৰাৰ বৈশিষ্ট্যপূৰ্ণ সাজ আৰু শিৰোস্ত্ৰাণ পৰিহিতা ভনীসকলক বিচাৰক।',
        'hi': 'मिजोरम, नागालैंड और त्रिपुरा की बहनों के आकर्षक मुकुट और पारंपरिक वस्त्र खोजें।',
        'bn': 'মিজোরাম, নাগাল্যান্ড ও ত্রিপুরার সুন্দর মাথার সাজ ও বয়নশিল্পের পোশাকগুলো দেখুন।',
      },
      '2x3_r1_c0': {
        'en': 'Find the bamboo platters of traditional smoked fish, aromatic black rice, and harvested mountain grains.',
        'as': 'বাঁহৰ ডলাত থকা পৰম্পৰাগত শুকান মাছ, সুগন্ধি ক’লা চাউল আৰু পাহাৰীয়া শস্যবোৰ বিচাৰক।',
        'hi': 'बांस की थालियों में रखी पारंपरिक मछली, खुशबूदार काला चावल और पहाड़ी अनाज देखें।',
        'bn': 'বাঁশের ডালায় সাজানো সুস্বাদু ঐতিহ্যবাহী মাছ, সুগন্ধি কালো চাল ও শস্যগুলো দেখুন।',
      },
      '2x3_r1_c1': {
        'en': 'Look for the fresh green herbs, tender bamboo shoots, and colorful handwoven wraparound fabrics.',
        'as': 'সতেজ বনৌষধি, বাঁহৰ কোমল গাঁজ আৰু ৰঙীন হাতশালৰ মেৰিওৱা কাপোৰবোৰ চাওক।',
        'hi': 'ताजा हरा साग, नरम बांस के करील और रंग-बिरंगी हथकरघा पोशाकों वाला हिस्सा देखें।',
        'bn': 'তাজা শাকসবজি, কচি বাঁশের কোঁড়ল এবং রঙিন তাঁতের কাপড়ের অংশটি দেখুন।',
      },
      '2x3_r1_c2': {
        'en': 'Notice the handwoven red-and-black striped skirts resting beside bowls of orchard fruits and hill chilies.',
        'as': 'ৰঙা-ক’লা পটীয়া পৰম্পৰাগত কাপোৰ আৰু বাটিত সজাই থোৱা ফলমূল আৰু ভোট জলকীয়া চাওক।',
        'hi': 'लाल-काली धारियों वाली पोशाक और कटोरों में रखे पहाड़ी फल व तीखी मिर्च देखें।',
        'bn': 'লাল-কালো ডোরাকাটা সুন্দর পোশাক এবং বাটিতে রাখা সুস্বাদু ফল ও পাহাড়ি মরিচ দেখুন।',
      },
    },

    // =========================================================================
    // 5. Cherrapunji Living Waterfalls (Meghalaya)
    // =========================================================================
    'puzzle_meghalaya_falls': {
      'left': {
        'en': 'Look for the deep rain-kissed green valley and the misty cloud cover drifting through the mountain gorges.',
        'as': 'মেঘেৰে আবৃত গভীৰ সেউজীয়া উপত্যকা আৰু পাহাৰৰ গিৰিখাতেদি বৈ যোৱা নদীখন চাওক।',
        'hi': 'बादलों से ढकी गहरी हरी घाटी और पहाड़ों के बीच से गुजरती धुंधली वादियों का नजारा देखें।',
        'bn': 'মেঘে ঢাকা গভীর সবুজ উপত্যকা এবং পাহাড়ের খাদ দিয়ে বয়ে যাওয়া নদীটি দেখুন।',
      },
      'right': {
        'en': 'Find the breathtaking white waterfalls plunging down the sheer cliffs and the hikers standing on the overlook.',
        'as': 'থিয় পাহাৰৰ পৰা সৰি পৰা ধুনীয়া বগা জলপ্ৰপাত আৰু পাহাৰৰ দাঁতিত থিয় হৈ থকা যাত্ৰীসকলক বিচাৰক।',
        'hi': 'ऊंचे पहाड़ों से गिरते सफेद दूधिया झरने और पहाड़ी रास्ते पर खड़े पदयात्रियों को देखें।',
        'bn': 'উঁচু পাহাড় থেকে নেমে আসা সাদা জলপ্রপাত এবং পাহাড়ের চূড়ায় দাঁড়িয়ে থাকা পথিকদের দেখুন।',
      },
      '2x2_r0_c0': {
        'en': 'Notice the swirling rain clouds and mist settling softly over the high plateaus of Cherrapunji.',
        'as': 'চেৰাপুঞ্জীৰ ওখ পাহাৰৰ ওপৰত খেলি থকা বৰষুণৰ ডাৱৰ আৰু কুঁৱলীবোৰ লক্ষ্য কৰক।',
        'hi': 'चेरापूंजी के ऊंचे पठारों पर तैरते बारिश के बादल और कोहरे की चादर देखें।',
        'bn': 'চেরাপুঞ্জির উঁচু পাহাড়ের ওপর ঘুরে বেড়ানো বৃষ্টির মেঘ ও কুয়াশা দেখুন।',
      },
      '2x2_r0_c1': {
        'en': 'Look for the sheer rocky cliff faces where multiple streams of water emerge from the jungle.',
        'as': 'অৰণ্যৰ মাজেৰে ওলাই অহা থিয় শিলৰ পাহাৰ আৰু জলধাৰাবোৰ চাওক।',
        'hi': 'जंगलों से निकलकर ऊंचे सीधे चट्टानों से गिरती कई जलधाराओं को देखें।',
        'bn': 'সবুজ জঙ্গল ভেদ করে পাথুরে পাহাড় বেয়ে নেমে আসা জলের ধারাগুলো দেখুন।',
      },
      '2x2_r1_c0': {
        'en': 'Find the lush green mountain ridge and the hikers with their walking sticks pausing to enjoy the view.',
        'as': 'সেউজীয়া পাহাৰীয়া বাট আৰু দৃশ্য উপভোগ কৰি ৰৈ থকা লাঠী হাতত লৈ যাত্ৰীকেইজনক বিচাৰক।',
        'hi': 'सुंदर हरी पहाड़ी चोटी और हाथ में लाठी लिए नजारे का आनंद लेते यात्रियों को खोजें।',
        'bn': 'সবুজ পাহাড়ি পথ এবং দৃশ্য উপভোগ করতে লাঠি হাতে দাঁড়িয়ে থাকা পর্যটকদের দেখুন।',
      },
      '2x2_r1_c1': {
        'en': 'Look for the magnificent cascading waterfall crashing into the deep canyon pool below.',
        'as': 'তলৰ গভীৰ উপত্যকাত সশব্দে সৰি পৰা বিশাল মনোৰম জলপ্ৰপাতটো বিচাৰক।',
        'hi': 'नीचे गहरी घाटी में गूंजते हुए गिरते विशाल और सुंदर झरने को देखें।',
        'bn': 'নিচের গভীর খাদে আছড়ে পড়া বিশাল নয়নাভিরাম জলপ্রপাতটি দেখুন।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the monsoon clouds releasing a gentle haze of rain across the distant green peaks.',
        'as': 'দূৰৰ সেউজীয়া পাহাৰৰ ওপৰত বৰষুণৰ কোমল কুঁৱলী পেলাই থকা ডাৱৰবোৰ চাওক।',
        'hi': 'दूर की हरी पहाड़ियों पर हल्की फुहारें बरसाते मानसूनी बादलों को देखें।',
        'bn': 'দূরের সবুজ পাহাড়ের ওপর বৃষ্টি ভেজা কুয়াশা ছড়ানো মেঘগুলো দেখুন।',
      },
      '2x3_r0_c1': {
        'en': 'Look for the silver mountain river flowing quietly through the dense green valley bottom.',
        'as': 'উপত্যকাৰ তলেদি শান্তভাৱে বৈ যোৱা ৰূপালী পাহাৰীয়া নদীখন চাওক।',
        'hi': 'घाटी की गहराई में शांत बहती चांदी जैसी पहाड़ी नदी को देखें।',
        'bn': 'উপত্যকার তলদেশ দিয়ে শান্তভাবে বয়ে যাওয়া রুপোলি পাহাড়ি নদীটি দেখুন।',
      },
      '2x3_r0_c2': {
        'en': 'Find the dramatic cliff edge where several white waterfalls begin their long plunge.',
        'as': 'য’ৰ পৰা কেইবাটাও বগা জলপ্ৰপাত তললৈ নামি আহিছে সেই ওখ পাহাৰৰ দাঁতিটো বিচাৰক।',
        'hi': 'पहाड़ का वह ऊंचा किनारा जहां से कई सफेद झरने नीचे की ओर छलांग लगाते हैं खोजें।',
        'bn': 'পাহাড়ের সেই উঁচু খাড়া ধারটি যেখান থেকে শুভ্র জলপ্রপাতগুলো নিচের দিকে নেমে এসেছে।',
      },
      '2x3_r1_c0': {
        'en': 'Look for the small group of hikers standing on the red dirt path surrounded by ferns.',
        'as': 'ঢেকীয়া লতাৰে ভৰা ৰঙা মাটিৰ বাটত থিয় হৈ থকা যাত্ৰীৰ দলটোক চাওক।',
        'hi': 'फर्न के पौधों के बीच लाल मिट्टी के रास्ते पर खड़े पदयात्रियों के समूह को देखें।',
        'bn': 'ফার্ন গাছের মাঝে লাল মাটির মেঠোপথে দাঁড়িয়ে থাকা পর্যটকদের দলটি দেখুন।',
      },
      '2x3_r1_c1': {
        'en': 'Notice the winding trail and lush emerald tree canopy blanketing the valley slopes.',
        'as': 'উপত্যকাৰ ঢালত সেউজীয়া অৰণ্যৰ দলিচা আৰু সৰ্পিল বাটটো লক্ষ্য কৰক।',
        'hi': 'पहाड़ की ढलानों को ढकने वाले घने पन्ना-हरे जंगलों और रास्ते को देखें।',
        'bn': 'পাহাড়ের ঢাল বেয়ে নেমে যাওয়া সবুজ বনানী ও আঁকাবাঁকা পথটি দেখুন।',
      },
      '2x3_r1_c2': {
        'en': 'Find the roaring white waterfall thundering down into the lush rainforest pool.',
        'as': 'অৰণ্যৰ মাজৰ জলাশয়ত গৰজি নামি অহা সুবিশাল বগা জলপ্ৰপাতটো বিচাৰক।',
        'hi': 'जंगल के बीच नीचे बने ताल में गरजते हुए गिरते सफेद विशाल झरने को खोजें।',
        'bn': 'সবুজ বনের মাঝে সৃষ্টি হওয়া জলাশয়ে গর্জন করে আছড়ে পড়া বিশাল শুভ্র জলপ্রপাতটি খুঁজুন।',
      },
    },

    // Legacy landmarks preserved
    'puzzle_morning_tea': {
      'left': {
        'en': 'Look for the fresh garland of golden marigold flowers and the antique brass teapot.',
        'hi': 'गेंदे के ताजे पीले फूलों की माला और पीतल की केतली वाला हिस्सा देखें।',
      },
      'right': {
        'en': 'Find the steaming brass cup of hot chai resting on the carved wooden tray.',
        'hi': 'नक्काशीदार लकड़ी की ट्रे पर रखी भाप छोड़ती चाय की प्याली खोजें।',
      },
    },
    'puzzle_courtyard_garden': {
      'left': {
        'en': 'Find the vibrant cluster of deep red roses and the courtyard swing.',
        'hi': 'खिलते हुए गहरे लाल गुलाब और आंगन का झूला खोजें।',
      },
      'right': {
        'en': 'Notice the sacred green Tulsi plant in its carved terracotta planter.',
        'hi': 'आंगन में नक्काशीदार गमले में रखी पवित्र तुलसी का पौधा देखें।',
      },
    },
    'puzzle_home_kitchen': {
      'left': {
        'en': 'Find the colorful bowl filled with sweet, ripe golden mangoes.',
        'hi': 'कटोरे में रखे मीठे और रसीले पके आमों वाला हिस्सा खोजें।',
      },
      'right': {
        'en': 'Notice the handmade terracotta chai cups and small clay pot on the table.',
        'hi': 'मेज पर रखे मिट्टी के चाय के कुल्हड़ और छोटी मटकी देखें।',
      },
    },
    'puzzle_family_gathering': {
      'left': {
        'en': 'Look for the loving grandmother smiling warmly in her maroon patterned saree.',
        'hi': 'मरून साड़ी पहने मुस्कुराती हुई प्यारी दादीजी को देखें।',
      },
      'right': {
        'en': 'Find the kind grandfather holding the cherished family photo album with the grandchild.',
        'hi': 'पोती के साथ पारिवारिक फोटो एलबम पकड़े दयालु दादाजी को देखें।',
      },
    },
  };
}
