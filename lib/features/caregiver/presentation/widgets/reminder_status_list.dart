// ==============================================================================
// NIRVANA - Reminder Status List Widget
// Description: Live reminder management for caregivers. Supports full CRUD:
// Add, Edit (time, recurrence, type), Toggle Active, and Delete, alongside
// real-time patient adherence status indicators.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class ReminderStatusList extends ConsumerWidget {
  const ReminderStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(selectedPatientRemindersProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.alarm, size: 20, color: ElderColors.primary),
                SizedBox(width: 8),
                Text(
                  'Daily Reminders & Routines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (selectedPatient != null)
              FilledButton.icon(
                onPressed: () => _showAddOrEditDialog(
                  context,
                  ref,
                  patientId: selectedPatient.id,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Reminder', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: ElderColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Reminders List or Empty State
        remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ElderColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_add,
                        size: 32,
                        color: ElderColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No reminders scheduled yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add medications, hydration, or meals for ${selectedPatient?.preferredName ?? 'your loved one'}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (selectedPatient != null)
                      OutlinedButton.icon(
                        onPressed: () => _showAddOrEditDialog(
                          context,
                          ref,
                          patientId: selectedPatient.id,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add First Reminder'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ElderColors.primary,
                          side: const BorderSide(color: ElderColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _ReminderTile(
                    reminder: reminder,
                    patientId: selectedPatient?.id ?? reminder.patientId,
                  );
                },
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load reminders: $e',
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static void _showAddOrEditDialog(
    BuildContext context,
    WidgetRef ref, {
    CaregiverReminderRecord? reminder,
    required String patientId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddOrEditReminderSheet(
        reminder: reminder,
        patientId: patientId,
      ),
    );
  }
}

// ==============================================================================
// Reminder Tile Item
// ==============================================================================
class _ReminderTile extends ConsumerWidget {
  final CaregiverReminderRecord reminder;
  final String patientId;

  const _ReminderTile({
    required this.reminder,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = reminder.isCompleted;
    final isSnoozed = reminder.snoozedUntil != null && !isCompleted;
    final isInactive = !reminder.isActive;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isInactive) {
      statusColor = Colors.grey;
      statusLabel = 'Disabled';
      statusIcon = Icons.pause_circle_outline;
    } else if (isCompleted) {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isSnoozed) {
      statusColor = const Color(0xFFE65100);
      statusLabel = 'Snoozed';
      statusIcon = Icons.snooze;
    } else {
      statusColor = ElderColors.primary;
      statusLabel = 'Scheduled';
      statusIcon = Icons.alarm;
    }

    final typeIcon = _getReminderTypeIcon(reminder.reminderType);
    final formattedTime = _formatTime(reminder.scheduleTime, reminder.scheduledAt);

    return InkWell(
      onTap: () => ReminderStatusList._showAddOrEditDialog(
        context,
        ref,
        reminder: reminder,
        patientId: patientId,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Type Icon Avatar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isInactive
                                ? Colors.grey[600]
                                : ElderColors.textPrimary,
                            decoration: isInactive
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description / subtitle info
                  if (reminder.description != null &&
                      reminder.description!.isNotEmpty) ...[
                    Text(
                      reminder.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Badges: Recurrence & Adherence status
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Recurrence badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatRecurrence(reminder.recurrenceDays),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Adherence status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              _formatStatusDetail(reminder, statusLabel),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Quick Action Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) async {
                if (action == 'edit') {
                  ReminderStatusList._showAddOrEditDialog(
                    context,
                    ref,
                    reminder: reminder,
                    patientId: patientId,
                  );
                } else if (action == 'toggle') {
                  await ref
                      .read(caregiverRemindersNotifierProvider.notifier)
                      .toggleReminderActive(reminder.id, !reminder.isActive);
                } else if (action == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Delete Reminder?'),
                      content: Text(
                        'Are you sure you want to remove "${reminder.title}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(caregiverRemindersNotifierProvider.notifier)
                        .deleteReminder(reminder.id);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        reminder.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(reminder.isActive ? 'Disable' : 'Enable'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  static IconData _getReminderTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'hydration':
        return Icons.water_drop;
      case 'meal':
        return Icons.restaurant;
      case 'activity':
        return Icons.directions_walk;
      case 'sleep':
        return Icons.bedtime;
      case 'social':
        return Icons.people;
      default:
        return Icons.alarm;
    }
  }

  static String _formatTime(String rawTime, DateTime scheduledAt) {
    int hour = scheduledAt.hour;
    int minute = scheduledAt.minute;

    if (rawTime.contains(':')) {
      final parts = rawTime.split(':');
      hour = int.tryParse(parts[0]) ?? hour;
      minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? minute) : minute;
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  static String _formatRecurrence(List<String> days) {
    if (days.isEmpty || days.length == 7) return 'Every Day';
    if (days.length == 5 &&
        days.contains('mon') &&
        days.contains('tue') &&
        days.contains('wed') &&
        days.contains('thu') &&
        days.contains('fri')) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains('sat') && days.contains('sun')) {
      return 'Weekends';
    }
    return days.map((d) => d.substring(0, 1).toUpperCase() + d.substring(1, 3)).join(', ');
  }

  static String _formatStatusDetail(
    CaregiverReminderRecord reminder,
    String defaultLabel,
  ) {
    if (reminder.isCompleted && reminder.completedAt != null) {
      final c = reminder.completedAt!;
      final h = c.hour > 12 ? c.hour - 12 : (c.hour == 0 ? 12 : c.hour);
      final p = c.hour >= 12 ? 'PM' : 'AM';
      final m = c.minute.toString().padLeft(2, '0');
      return 'Completed at $h:$m $p';
    }
    if (reminder.snoozedUntil != null && !reminder.isCompleted) {
      final s = reminder.snoozedUntil!;
      final h = s.hour > 12 ? s.hour - 12 : (s.hour == 0 ? 12 : s.hour);
      final p = s.hour >= 12 ? 'PM' : 'AM';
      final m = s.minute.toString().padLeft(2, '0');
      return 'Snoozed until $h:$m $p';
    }
    return defaultLabel;
  }
}

// ==============================================================================
// Add / Edit Reminder Modal Bottom Sheet
// ==============================================================================
class _AddOrEditReminderSheet extends ConsumerStatefulWidget {
  final CaregiverReminderRecord? reminder;
  final String patientId;

  const _AddOrEditReminderSheet({
    this.reminder,
    required this.patientId,
  });

  @override
  ConsumerState<_AddOrEditReminderSheet> createState() =>
      _AddOrEditReminderSheetState();
}

class _AddOrEditReminderSheetState
    extends ConsumerState<_AddOrEditReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _reminderType;
  late TimeOfDay _selectedTime;
  late List<String> _recurrenceDays;
  late bool _isActive;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _types = [
    {'key': 'medication', 'label': 'Medication', 'icon': Icons.medication},
    {'key': 'hydration', 'label': 'Hydration', 'icon': Icons.water_drop},
    {'key': 'meal', 'label': 'Meal', 'icon': Icons.restaurant},
    {'key': 'activity', 'label': 'Activity', 'icon': Icons.directions_walk},
    {'key': 'sleep', 'label': 'Sleep', 'icon': Icons.bedtime},
    {'key': 'general', 'label': 'General', 'icon': Icons.alarm},
  ];

  final List<Map<String, String>> _allDays = [
    {'key': 'mon', 'label': 'M'},
    {'key': 'tue', 'label': 'T'},
    {'key': 'wed', 'label': 'W'},
    {'key': 'thu', 'label': 'T'},
    {'key': 'fri', 'label': 'F'},
    {'key': 'sat', 'label': 'S'},
    {'key': 'sun', 'label': 'S'},
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _reminderType = r?.reminderType ?? 'medication';
    _isActive = r?.isActive ?? true;

    if (r != null && r.scheduleTime.contains(':')) {
      final parts = r.scheduleTime.split(':');
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 30);
    }

    _recurrenceDays = r != null
        ? List<String>.from(r.recurrenceDays)
        : ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ElderColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ElderColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _setPresetRecurrence(String preset) {
    setState(() {
      if (preset == 'daily') {
        _recurrenceDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      } else if (preset == 'weekdays') {
        _recurrenceDays = ['mon', 'tue', 'wed', 'thu', 'fri'];
      } else if (preset == 'weekends') {
        _recurrenceDays = ['sat', 'sun'];
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minStr = _selectedTime.minute.toString().padLeft(2, '0');
    final scheduleTime = '$hourStr:$minStr';

    final input = CreateOrUpdateReminderInput(
      id: widget.reminder?.id,
      patientId: widget.patientId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      reminderType: _reminderType,
      scheduleTime: scheduleTime,
      recurrenceDays: _recurrenceDays.isEmpty
          ? ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
          : _recurrenceDays,
      isActive: _isActive,
    );

    final notifier = ref.read(caregiverRemindersNotifierProvider.notifier);

    if (widget.reminder == null) {
      await notifier.createReminder(input);
    } else {
      await notifier.updateReminder(widget.reminder!.id, input);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminder != null;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Reminder' : 'Add New Reminder',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reminder Type Chips
              const Text(
                'Reminder Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((t) {
                    final isSelected = _reminderType == t['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          t['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        label: Text(t['label'] as String),
                        selected: isSelected,
                        selectedColor: ElderColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _reminderType = t['key'] as String);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Reminder Title
              const Text(
                'Reminder Title *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Morning Blood Pressure Medication',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Schedule Time Picker
              const Text(
                'Schedule Time *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: ElderColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ElderColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: ElderColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurrence Days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Repeat On',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _PresetButton(
                        label: 'Daily',
                        isSelected: _recurrenceDays.length == 7,
                        onTap: () => _setPresetRecurrence('daily'),
                      ),
                      const SizedBox(width: 4),
                      _PresetButton(
                        label: 'Weekdays',
                        isSelected: _recurrenceDays.length == 5 &&
                            !_recurrenceDays.contains('sat') &&
                            !_recurrenceDays.contains('sun'),
                        onTap: () => _setPresetRecurrence('weekdays'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _allDays.map((d) {
                  final key = d['key']!;
                  final isSelected = _recurrenceDays.contains(key);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_recurrenceDays.length > 1) {
                            _recurrenceDays.remove(key);
                          }
                        } else {
                          _recurrenceDays.add(key);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? ElderColors.primary
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected
                              ? ElderColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          d['label']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Optional Notes / Description
              const Text(
                'Notes & Instructions (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Take with a full glass of water after food',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Reminder is Active',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  _isActive
                      ? 'Notifications will alert on the patient device'
                      : 'Reminder is paused',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _isActive,
                activeTrackColor: ElderColors.primary,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: ElderColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add Reminder'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? ElderColors.primary.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ElderColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? ElderColors.primary : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
