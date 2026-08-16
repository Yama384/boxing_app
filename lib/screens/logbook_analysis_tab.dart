import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/improvement_goal.dart';
import '../models/pain_entry.dart';
import '../models/training_entry.dart';
import '../widgets/body_pain_map.dart';

enum _Range { d7, d30, d90, all }

/// Reine Auswertungs-Ansicht über die vorhandenen Trainingseinträge: zeigt
/// Trends (Bewertung, Intensität, Technik-Erfolg), die Verteilung der
/// Trainingsarten und wiederkehrende Schmerzzonen -- alles nur lesend, ohne
/// eigene Dateneingabe.
class LogbookAnalysisTab extends StatefulWidget {
  const LogbookAnalysisTab({
    super.key,
    required this.s,
    this.weekRecapKey,
    this.recordsKey,
    this.staleTechniquesKey,
    this.radarKey,
    this.rangeKey,
    this.statsKey,
    this.ratingTrendKey,
    this.intensityTrendKey,
    this.typeDistributionKey,
    this.techniqueTrendKey,
    this.painKey,
  });

  final AppStrings s;

  /// Anker für die Logbuch-Guide-Tour (siehe logbook_screen.dart) -- optional,
  /// damit dieses Widget auch ohne Tour-Anbindung nutzbar bleibt.
  final GlobalKey? weekRecapKey;
  final GlobalKey? recordsKey;
  final GlobalKey? staleTechniquesKey;
  final GlobalKey? radarKey;
  final GlobalKey? rangeKey;
  final GlobalKey? statsKey;
  final GlobalKey? ratingTrendKey;
  final GlobalKey? intensityTrendKey;
  final GlobalKey? typeDistributionKey;
  final GlobalKey? techniqueTrendKey;
  final GlobalKey? painKey;

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  ({int sessions, double? avgRating, int minutes}) _windowStats(
    List<TrainingEntry> all,
    DateTime start,
    DateTime end,
  ) {
    final inWindow = all.where((e) {
      final d = _dateOnly(e.date);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    final minutes = inWindow.fold<int>(
      0,
      (sum, e) => sum + (e.durationMinutes ?? 0),
    );
    return (
      sessions: inWindow.length,
      avgRating: _avg(inWindow.map((e) => e.rating)),
      minutes: minutes,
    );
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
                // minY/maxY sind bewusst um 0.5 gepolstert (siehe Aufrufer),
                // damit die Linie nicht am Rand klebt. Ohne minIncluded/
                // maxIncluded:false rendert fl_chart zusätzlich zu den
                // Intervall-Ticks (1,2,3,...) immer auch den exakten Rand-
                // wert (0.5, 5.5) -- gerundet ergäbe das eine doppelte "1"
                // am Anfang und eine ungültige "6" am Ende der Skala.
                minIncluded: false,
                maxIncluded: false,
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
                // Gleicher Grund wie oben: verhindert ein doppelt
                // gerendertes Datum am Rand, wenn der exakte erste/letzte
                // Zeitstempel knapp neben einem Intervall-Tick landet.
                minIncluded: false,
                maxIncluded: false,
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
              preventCurveOverShooting: true,
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

  Widget _recapTile(String value, String label, num? current, num? previous) {
    Widget? trend;
    if (current != null && previous != null && current != previous) {
      trend = Icon(
        current > previous
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        size: 14,
        color: current > previous ? Colors.greenAccent : Colors.redAccent,
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (trend != null) ...[const SizedBox(width: 4), trend],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  /// Vergleicht die letzten 7 Tage (inkl. heute) mit den 7 Tagen davor --
  /// rollierendes Fenster statt Kalenderwoche, damit es unabhängig vom
  /// Wochentag sofort nützlich ist.
  Widget _weekRecapCard(AppStrings s, List<TrainingEntry> allEntries) {
    final today = _dateOnly(DateTime.now());
    final thisWeekStart = today.subtract(const Duration(days: 6));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));

    final thisWeek = _windowStats(allEntries, thisWeekStart, today);
    final lastWeek = _windowStats(allEntries, lastWeekStart, lastWeekEnd);

    return _card(
      title: s('analysisWeekRecap'),
      child: Row(
        children: [
          Expanded(
            child: _recapTile(
              '${thisWeek.sessions}',
              s('analysisWeekSessions'),
              thisWeek.sessions,
              lastWeek.sessions,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _recapTile(
              thisWeek.avgRating == null
                  ? '--'
                  : thisWeek.avgRating!.toStringAsFixed(1),
              s('analysisWeekAvgRating'),
              thisWeek.avgRating,
              lastWeek.avgRating,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _recapTile(
              '${thisWeek.minutes}',
              s('analysisWeekMinutes'),
              thisWeek.minutes,
              lastWeek.minutes,
            ),
          ),
        ],
      ),
    );
  }

  /// Persönliche Bestleistungen über die gesamte Historie (unabhängig vom
  /// Zeitraum-Filter darunter, der nur die Trend-Charts betrifft).
  Widget _recordsCard(AppStrings s, List<TrainingEntry> allEntries) {
    final longestStreak = LogbookData.longestStreak;
    final totalHours =
        allEntries.fold<int>(0, (sum, e) => sum + (e.durationMinutes ?? 0)) /
        60;

    var bestWeekCount = 0;
    for (final anchor in allEntries) {
      final start = _dateOnly(anchor.date);
      final end = start.add(const Duration(days: 6));
      final count = allEntries.where((e) {
        final d = _dateOnly(e.date);
        return !d.isBefore(start) && !d.isAfter(end);
      }).length;
      if (count > bestWeekCount) bestWeekCount = count;
    }

    final byMonth = <String, List<int>>{};
    for (final e in allEntries) {
      byMonth
          .putIfAbsent('${e.date.year}-${e.date.month}', () => [])
          .add(e.rating);
    }
    String? bestMonthLabel;
    var bestMonthAvg = 0.0;
    for (final entry in byMonth.entries) {
      if (entry.value.length < 2) continue;
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (bestMonthLabel == null || avg > bestMonthAvg) {
        bestMonthAvg = avg;
        final parts = entry.key.split('-');
        bestMonthLabel = '${parts[1].padLeft(2, '0')}/${parts[0]}';
      }
    }

    return _card(
      title: s('analysisRecords'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statTile(
                  '$longestStreak',
                  s('analysisRecordLongestStreak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile('$bestWeekCount', s('analysisRecordBestWeek')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  bestMonthLabel == null
                      ? '--'
                      : '$bestMonthLabel (${bestMonthAvg.toStringAsFixed(1)})',
                  s('analysisRecordBestRatingMonth'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  totalHours.toStringAsFixed(1),
                  s('analysisRecordTotalHours'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Techniken, die früher regelmäßig geübt wurden (mind. 2x), aber seit
  /// über 2 Wochen nicht mehr auftauchen -- macht "einrosten" sichtbar,
  /// bevor man es im Sparring schmerzhaft merkt.
  Widget? _staleTechniquesCard(AppStrings s, List<TrainingEntry> allEntries) {
    final lastPracticed = <String, DateTime>{};
    final practiceCounts = <String, int>{};
    for (final e in allEntries) {
      for (final raw in e.techniquesPracticed) {
        final key = raw.trim();
        if (key.isEmpty) continue;
        practiceCounts[key] = (practiceCounts[key] ?? 0) + 1;
        final existing = lastPracticed[key];
        if (existing == null || e.date.isAfter(existing)) {
          lastPracticed[key] = e.date;
        }
      }
    }
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final stale =
        lastPracticed.entries
            .where(
              (entry) =>
                  (practiceCounts[entry.key] ?? 0) >= 2 &&
                  entry.value.isBefore(cutoff),
            )
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    if (stale.isEmpty) return null;

    return _card(
      title: s('analysisStaleTechniques'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s('analysisStaleTechniquesHint'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in stale.take(6))
                Chip(
                  label: Text(entry.key),
                  backgroundColor: const Color(0xFF2A2A2C),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
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
        // Körper-Karte fürs schnelle Erfassen, Balkenliste darunter für die
        // genauen Zahlen -- Ergänzung, kein Ersatz.
        BodyPainMap(counts: counts, s: s),
        const SizedBox(height: 16),
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

  /// Ø-Fortschritt je [SkillArea] über alle Ziele dieser Kategorie -- nutzt
  /// das bestehende Ziel-Fortschritt-Modell 1:1, keine neue Metrik. Eine
  /// unsichtbare "Anker"-Datenreihe fixiert die Skala immer auf 0-100,
  /// sonst würde fl_chart automatisch auf den aktuell höchsten Wert
  /// skalieren und die Form wäre über die Zeit nicht vergleichbar.
  Widget _skillRadarChart(
    AppStrings s,
    List<ImprovementGoal> goals,
    Color primary,
  ) {
    if (goals.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            s('skillRadarEmptyHint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    final byArea = <SkillArea, List<int>>{};
    for (final g in goals) {
      byArea.putIfAbsent(g.category, () => []).add(g.progress);
    }
    final values = [
      for (final area in SkillArea.values)
        if (byArea[area] case final progresses? when progresses.isNotEmpty)
          progresses.reduce((a, b) => a + b) / progresses.length
        else
          0.0,
    ];

    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          radarBorderData: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          tickBorderData: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          gridBorderData: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          tickCount: 4,
          ticksTextStyle: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          titlePositionPercentageOffset: 0.22,
          titleTextStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          getTitle: (index, angle) {
            final area = SkillArea.values[index];
            return RadarChartTitle(
              text: '${skillAreaEmoji(area)} ${skillAreaLabel(area, s)}',
              angle: angle,
            );
          },
          dataSets: [
            // Unsichtbarer Skalen-Anker, siehe Doc-Kommentar oben.
            RadarDataSet(
              dataEntries: List.generate(
                SkillArea.values.length,
                (_) => const RadarEntry(value: 100),
              ),
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              entryRadius: 0,
            ),
            RadarDataSet(
              dataEntries: [for (final v in values) RadarEntry(value: v)],
              fillColor: primary.withValues(alpha: 0.25),
              borderColor: primary,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
        ),
      ),
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
        final staleCard = _staleTechniquesCard(widget.s, allEntries);

        return ValueListenableBuilder<List<ImprovementGoal>>(
          valueListenable: LogbookData.goals,
          builder: (context, goals, _) {
            return ListView(
              // ListView virtualisiert Kinder außerhalb des sichtbaren
              // Bereichs (+ Standard-cacheExtent von 250px) -- ohne
              // großzügigeren cacheExtent haben GlobalKeys weit unten (z.B.
              // die Trend-Charts) beim Guide-Start noch kein currentContext,
              // obwohl die Karten da sind. Das ließ den Guide fälschlich
              // "fehlende" Schritte überspringen. Großzügiger fixer Wert
              // statt double.infinity, da die Liste klein/begrenzt ist.
              scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                KeyedSubtree(
                  key: widget.weekRecapKey,
                  child: _weekRecapCard(widget.s, allEntries),
                ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: widget.recordsKey,
                  child: _recordsCard(widget.s, allEntries),
                ),
                if (staleCard != null) ...[
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: widget.staleTechniquesKey,
                    child: staleCard,
                  ),
                ],
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: widget.radarKey,
                  child: _card(
                    title: widget.s('skillRadarTitle'),
                    child: _skillRadarChart(widget.s, goals, primary),
                  ),
                ),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: widget.rangeKey,
                  child: _rangeChips(widget.s),
                ),
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
                  KeyedSubtree(
                    key: widget.statsKey,
                    child: _statsGrid(widget.s, entries),
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: widget.ratingTrendKey,
                    child: _card(
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
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: widget.intensityTrendKey,
                    child: _card(
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
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: widget.typeDistributionKey,
                    child: _card(
                      title: widget.s('analysisTypeDistribution'),
                      child: _typeDistribution(widget.s, entries, primary),
                    ),
                  ),
                  if (entries.any((e) => e.techniqueSuccessRating != null)) ...[
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: widget.techniqueTrendKey,
                      child: _card(
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
                    ),
                  ],
                  if (entries.any((e) => e.painEntries.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: widget.painKey,
                      child: _card(
                        title: widget.s('analysisPainZones'),
                        child: _painZones(widget.s, entries),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }
}
