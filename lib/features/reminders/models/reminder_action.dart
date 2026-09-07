// ==============================================================================
// NIRVANA - Reminder Action Model
// Description: Enum and constants representing the 3 elder-supportive reminder
// response actions: Done, Snooze (15m), and Later Today.
// ==============================================================================

enum ReminderActionType {
  done('done', 'Done'),
  snoozed('snoozed', 'Snooze 15 minutes'),
  laterToday('later_today', 'Later today');

  final String value;
  final String label;

  const ReminderActionType(this.value, this.label);

  static ReminderActionType fromString(String val) {
    switch (val) {
      case 'done':
        return ReminderActionType.done;
      case 'snoozed':
        return ReminderActionType.snoozed;
      case 'later_today':
      case 'laterToday':
        return ReminderActionType.laterToday;
      default:
        return ReminderActionType.done;
    }
  }
}

class NotificationActionIds {
  NotificationActionIds._();

  static const String done = 'action_done';
  static const String snooze15 = 'action_snooze_15';
  static const String laterToday = 'action_later_today';
}
