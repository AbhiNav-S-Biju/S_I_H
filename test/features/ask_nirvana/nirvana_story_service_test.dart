// ==============================================================================
// NIRVANA - Story Service Unit Tests
// Description: Tests offline story retrieval, category filtering, language
// fallback, and story rotation ("another one").
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/ask_nirvana/ask_nirvana.dart';

void main() {
  late NirvanaStoryService storyService;

  setUp(() {
    storyService = NirvanaStoryService();
  });

  group('NirvanaStoryService Tests', () {
    test('Returns an English story by default', () {
      final story = storyService.getStory(languageCode: 'en');

      expect(story.language, equals('en'));
      expect(story.title, isNotEmpty);
      expect(story.content, isNotEmpty);
    });

    test('Returns Hindi story when requested', () {
      final story = storyService.getStory(languageCode: 'hi');

      expect(story.language, equals('hi'));
      expect(story.title, isNotEmpty);
      expect(story.content, isNotEmpty);
    });

    test('Returns Bengali story when requested', () {
      final story = storyService.getStory(languageCode: 'bn');

      expect(story.language, equals('bn'));
      expect(story.title, isNotEmpty);
      expect(story.content, isNotEmpty);
    });

    test('Filters by category (e.g., funny / humor)', () {
      final story = storyService.getStory(
        languageCode: 'en',
        category: 'funny',
      );

      expect(story.category, equals('funny'));
      expect(story.title, equals('The Mischievous Kitten'));
    });

    test('Filters by category (e.g., family)', () {
      final story = storyService.getStory(
        languageCode: 'en',
        category: 'family',
      );

      expect(story.category, equals('family'));
      expect(story.title, equals('The Sweet Cup of Tea'));
    });

    test('Rotates and avoids repeating the last story when isAnother is true', () {
      final story1 = storyService.getStory(languageCode: 'en');
      final story2 = storyService.getStory(
        languageCode: 'en',
        isAnother: true,
      );

      expect(story1.id, isNot(equals(story2.id)));
    });

    test('Formats story with gentle intro', () {
      final story = storyService.getStory(languageCode: 'en');
      final formatted = storyService.formatStoryResponse(story, 'en');

      expect(formatted, startsWith('Of course. Here is a short story for you:'));
      expect(formatted, contains(story.title));
      expect(formatted, contains(story.content));
    });
  });
}
