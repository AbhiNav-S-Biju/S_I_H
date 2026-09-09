// ==============================================================================
// NIRVANA - Local Offline Story Service
// Description: Statefully serves dementia-friendly stories in the user's language,
// handling categories ("family", "funny", "nature", "calm") and rotation for
// "another one" / "tell me another story" requests completely offline.
// ==============================================================================

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/nirvana_story.dart';

class NirvanaStoryService {
  String? _lastStoryId;
  final Random _random = Random();

  NirvanaStoryService();

  /// Gets a story in the given language, optionally matching a category and avoiding the last story
  NirvanaStory getStory({
    required String languageCode,
    String? category,
    bool isAnother = false,
  }) {
    // 1. Filter stories for the requested language (fallback to 'en' if none exist)
    var available = NirvanaStoryLibrary.stories
        .where((s) => s.language == languageCode)
        .toList();

    if (available.isEmpty) {
      available = NirvanaStoryLibrary.stories
          .where((s) => s.language == 'en')
          .toList();
    }

    // 2. Filter by category if requested
    if (category != null && category.isNotEmpty) {
      final catMatches = available
          .where(
            (s) => s.category.toLowerCase().contains(category.toLowerCase()),
          )
          .toList();
      if (catMatches.isNotEmpty) {
        available = catMatches;
      }
    }

    // 3. If requesting "another one" or rotating, avoid the last shown story
    if (available.length > 1 && _lastStoryId != null) {
      final distinct = available.where((s) => s.id != _lastStoryId).toList();
      if (distinct.isNotEmpty) {
        available = distinct;
      }
    }

    final selected = available[_random.nextInt(available.length)];
    _lastStoryId = selected.id;
    return selected;
  }

  /// Formats the story with a comforting intro in the active language
  String formatStoryResponse(NirvanaStory story, String languageCode) {
    const intros = {
      'en': "Of course. Here is a short story for you:\n\n",
      'hi': "ज़रूर! यह रही आपके लिए एक छोटी सी कहानी:\n\n",
      'bn': "অবশ্যই! আপনার জন্য একটি ছোট গল্প:\n\n",
      'as': "নিশ্চয়! আপোনাৰ বাবে এটি চুটি কাহিনী:\n\n",
      'ne': "अवश्य! तपाईंको लागि एउटा छोटो कथा:\n\n",
    };

    final intro = intros[languageCode] ?? intros['en']!;
    return '$intro${story.title}\n\n${story.content}';
  }

  /// Reset history for tests
  void reset() {
    _lastStoryId = null;
  }
}

final nirvanaStoryServiceProvider = Provider<NirvanaStoryService>((ref) {
  return NirvanaStoryService();
});
