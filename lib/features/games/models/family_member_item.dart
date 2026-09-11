// ==============================================================================
// NIRVANA - FamilyMemberItem Model
// Description: Bundled demo family members for the "Who Is This?" relationship game
// ==============================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../family_photos/models/family_photo.dart';

class FamilyMemberItem {
  final String id;
  final String name;
  final String relationship; // e.g. "Granddaughter"
  final String
  hintDescription; // Gentle clue, e.g. "She visits on Sundays and loves baking!"
  final String voiceNoteTranscription; // Non-audio fallback prompt
  final IconData avatarIcon;
  final Color avatarColor;
  final List<String>
  alternativeRelationshipOptions; // Distractors for selection
  final String? photoUrl;
  final String? localPath;
  final Uint8List? localBytes;

  const FamilyMemberItem({
    required this.id,
    required this.name,
    required this.relationship,
    required this.hintDescription,
    required this.voiceNoteTranscription,
    required this.avatarIcon,
    required this.avatarColor,
    required this.alternativeRelationshipOptions,
    this.photoUrl,
    this.localPath,
    this.localBytes,
  });

  factory FamilyMemberItem.fromFamilyPhoto(FamilyPhoto photo) {
    const commonRelationships = [
      'Daughter',
      'Son',
      'Sister',
      'Brother',
      'Granddaughter',
      'Grandson',
      'Friend',
      'Family Member',
    ];
    final options = <String>[photo.relationship];
    for (final relationship in commonRelationships) {
      if (options.length >= 4) break;
      if (!options.contains(relationship)) options.add(relationship);
    }
    return FamilyMemberItem(
      id: photo.id,
      name: photo.name,
      relationship: photo.relationship,
      hintDescription: _relationshipHint(photo.relationship),
      voiceNoteTranscription: 'A familiar person is smiling in this picture.',
      avatarIcon: Icons.person_rounded,
      avatarColor: const Color(0xFF9B8EC4),
      alternativeRelationshipOptions: options,
      photoUrl: photo.photoUrl,
      localPath: photo.localPath,
      localBytes: photo.localBytes,
    );
  }

  static String _relationshipHint(String relationship) {
    switch (relationship.trim().toLowerCase()) {
      case 'daughter':
      case 'son':
        return 'This person is part of your immediate family and has shared many everyday moments with you.';
      case 'granddaughter':
      case 'grandson':
        return 'This cheerful young family member brings a special joy and a new generation of memories.';
      case 'sister':
      case 'brother':
        return 'You grew up sharing family memories and know this person from long ago.';
      case 'friend':
        return 'This is someone who has chosen to share good times and warm memories with you.';
      case 'family pet':
        return 'This loving companion brings comfort, playful moments, and plenty of affection.';
      default:
        return 'This person is someone special who shares meaningful memories with you.';
    }
  }

  String localizedRelationship(String languageCode) {
    return localizeRelationship(relationship, languageCode);
  }

  String localizedName(String languageCode) {
    final trans = _localizedNames[id];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return name;
  }

  String localizedQuestionPrompt(String langCode) {
    final memberName = localizedName(langCode);
    switch (langCode) {
      case 'hi':
        return '$memberName से आपका क्या संबंध है?';
      case 'bn':
        return '$memberName-র সাথে আপনার কী সম্পর্ক?';
      case 'as':
        return '$memberNameৰ সৈতে আপোনাৰ কি সম্পৰ্ক?';
      case 'ne':
        return '$memberNameसँग तपाईंको के नाता छ?';
      default:
        return 'What is $memberName\'s relationship to you?';
    }
  }

  String localizedHintDescription(String languageCode) {
    final trans = _localizedHints[id];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return hintDescription;
  }

  String localizedVoiceNoteTranscription(String languageCode) {
    final trans = _localizedTranscriptions[id];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return voiceNoteTranscription;
  }

  static String localizeRelationship(String rel, String languageCode) {
    final trans = _localizedRelationships[rel];
    if (trans != null && trans.containsKey(languageCode)) {
      return trans[languageCode]!;
    }
    return rel;
  }

  static const Map<String, Map<String, String>> _localizedNames = {
    'fam_emily': {
      'en': 'Emily',
      'hi': 'एमिली',
      'bn': 'এমিলি',
      'as': 'এমিলি',
      'ne': 'एमिली',
    },
    'fam_sarah': {
      'en': 'Sarah',
      'hi': 'सारा',
      'bn': 'সারা',
      'as': 'চাৰা',
      'ne': 'सारा',
    },
    'fam_david': {
      'en': 'David',
      'hi': 'डेविड',
      'bn': 'ডেভিড',
      'as': 'ডেভিড',
      'ne': 'डेभिड',
    },
    'fam_bailey': {
      'en': 'Bailey',
      'hi': 'बेली',
      'bn': 'বেইলি',
      'as': 'বেইলী',
      'ne': 'बेली',
    },
  };

  static const Map<String, Map<String, String>> _localizedHints = {
    'fam_emily': {
      'en':
          'She brings a bright new generation of memories and loves painting!',
      'hi':
          'वह आपके जीवन में नई पीढ़ी की खुशियां और चित्रकारी की यादें लाती है!',
      'bn':
          'সে আপনার জীবনে নতুন প্রজন্মের আনন্দ এবং ছবি আঁকার স্মৃতি নিয়ে আসে!',
      'as': 'তেওঁ আপোনাৰ জীৱনলৈ নতুন প্ৰজন্মৰ আনন্দ আৰু ছবি আঁকাৰ স্মৃতি আনে!',
      'ne':
          'उनी तपाईंको जीवनमा नयाँ पुस्ताको खुसी र चित्रकलाका सम्झना ल्याउँछिन्!',
    },
    'fam_sarah': {
      'en': 'She calls you every morning and brings your favorite tea.',
      'hi': 'वह आपको हर सुबह फोन करती है और आपकी पसंदीदा चाय लाती है।',
      'bn': 'সে প্রতিদিন সকালে আপনাকে फोन করে এবং আপনার পছন্দের চা নিয়ে আসে।',
      'as': 'তেওঁ প্ৰতি পুৱা আপোনাক ফোন কৰে আৰু আপোনাৰ প্ৰিয় চাহ আনে।',
      'ne':
          'उनी हरेक बिहान तपाईंलाई फोन गर्छिन् र तपाईंको मनपर्ने चिया ल्याउँछिन्।',
    },
    'fam_david': {
      'en': 'He loves gardening with you and fixing things around the house.',
      'hi': 'उसे आपके साथ बागवानी करना और घर के काम ठीक करना पसंद है।',
      'bn':
          'সে আপনার সাথে বাগানের কাজ করতে এবং বাড়ির জিনিস মেরামত করতে পছন্দ করে।',
      'as':
          'তেওঁ আপোনাৰ সৈতে বাগিচা কাম কৰিবলৈ আৰু ঘৰৰ কাম ঠিক কৰিবলৈ ভাল পায়।',
      'ne':
          'उनलाई तपाईंसँग बगैंचाको काम गर्न र घरका कुराहरू मर्मत गर्न मन पर्छ।',
    },
    'fam_bailey': {
      'en': 'The cheerful dog who wags his tail and sits by your feet!',
      'hi':
          'खुशमिजाज कुत्ता जो अपनी पूंछ हिलाता है और आपके पैरों के पास बैठता है!',
      'bn': 'আনন্দময় কুকুরটি যে লেজ নাড়ায় এবং আপনার পায়ের কাছে বসে!',
      'as': 'আনন্দময় কুকুৰটো যিয়ে নেজ জোকাৰি আপোনাৰ ভৰিৰ কাষত বহে!',
      'ne': 'हँसिलो कुकुर जसले पुच्छर हल्लाउँछ र तपाईंको खुट्टा नजिक बस्छ!',
    },
  };

  static const Map<String, Map<String, String>> _localizedTranscriptions = {
    'fam_emily': {
      'en': 'Hi Grandpa! Hope you are having a wonderful day!',
      'hi': 'नमस्ते दादाजी! आशा है आपका दिन बहुत अच्छा बीत रहा होगा!',
      'bn': 'হ্যালো দাদু! আশা করি আপনার দিনটি খুব সুন্দর কাটছে!',
      'as': 'নমস্কাৰ ককা! আশা কৰোঁ আপোনাৰ দিনটো অতি সুন্দৰকৈ পাৰ হৈছে!',
      'ne': 'नमस्ते बाजे! आशा छ तपाईंको दिन धेरै राम्रो बितिरहेको छ!',
    },
    'fam_sarah': {
      'en': 'Hello Dad, thinking of you today!',
      'hi': 'नमस्ते पिताजी, आज आपकी याद आ रही थी!',
      'bn': 'হ্যালো বাবা, আজ তোমার কথা ভাবছিলাম!',
      'as': 'নমস্কাৰ দেউতা, আজি আপোনাৰ কথা ভাবি আছিলোঁ!',
      'ne': 'नमस्ते बुबा, आज तपाईंको सम्झना आइरहेको छ!',
    },
    'fam_david': {
      'en': 'Hey Dad, looking forward to our weekend walk!',
      'hi': 'अरे पिताजी, हमारे सप्ताहांत की सैर का बेसब्री से इंतज़ार है!',
      'bn': 'আরে বাবা, আমাদের উইকএন্ডে হাঁটার অপেক্ষায় রইলাম!',
      'as': 'নমস্কাৰ দেউতা, সপ্তাহান্তৰ খোজ কঢ়াৰ বাবে আগ্ৰহেৰে বাট চাই আছোঁ!',
      'ne':
          'नमस्ते बुबा, सप्ताहन्तको पैदल यात्राको उत्सुकताका साथ पर्खाइमा छु!',
    },
    'fam_bailey': {
      'en': 'Woof woof! Friendly tail wags!',
      'hi': 'भौंक-भौंक! प्यार से पूंछ हिलाना!',
      'bn': 'ঘেউ ঘেউ! ভালোবাসায় লেজ নাড়ানো!',
      'as': 'ভৌ ভৌ! মৰমেৰে নেজ জোকাৰিছে!',
      'ne': 'भुक्-भुक्! मायालु पुच्छर हल्लाइ!',
    },
  };

  static const Map<String, Map<String, String>> _localizedRelationships = {
    'Granddaughter': {
      'en': 'Granddaughter',
      'hi': 'पोती / नातिन',
      'bn': 'নাতনি',
      'as': 'নাতিনী',
      'ne': 'नातिनी',
    },
    'Doctor': {
      'en': 'Doctor',
      'hi': 'डॉक्टर',
      'bn': 'ডাক্তার',
      'as': 'চিকিৎসক',
      'ne': 'डाक्टर',
    },
    'Neighbor': {
      'en': 'Neighbor',
      'hi': 'पड़ोसी',
      'bn': 'প্রতিবেশী',
      'as': 'চুবুৰীয়া',
      'ne': 'छिमेकी',
    },
    'Sister': {
      'en': 'Sister',
      'hi': 'बहन',
      'bn': 'বোন',
      'as': 'ভনী / বায়েক',
      'ne': 'बहिनी / दिदी',
    },
    'Daughter': {
      'en': 'Daughter',
      'hi': 'बेटी',
      'bn': 'মেয়ে',
      'as': 'জীয়াৰী',
      'ne': 'छोरी',
    },
    'Teacher': {
      'en': 'Teacher',
      'hi': 'शिक्षक',
      'bn': 'শিক্ষক',
      'as': 'শিক্ষক',
      'ne': 'शिक्षक',
    },
    'Cousin': {
      'en': 'Cousin',
      'hi': 'चचेरा भाई / बहन',
      'bn': 'মামাতো/কাকাতো ভাই-বোন',
      'as': 'সম্পৰ্কীয় ভাই-ভনী',
      'ne': 'काका/मामाको सन्तान',
    },
    'Nurse': {
      'en': 'Nurse',
      'hi': 'नर्स',
      'bn': 'নার্স',
      'as': 'নাৰ্ছ',
      'ne': 'नर्स',
    },
    'Son': {
      'en': 'Son',
      'hi': 'बेटा',
      'bn': 'ছেলে',
      'as': 'পুত্ৰ',
      'ne': 'छोरा',
    },
    'Grandson': {
      'en': 'Grandson',
      'hi': 'पोता / नाती',
      'bn': 'নাতি',
      'as': 'নাতি',
      'ne': 'नाति',
    },
    'Dentist': {
      'en': 'Dentist',
      'hi': 'दांतों के डॉक्टर',
      'bn': 'দাঁতের ডাক্তার',
      'as': 'দাঁতৰ ডাক্তৰ',
      'ne': 'दन्त चिकित्सक',
    },
    'Mail Carrier': {
      'en': 'Mail Carrier',
      'hi': 'डाकिया',
      'bn': 'ডাকপিয়ন',
      'as': 'ডাকোৱাল',
      'ne': 'हुलाकी',
    },
    'Family Pet': {
      'en': 'Family Pet',
      'hi': 'पालतू कुत्ता / बिल्ली',
      'bn': 'পোষা প্রাণী',
      'as': 'পোহনীয়া জীৱ',
      'ne': 'घरपालुवा जनावर',
    },
    "Neighbor's Cat": {
      'en': "Neighbor's Cat",
      'hi': 'पड़ोसी की बिल्ली',
      'bn': 'প্রতিবেশীর বিড়াল',
      'as': 'চুবুৰীয়াৰ মেকুৰী',
      'ne': 'छिमेकीको बिरालो',
    },
    'Bird': {
      'en': 'Bird',
      'hi': 'चिड़िया',
      'bn': 'পাখি',
      'as': 'চৰাই',
      'ne': 'चरा',
    },
    'Teddy Bear': {
      'en': 'Teddy Bear',
      'hi': 'टेडी बियर',
      'bn': 'টেডি বিয়ার',
      'as': 'টেডি বিয়েৰ',
      'ne': 'टेडी बियर',
    },
  };

  /// Curated demo family list (fully offline)
  static const List<FamilyMemberItem> defaultFamilyMembers = [
    FamilyMemberItem(
      id: 'fam_emily',
      name: 'Emily',
      relationship: 'Granddaughter',
      hintDescription:
          'She brings a bright new generation of memories and loves painting!',
      voiceNoteTranscription:
          'Hi Grandpa! Hope you are having a wonderful day!',
      avatarIcon: Icons.face_3_rounded,
      avatarColor: Color(0xFFE91E63),
      alternativeRelationshipOptions: [
        'Granddaughter',
        'Doctor',
        'Neighbor',
        'Sister',
      ],
    ),
    FamilyMemberItem(
      id: 'fam_sarah',
      name: 'Sarah',
      relationship: 'Daughter',
      hintDescription:
          'She calls you every morning and brings your favorite tea.',
      voiceNoteTranscription: 'Hello Dad, thinking of you today!',
      avatarIcon: Icons.face_4_rounded,
      avatarColor: Color(0xFF00897B),
      alternativeRelationshipOptions: [
        'Daughter',
        'Teacher',
        'Cousin',
        'Nurse',
      ],
    ),
    FamilyMemberItem(
      id: 'fam_david',
      name: 'David',
      relationship: 'Son',
      hintDescription:
          'He loves gardening with you and fixing things around the house.',
      voiceNoteTranscription: 'Hey Dad, looking forward to our weekend walk!',
      avatarIcon: Icons.face_6_rounded,
      avatarColor: Color(0xFF1E88E5),
      alternativeRelationshipOptions: [
        'Son',
        'Grandson',
        'Dentist',
        'Mail Carrier',
      ],
    ),
    FamilyMemberItem(
      id: 'fam_bailey',
      name: 'Bailey',
      relationship: 'Family Pet',
      hintDescription:
          'The cheerful dog who wags his tail and sits by your feet!',
      voiceNoteTranscription: 'Woof woof! Friendly tail wags!',
      avatarIcon: Icons.pets_rounded,
      avatarColor: Color(0xFFFFA000),
      alternativeRelationshipOptions: [
        'Family Pet',
        'Neighbor\'s Cat',
        'Bird',
        'Teddy Bear',
      ],
    ),
  ];
}
