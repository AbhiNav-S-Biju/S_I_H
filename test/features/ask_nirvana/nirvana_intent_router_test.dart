// ==============================================================================
// NIRVANA - Ask NIRVANA Intent Router Unit Tests
// Description: Tests classification accuracy and normalization across all 18
// intents (Stories, Reminders, Routine, Date/Day/Time, Games, Family, Memories,
// Activity, Social, Help, and AI Fallback) in English, Hindi, and regional languages.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/ask_nirvana/ask_nirvana.dart';

void main() {
  const router = NirvanaIntentRouter();

  group('NirvanaIntentRouter - Normalization', () {
    test('Normalizes punctuation, contractions, and multiple spaces', () {
      expect(
        NirvanaIntentRouter.normalize("  What's   today's   date??? "),
        equals('what is todays date'),
      );
      expect(
        NirvanaIntentRouter.normalize("I'm bored!"),
        equals('i am bored'),
      );
      expect(
        NirvanaIntentRouter.normalize("Can't you tell me a story?"),
        equals('cannot you tell me a story'),
      );
    });
  });

  group('NirvanaIntentRouter - 18 Intents Classification', () {
    test('1. TELL_STORY: story queries and categories', () {
      final q1 = router.route('Tell me a story');
      expect(q1.intent, equals(NirvanaIntent.tellStory));

      final q2 = router.route('Can you tell me a story?');
      expect(q2.intent, equals(NirvanaIntent.tellStory));

      final q3 = router.route('I want to hear a story');
      expect(q3.intent, equals(NirvanaIntent.tellStory));

      final q4 = router.route('Read me a story');
      expect(q4.intent, equals(NirvanaIntent.tellStory));

      // Category extraction
      final q5 = router.route('Tell me a funny story');
      expect(q5.intent, equals(NirvanaIntent.tellStory));
      expect(q5.storyCategory, equals('funny'));

      final q6 = router.route('Tell me a family story');
      expect(q6.intent, equals(NirvanaIntent.tellStory));
      expect(q6.storyCategory, equals('family'));

      // Hindi
      final q7 = router.route('मुझे एक कहानी सुनाओ');
      expect(q7.intent, equals(NirvanaIntent.tellStory));

      // Bengali
      final q8 = router.route('আমাকে একটা গল্প বলো');
      expect(q8.intent, equals(NirvanaIntent.tellStory));

      // Assamese
      final q9 = router.route('মোক এটি সাধু কোৱা');
      expect(q9.intent, equals(NirvanaIntent.tellStory));
    });

    test('2. TELL_ANOTHER_STORY: context follow-up', () {
      final q1 = router.route('Another one');
      expect(q1.intent, equals(NirvanaIntent.tellAnotherStory));

      final q2 = router.route('Tell me another story');
      expect(q2.intent, equals(NirvanaIntent.tellAnotherStory));

      final q3 = router.route('One more');
      expect(q3.intent, equals(NirvanaIntent.tellAnotherStory));

      // Hindi
      final q4 = router.route('एक और कहानी सुनाओ');
      expect(q4.intent, equals(NirvanaIntent.tellAnotherStory));
    });

    test('3. GET_NEXT_REMINDER: next reminder and medicine queries', () {
      final q1 = router.route('When is my medicine?');
      expect(q1.intent, equals(NirvanaIntent.getNextReminder));
      expect(q1.isMedicineSpecific, isTrue);

      final q2 = router.route('What is my next reminder?');
      expect(q2.intent, equals(NirvanaIntent.getNextReminder));

      final q3 = router.route('When do I take my pill?');
      expect(q3.intent, equals(NirvanaIntent.getNextReminder));

      // Hindi
      final q4 = router.route('मेरी अगली दवाई कब है?');
      expect(q4.intent, equals(NirvanaIntent.getNextReminder));
      expect(q4.isMedicineSpecific, isTrue);
    });

    test('4. GET_TODAYS_REMINDERS: today reminders queries', () {
      final q1 = router.route('What reminders do I have today?');
      expect(q1.intent, equals(NirvanaIntent.getTodaysReminders));

      final q2 = router.route('Today\'s reminders');
      expect(q2.intent, equals(NirvanaIntent.getTodaysReminders));

      // Hindi
      final q3 = router.route('आज के रिमाइंडर दिखाओ');
      expect(q3.intent, equals(NirvanaIntent.getTodaysReminders));
    });

    test('5. GET_DAILY_ROUTINE: schedule and periods', () {
      final q1 = router.route('What do I have to do today?');
      expect(q1.intent, equals(NirvanaIntent.getDailyRoutine));
      expect(q1.routinePeriod, equals(RoutinePeriod.allDay));

      final q2 = router.route('What am I doing this morning?');
      expect(q2.intent, equals(NirvanaIntent.getDailyRoutine));
      expect(q2.routinePeriod, equals(RoutinePeriod.morning));

      final q3 = router.route('What is next?');
      expect(q3.intent, equals(NirvanaIntent.getDailyRoutine));
      expect(q3.routinePeriod, equals(RoutinePeriod.nextUp));

      final q4 = router.route('What is my routine?');
      expect(q4.intent, equals(NirvanaIntent.getDailyRoutine));
    });

    test('6. GET_TIME: clock queries', () {
      final q1 = router.route('What time is it?');
      expect(q1.intent, equals(NirvanaIntent.getTime));

      final q2 = router.route('What is the time?');
      expect(q2.intent, equals(NirvanaIntent.getTime));

      // Hindi
      final q3 = router.route('समय क्या हुआ है?');
      expect(q3.intent, equals(NirvanaIntent.getTime));
    });

    test('7. GET_DAY: day of the week', () {
      final q1 = router.route('What day is today?');
      expect(q1.intent, equals(NirvanaIntent.getDay));

      final q2 = router.route('What day is it?');
      expect(q2.intent, equals(NirvanaIntent.getDay));

      // Hindi
      final q3 = router.route('आज कौन सा दिन है?');
      expect(q3.intent, equals(NirvanaIntent.getDay));
    });

    test('8. GET_DATE: calendar date queries', () {
      final q1 = router.route('What is today\'s date?');
      expect(q1.intent, equals(NirvanaIntent.getDate));

      final q2 = router.route('What date is it?');
      expect(q2.intent, equals(NirvanaIntent.getDate));

      // Hindi
      final q3 = router.route('आज की तारीख क्या है?');
      expect(q3.intent, equals(NirvanaIntent.getDate));
    });

    test('9. START_GAME: start playing', () {
      final q1 = router.route('I want to play a game');
      expect(q1.intent, equals(NirvanaIntent.startGame));

      final q2 = router.route('Let\'s play a game');
      expect(q2.intent, equals(NirvanaIntent.startGame));
    });

    test('10. RECOMMEND_GAME & Boredom', () {
      final q1 = router.route('I\'m bored');
      expect(q1.intent, equals(NirvanaIntent.recommendGame));
      expect(q1.isBoredQuery, isTrue);

      final q2 = router.route('Recommend a game');
      expect(q2.intent, equals(NirvanaIntent.recommendGame));
      expect(q2.isBoredQuery, isFalse);
    });

    test('11. FAMILY_QUERY: relatives and visitors', () {
      final q1 = router.route('Who is my daughter?');
      expect(q1.intent, equals(NirvanaIntent.familyQuery));
      expect(q1.specificRelation, equals('daughter'));

      final q2 = router.route('Who is my son?');
      expect(q2.intent, equals(NirvanaIntent.familyQuery));
      expect(q2.specificRelation, equals('son'));

      final q3 = router.route('Show my family');
      expect(q3.intent, equals(NirvanaIntent.familyQuery));
    });

    test('12. MEMORY_QUERY: reminiscence queries', () {
      final q1 = router.route('Show my memories');
      expect(q1.intent, equals(NirvanaIntent.memoryQuery));

      final q2 = router.route('Tell me about my memories');
      expect(q2.intent, equals(NirvanaIntent.memoryQuery));
    });

    test('13. GET_TODAYS_ACTIVITY: activity queries', () {
      final q1 = router.route('What did I do today?');
      expect(q1.intent, equals(NirvanaIntent.getTodaysActivity));

      final q2 = router.route('My activity today');
      expect(q2.intent, equals(NirvanaIntent.getTodaysActivity));
    });

    test('14. GREETING', () {
      expect(router.route('Hello').intent, equals(NirvanaIntent.greeting));
      expect(router.route('Good morning').intent, equals(NirvanaIntent.greeting));
      expect(router.route('नमस्ते').intent, equals(NirvanaIntent.greeting));
    });

    test('15. GRATITUDE', () {
      expect(router.route('Thank you').intent, equals(NirvanaIntent.gratitude));
      expect(router.route('Thanks a lot').intent, equals(NirvanaIntent.gratitude));
      expect(router.route('धन्यवाद').intent, equals(NirvanaIntent.gratitude));
    });

    test('16. GOODBYE', () {
      expect(router.route('Goodbye').intent, equals(NirvanaIntent.goodbye));
      expect(router.route('Bye bye').intent, equals(NirvanaIntent.goodbye));
      expect(router.route('अलविदा').intent, equals(NirvanaIntent.goodbye));
    });

    test('17. HELP', () {
      expect(router.route('What can you do?').intent, equals(NirvanaIntent.help));
      expect(router.route('Help me').intent, equals(NirvanaIntent.help));
    });

    test('18. GENERAL_CONVERSATION: AI Fallback', () {
      expect(
        router.route('Why is the sky blue?').intent,
        equals(NirvanaIntent.generalConversation),
      );
      expect(
        router.route('How far is the moon?').intent,
        equals(NirvanaIntent.generalConversation),
      );
    });
  });
}
