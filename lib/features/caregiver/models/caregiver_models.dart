// ==============================================================================
// NIRVANA - Caregiver Models
// Description: Domain models for Caregiver Portal, Patient Selector,
// Non-Clinical Activity Summaries, Game History, and Adherence Tracking.
// ==============================================================================

class CaregiverProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // 'primary_caregiver', 'family_member', 'care_assistant'

  const CaregiverProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.role = 'primary_caregiver',
  });

  factory CaregiverProfile.fromMap(Map<String, dynamic> map) {
    return CaregiverProfile(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Caregiver',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'primary_caregiver',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      };
}

class PatientSummary {
  final String id;
  final String fullName;
  final String relationship; // e.g. "Father", "Mother", "Spouse"
  final String? avatarUrl;
  final String primaryCaregiverId;
  final DateTime? lastActiveAt;

  const PatientSummary({
    required this.id,
    required this.fullName,
    required this.relationship,
    this.avatarUrl,
    required this.primaryCaregiverId,
    this.lastActiveAt,
  });

  factory PatientSummary.fromMap(Map<String, dynamic> map) {
    return PatientSummary(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Loved One',
      relationship: map['relationship'] as String? ?? 'Family Member',
      avatarUrl: map['avatar_url'] as String?,
      primaryCaregiverId: map['primary_caregiver_id'] as String? ?? '',
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.tryParse(map['last_active_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'relationship': relationship,
        'avatar_url': avatarUrl,
        'primary_caregiver_id': primaryCaregiverId,
        'last_active_at': lastActiveAt?.toIso8601String(),
      };
}

class CaregiverGameRecord {
  final String id;
  final String gameTitle; // e.g. "Remember Objects", "Who Is This?", "Grocery Memory"
  final String gameType;
  final String difficulty;
  final int score;
  final int durationSeconds;
  final int correctCount;
  final int totalCount;
  final DateTime playedAt;

  const CaregiverGameRecord({
    required this.id,
    required this.gameTitle,
    required this.gameType,
    required this.difficulty,
    required this.score,
    required this.durationSeconds,
    required this.correctCount,
    required this.totalCount,
    required this.playedAt,
  });

  factory CaregiverGameRecord.fromMap(Map<String, dynamic> map) {
    return CaregiverGameRecord(
      id: map['id'] as String? ?? '',
      gameTitle: map['game_title'] as String? ?? 'Memory Activity',
      gameType: map['game_type'] as String? ?? 'remember_objects',
      difficulty: map['difficulty'] as String? ?? 'easy',
      score: map['score'] as int? ?? 0,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
      totalCount: map['total_count'] as int? ?? 0,
      playedAt: map['played_at'] != null
          ? DateTime.parse(map['played_at'] as String)
          : DateTime.now(),
    );
  }
}

class CaregiverReminderRecord {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  final String? lastAction; // 'done', 'snoozed', 'later_today', null

  const CaregiverReminderRecord({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.isCompleted,
    this.completedAt,
    this.snoozedUntil,
    this.lastAction,
  });

  factory CaregiverReminderRecord.fromMap(Map<String, dynamic> map) {
    return CaregiverReminderRecord(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Daily Reminder',
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String)
          : DateTime.now(),
      isCompleted: map['is_completed'] as bool? ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      snoozedUntil: map['snoozed_until'] != null
          ? DateTime.tryParse(map['snoozed_until'] as String)
          : null,
      lastAction: map['last_action'] as String?,
    );
  }
}

class DailyActivitySummary {
  final DateTime date;
  final String dayLabel; // e.g. "Mon", "Tue"
  final int gamesCompleted;
  final int remindersCompleted;
  final int totalActivities;

  const DailyActivitySummary({
    required this.date,
    required this.dayLabel,
    required this.gamesCompleted,
    required this.remindersCompleted,
    required this.totalActivities,
  });
}

class CaregiverSyncInfo {
  final int pendingEventsCount;
  final DateTime? lastSyncedAt;
  final bool isOnline;
  final String statusLabel;

  const CaregiverSyncInfo({
    required this.pendingEventsCount,
    this.lastSyncedAt,
    required this.isOnline,
    required this.statusLabel,
  });
}
