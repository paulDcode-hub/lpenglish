import 'dart:async';

import 'package:flutter/material.dart';

import '../data/stats_repo.dart';
import '../models/test_result.dart';
import '../services/gemini_service.dart';
import '../services/srs_service.dart';
import '../theme.dart';

class GrammarTestScreen extends StatefulWidget {
  const GrammarTestScreen({super.key, this.theme});

  final String? theme;

  @override
  State<GrammarTestScreen> createState() => _GrammarTestScreenState();
}

class _GrammarTestScreenState extends State<GrammarTestScreen> {
  late Future<List<GrammarExercise>> _exercisesFuture;
  List<TextEditingController> _controllers = [];
  List<bool> _correctAnswers = [];
  bool _submitted = false;
  bool _submitting = false;
  int _score = 0;

  int get _filledCount => _controllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _loadExercises();
  }

  @override
  void dispose() {
    _disposeControllers(_controllers);
    super.dispose();
  }

  Future<List<GrammarExercise>> _loadExercises() async {
    final accuracyByTheme = await StatsRepo.accuracyByTheme();
    final weakThemes = accuracyByTheme.entries
        .where((entry) => entry.value < 70)
        .map((entry) => entry.key)
        .toList();
    final exercises = await GeminiService.generateGrammarExercises(
      theme: widget.theme,
      weakThemes: weakThemes,
    );

    if (mounted) {
      _disposeControllers(_controllers);
      _controllers = List.generate(
        exercises.length,
        (_) => TextEditingController()..addListener(_onAnswerChanged),
      );
    }
    return exercises;
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller
        ..removeListener(_onAnswerChanged)
        ..dispose();
    }
  }

  void _onAnswerChanged() {
    if (mounted && !_submitted) setState(() {});
  }

  String _normalize(String value) => value.trim().toLowerCase();

  bool _isCorrect(String input, GrammarExercise exercise) {
    final answer = _normalize(input);
    return answer == _normalize(exercise.answer) ||
        exercise.accepted.any((accepted) => answer == _normalize(accepted));
  }

  Future<void> _submit(List<GrammarExercise> exercises) async {
    if (_submitted || _submitting) return;
    if (_filledCount != exercises.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complète toutes les réponses avant de valider.'),
        ),
      );
      return;
    }

    final correctAnswers = List.generate(
      exercises.length,
      (index) => _isCorrect(_controllers[index].text, exercises[index]),
    );
    final score = correctAnswers.where((correct) => correct).length;
    final themeResults = <String, (int, int)>{};
    for (var index = 0; index < exercises.length; index++) {
      final exercise = exercises[index];
      final previous = themeResults[exercise.theme] ?? (0, 0);
      themeResults[exercise.theme] = (
        previous.$1 + (correctAnswers[index] ? 1 : 0),
        previous.$2 + 1,
      );
    }

    setState(() => _submitting = true);
    try {
      await StatsRepo.addResult(
        TestResult(
          type: 'grammar',
          score: score,
          total: exercises.length,
          theme: widget.theme,
          date: DateTime.now(),
        ),
      );
      await SrsService.applyThemeReviews(themeResults);
      if (!mounted) return;
      setState(() {
        _correctAnswers = correctAnswers;
        _score = score;
        _submitted = true;
        _submitting = false;
      });
      unawaited(SrsService.maybeOptimize());
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

  Future<void> _retry() async {
    _disposeControllers(_controllers);
    setState(() {
      _controllers = [];
      _correctAnswers = [];
      _submitted = false;
      _submitting = false;
      _score = 0;
      _exercisesFuture = _loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test de grammaire')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<GrammarExercise>>(
          future: _exercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Génération des exercices...'),
                  ],
                ),
              );
            }
            if (snapshot.hasError) return _buildError(snapshot.error!);
            final exercises = snapshot.data ?? const <GrammarExercise>[];
            if (exercises.isEmpty) {
              return _buildError(Exception('Aucun exercice reçu.'));
            }
            return _buildTest(exercises);
          },
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^Exception: '), '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _retry,
                  child: const Text('Réessayer'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTest(List<GrammarExercise> exercises) {
    final progress = exercises.isEmpty ? 0.0 : _filledCount / exercises.length;
    return Column(
      children: [
        if (_submitted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Text(
                  '$_score/10',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Résultat', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )
        else
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
                  '$_filledCount/${exercises.length} remplis',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: exercises.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
            itemBuilder: (context, index) =>
                _buildExercise(exercises[index], index),
          ),
        ),
        _buildBottomActions(exercises),
      ],
    );
  }

  Widget _buildExercise(GrammarExercise exercise, int index) {
    final isCorrect = _submitted && _correctAnswers[index];
    final color = isCorrect ? AppTheme.ok : AppTheme.error;
    final parts = exercise.sentence.split('___');
    final before = parts.first.trimRight();
    final after = parts.length > 1 ? parts.skip(1).join('___').trimLeft() : '';

    return Container(
      key: ValueKey(index),
      padding: const EdgeInsets.all(10),
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
            children: [
              Text(
                '${index + 1}.',
                style: const TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Text(
                  exercise.theme,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(before, style: const TextStyle(color: AppTheme.text)),
              const SizedBox(width: 6),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _controllers[index],
                  readOnly: _submitted,
                  maxLines: 1,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                        color: _submitted ? color : AppTheme.border,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(after, style: const TextStyle(color: AppTheme.text)),
            ],
          ),
          if (_submitted) ...[
            if (!isCorrect) ...[
              const SizedBox(height: 6),
              Text(
                'Réponse : ${exercise.answer}',
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              exercise.explanation,
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(List<GrammarExercise> exercises) {
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
            child: _submitted
                ? ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Nouveau test'),
                  )
                : ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(exercises),
                    child: Text(_submitting ? 'Enregistrement…' : 'Valider'),
                  ),
          ),
        ],
      ),
    );
  }
}
