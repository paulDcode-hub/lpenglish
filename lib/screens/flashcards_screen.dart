import 'package:flutter/material.dart';

import '../data/word_repo.dart';
import '../models/word.dart';
import '../services/srs_service.dart';
import '../theme.dart';
import '../widgets/word_pool_selector.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<String> _themes = [];
  List<String> _labels = [];
  Set<String> _selectedLabels = {};
  List<Word> _deck = [];
  String? _selectedTheme;
  bool _markedOnly = false;
  String? _error;
  int _availableCount = 0;
  int _currentIndex = 0;
  int _knownCount = 0;
  bool _englishFirst = true;
  bool _loadingThemes = true;
  bool _loadingDeck = false;
  bool _inSession = false;
  bool _revealed = false;
  bool _answering = false;
  int _selectionRequest = 0;

  bool get _sessionComplete => _inSession && _currentIndex >= _deck.length;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    final request = ++_selectionRequest;
    try {
      final themes = await WordRepo.themes();
      final labels = await WordRepo.labels();
      final selectedTheme =
          _selectedTheme != null && !themes.contains(_selectedTheme)
          ? null
          : _selectedTheme;
      final words = await WordRepo.all(
        theme: selectedTheme,
        labels: _selectedLabels,
        markedOnly: _markedOnly,
      );
      if (!mounted || request != _selectionRequest) return;
      setState(() {
        _themes = themes;
        _labels = labels;
        _selectedTheme = selectedTheme;
        _availableCount = words.length;
        _loadingThemes = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || request != _selectionRequest) return;
      setState(() {
        _loadingThemes = false;
        _error = 'Impossible de charger les mots : $error';
      });
    }
  }

  Future<void> _selectFilters({
    String? theme,
    bool updateTheme = false,
    Set<String>? labels,
    bool? markedOnly,
  }) async {
    final request = ++_selectionRequest;
    setState(() {
      if (updateTheme) _selectedTheme = theme;
      if (labels != null) _selectedLabels = labels;
      if (markedOnly != null) _markedOnly = markedOnly;
      _loadingThemes = true;
      _error = null;
    });
    try {
      final words = await WordRepo.all(
        theme: _selectedTheme,
        labels: _selectedLabels,
        markedOnly: _markedOnly,
      );
      if (!mounted || request != _selectionRequest) return;
      setState(() {
        _availableCount = words.length;
        _loadingThemes = false;
      });
    } catch (error) {
      if (!mounted || request != _selectionRequest) return;
      setState(() {
        _loadingThemes = false;
        _error = 'Impossible de charger les mots : $error';
      });
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _loadingDeck = true;
      _error = null;
    });
    try {
      final words = await WordRepo.all(
        theme: _selectedTheme,
        labels: _selectedLabels,
        markedOnly: _markedOnly,
      );
      if (!mounted) return;
      if (words.isEmpty) {
        setState(() {
          _loadingDeck = false;
          _error = 'Aucun mot ne correspond à ces filtres.';
        });
        return;
      }
      words.shuffle();
      setState(() {
        _deck = words;
        _currentIndex = 0;
        _knownCount = 0;
        _revealed = false;
        _answering = false;
        _inSession = true;
        _loadingDeck = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDeck = false;
        _error = 'Impossible de préparer le paquet : $error';
      });
    }
  }

  Future<void> _answerCurrent(bool known) async {
    if (_answering || !_revealed || _sessionComplete) return;
    setState(() => _answering = true);
    try {
      await SrsService.applyFlashcardReview(_deck[_currentIndex], known);
      if (!mounted) return;
      setState(() {
        if (known) _knownCount++;
        _currentIndex++;
        _revealed = false;
        _answering = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _answering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’enregistrer la révision : $error'),
        ),
      );
    }
  }

  void _leaveSession() {
    setState(() {
      _deck = [];
      _currentIndex = 0;
      _knownCount = 0;
      _inSession = false;
      _revealed = false;
      _answering = false;
    });
    _loadThemes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Révision de vocabulaire'),
        leading: _inSession
            ? IconButton(
                tooltip: 'Quitter la révision',
                onPressed: _answering ? null : _leaveSession,
                icon: const Icon(Icons.close),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: _inSession ? _buildSession() : _buildSetup(),
      ),
    );
  }

  Widget _buildSetup() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Préparer un paquet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            WordPoolSelector(
              themes: _themes,
              labels: _labels,
              selectedTheme: _selectedTheme,
              selectedLabels: _selectedLabels,
              markedOnly: _markedOnly,
              onThemeChanged: (theme) =>
                  _selectFilters(theme: theme, updateTheme: true),
              onLabelsChanged: (labels) => _selectFilters(labels: labels),
              onMarkedChanged: (markedOnly) =>
                  _selectFilters(markedOnly: markedOnly),
            ),
            const SizedBox(height: 20),
            Text(
              'Sens des cartes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('EN → FR')),
                ButtonSegment(value: false, label: Text('FR → EN')),
              ],
              selected: {_englishFirst},
              onSelectionChanged: (selection) {
                setState(() => _englishFirst = selection.first);
              },
            ),
            const SizedBox(height: 16),
            if (_loadingThemes)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.accent,
                backgroundColor: AppTheme.border,
              )
            else
              Text(
                '$_availableCount cartes dans ce paquet',
                style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _loadingThemes || _loadingDeck || _availableCount == 0
                    ? null
                    : _startSession,
                child: Text(
                  _loadingDeck ? 'Préparation…' : 'Commencer la révision',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildSession() {
    if (_sessionComplete) return _buildCompletion();

    final word = _deck[_currentIndex];
    final front = _englishFirst ? word.en : word.fr;
    final back = _englishFirst ? word.fr : word.en;
    final progress = _currentIndex / _deck.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.border,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_currentIndex + 1}/${_deck.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 230),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _englishFirst ? 'ANGLAIS' : 'FRANÇAIS',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        front,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (_revealed) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1, color: AppTheme.border),
                        ),
                        Text(
                          _englishFirst ? 'FRANÇAIS' : 'ANGLAIS',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          back,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _revealed
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _answering
                            ? null
                            : () => _answerCurrent(false),
                        child: const Text('À revoir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _answering
                            ? null
                            : () => _answerCurrent(true),
                        child: Text(
                          _answering ? 'Enregistrement…' : 'Je savais',
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _revealed = true),
                    child: const Text('Révéler la réponse'),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCompletion() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.ok,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              'Paquet terminé',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$_knownCount/${_deck.length} réponses connues',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startSession,
              child: const Text('Recommencer ce paquet'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _leaveSession,
              child: const Text('Changer de thème'),
            ),
          ],
        ),
      ),
    ),
  );
}
