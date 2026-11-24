import 'dart:async';

import 'package:flutter/material.dart';

import '../data/stats_repo.dart';
import '../data/word_repo.dart';
import '../models/test_result.dart';
import '../models/word.dart';
import '../services/srs_service.dart';
import '../theme.dart';

class VocabTestScreen extends StatefulWidget {
  const VocabTestScreen({
    this.theme,
    this.labels = const {},
    this.markedOnly = false,
    super.key,
  });

  final String? theme;
  final Set<String> labels;
  final bool markedOnly;

  @override
  State<VocabTestScreen> createState() => _VocabTestScreenState();
}

class _VocabTestScreenState extends State<VocabTestScreen> {
  List<Word> _words = [];
  List<TextEditingController> _controllers = [];
  List<bool> _correctAnswers = [];
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  int _score = 0;

  int get _filledCount => _controllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _disposeControllers(_controllers);
    super.dispose();
  }

  Future<void> _loadWords() async {
    try {
      final words = await WordRepo.pickForTest(
        10,
        theme: widget.theme,
        labels: widget.labels,
        markedOnly: widget.markedOnly,
      );
      final controllers = List.generate(
        words.length,
        (_) => TextEditingController()..addListener(_onAnswerChanged),
      );
      if (!mounted) {
        _disposeControllers(controllers);
        return;
      }
      setState(() {
        _words = words;
        _controllers = controllers;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les mots : $error';
      });
    }
  }

  void _onAnswerChanged() {
    if (mounted && !_submitted) setState(() {});
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller
        ..removeListener(_onAnswerChanged)
        ..dispose();
    }
  }

  Future<void> _submit() async {
    if (_submitting || _submitted || _words.isEmpty) return;
    if (_filledCount != _words.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complète toutes les réponses avant de valider.'),
        ),
      );
      return;
    }

    final correctAnswers = List.generate(
      _words.length,
      (index) => _matchesAnswer(_controllers[index].text, _words[index].en),
    );
    final score = correctAnswers.where((correct) => correct).length;
    setState(() => _submitting = true);

    try {
      await SrsService.applyReviews([
        for (var index = 0; index < _words.length; index++)
          (_words[index], correctAnswers[index]),
      ]);
      await StatsRepo.addResult(
        TestResult(
          type: 'vocab',
          score: score,
          total: _words.length,
          date: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _correctAnswers = correctAnswers;
        _score = score;
        _submitted = true;
        _submitting = false;
      });
      _maybeOptimize();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’enregistrer le résultat : $error'),
        ),
      );
    }
  }

  bool _matchesAnswer(String input, String expected) {
    final normalizedInput = _normalize(input);
    final acceptedAnswers = expected
        .split(RegExp(r'[/,]'))
        .map(_normalize)
        .where((answer) => answer.isNotEmpty);
    return acceptedAnswers.contains(normalizedInput);
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'[.,;:!?]+$'), '')
      .trim()
      .replaceFirst(RegExp(r'^to\s+'), '');

  void _maybeOptimize() {
    unawaited(SrsService.maybeOptimize());
  }

  Future<void> _replay() async {
    _disposeControllers(_controllers);
    setState(() {
      _words = [];
      _controllers = [];
      _correctAnswers = [];
      _loading = true;
      _submitting = false;
      _submitted = false;
      _error = null;
      _score = 0;
    });
    await _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    final filledCount = _filledCount;
    final progress = _words.isEmpty ? 0.0 : filledCount / _words.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Test de vocabulaire')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_submitted) _buildResultHeader(),
            if (!_submitted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: AppTheme.border,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$filledCount/${_words.length} remplis',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildContent()),
            if (_words.isNotEmpty) _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Text(
            '$_score/${_words.length}',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: AppTheme.text, fontWeight: FontWeight.bold),
          ),
          Text('Résultat', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ),
      );
    }
    if (_words.isEmpty) {
      return Center(
        child: Text(
          'Aucun mot à tester pour le moment.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _words.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
      itemBuilder: (context, index) => _buildQuestion(index),
    );
  }

  Widget _buildQuestion(int index) {
    final word = _words[index];
    final isCorrect = _submitted && _correctAnswers[index];
    final color = isCorrect ? AppTheme.ok : AppTheme.error;

    return Container(
      key: ValueKey(word.id),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: _submitted
          ? BoxDecoration(
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.65)),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  word.fr,
                  style: const TextStyle(color: AppTheme.text, fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _controllers[index],
                  readOnly: _submitted,
                  maxLines: 1,
                  textInputAction: index == _words.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'En anglais',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                        color: _submitted ? color : AppTheme.border,
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (index < _controllers.length - 1) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
            ],
          ),
          if (_submitted && !isCorrect) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'Réponse : ${word.en}',
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Terminer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _replay,
                child: const Text('Rejouer'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading || _submitting || _words.isEmpty ? null : _submit,
          child: Text(_submitting ? 'Enregistrement…' : 'Valider'),
        ),
      ),
    );
  }
}
