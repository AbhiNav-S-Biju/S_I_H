// ==============================================================================
// NIRVANA - Caregiver Patient Onboarding Screen
// Description: Multi-step wizard allowing caregivers to register care recipients
// with personal details, accessibility comfort presets, initial reminders,
// and device pairing preparation.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class CaregiverPatientOnboardingScreen extends ConsumerStatefulWidget {
  const CaregiverPatientOnboardingScreen({super.key});

  @override
  ConsumerState<CaregiverPatientOnboardingScreen> createState() =>
      _CaregiverPatientOnboardingScreenState();
}

class _CaregiverPatientOnboardingScreenState
    extends ConsumerState<CaregiverPatientOnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Patient Information Controllers & State
  final _fullNameController = TextEditingController();
  final _preferredNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String _selectedRelationship = 'Parent';
  String _selectedTimezone = 'UTC';

  final List<String> _relationshipOptions = [
    'Parent',
    'Mother',
    'Father',
    'Spouse',
    'Grandparent',
    'Sibling',
    'Friend',
    'Care Recipient',
    'Other',
  ];

  final List<String> _timezoneOptions = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Kolkata',
    'Asia/Tokyo',
    'Australia/Sydney',
  ];

  // Step 2: Accessibility Preferences State
  double _fontScale = 1.3;
  bool _highContrast = true;
  bool _largeText = true;
  bool _audioPrompts = true;
  bool _hapticFeedback = true;
  bool _lowMotion = true;

  // Step 3: Reminders Configuration State
  late List<_EditableReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = [
      _EditableReminder(
        title: 'Morning Medication',
        description: 'Take prescribed morning medicine with water',
        reminderType: 'medication',
        timeOfDay: const TimeOfDay(hour: 8, minute: 30),
        isEnabled: true,
      ),
      _EditableReminder(
        title: 'Afternoon Hydration',
        description: 'Drink a full glass of fresh water',
        reminderType: 'hydration',
        timeOfDay: const TimeOfDay(hour: 13, minute: 0),
        isEnabled: true,
      ),
      _EditableReminder(
        title: 'Evening Walk & Stretch',
        description: 'Gentle walk in the garden or living room',
        reminderType: 'activity',
        timeOfDay: const TimeOfDay(hour: 17, minute: 30),
        isEnabled: true,
      ),
    ];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _preferredNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    final input = CreatePatientInput(
      fullName: _fullNameController.text.trim(),
      preferredName: _preferredNameController.text.trim().isNotEmpty
          ? _preferredNameController.text.trim()
          : _fullNameController.text.trim(),
      relationship: _selectedRelationship,
      dateOfBirth: _dateOfBirth,
      emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty
          ? _emergencyPhoneController.text.trim()
          : null,
      timezone: _selectedTimezone,
      fontScale: _fontScale,
      highContrast: _highContrast,
      largeText: _largeText,
      audioPrompts: _audioPrompts,
      hapticFeedback: _hapticFeedback,
      lowMotion: _lowMotion,
      initialReminders: _reminders
          .where((r) => r.isEnabled)
          .map((r) => r.toInput())
          .toList(),
    );

    final created = await ref
        .read(patientOnboardingProvider.notifier)
        .createPatient(input);

    if (created != null && mounted) {
      _showSuccessDialog(created);
    }
  }

  void _showSuccessDialog(PatientSummary patient) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: ElderColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Patient Onboarded!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${patient.fullName} (${patient.relationship}) has been successfully added to your caregiver portal.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ElderColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: ElderColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accessibility profile and initial reminders are ready.',
                      style: TextStyle(
                        fontSize: 13,
                        color: ElderColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ElderColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/caregiver/dashboard');
            },
            child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(patientOnboardingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: ElderColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/caregiver/dashboard');
            }
          },
        ),
        title: const Text(
          'Add Loved One',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/caregiver/dashboard'),
            child: const Text('Skip to Dashboard', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            _buildProgressIndicator(),

            if (onboardingState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        onboardingState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Controls
            _buildBottomBar(onboardingState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepLabels = ['Profile', 'Comfort', 'Reminders', 'Pairing'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted || isCurrent
                                  ? ElderColors.primary
                                  : Colors.grey.shade300,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stepLabels[index],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? ElderColors.primary : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? ElderColors.primary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PatientInformation();
      case 1:
        return _buildStep2AccessibilityPreferences();
      case 2:
        return _buildStep3Reminders();
      case 3:
        return _buildStep4DevicePairing();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- STEP 1: PATIENT INFORMATION ----------
  Widget _buildStep1PatientInformation() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the personal details for the care recipient you will be supporting.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildFieldLabel('Full Name *'),
          TextFormField(
            key: const Key('patient_full_name_field'),
            controller: _fullNameController,
            decoration: _inputDecoration('e.g. Elena Rostova', Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter the patient\'s name';
              if (val.trim().length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Preferred Name
          _buildFieldLabel('Preferred Name / Nickname'),
          TextFormField(
            key: const Key('patient_preferred_name_field'),
            controller: _preferredNameController,
            decoration: _inputDecoration('e.g. Mom, Dad, Grandma', Icons.favorite_border),
          ),
          const SizedBox(height: 16),

          // Relationship
          _buildFieldLabel('Relationship to Caregiver *'),
          DropdownButtonFormField<String>(
            initialValue: _selectedRelationship,
            decoration: _inputDecoration('Select Relationship', Icons.people_outline),
            items: _relationshipOptions.map((rel) {
              return DropdownMenuItem(value: rel, child: Text(rel));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedRelationship = val);
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth
          _buildFieldLabel('Date of Birth (Optional)'),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime(1950, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dateOfBirth = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                        : 'Select Date of Birth',
                    style: TextStyle(
                      fontSize: 15,
                      color: _dateOfBirth != null ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (_dateOfBirth != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _dateOfBirth = null),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Contact Phone
          _buildFieldLabel('Emergency Contact Phone'),
          TextFormField(
            key: const Key('patient_emergency_phone_field'),
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('+1 555-0199', Icons.phone_outlined),
          ),
          const SizedBox(height: 16),

          // Timezone
          _buildFieldLabel('Timezone'),
          DropdownButtonFormField<String>(
            initialValue: _selectedTimezone,
            decoration: _inputDecoration('Select Timezone', Icons.access_time),
            items: _timezoneOptions.map((tz) {
              return DropdownMenuItem(value: tz, child: Text(tz));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedTimezone = val);
            },
          ),
        ],
      ),
    );
  }

  // ---------- STEP 2: ACCESSIBILITY PREFERENCES ----------
  Widget _buildStep2AccessibilityPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visual & Comfort Preferences',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Tailor the interface comfort settings according to the care recipient\'s cognitive and visual needs.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Font Scale Slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font Size & Scale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${(_fontScale * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: ElderColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _fontScale,
                min: 1.0,
                max: 1.8,
                divisions: 8,
                activeColor: ElderColors.primary,
                onChanged: (val) => setState(() => _fontScale = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Standard (100%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Extra Large (180%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildSwitchCard(
          title: 'High Contrast Mode',
          subtitle: 'Crisp, high-contrast borders and elevated text contrast.',
          value: _highContrast,
          onChanged: (v) => setState(() => _highContrast = v),
          icon: Icons.contrast,
        ),
        const SizedBox(height: 10),

        _buildSwitchCard(
          title: 'Large Touch Targets',
          subtitle: 'Oversized buttons with generous spacing to avoid accidental taps.',
          value: _largeText,
          onChanged: (v) => setState(() => _largeText = v),
          icon: Icons.touch_app_outlined,
        ),
        const SizedBox(height: 10),

        _buildSwitchCard(
          title: 'Audio Prompt Guidance',
          subtitle: 'Read aloud daily reminders and spoken activity instructions.',
          value: _audioPrompts,
          onChanged: (v) => setState(() => _audioPrompts = v),
          icon: Icons.volume_up_outlined,
        ),
        const SizedBox(height: 10),

        _buildSwitchCard(
          title: 'Gentle Haptic Feedback',
          subtitle: 'Vibration confirmations when tapping buttons and completing routines.',
          value: _hapticFeedback,
          onChanged: (v) => setState(() => _hapticFeedback = v),
          icon: Icons.vibration,
        ),
        const SizedBox(height: 10),

        _buildSwitchCard(
          title: 'Low Motion & Reduced Transitions',
          subtitle: 'Minimize fast animations to prevent disorientation.',
          value: _lowMotion,
          onChanged: (v) => setState(() => _lowMotion = v),
          icon: Icons.motion_photos_off_outlined,
        ),
      ],
    );
  }

  // ---------- STEP 3: REMINDERS SETUP ----------
  Widget _buildStep3Reminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Routine & Reminders',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Select initial routine reminders. You can modify schedules or add custom reminders anytime from your dashboard.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        for (final item in _reminders)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isEnabled
                    ? ElderColors.primary.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Switch(
                  value: item.isEnabled,
                  activeTrackColor: ElderColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: ElderColors.primary,
                  onChanged: (v) {
                    setState(() => item.isEnabled = v);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.isEnabled ? ElderColors.textPrimary : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: item.isEnabled
                      ? () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: item.timeOfDay,
                          );
                          if (picked != null) {
                            setState(() => item.timeOfDay = picked);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.isEnabled
                          ? ElderColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.timeOfDay.format(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isEnabled ? ElderColors.primary : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: ElderColors.primary,
            side: const BorderSide(color: ElderColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onPressed: _showAddCustomReminderDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Routine / Reminder'),
        ),
      ],
    );
  }

  void _showAddCustomReminderDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 0);
    String reminderType = 'general';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Routine Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: _inputDecoration('Reminder Title (e.g. Afternoon Tea)', Icons.alarm),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: _inputDecoration('Description (optional)', Icons.notes),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: reminderType,
                  decoration: _inputDecoration('Type', Icons.category),
                  items: const [
                    DropdownMenuItem(value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'hydration', child: Text('Hydration')),
                    DropdownMenuItem(value: 'meal', child: Text('Meal')),
                    DropdownMenuItem(value: 'activity', child: Text('Activity')),
                    DropdownMenuItem(value: 'social', child: Text('Social')),
                    DropdownMenuItem(value: 'general', child: Text('General Routine')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => reminderType = v);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule, color: ElderColors.primary),
                  title: const Text('Scheduled Time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: pickedTime);
                      if (t != null) setDialogState(() => pickedTime = t);
                    },
                    child: Text(pickedTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ElderColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  setState(() {
                    _reminders.add(
                      _EditableReminder(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        reminderType: reminderType,
                        timeOfDay: pickedTime,
                        isEnabled: true,
                      ),
                    );
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- STEP 4: DEVICE PAIRING (PHASE 4 PREVIEW) ----------
  Widget _buildStep4DevicePairing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pair Patient Device',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Connect the care recipient\'s phone or tablet to synchronize engagement activities.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ElderColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ElderColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices_other,
                  color: ElderColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Device Pairing Ready',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your patient profile and preferences are configured. You can generate a 6-digit one-time pairing code anytime from your Caregiver Dashboard to connect your patient\'s device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade800, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Ready to Pair via Caregiver Dashboard',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary Preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _buildSummaryRow('Name', _fullNameController.text),
              _buildSummaryRow('Preferred Name', _preferredNameController.text.isNotEmpty ? _preferredNameController.text : _fullNameController.text),
              _buildSummaryRow('Relationship', _selectedRelationship),
              _buildSummaryRow('Timezone', _selectedTimezone),
              _buildSummaryRow('Active Reminders', '${_reminders.where((r) => r.isEnabled).length} configured'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ElderColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: isLoading ? null : () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              key: const Key('patient_onboarding_next_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElderColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      if (_currentStep == 0) {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _currentStep++);
                        }
                      } else if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _submitOnboarding();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _currentStep == 3 ? 'Finish & Save Patient' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ElderColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: ElderColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: ElderColors.primary.withValues(alpha: 0.5),
            activeThumbColor: ElderColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ElderColors.primary, width: 1.5),
      ),
    );
  }
}

class _EditableReminder {
  final String title;
  final String description;
  final String reminderType;
  TimeOfDay timeOfDay;
  bool isEnabled;

  _EditableReminder({
    required this.title,
    required this.description,
    required this.reminderType,
    required this.timeOfDay,
    required this.isEnabled,
  });

  InitialReminderInput toInput() {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return InitialReminderInput(
      title: title,
      description: description,
      reminderType: reminderType,
      scheduleTime: '$hour:$minute:00',
      isEnabled: isEnabled,
    );
  }
}
