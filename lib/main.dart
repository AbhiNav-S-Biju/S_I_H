import 'package:flutter/material.dart';
import 'features/games/games.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NirvanaApp());
}

class NirvanaApp extends StatelessWidget {
  const NirvanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIRVANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      home: GamesHubScreen(
        onSessionCompleted: (GameSession session) {
          debugPrint('Game Session Completed: $session');
        },
      ),
    );
  }
}
