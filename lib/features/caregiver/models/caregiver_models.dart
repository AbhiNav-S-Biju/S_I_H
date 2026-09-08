// ==============================================================================
// NIRVANA - Caregiver Models
// Description: Domain models for Caregiver Portal, Patient Management & Onboarding,
// Accessibility Settings, Activity Summaries, Game History, and Adherence Tracking.
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

/// Extensible Domain Model for Care Recipient / Patient
class PatientModel {
  final String id;
  final String? primaryCaregiverId;
  final String displayName;
  final String preferredName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? emergencyContactPhone;
  final String relationship; // e.g. "Father", "Mother", "Spouse"
  final Map<String, dynamic> accessibilitySettings;
  final Map<String, dynamic> customPreferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientModel({
    required this.id,
    this.primaryCaregiverId,
    required this.displayName,
    required this.preferredName,
    this.avatarUrl,
    this.dateOfBirth,
    this.emergencyContactPhone,
    this.relationship = 'Family Member',
    this.accessibilitySettings = const {
      'large_text': true,
      'high_contrast': true,
      'audio_prompts': true,
      'haptic_feedback': true,
      'low_motion': true,
      'font_scale': 1.3,
      'timezone': 'UTC',
    },
    this.customPreferences = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    final rawSettings = map['accessibility_settings'];
    Map<String, dynamic> settingsMap = {};
    if (rawSettings is Map<String, dynamic>) {
      settingsMap = Map<String, dynamic>.from(rawSettings);
    } else if (rawSettings is Map) {
      settingsMap = Map<String, dynamic>.from(rawSettings);
    }

    final rawCustom = map['custom_preferences'] ?? map['preferences'];
    Map<String, dynamic> customMap = {};
    if (rawCustom is Map<String, dynamic>) {
      customMap = Map<String, dynamic>.from(rawCustom);
    } else if (rawCustom is Map) {
      customMap = Map<String, dynamic>.from(rawCustom);
    }

    // Extract relationship from joined links if available
    String relationship = 'Family Member';
    if (map['relationship'] != null) {
      relationship = map['relationship'] as String;
    } else if (map['relationship_label'] != null) {
      relationship = map['relationship_label'] as String;
    } else if (map['caregiver_patient_links'] is List &&
        (map['caregiver_patient_links'] as List).isNotEmpty) {
      final firstLink = (map['caregiver_patient_links'] as List).first;
      if (firstLink is Map && firstLink['relationship_label'] != null) {
        relationship = firstLink['relationship_label'] as String;
      }
    }

    return PatientModel(
      id: map['id'] as String? ?? '',
      primaryCaregiverId: map['primary_caregiver_id'] as String?,
      displayName: map['display_name'] as String? ?? map['full_name'] as String? ?? 'Loved One',
      preferredName: map['preferred_name'] as String? ?? map['display_name'] as String? ?? 'Loved One',
      avatarUrl: map['avatar_url'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'].toString())
          : null,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      relationship: relationship,
      accessibilitySettings: settingsMap.isNotEmpty
          ? settingsMap
          : const {
              'large_text': true,
              'high_contrast': true,
              'audio_prompts': true,
              'haptic_feedback': true,
              'low_motion': true,
              'font_scale': 1.3,
              'timezone': 'UTC',
            },
      customPreferences: customMap,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (primaryCaregiverId != null) 'primary_caregiver_id': primaryCaregiverId,
    'display_name': displayName,
    'preferred_name': preferredName,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (dateOfBirth != null)
      'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
    if (emergencyContactPhone != null)
      'emergency_contact_phone': emergencyContactPhone,
    'accessibility_settings': {
      ...accessibilitySettings,
      ...customPreferences,
    },
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  PatientSummary toSummary({DateTime? lastActiveAt}) {
    return PatientSummary(
      id: id,
      fullName: displayName,
      preferredName: preferredName,
      relationship: relationship,
      avatarUrl: avatarUrl,
      primaryCaregiverId: primaryCaregiverId ?? '',
      emergencyContactPhone: emergencyContactPhone,
      lastActiveAt: lastActiveAt,
    );
  }
}

class PatientSummary {
  final String id;
  final String fullName;
  final String? preferredName;
  final String relationship; // e.g. "Father", "Mother", "Spouse"
  final String? avatarUrl;
  final String primaryCaregiverId;
  final String? emergencyContactPhone;
  final DateTime? lastActiveAt;

  const PatientSummary({
    required this.id,
    required this.fullName,
    this.preferredName,
    required this.relationship,
    this.avatarUrl,
    required this.primaryCaregiverId,
    this.emergencyContactPhone,
    this.lastActiveAt,
  });

  factory PatientSummary.fromMap(Map<String, dynamic> map) {
    String relationship = 'Family Member';
    if (map['relationship'] != null) {
      relationship = map['relationship'] as String;
    } else if (map['relationship_label'] != null) {
      relationship = map['relationship_label'] as String;
    } else if (map['caregiver_patient_links'] is List &&
        (map['caregiver_patient_links'] as List).isNotEmpty) {
      final firstLink = (map['caregiver_patient_links'] as List).first;
      if (firstLink is Map && firstLink['relationship_label'] != null) {
        relationship = firstLink['relationship_label'] as String;
      }
    }

    final name = map['display_name'] as String? ?? map['full_name'] as String? ?? 'Loved One';
    final preferred = map['preferred_name'] as String? ?? name;

    return PatientSummary(
      id: map['id'] as String? ?? '',
      fullName: name,
      preferredName: preferred,
      relationship: relationship,
      avatarUrl: map['avatar_url'] as String?,
      primaryCaregiverId: map['primary_caregiver_id'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.tryParse(map['last_active_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'full_name': fullName,
    'display_name': fullName,
    if (preferredName != null) 'preferred_name': preferredName,
    'relationship': relationship,
    'avatar_url': avatarUrl,
    'primary_caregiver_id': primaryCaregiverId,
    if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone,
    'last_active_at': lastActiveAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Initial template reminder configured during onboarding
class InitialReminderInput {
  final String title;
  final String description;
  final String reminderType; // 'medication', 'hydration', 'meal', 'social', 'activity', 'general'
  final String scheduleTime; // HH:mm:ss
  final List<String> recurrenceDays;
  final bool isEnabled;

  const InitialReminderInput({
    required this.title,
    this.description = '',
    this.reminderType = 'general',
    required this.scheduleTime,
    this.recurrenceDays = const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap(String patientId) => {
    'patient_id': patientId,
    'title': title,
    'description': description.isNotEmpty ? description : null,
    'reminder_type': reminderType,
    'schedule_time': scheduleTime,
    'recurrence_days': recurrenceDays,
    'is_active': isEnabled,
    'is_deleted': false,
  };
}

/// Input DTO for Patient Onboarding
class CreatePatientInput {
  final String fullName;
  final String preferredName;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? emergencyContactPhone;
  final String timezone;
  final double fontScale;
  final bool highContrast;
  final bool largeText;
  final bool audioPrompts;
  final bool hapticFeedback;
  final bool lowMotion;
  final Map<String, dynamic> customPreferences;
  final List<InitialReminderInput> initialReminders;

  const CreatePatientInput({
    required this.fullName,
    required this.preferredName,
    this.relationship = 'Parent',
    this.dateOfBirth,
    this.emergencyContactPhone,
    this.timezone = 'UTC',
    this.fontScale = 1.3,
    this.highContrast = true,
    this.largeText = true,
    this.audioPrompts = true,
    this.hapticFeedback = true,
    this.lowMotion = true,
    this.customPreferences = const {},
    this.initialReminders = const [],
  });

  Map<String, dynamic> toAccessibilitySettings() => {
    'font_scale': fontScale,
    'high_contrast': highContrast,
    'large_text': largeText,
    'audio_prompts': audioPrompts,
    'haptic_feedback': hapticFeedback,
    'low_motion': lowMotion,
    'timezone': timezone,
    ...customPreferences,
  };
}

class CaregiverGameRecord {
  final String id;
  final String gameTitle;
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
