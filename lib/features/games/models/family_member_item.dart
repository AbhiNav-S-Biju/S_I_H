// ==============================================================================
// NIRVANA - FamilyMemberItem Model
// Description: Bundled demo family members for the "Who Is This?" relationship game
// ==============================================================================

import 'package:flutter/material.dart';

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

  const FamilyMemberItem({
    required this.id,
    required this.name,
    required this.relationship,
    required this.hintDescription,
    required this.voiceNoteTranscription,
    required this.avatarIcon,
    required this.avatarColor,
    required this.alternativeRelationshipOptions,
  });

  /// Curated demo family list (fully offline)
  static const List<FamilyMemberItem> defaultFamilyMembers = [
    FamilyMemberItem(
      id: 'fam_emily',
      name: 'Emily',
      relationship: 'Granddaughter',
      hintDescription:
          'She is your daughter Sarah\'s child and loves painting!',
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
