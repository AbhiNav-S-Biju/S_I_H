// ==============================================================================
// NIRVANA - Local Dementia-Friendly Story Library
// Description: Offline story library providing calm, short, comforting, and
// simple stories tailored for older adults across multiple supported languages.
// ==============================================================================

import 'package:flutter/foundation.dart';

@immutable
class NirvanaStory {
  final String id;
  final String title;
  final String language;
  final String content;
  final String category; // 'nature', 'family', 'funny', 'calm', 'morning'

  const NirvanaStory({
    required this.id,
    required this.title,
    required this.language,
    required this.content,
    required this.category,
  });
}

/// Curated offline story collection
class NirvanaStoryLibrary {
  static const List<NirvanaStory> stories = [
    // ---------------------------------------------------------------------------
    // ENGLISH STORIES (en)
    // ---------------------------------------------------------------------------
    NirvanaStory(
      id: 'en_story_1',
      title: 'The Morning Sparrow',
      language: 'en',
      category: 'nature',
      content:
          'Every morning, a little brown sparrow visits the garden fence. It perches softly on the wooden post, greeting the golden sunrise with a cheerful song. When the garden flowers sway in the cool breeze, the sparrow flutters its wings and rests peacefully in the warm morning light.',
    ),
    NirvanaStory(
      id: 'en_story_2',
      title: 'The Sweet Cup of Tea',
      language: 'en',
      category: 'family',
      content:
          'In a quiet kitchen, grandfather liked to brew cardamom tea in his favorite clay teapot. The aroma of warm cinnamon and fresh milk filled the entire house. As the family gathered by the window, they shared stories of past picnics, laughing together as the gentle steam rose from their cups.',
    ),
    NirvanaStory(
      id: 'en_story_3',
      title: 'The Mischievous Kitten',
      language: 'en',
      category: 'funny',
      content:
          'Grandma was knitting a cozy blue woolen blanket when a playful kitten spotted the ball of yarn. With a sudden playful pounce, the kitten rolled the yarn across the living room rug. Grandma could not help but chuckle as the little cat proudly curled up inside the blue yarn circle.',
    ),
    NirvanaStory(
      id: 'en_story_4',
      title: 'The River by the Village',
      language: 'en',
      category: 'calm',
      content:
          'A quiet, clear river flows gently past the green hills of the village. Smooth round pebbles shine under the gentle afternoon sun. The gentle sound of flowing water brings peace to everyone who sits on the wooden bench under the big banyan tree.',
    ),
    NirvanaStory(
      id: 'en_story_5',
      title: 'The Garden Rose',
      language: 'en',
      category: 'morning',
      content:
          'A delicate pink rose opened its petals as the morning dew sparkled like tiny crystals. A gentle butterfly with orange wings fluttered by and paused to rest. The whole garden was peaceful and still, welcoming another bright and sunny day.',
    ),

    // ---------------------------------------------------------------------------
    // HINDI STORIES (hi)
    // ---------------------------------------------------------------------------
    NirvanaStory(
      id: 'hi_story_1',
      title: 'सुबह की गौरैया',
      language: 'hi',
      category: 'nature',
      content:
          'हर सुबह एक छोटी सी भूरी गौरैया बगीचे की मुंडेर पर आकर बैठती है। वह सुबह की सुनहरी धूप में अपनी मीठी आवाज़ में चहकती है। जब ठंडी हवा में फूल झूमते हैं, तो वह अपने पंख फैलाकर खिड़की पर आराम से बैठ जाती है।',
    ),
    NirvanaStory(
      id: 'hi_story_2',
      title: 'गरमा-गरम चाय की महक',
      language: 'hi',
      category: 'family',
      content:
          'एक शांत सुबह दादाजी ने इलायची वाली चाय बनाई। पूरे घर में ताज़ी चाय और दूध की भीनी-भीनी खुशबू फैल गई। सभी लोग खिड़की के पास बैठे और पुरानी पिकनिक की बातें याद करके मुस्कुराने लगे।',
    ),
    NirvanaStory(
      id: 'hi_story_3',
      title: 'नटखट बिल्ली का बच्चा',
      language: 'hi',
      category: 'funny',
      content:
          'दादी माँ नीले ऊन से स्वेटर बुन रही थीं। तभी एक छोटे बिल्ली के बच्चे ने ऊन के गोले पर झपट्टा मारा और उसे पूरे कमरे में लुढ़का दिया। दादी माँ उसकी यह नटखट शरारत देखकर हंस पड़ीं।',
    ),
    NirvanaStory(
      id: 'hi_story_4',
      title: 'गाँव की शांत नदी',
      language: 'hi',
      category: 'calm',
      content:
          'गाँव के पास से एक शांत नदी धीरे-धीरे बहती है। पानी की कल-कल आवाज़ मन को बहुत शांति देती है। किनारे पर लगे बड़े बरगद के पेड़ के नीचे बैठकर ठंडी हवा का आनंद लेना सबको बहुत भाता है।',
    ),

    // ---------------------------------------------------------------------------
    // BENGALI STORIES (bn)
    // ---------------------------------------------------------------------------
    NirvanaStory(
      id: 'bn_story_1',
      title: 'সকালের চড়ুই পাখি',
      language: 'bn',
      category: 'nature',
      content:
          'প্রতিদিন সকালে একটি ছোট্ট চড়ুই পাখি বারান্দার রেলিংয়ে এসে বসে। মিষ্টি রোদে সে সুন্দর গান গায়। বাগানের ফুলগুলো যখন বাতাসে দোলে, পাখিটি ডানা মেলে শান্তিতে বসে থাকে।',
    ),
    NirvanaStory(
      id: 'bn_story_2',
      title: 'এক কাপ গরম চা',
      language: 'bn',
      category: 'family',
      content:
          'দাদু সকালে মাটির কাপে এলাচ দেওয়া চা বানাতেন। চায়ের সুগন্ধে ঘর ভরে যেত। সবাই একসঙ্গে বসে পুরোনো দিনের মিষ্টি স্মৃতি মনে করে গল্প করত আর হাসত।',
    ),
    NirvanaStory(
      id: 'bn_story_3',
      title: 'দুষ্টু বিড়ালছানা',
      language: 'bn',
      category: 'funny',
      content:
          'দিদিমা নীল রঙের উল দিয়ে সোয়েটার বুনছিলেন। একটা ছোট বিড়ালছানা উলের বল দেখে দৌড়ে এসে তা মেঝেতে গড়িয়ে দিল। তার কান্ড দেখে দিদিমা হেসে উঠলেন।',
    ),

    // ---------------------------------------------------------------------------
    // ASSAMESE STORIES (as)
    // ---------------------------------------------------------------------------
    NirvanaStory(
      id: 'as_story_1',
      title: 'পুৱাৰ ঘৰচিৰিকা',
      language: 'as',
      category: 'nature',
      content:
          'প্ৰতিদিনে ৰাতিপুৱা এজনী সৰু ঘৰচিৰিকা ফুলনিৰ জেওৰাত আহি বহে। ৰাতিপুৱাৰ কোমল ৰ’দত তাই সুন্দৰকৈ গান গায়। ফুলবোৰ বতাহত হালি-জালি থকা সময়ত তাই শান্তভাৱে জিৰণি লয়।',
    ),
    NirvanaStory(
      id: 'as_story_2',
      title: 'একাঁহী গৰম চাহ',
      language: 'as',
      category: 'family',
      content:
          'ককাদেউতাই পুৱা সুগন্ধি ইলাচী চাহ তৈয়াৰ কৰিছিল। ঘৰখনত চাহৰ সুবাস বিয়পি পৰিল। সকলোৱে একেলগে বহি পুৰণি সুখৰ দিনবোৰ সোঁৱৰি আনন্দ কৰিলে।',
    ),

    // ---------------------------------------------------------------------------
    // NEPALI STORIES (ne)
    // ---------------------------------------------------------------------------
    NirvanaStory(
      id: 'ne_story_1',
      title: 'बिहानीको भँगेरा',
      language: 'ne',
      category: 'nature',
      content:
          'हरेक बिहान एउटा सानो भँगेरा बगैंचाको बारमा आएर बस्छ। बिहानीको पारिलो घाममा उसले मिठो गीत गाउँछ। शीतल हावा चल्दा भँगेरा आनन्दले पखेटा फिँजाएर बस्छ।',
    ),
    NirvanaStory(
      id: 'ne_story_2',
      title: 'तातो चियाको कप',
      language: 'ne',
      category: 'family',
      content:
          'हजुरबुबाले बिहान सुगन्धित अलैंची चिया बनाउनुभयो। घरभरि मिठो बास्ना फैलियो। परिवारका सबैजना सँगै बसेर पुराना रमाइला क्षणहरू सम्झँदै मुस्कुराए।',
    ),
  ];
}
