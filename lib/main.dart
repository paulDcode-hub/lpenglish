import 'package:flutter/material.dart';

import 'data/database.dart';
import 'home_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance;
  runApp(const FlashcardsApp());
}

class FlashcardsApp extends StatelessWidget {
  const FlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcards EN',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}
