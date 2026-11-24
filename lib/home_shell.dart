import 'package:flutter/material.dart';

import 'screens/flashcards_screen.dart';
import 'screens/grammar_tab.dart';
import 'screens/stats_screen.dart';
import 'screens/test_home.dart';
import 'screens/vocab_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  Key _statsKey = UniqueKey();

  void _selectTab(int index) {
    if (index == 3 && _selectedIndex != 3) {
      _statsKey = UniqueKey();
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const _CardsScreen(),
          const TestHome(),
          const FlashcardsScreen(),
          StatsScreen(key: _statsKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Cartes'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.flip), label: 'Réviser'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

class _CardsScreen extends StatelessWidget {
  const _CardsScreen();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: TabBar(
              tabs: [
                Tab(text: 'Vocabulaire'),
                Tab(text: 'Grammaire'),
              ],
            ),
          ),
          Expanded(child: TabBarView(children: [VocabTab(), GrammarTab()])),
        ],
      ),
    );
  }
}
