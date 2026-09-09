// ==============================================================================
// NIRVANA - PuzzleItem & PuzzleImage Models
// Description: Dementia-friendly familiar images with semantic landmark guidance
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

      // Fallback to coarse left/right or top/bottom landmarks
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

    // 2. Engaging visual content fallback (never clinical positions)
    switch (langCode) {
      case 'hi':
        return 'तस्वीर में रंगों और सुंदर आकृतियों को ध्यान से देखें।';
      case 'bn':
        return 'ছবির সুন্দর রং এবং চেনা রূপগুলো মনোযোগ দিয়ে দেখুন।';
      case 'as':
        return 'ছবিখনৰ ধুনীয়া ৰং আৰু চিনাকি দৃশ্যবোৰ ভালদৰে চাওক।';
      case 'ne':
        return 'तस्वीरका सुन्दर रङहरू र परिचित रूपहरू ध्यान दिएर हेर्नुहोस्।';
      default:
        return 'Notice the warm colors and familiar shapes in this part of the picture.';
    }
  }

  // ---------------------------------------------------------------------------
  // Default Curated Dementia-Friendly Scenes
  // ---------------------------------------------------------------------------
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

  static const List<PuzzleImage> defaultFamiliarImages = [
    morningTea,
    courtyardGarden,
    homeKitchen,
    familyGathering,
  ];

  // ---------------------------------------------------------------------------
  // Localization Dictionaries
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, String>> _localizedTitles = {
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
    'puzzle_morning_tea': {
      'en': 'A comforting cup of morning chai with fresh flowers',
      'hi': 'ताजे फूलों के साथ सुबह की गर्मागर्म चाय',
      'bn': 'তাজা ফুলের সাথে সকালের আরামদায়ক চা',
      'as': 'সতেজ ফুলৰ সৈতে পুৱাৰ আৰামদায়ক চাহ',
      'ne': 'ताजा फूलहरूसँग बिहानको मीठो चिया',
    },
    'puzzle_courtyard_garden': {
      'en': 'A peaceful home garden with sacred Tulsi and blooming roses',
      'hi': 'पवित्र तुलसी और खिलते गुलाबों से महकता शांत आंगन',
      'bn': 'পবিত্র তুলসী ও প্রস্ফুটিত গোলাপে ভরা শান্ত উঠান',
      'as': 'পবিত্ৰ তুলসী আৰু ফুলি থকা গোলাপেৰে শান্ত চোতাল',
      'ne': 'पवित्र तुलसी र फुलेका गुलाबहरूले सजिएको शान्त आँगन',
    },
    'puzzle_home_kitchen': {
      'en': 'Golden sweet mangoes and earthen clay cups in the kitchen',
      'hi': 'रसोई में रखे मीठे आम और मिट्टी के कुल्हड़',
      'bn': 'রান্নাঘরে পাকা মিষ্টি আম ও মাটির কাপ',
      'as': 'পাকঘৰত মিঠা আম আৰু মাটিৰ কাপ',
      'ne': 'भान्छामा पाकेका मीठा आँप र माटाका कपहरू',
    },
    'puzzle_family_gathering': {
      'en': 'Grandparents and grandchild sharing a cherished photo album',
      'hi': 'पोती के साथ पुरानी फोटो एलबम देखते दादा-दादी',
      'bn': 'নাতনির সাথে পুরোনো ছবির অ্যালবাম দেখছেন দাদু-দিদা',
      'as': 'নাতিনীৰ সৈতে পুৰণি ছবিৰ এলবাম চাই থকা ককা-আইতা',
      'ne': 'नातिनीसँग पुराना फोटो हेर्दै गरेका हजुरबुबा र हजुरआमा',
    },
  };

  static const Map<String, Map<String, Map<String, String>>> _semanticLandmarks = {
    // 1. Morning Tea
    'puzzle_morning_tea': {
      'left': {
        'en': 'Look for the fresh garland of golden marigold flowers resting on the table.',
        'hi': 'मेज पर रखी ताजे पीले गेंदे के फूलों की माला खोजें।',
        'bn': 'টেবিলে রাখা তাজা হলুদ গাঁদা ফুলের মালাটি খুঁজুন।',
        'as': 'মেজত থকা সতেজ হালধীয়া গেন্দা ফুলৰ মালাডাল বিচাৰক।',
        'ne': 'टेबलमा राखिएको ताजा पहेंलो सयपत्री फूलको माला खोज्नुहोस्।',
      },
      'right': {
        'en': 'Notice the steaming cup of freshly brewed morning chai and traditional teapot.',
        'hi': 'पीतल की गर्मागर्म चाय की प्याली और केतली खोजें।',
        'bn': 'গরম চায়ের পিতলের কাপ এবং কেটলিটি খুঁজুন।',
        'as': 'গৰম চাহৰ পিতলৰ কাপ আৰু কেটলিটো বিচাৰক।',
        'ne': 'तातो चियाको पित्तलको कप र केतली खोज्नुहोस्।',
      },
      '2x2_r0_c0': {
        'en': 'Notice the peaceful open window showing pink garden blossoms in the morning sun.',
        'hi': 'सुबह की धूप में बगीचे के गुलाबी फूलों वाली खुली खिड़की देखें।',
      },
      '2x2_r0_c1': {
        'en': 'Look for the gentle swirls of fragrant steam rising from the hot tea.',
        'hi': 'गर्म चाय से उठती हल्की खुशबूदार भाप वाला हिस्सा देखें।',
      },
      '2x2_r1_c0': {
        'en': 'Find the beautiful garland of yellow and orange marigold blossoms.',
        'hi': 'पीले और नारंगी गेंदे के फूलों की सुंदर माला खोजें।',
      },
      '2x2_r1_c1': {
        'en': 'Look for the traditional brass chai cup resting on the carved wooden saucer.',
        'hi': 'नक्काशीदार लकड़ी की तश्तरी पर रखी पीतल की चाय की प्याली खोजें।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the sunny garden window with pink bougainvillea flowers outside.',
        'hi': 'बगीचे की खिड़की और बाहर खिले गुलाबी फूलों वाला हिस्सा देखें।',
      },
      '2x3_r0_c1': {
        'en': 'Look for the delicate swirls of steam rising in the morning light.',
        'hi': 'चाय से उठती खुशबूदार भाप और सुबह की धूप वाला हिस्सा देखें।',
      },
      '2x3_r0_c2': {
        'en': 'Find the antique brass kettle and the plate of morning biscuits.',
        'hi': 'पीतल की केतली और बिस्कुट की थाली वाला हिस्सा देखें।',
      },
      '2x3_r1_c0': {
        'en': 'Notice the patterned Indian fabric draped across the wooden daybed.',
        'hi': 'लकड़ी की दीवान पर बिछी सुंदर चादर वाला हिस्सा देखें।',
      },
      '2x3_r1_c1': {
        'en': 'Find the vibrant garland of fresh yellow and orange marigold blossoms.',
        'hi': 'पीले और नारंगी गेंदे के ताजे फूलों की माला खोजें।',
      },
      '2x3_r1_c2': {
        'en': 'Look for the warm brass chai cup resting on the carved wooden saucer.',
        'hi': 'नक्काशीदार लकड़ी की तश्तरी पर रखी पीतल की चाय की प्याली खोजें।',
      },
    },

    // 2. Courtyard Garden
    'puzzle_courtyard_garden': {
      'left': {
        'en': 'Find the vibrant cluster of deep red roses and the courtyard swing.',
        'hi': 'खिलते हुए गहरे लाल गुलाब और आंगन का झूला खोजें।',
        'bn': 'ফুটে থাকা উজ্জ্বল লাল গোলাপ ও উঠানের দোলনাটি খুঁজুন।',
        'as': 'ফুলি থকা উজ্জ্বল ৰঙা গোলাপ আৰু চোতালৰ দোলনাখন বিচাৰক।',
        'ne': 'फुलेका राता गुलाबहरू र आँगनको पिङ खोज्नुहोस्।',
      },
      'right': {
        'en': 'Notice the sacred green Tulsi plant in its carved terracotta planter.',
        'hi': 'आंगन में नक्काशीदार गमले में रखी पवित्र तुलसी का पौधा देखें।',
        'bn': 'উঠানের সুন্দর পাত্রে রাখা পবিত্র তুলসী গাছটি দেখুন।',
        'as': 'চোতালৰ পাত্ৰত থকা পবিত্ৰ তুলসী গছজোপাৰ অংশটো চাওক।',
        'ne': 'आँगनमा राखिएको पवित्र तुलसीको बोट भएको भाग हेर्नुहोस्।',
      },
      '2x2_r0_c0': {
        'en': 'Look for the climbing leafy ivy spreading across the courtyard wall.',
        'hi': 'आंगन की दीवार पर फैली हरी-भरी सुंदर लताएं देखें।',
      },
      '2x2_r0_c1': {
        'en': 'Notice the traditional carved wooden verandah arches and hanging temple bell.',
        'hi': 'बरामदे के नक्काशीदार लकड़ी के खंभे और लटकी घंटी देखें।',
      },
      '2x2_r1_c0': {
        'en': 'Find the cluster of fragrant red roses blooming near the wooden swing.',
        'hi': 'लकड़ी के झूले के पास खिले महकते लाल गुलाब खोजें।',
      },
      '2x2_r1_c1': {
        'en': 'Notice the terracotta Tulsi planter decorated with flowers and the brass watering can.',
        'hi': 'फूलों से सजा तुलसी का गमला और पीतल का लोटा देखें।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the green ivy climbing over the courtyard garden wall.',
        'hi': 'आंगन की दीवार पर चढ़ी हरी लताएं देखें।',
      },
      '2x3_r0_c1': {
        'en': 'Look for the tall bush of blooming red roses under the sunshine.',
        'hi': 'धूप में खिले लाल गुलाबों की झाड़ी देखें।',
      },
      '2x3_r0_c2': {
        'en': 'Find the carved wooden verandah pillars and the hanging temple bell.',
        'hi': 'बरामदे के लकड़ी के खंभे और मंदिर की घंटी देखें।',
      },
      '2x3_r1_c0': {
        'en': 'Notice the wooden courtyard swing with colorful embroidered cushions.',
        'hi': 'कढ़ाई वाले तकियों से सजा आंगन का झूला देखें।',
      },
      '2x3_r1_c1': {
        'en': 'Look for the blooming red roses and flowering pots on the stone courtyard.',
        'hi': 'पत्थर के आंगन में रखे गमले और लाल गुलाब देखें।',
      },
      '2x3_r1_c2': {
        'en': 'Find the terracotta Tulsi shrine and the golden brass watering pot.',
        'hi': 'तुलसी का मंदिर और सुनहरी पीतल की झारी खोजें।',
      },
    },

    // 3. Home Kitchen
    'puzzle_home_kitchen': {
      'left': {
        'en': 'Find the colorful bowl filled with sweet, ripe golden mangoes.',
        'hi': 'कटोरे में रखे मीठे और रसीले पके आमों वाला हिस्सा खोजें।',
        'bn': 'বাটিতে রাখা মিষ্টি পাকা সোনালী আমের অংশটি খুঁজুন।',
        'as': 'বাটিত থকা মিঠা পকা সোণালী আমৰ অংশটো বিচাৰক।',
        'ne': 'बाटामा राखिएका मीठा पाकेका आँपहरूको भाग खोज्नुहोस्।',
      },
      'right': {
        'en': 'Notice the handmade terracotta chai cups and small clay pot on the table.',
        'hi': 'मेज पर रखे मिट्टी के चाय के कुल्हड़ और छोटी मटकी देखें।',
        'bn': 'টেবিলে রাখা মাটির চায়ের কাপ ও ছোট পাত্রটি দেখুন।',
        'as': 'মেজত থকা মাটিৰ চাহৰ কাপ আৰু সৰু পাত্ৰটো চাওক।',
        'ne': 'टेबलमा राखिएका माटाका चिया कपहरू र सानो भाँडो हेर्नुहोस्।',
      },
      '2x2_r0_c0': {
        'en': 'Look for the kitchen shelf holding traditional spice and pickle jars.',
        'hi': 'मसालों और अचार के पारंपरिक डिब्बों वाला रैक देखें।',
      },
      '2x2_r0_c1': {
        'en': 'Notice the open window bringing warm morning sunlight into the room.',
        'hi': 'रसोई में धूप लाती खुली खिड़की वाला हिस्सा देखें।',
      },
      '2x2_r1_c0': {
        'en': 'Find the bowl of golden ripe mangoes with freshly sliced juicy fruit.',
        'hi': 'कटे हुए रसीले आम और सुनहरे पके आमों का कटोरा खोजें।',
      },
      '2x2_r1_c1': {
        'en': 'Notice the matching terracotta tea cups and the small earthen pot.',
        'hi': 'मिट्टी के चाय के कुल्हड़ और छोटी हांडी देखें।',
      },
      '2x3_r0_c0': {
        'en': 'Look for the neat row of ceramic pickle jars and kitchen ladles.',
        'hi': 'अचार की बरनियों और करछुलों वाला हिस्सा देखें।',
      },
      '2x3_r0_c1': {
        'en': 'Notice the cookware and pots resting on the kitchen rack.',
        'hi': 'रसोई के स्टैंड पर रखे बर्तन देखें।',
      },
      '2x3_r0_c2': {
        'en': 'Look for the open wooden window looking into the green trees.',
        'hi': 'हरे-भरे पेड़ों की ओर खुलती लकड़ी की खिड़की देखें।',
      },
      '2x3_r1_c0': {
        'en': 'Find the wooden dining chair and the folded cotton napkin.',
        'hi': 'लकड़ी की कुर्सी और रखा हुआ साफ कपड़ा देखें।',
      },
      '2x3_r1_c1': {
        'en': 'Notice the bowl filled with ripe golden mangoes and sweet cut slices.',
        'hi': 'पके हुए मीठे आमों का कटोरा और कटे हुए टुकड़े देखें।',
      },
      '2x3_r1_c2': {
        'en': 'Find the pair of terracotta tea cups filled with warm milk chai.',
        'hi': 'गरम चाय से भरे मिट्टी के कुल्हड़ों की जोड़ी खोजें।',
      },
    },

    // 4. Family Gathering
    'puzzle_family_gathering': {
      'left': {
        'en': 'Look for the loving grandmother smiling warmly in her maroon patterned saree.',
        'hi': 'मरून साड़ी पहने मुस्कुराती हुई प्यारी दादीजी को देखें।',
        'bn': 'মেরুন শাড়ি পরা হাসিমুখ স্নেহময়ী দিদিমাকে দেখুন।',
        'as': 'মেৰুন সাজ পৰিহিতা হাঁহিমুখী আইতাক চাওক।',
        'ne': 'सजावटयुक्त साडीमा मुस्कुराइरहेकी हजुरआमालाई हेर्नुहोस्।',
      },
      'right': {
        'en': 'Find the kind grandfather holding the cherished family photo album with the grandchild.',
        'hi': 'पोती के साथ पारिवारिक फोटो एलबम पकड़े दयालु दादाजी को देखें।',
        'bn': 'নাতনির সাথে পারিবারিক ছবির অ্যালবাম ধরে রাখা দাদুকে দেখুন।',
        'as': 'নাতিনীৰ সৈতে ফটো এলবাম লৈ থকা মৰমীয়াল ককাক চাওক।',
        'ne': 'नातिनीसँग पारिवारिक फोटो हेरिरहनुभएका हजुरबुबालाई हेर्नुहोस्।',
      },
      '2x2_r0_c0': {
        'en': 'Notice grandmother’s gentle smile and her graceful silver hair.',
        'hi': 'दादीजी की प्यारी मुस्कान और उनके चांदी जैसे सफेद बाल देखें।',
      },
      '2x2_r0_c1': {
        'en': 'Find grandfather’s happy face looking warmly through his reading glasses.',
        'hi': 'चश्मा लगाए दादाजी का मुस्कुराता हुआ चेहरा देखें।',
      },
      '2x2_r1_c0': {
        'en': 'Look for the cheerful little granddaughter pointing at an old family photograph.',
        'hi': 'पुरानी फोटो की ओर इशारा करती खुश बच्ची को देखें।',
      },
      '2x2_r1_c1': {
        'en': 'Find the large vintage family album showing black-and-white photos.',
        'hi': 'काले-सफेद फोटो वाली बड़ी पारिवारिक एलबम खोजें।',
      },
      '2x3_r0_c0': {
        'en': 'Notice the framed family portraits and beloved books on the living room shelf.',
        'hi': 'अलमारी में रखी परिवार की तस्वीरें और किताबें देखें।',
      },
      '2x3_r0_c1': {
        'en': 'Look for grandmother’s radiant smile and the gentle lamplight.',
        'hi': 'दादीजी का मुस्कुराता चेहरा और लैंप की रोशनी देखें।',
      },
      '2x3_r0_c2': {
        'en': 'Find grandfather’s affectionate expression and the warm room curtain.',
        'hi': 'दादाजी का स्नेहमय चेहरा और कमरे का पर्दा देखें।',
      },
      '2x3_r1_c0': {
        'en': 'Notice the rich maroon saree and traditional gold bangles on grandmother’s wrist.',
        'hi': 'दादीजी की लाल साड़ी और उनकी चूड़ियाँ देखें।',
      },
      '2x3_r1_c1': {
        'en': 'Look for the little girl’s colorful floral dress as she discovers family memories.',
        'hi': 'फूलों वाली फ्रॉक पहने प्यारी बच्ची को देखें।',
      },
      '2x3_r1_c2': {
        'en': 'Find the open vintage photo album filled with cherished generational pictures.',
        'hi': 'पुरानी यादों से भरी खुली फोटो एलबम खोजें।',
      },
    },
  };
}
