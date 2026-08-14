import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/pain_entry.dart';
import '../models/training_entry.dart';

enum _Range { d7, d30, d90, all }

/// Reine Auswertungs-Ansicht über die vorhandenen Trainingseinträge: zeigt
/// Trends (Bewertung, Intensität, Technik-Erfolg), die Verteilung der
/// Trainingsarten und wiederkehrende Schmerzzonen -- alles nur lesend, ohne
/// eigene Dateneingabe.
class LogbookAnalysisTab extends StatefulWidget {
  const LogbookAnalysisTab({super.key, required this.s});

  final AppStrings s;

  @override
  State<LogbookAnalysisTab> createState() => _LogbookAnalysisTabState();
}

class _LogbookAnalysisTabState extends State<LogbookAnalysisTab> {
  _Range _range = _Range.all;

  static const _typeEmojis = {
    TrainingType.technique: '🥊',
    TrainingType.sparring: '🥊',
    TrainingType.boxing: '🥊',
    TrainingType.muayThai: '🦵',
    TrainingType.kickboxing: '🦵',
    TrainingType.mma: '🤼',
    TrainingType.strength: '🏋️',
    TrainingType.cardio: '🏃',
    TrainingType.other: '📋',
  };

  static const _typeLabelKeys = {
    TrainingType.technique: 'trainingTypeTechnique',
    TrainingType.sparring: 'trainingTypeSparring',
    TrainingType.boxing: 'trainingTypeBoxing',
    TrainingType.muayThai: 'trainingTypeMuayThai',
    TrainingType.kickboxing: 'trainingTypeKickboxing',
    TrainingType.mma: 'trainingTypeMma',
    TrainingType.strength: 'trainingTypeStrength',
    TrainingType.cardio: 'trainingTypeCardio',
    TrainingType.other: 'trainingTypeOther',
  };

  static const _rangeOptions = [
    (_Range.d7, 'analysisRange7d'),
    (_Range.d30, 'analysisRange30d'),
    (_Range.d90, 'analysisRange90d'),
    (_Range.all, 'analysisRangeAll'),
  ];

  List<TrainingEntry> _inRange(List<TrainingEntry> all) {
    if (_range == _Range.all) return all;
    final days = switch (_range) {
      _Range.d7 => 7,
      _Range.d30 => 30,
      _Range.d90 => 90,
      _Range.all => 0,
    };
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => !e.date.isBefore(cutoff)).toList();
  }

  int _intensityValue(TrainingIntensity i) => switch (i) {
    TrainingIntensity.light => 1,
    TrainingIntensity.medium => 2,
    TrainingIntensity.hard => 3,
    TrainingIntensity.veryHard => 4,
  };

  double? _avg(Iterable<num> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_sectionLabel(title), child],
      ),
    );
  }

  Widget _rangeChips(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, key) in _rangeOptions)
          ChoiceChip(
            label: Text(s(key)),
            selected: _range == value,
            onSelected: (_) => setState(() => _range = value),
          ),
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(AppStrings s, List<TrainingEntry> entries) {
    final avgDuration = _avg(
      entries
          .where((e) => e.durationMinutes != null)
          .map((e) => e.durationMinutes!),
    );
    final avgRating = _avg(entries.map((e) => e.rating));
    final avgIntensity = _avg(entries.map((e) => _intensityValue(e.intensity)));
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statTile(
                '${entries.length}',
                s('analysisSessionsInRange'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                avgDuration == null
                    ? '--'
                    : '${avgDuration.round()} ${s('minutesUnit')}',
                s('analysisAvgDuration'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                avgRating == null ? '--' : avgRating.toStringAsFixed(1),
                s('analysisAvgRating'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                avgIntensity == null ? '--' : avgIntensity.toStringAsFixed(1),
                s('analysisAvgIntensity'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Generischer Trendlinien-Chart: `valueOf` liefert pro Eintrag den
  /// darzustellenden Wert (oder null, wenn der Eintrag dafür keine Angabe
  /// hat -- wird dann übersprungen statt als 0 gewertet).
  Widget _trendChart(
    AppStrings s, {
    required List<TrainingEntry> entries,
    required double? Function(TrainingEntry) valueOf,
    required double minY,
    required double maxY,
    required Color color,
  }) {
    final points = <MapEntry<DateTime, double>>[];
    for (final e in entries) {
      final v = valueOf(e);
      if (v != null) points.add(MapEntry(e.date, v));
    }
    points.sort((a, b) => a.key.compareTo(b.key));

    if (points.length < 2) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            s('analysisNotEnoughData'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    final spots = [
      for (final p in points)
        FlSpot(p.key.millisecondsSinceEpoch.toDouble(), p.value),
    ];
    var minX = spots.first.x;
    var maxX = spots.last.x;
    if (minX == maxX) {
      // Alle Punkte am selben Tag -- künstlich Platz schaffen, damit die
      // Achse nicht auf eine einzelne Linie kollabiert.
      final halfDay = const Duration(hours: 12).inMilliseconds;
      minX -= halfDay;
      maxX += halfDay;
    }

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
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
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (maxX - minX) / 3 < 1 ? 1 : (maxX - minX) / 3,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    value.round(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${date.day}.${date.month}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => color,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.round(),
                );
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${date.day}.${date.month}.${date.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proportionBar(
    String emoji,
    String label,
    int count,
    int maxCount,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: constraints.maxWidth * (count / maxCount),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeDistribution(
    AppStrings s,
    List<TrainingEntry> entries,
    Color color,
  ) {
    final counts = <TrainingType, int>{};
    for (final e in entries) {
      counts[e.trainingType] = (counts[e.trainingType] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;
    return Column(
      children: [
        for (final entry in sorted)
          _proportionBar(
            _typeEmojis[entry.key]!,
            s(_typeLabelKeys[entry.key]!),
            entry.value,
            maxCount,
            color,
          ),
      ],
    );
  }

  Widget _painZones(AppStrings s, List<TrainingEntry> entries) {
    final counts = <BodyZone, int>{};
    for (final e in entries) {
      for (final p in e.painEntries) {
        counts[p.bodyZone] = (counts[p.bodyZone] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;
    return Column(
      children: [
        for (final entry in sorted)
          _proportionBar(
            '🩹',
            bodyZoneLabel(entry.key, s),
            entry.value,
            maxCount,
            Colors.redAccent,
          ),
      ],
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              s('developmentStarts'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s('developmentStartsSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrainingEntry>>(
      valueListenable: LogbookData.entries,
      builder: (context, allEntries, _) {
        if (allEntries.isEmpty) return _buildEmptyState(widget.s);

        final entries = _inRange(allEntries)
          ..sort((a, b) => a.date.compareTo(b.date));
        final primary = Theme.of(context).colorScheme.primary;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _rangeChips(widget.s),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    widget.s('analysisNoDataInRange'),
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else ...[
              _statsGrid(widget.s, entries),
              const SizedBox(height: 16),
              _card(
                title: widget.s('analysisRatingTrend'),
                child: _trendChart(
                  widget.s,
                  entries: entries,
                  valueOf: (e) => e.rating.toDouble(),
                  minY: 0.5,
                  maxY: 5.5,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 16),
              _card(
                title: widget.s('analysisIntensityTrend'),
                child: _trendChart(
                  widget.s,
                  entries: entries,
                  valueOf: (e) => _intensityValue(e.intensity).toDouble(),
                  minY: 0.5,
                  maxY: 4.5,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              _card(
                title: widget.s('analysisTypeDistribution'),
                child: _typeDistribution(widget.s, entries, primary),
              ),
              if (entries.any((e) => e.techniqueSuccessRating != null)) ...[
                const SizedBox(height: 16),
                _card(
                  title: widget.s('analysisTechniqueTrend'),
                  child: _trendChart(
                    widget.s,
                    entries: entries,
                    valueOf: (e) => e.techniqueSuccessRating?.toDouble(),
                    minY: 0.5,
                    maxY: 5.5,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
              if (entries.any((e) => e.painEntries.isNotEmpty)) ...[
                const SizedBox(height: 16),
                _card(
                  title: widget.s('analysisPainZones'),
                  child: _painZones(widget.s, entries),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
