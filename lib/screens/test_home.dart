import 'package:flutter/material.dart';

import '../data/rule_repo.dart';
import '../data/word_repo.dart';
import '../theme.dart';
import '../widgets/word_pool_selector.dart';
import 'grammar_test_screen.dart';
import 'vocab_test_screen.dart';

class TestHome extends StatefulWidget {
  const TestHome({super.key});

  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  static const _allThemes = '__all_themes__';

  late final Future<List<String>> _themesFuture;
  List<String> _wordThemes = [];
  List<String> _labels = [];
  String? _selectedWordTheme;
  Set<String> _selectedLabels = {};
  bool _markedOnly = false;
  bool _loadingWordFilters = true;
  int? _selectedWordCount;
  int _wordCountRequest = 0;
  int _wordFiltersRequest = 0;
  String? _filterError;
  String _selectedGrammarTheme = _allThemes;

  @override
  void initState() {
    super.initState();
    _themesFuture = RuleRepo.themes();
    _loadWordFilters();
  }

  Future<void> _loadWordFilters() async {
    final request = ++_wordFiltersRequest;
    try {
      final themes = await WordRepo.themes();
      final labels = await WordRepo.labels();
      if (!mounted || request != _wordFiltersRequest) return;
      setState(() {
        _wordThemes = themes;
        _labels = labels;
        if (_selectedWordTheme != null &&
            !themes.contains(_selectedWordTheme)) {
          _selectedWordTheme = null;
        }
        _selectedLabels = _selectedLabels.intersection(labels.toSet());
        _loadingWordFilters = false;
      });
      await _refreshSelectedWordCount();
    } catch (error) {
      if (!mounted || request != _wordFiltersRequest) return;
      setState(() {
        _loadingWordFilters = false;
        _filterError = 'Impossible de charger les filtres : $error';
      });
    }
  }

  Future<void> _refreshSelectedWordCount() async {
    final request = ++_wordCountRequest;
    try {
      final words = await WordRepo.all(
        theme: _selectedWordTheme,
        labels: _selectedLabels,
        markedOnly: _markedOnly,
      );
      if (!mounted || request != _wordCountRequest) return;
      setState(() => _selectedWordCount = words.length);
    } catch (error) {
      if (!mounted || request != _wordCountRequest) return;
      setState(() => _filterError = 'Impossible de charger les mots : $error');
    }
  }

  void _updateWordFilters({
    String? theme,
    bool updateTheme = false,
    Set<String>? labels,
    bool? markedOnly,
  }) {
    setState(() {
      if (updateTheme) _selectedWordTheme = theme;
      if (labels != null) _selectedLabels = labels;
      if (markedOnly != null) _markedOnly = markedOnly;
      _selectedWordCount = null;
      _filterError = null;
    });
    _refreshSelectedWordCount();
  }

  Future<void> _openVocabularyTest() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => VocabTestScreen(
          theme: _selectedWordTheme,
          labels: _selectedLabels,
          markedOnly: _markedOnly,
        ),
      ),
    );
    if (mounted) await _loadWordFilters();
  }

  Future<void> _openGrammarTest() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => GrammarTestScreen(
          theme: _selectedGrammarTheme == _allThemes
              ? null
              : _selectedGrammarTheme,
        ),
      ),
    );
    if (mounted) await _loadWordFilters();
  }

  @override
  Widget build(BuildContext context) {
    final vocabDescription = _loadingWordFilters
        ? 'Chargement des thèmes et labels…'
        : '${_selectedWordCount ?? 0} mots disponibles · jusqu’à 10 par test';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choisir un test',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _TestButton(
                    icon: Icons.style,
                    title: 'Test de vocabulaire',
                    subtitle: vocabDescription,
                    onPressed: _loadingWordFilters ||
                            (_selectedWordCount ?? 0) == 0
                        ? null
                        : _openVocabularyTest,
                  ),
                  const SizedBox(height: 16),
                  if (_loadingWordFilters)
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.border,
                    )
                  else
                    WordPoolSelector(
                      themes: _wordThemes,
                      labels: _labels,
                      selectedTheme: _selectedWordTheme,
                      selectedLabels: _selectedLabels,
                      markedOnly: _markedOnly,
                      onThemeChanged: (theme) => _updateWordFilters(
                        theme: theme,
                        updateTheme: true,
                      ),
                      onLabelsChanged: (labels) =>
                          _updateWordFilters(labels: labels),
                      onMarkedChanged: (markedOnly) =>
                          _updateWordFilters(markedOnly: markedOnly),
                    ),
                  if (_filterError != null)
                    Text(
                      _filterError!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  const SizedBox(height: 16),
                  _buildThemeSelector(),
                  const SizedBox(height: 8),
                  _TestButton(
                    icon: Icons.edit,
                    title: 'Test de grammaire',
                    subtitle: '10 exercices générés par Gemini',
                    onPressed: _openGrammarTest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return FutureBuilder<List<String>>(
      future: _themesFuture,
      builder: (context, snapshot) {
        final themes = snapshot.data ?? const <String>[];
        final selectedTheme = themes.contains(_selectedGrammarTheme)
            ? _selectedGrammarTheme
            : _allThemes;

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: Border.all(color: AppTheme.border),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTheme,
                isExpanded: true,
                dropdownColor: AppTheme.card,
                iconEnabledColor: AppTheme.muted,
                style: const TextStyle(color: AppTheme.text, fontSize: 14),
                items: [
                  const DropdownMenuItem(
                    value: _allThemes,
                    child: Text('Thème : Tous'),
                  ),
                  ...themes.map(
                    (theme) => DropdownMenuItem(
                      value: theme,
                      child: Text(
                        'Thème : $theme',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged:
                    snapshot.connectionState == ConnectionState.done &&
                        !snapshot.hasError
                    ? (theme) {
                        if (theme != null) {
                          setState(() => _selectedGrammarTheme = theme);
                        }
                      }
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.card,
        foregroundColor: AppTheme.text,
        side: const BorderSide(color: AppTheme.border, width: 1),
        minimumSize: const Size.fromHeight(92),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.muted),
        ],
      ),
    );
  }
}
