// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Router Unit Tests
// Description: Tests classification accuracy for all 8 supported intents
// across English, Hindi, and other regional languages.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/ask_nirvana/ask_nirvana.dart';

void main() {
  const router = NirvanaIntentRouter();

  group('NirvanaIntentRouter - All Intents Classification', () {
    test('1. REMINDERS: next reminder and medicine queries', () {
      final q1 = router.route('When is my medicine?');
      expect(q1.intent, equals(NirvanaIntent.nextReminder));
      expect(q1.isMedicineSpecific, isTrue);

      final q2 = router.route('What is my next reminder?');
      expect(q2.intent, equals(NirvanaIntent.nextReminder));

      final q3 = router.route('When do I take my pill?');
      expect(q3.intent, equals(NirvanaIntent.nextReminder));

      // Hindi
      final q4 = router.route('मेरी अगली दवाई कब है?');
      expect(q4.intent, equals(NirvanaIntent.nextReminder));
      expect(q4.isMedicineSpecific, isTrue);

      // Bengali
      final q5 = router.route('আমার পরের ওষুধ কখন?');
      expect(q5.intent, equals(NirvanaIntent.nextReminder));
    });

    test('1B. REMINDERS: today reminders queries', () {
      final q1 = router.route('What reminders do I have today?');
      expect(q1.intent, equals(NirvanaIntent.todaysReminders));

      final q2 = router.route('Today\'s reminders');
      expect(q2.intent, equals(NirvanaIntent.todaysReminders));

      // Hindi
      final q3 = router.route('आज के रिमाइंडर दिखाओ');
      expect(q3.intent, equals(NirvanaIntent.todaysReminders));
    });

    test('2. DAILY ROUTINE: schedule and periods', () {
      final q1 = router.route('What do I have to do today?');
      expect(q1.intent, equals(NirvanaIntent.dailyRoutine));
      expect(q1.routinePeriod, equals(RoutinePeriod.allDay));

      final q2 = router.route('What am I doing this morning?');
      expect(q2.intent, equals(NirvanaIntent.dailyRoutine));
      expect(q2.routinePeriod, equals(RoutinePeriod.morning));

      final q3 = router.route('What is next?');
      expect(q3.intent, equals(NirvanaIntent.dailyRoutine));
      expect(q3.routinePeriod, equals(RoutinePeriod.nextUp));

      // Hindi
      final q4 = router.route('आज सुबह क्या करना है?');
      expect(q4.intent, equals(NirvanaIntent.dailyRoutine));
      expect(q4.routinePeriod, equals(RoutinePeriod.morning));
    });

    test('3. FAMILY: specific relatives and visitors', () {
      final q1 = router.route('Who is my daughter?');
      expect(q1.intent, equals(NirvanaIntent.familyInfo));
      expect(q1.specificRelation, equals('daughter'));

      final q2 = router.route('Who is my son?');
      expect(q2.intent, equals(NirvanaIntent.familyInfo));
      expect(q2.specificRelation, equals('son'));

      final q3 = router.route('Who is visiting me?');
      expect(q3.intent, equals(NirvanaIntent.familyInfo));
      expect(q3.specificRelation, equals('visitor'));

      final q4 = router.route('Show me my family');
      expect(q4.intent, equals(NirvanaIntent.familyInfo));
      expect(q4.specificRelation, isNull);

      // Hindi
      final q5 = router.route('मेरी बेटी कौन है?');
      expect(q5.intent, equals(NirvanaIntent.familyInfo));
      expect(q5.specificRelation, equals('daughter'));
    });

    test('4. MEMORIES: reminiscence queries', () {
      final q1 = router.route('Tell me about my memories.');
      expect(q1.intent, equals(NirvanaIntent.memories));

      final q2 = router.route('Show me my family memories.');
      expect(q2.intent, equals(NirvanaIntent.memories));

      // Hindi
      final q3 = router.route('मेरी पुरानी यादें बताओ');
      expect(q3.intent, equals(NirvanaIntent.memories));
    });

    test('5. GAMES: game requests and boredom', () {
      final q1 = router.route('I want to play a game.');
      expect(q1.intent, equals(NirvanaIntent.games));

      final q2 = router.route('What game should I play?');
      expect(q2.intent, equals(NirvanaIntent.games));

      final q3 = router.route('I\'m bored.');
      expect(q3.intent, equals(NirvanaIntent.games));

      // Hindi
      final q4 = router.route('मुझे कोई खेल खेलना है');
      expect(q4.intent, equals(NirvanaIntent.games));
    });

    test('6. ORIENTATION: day, date, and time queries', () {
      final q1 = router.route('What time is it?');
      expect(q1.intent, equals(NirvanaIntent.orientation));
      expect(q1.orientationTarget, equals(OrientationTarget.time));

      final q2 = router.route('What day is it?');
      expect(q2.intent, equals(NirvanaIntent.orientation));
      expect(q2.orientationTarget, equals(OrientationTarget.dayOfWeek));

      final q3 = router.route('What is today\'s date?');
      expect(q3.intent, equals(NirvanaIntent.orientation));
      expect(q3.orientationTarget, equals(OrientationTarget.date));

      // Hindi
      final q4 = router.route('अभी क्या समय हुआ है?');
      expect(q4.intent, equals(NirvanaIntent.orientation));
      expect(q4.orientationTarget, equals(OrientationTarget.time));

      final q5 = router.route('आज कौन सा दिन है?');
      expect(q5.intent, equals(NirvanaIntent.orientation));
      expect(q5.orientationTarget, equals(OrientationTarget.dayOfWeek));
    });

    test('7. ACTIVITY: daily accomplishments and history', () {
      final q1 = router.route('What did I do today?');
      expect(q1.intent, equals(NirvanaIntent.activity));

      final q2 = router.route('What have I done today?');
      expect(q2.intent, equals(NirvanaIntent.activity));

      // Hindi
      final q3 = router.route('आज मैंने क्या क्या किया?');
      expect(q3.intent, equals(NirvanaIntent.activity));
    });

    test('8. HELP: assistant capabilities and instructions', () {
      final q1 = router.route('What can you do?');
      expect(q1.intent, equals(NirvanaIntent.help));

      final q2 = router.route('Help me.');
      expect(q2.intent, equals(NirvanaIntent.help));

      // Hindi
      final q3 = router.route('आप क्या कर सकते हैं?');
      expect(q3.intent, equals(NirvanaIntent.help));
    });

    test('9. FALLBACK: unmapped questions', () {
      final q1 = router.route('What is the capital of France?');
      expect(q1.intent, equals(NirvanaIntent.fallback));

      final q2 = router.route('');
      expect(q2.intent, equals(NirvanaIntent.fallback));
    });
  });
}
