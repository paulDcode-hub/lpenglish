import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stats_repo.dart';
import '../data/word_repo.dart';
import '../models/test_result.dart';
import '../models/vocabulary_stats.dart';
import '../services/srs_service.dart';
import '../theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<_StatsData> _dataFuture;
  bool _optimizing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_StatsData> _loadData() async {
    final vocabularyAverage = await StatsRepo.averageScore(type: 'vocab');
    final grammarAverage = await StatsRepo.averageScore(type: 'grammar');
    final streak = await StatsRepo.streakDays();
    final mastered = await WordRepo.countMastered();
    final totalWords = await WordRepo.countAll();
    final dueWords = await WordRepo.countDue();
    final results = await StatsRepo.results(limit: 20);
    final accuracyByTheme = await StatsRepo.accuracyByTheme();
    final recentResults = await StatsRepo.results(limit: 10);
    final vocabularyStats = await StatsRepo.vocabularyStats();
    final flashcardPerformance = await StatsRepo.flashcardPerformance(
      limit: 10,
    );

    return _StatsData(
      vocabularyAverage: vocabularyAverage,
      grammarAverage: grammarAverage,
      streak: streak,
      mastered: mastered,
      totalWords: totalWords,
      dueWords: dueWords,
      chartResults: results,
      accuracyByTheme: accuracyByTheme,
      recentResults: recentResults,
      vocabularyStats: vocabularyStats,
      flashcardPerformance: flashcardPerformance,
    );
  }

  Future<void> _refresh() async {
    final future = _loadData();
    setState(() => _dataFuture = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder présente l’erreur dans la page.
    }
  }

  Future<void> _optimize() async {
    if (_optimizing) return;
    setState(() => _optimizing = true);
    try {
      final comment = await SrsService.maybeOptimize(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            comment?.trim().isNotEmpty == true ? comment! : 'Aucun commentaire reçu. Vérifiez la connexion et la clé Gemini.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Optimisation impossible : $error')),
      );
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Statistiques')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        child: FutureBuilder<_StatsData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _scrollableMessage(
                const CircularProgressIndicator(color: AppTheme.accent),
              );
            }
            if (snapshot.hasError) {
              return _scrollableMessage(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Impossible de charger les statistiques.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return _scrollableMessage(
                const Text('Aucune statistique disponible.'),
              );
            }
            return _buildDashboard(data);
          },
        ),
      ),
    );
  }

  Widget _scrollableMessage(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ],
  );

  Widget _buildDashboard(_StatsData data) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [
      _buildKeyMetrics(data),
      _sectionDivider(),
      _buildVocabularyLearning(data.vocabularyStats),
      _sectionDivider(),
      _buildFlashcardPerformance(data.flashcardPerformance),
      _sectionDivider(),
      _buildHistory(data.chartResults),
      _sectionDivider(),
      _buildThemeAccuracy(data.accuracyByTheme),
      _sectionDivider(),
      _buildRecentTests(data.recentResults),
      _sectionDivider(),
      _buildOptimizationButton(),
    ],
  );

  Widget _buildKeyMetrics(_StatsData data) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _metric('Vocabulaire', _percent(data.vocabularyAverage)),
          ),
          Expanded(child: _metric('Grammaire', _percent(data.grammarAverage))),
          Expanded(child: _metric('Série', '${data.streak} j')),
          Expanded(
            child: _metric('Maîtrisés', '${data.mastered}/${data.totalWords}'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'À revoir aujourd’hui : ${data.dueWords}',
        style: const TextStyle(color: AppTheme.muted, fontSize: 14),
      ),
    ],
  );

  Widget _metric(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.muted, fontSize: 11),
        ),
      ],
    ),
  );

  String _percent(double value) => '${value.round()}%';

  Widget _buildVocabularyLearning(VocabularyStats stats) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Apprentissage du vocabulaire'),
      Row(
        children: [
          Expanded(
            child: _metric('Points flashcards', '${stats.flashcardXp} XP'),
          ),
          Expanded(child: _metric('Précision', _percent(stats.accuracy))),
          Expanded(
            child: _metric(
              'Cartes révisées',
              '${stats.reviewedWordCount}/${stats.totalWordCount}',
            ),
          ),
          Expanded(child: _metric('Réponses', '${stats.reviewCount}')),
        ],
      ),
    ],
  );

  Widget _buildFlashcardPerformance(List<FlashcardPerformance> cards) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Précision par flashcard'),
      if (cards.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Pas encore de révisions de vocabulaire',
            style: TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
        )
      else
        ...cards.map((card) {
          final accuracy = card.accuracy.clamp(0, 100).toDouble();
          final color = accuracy < 60 ? AppTheme.error : AppTheme.accent;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${card.en} · ${card.fr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${accuracy.round()}%  ${card.correctCount}/${card.reviewCount}',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: accuracy / 100,
                    minHeight: 4,
                    color: color,
                    backgroundColor: AppTheme.border,
                  ),
                ),
              ],
            ),
          );
        }),
    ],
  );

  Widget _buildHistory(List<TestResult> results) {
    final chronological = results.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Évolution'),
        if (chronological.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Pas encore de données',
                style: TextStyle(color: AppTheme.muted),
              ),
            ),
          )
        else ...[
          SizedBox(height: 220, child: _buildLineChart(chronological)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Vocabulaire', AppTheme.accent),
              const SizedBox(width: 20),
              _legendItem('Grammaire', AppTheme.muted),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLineChart(List<TestResult> results) {
    final vocabularySpots = <FlSpot>[];
    final grammarSpots = <FlSpot>[];
    for (var index = 0; index < results.length; index++) {
      final result = results[index];
      if (result.total <= 0) continue;
      final spot = FlSpot(index.toDouble(), result.score * 100 / result.total);
      if (result.type == 'vocab') vocabularySpots.add(spot);
      if (result.type == 'grammar') grammarSpots.add(spot);
    }

    final maxX = results.length > 1 ? (results.length - 1).toDouble() : 1.0;
    final xInterval = results.length > 4
        ? (results.length / 4).ceilToDouble()
        : 1.0;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppTheme.border, strokeWidth: 0.6),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(color: AppTheme.muted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= results.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    DateFormat('dd/MM').format(results[index].date),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: AppTheme.border, width: 0.6),
            bottom: BorderSide(color: AppTheme.border, width: 0.6),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          _line(vocabularySpots, AppTheme.accent),
          _line(grammarSpots, AppTheme.muted),
        ],
      ),
      duration: Duration.zero,
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: false,
    color: color,
    barWidth: 2,
    dotData: const FlDotData(show: true),
    belowBarData: BarAreaData(show: false),
  );

  Widget _legendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 3, color: color),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
    ],
  );

  Widget _buildThemeAccuracy(Map<String, double> accuracy) {
    final entries = accuracy.entries.toList()
      ..sort((first, second) => first.value.compareTo(second.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Précision par thème'),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Pas encore de données',
              style: TextStyle(color: AppTheme.muted),
            ),
          )
        else
          ...entries.map((entry) {
            final percentage = entry.value.clamp(0, 100).toDouble();
            final color = entry.value < 60 ? AppTheme.error : AppTheme.accent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 4,
                        backgroundColor: AppTheme.border,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${entry.value.round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentTests(List<TestResult> results) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Derniers tests'),
      if (results.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Pas encore de données',
            style: TextStyle(color: AppTheme.muted),
          ),
        )
      else
        ...results.map(
          (result) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              '${DateFormat('dd/MM').format(result.date)} - ${_typeLabel(result.type)} - ${result.score}/${result.total}',
              style: const TextStyle(color: AppTheme.text, fontSize: 14),
            ),
          ),
        ),
    ],
  );

  String _typeLabel(String type) => switch (type) {
    'vocab' => 'Vocabulaire',
    'grammar' => 'Grammaire',
    _ => type,
  };

  Widget _buildOptimizationButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _optimizing ? null : _optimize,
      icon: _optimizing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(
        _optimizing
            ? 'Optimisation en cours…'
            : 'Optimiser la répétition (Gemini)',
      ),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _sectionDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Divider(height: 1, thickness: 1, color: AppTheme.border),
  );
}

class _StatsData {
  const _StatsData({
    required this.vocabularyAverage,
    required this.grammarAverage,
    required this.streak,
    required this.mastered,
    required this.totalWords,
    required this.dueWords,
    required this.chartResults,
    required this.accuracyByTheme,
    required this.recentResults,
    required this.vocabularyStats,
    required this.flashcardPerformance,
  });

  final double vocabularyAverage;
  final double grammarAverage;
  final int streak;
  final int mastered;
  final int totalWords;
  final int dueWords;
  final List<TestResult> chartResults;
  final Map<String, double> accuracyByTheme;
  final List<TestResult> recentResults;
  final VocabularyStats vocabularyStats;
  final List<FlashcardPerformance> flashcardPerformance;
}
