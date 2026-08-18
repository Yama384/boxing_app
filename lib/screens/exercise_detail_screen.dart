import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../models/exercise.dart';
import '../strength_data.dart';
import '../widgets/confirm_delete_dialog.dart';

enum _DetailTab { entries, progress }

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  /// Stand der Übung zum Zeitpunkt der Navigation -- dient nur dazu, die
  /// aktuelle Version anhand des Namens in der Liste wiederzufinden (siehe
  /// build), da beim Hinzufügen eines Eintrags ein neues Exercise-Objekt
  /// entsteht.
  final Exercise exercise;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  _DetailTab _tab = _DetailTab.entries;

  /// Zeigt denselben Dialog fürs Hinzufügen (`existing == null`) und
  /// Bearbeiten (`existing` gesetzt) eines Eintrags -- Bearbeiten ersetzt
  /// nur den Wert/das Datum, statt den alten Eintrag zu löschen und einen
  /// neuen ohne das ursprüngliche Datum anzulegen.
  Future<void> _showEntryDialog(
    BuildContext context,
    AppStrings s,
    Exercise current, {
    SessionEntry? existing,
  }) async {
    final weightController = TextEditingController(
      text: existing != null ? _formatWeight(existing.weight) : '',
    );
    var selectedDate = existing?.timestamp ?? DateTime.now();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing != null ? s('editEntry') : s('newEntry')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: s('maxWeightKg'),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(s('entryDate')),
                    trailing: Text(_formatDate(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365 * 3),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(s('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final weight = double.tryParse(
                      weightController.text.replaceAll(',', '.'),
                    );
                    if (weight == null || weight <= 0) {
                      setDialogState(() => error = s('weightInputError'));
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: Text(existing != null ? s('save') : s('add')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final weight = double.parse(weightController.text.replaceAll(',', '.'));
    final entry = SessionEntry(weight: weight, timestamp: selectedDate);
    if (existing != null) {
      StrengthData.updateEntryIn(current, existing, entry);
    } else {
      StrengthData.addEntryTo(current, entry);
    }
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
  }

  String _formatWeight(double weight) {
    return weight == weight.truncateToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toString();
  }

  void _deleteEntry(Exercise current, SessionEntry entry) {
    StrengthData.removeEntryFrom(current, entry);
  }

  Widget _buildEntriesList(
    BuildContext context,
    AppStrings s,
    Exercise current,
  ) {
    if (current.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            s('noEntriesYet'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }
    final sorted = [...current.entries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final maxWeight = current.entries
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final isPr = entry.weight == maxWeight;
        // sorted ist absteigend nach Datum -- der chronologisch vorherige
        // Eintrag steht also einen Index weiter unten in der Liste.
        final previous = index + 1 < sorted.length ? sorted[index + 1] : null;
        final trendUp = previous == null || previous.weight == entry.weight
            ? null
            : entry.weight > previous.weight;
        return Dismissible(
          key: ObjectKey(entry),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => confirmDelete(context, s),
          onDismissed: (_) => _deleteEntry(current, entry),
          child: ListTile(
            onTap: () => _showEntryDialog(context, s, current, existing: entry),
            leading: Icon(
              isPr ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: isPr ? Colors.amber : null,
            ),
            title: Row(
              children: [
                Text('${_formatWeight(entry.weight)} kg'),
                if (trendUp != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: trendUp ? Colors.greenAccent : Colors.redAccent,
                  ),
                ],
                if (isPr) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s('personalRecord'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(_formatDate(entry.timestamp)),
          ),
        );
      },
    );
  }

  Widget _progressStat(
    String label,
    String value, {
    Color? valueColor,
    Widget? trailing,
  }) {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? Colors.white,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
    AppStrings s,
    List<SessionEntry> sorted,
    double maxWeight,
  ) {
    final first = sorted.first.weight;
    final last = sorted.last.weight;
    final delta = last - first;
    final trendColor = delta > 0
        ? Colors.greenAccent
        : (delta < 0 ? Colors.redAccent : Colors.grey.shade400);
    return Row(
      children: [
        Expanded(
          child: _progressStat(
            s('progressCurrent'),
            '${_formatWeight(last)} kg',
            trailing: delta == 0
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta > 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: trendColor,
                      ),
                      Text(
                        '${_formatWeight(delta.abs())} kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _progressStat(
            s('personalRecordLabel'),
            '${_formatWeight(maxWeight)} kg',
            valueColor: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(
    BuildContext context,
    AppStrings s,
    Exercise current,
  ) {
    if (current.entries.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 40, color: Colors.grey.shade700),
              const SizedBox(height: 12),
              Text(
                s('notEnoughData'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...current.entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final spots = [
      for (final entry in sorted)
        FlSpot(entry.timestamp.millisecondsSinceEpoch.toDouble(), entry.weight),
    ];
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minWeight = sorted
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = sorted
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);
    final weightPadding = (maxWeight - minWeight).abs() < 1
        ? 2.0
        : (maxWeight - minWeight) * 0.35;

    final color = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _buildProgressHeader(s, sorted, maxWeight),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 24, 20, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 260,
            // Eigene "Zeichnen"-Animation: die Linie wächst kontrolliert von
            // links (minX) nach rechts (maxX), statt fl_charts eingebauter
            // Animation zu nutzen (die nur bei Datenänderungen greift, nicht
            // beim erneuten Anzeigen desselben Diagramms). Weil dieses
            // Widget bei jedem Tab-Wechsel neu gebaut wird, startet
            // TweenAnimationBuilder jedes Mal wieder bei 0.
            child: TweenAnimationBuilder<double>(
              key: ValueKey(spots.length),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              builder: (context, reveal, _) {
                final cutoffX = minX + (maxX - minX) * reveal;
                final revealedSpots = <FlSpot>[];
                for (final spot in spots) {
                  if (spot.x <= cutoffX) {
                    revealedSpots.add(spot);
                  } else {
                    final prev = revealedSpots.isNotEmpty
                        ? revealedSpots.last
                        : spots.first;
                    if (cutoffX > prev.x) {
                      final t = (cutoffX - prev.x) / (spot.x - prev.x);
                      revealedSpots.add(
                        FlSpot(cutoffX, prev.y + (spot.y - prev.y) * t),
                      );
                    }
                    break;
                  }
                }
                final lastIndex = revealedSpots.length - 1;
                return _buildChart(
                  s,
                  color,
                  minX,
                  maxX,
                  minWeight,
                  maxWeight,
                  weightPadding,
                  revealedSpots,
                  lastIndex,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    AppStrings s,
    Color color,
    double minX,
    double maxX,
    double minWeight,
    double maxWeight,
    double weightPadding,
    List<FlSpot> spots,
    int lastIndex,
  ) {
    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minWeight - weightPadding,
        maxY: maxWeight + weightPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: weightPadding.clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: maxWeight,
              color: Colors.amber.withValues(alpha: 0.55),
              strokeWidth: 1.5,
              dashArray: [6, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
                labelResolver: (_) => s('personalRecord'),
              ),
            ),
          ],
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
              reservedSize: 46,
              // minY/maxY sind um weightPadding gepolstert (siehe Aufrufer),
              // meist kein glatter Vielfaches des Intervalls. Ohne
              // minIncluded/maxIncluded:false rendert fl_chart zusätzlich zu
              // den Intervall-Ticks immer auch den exakten (krummen)
              // Randwert -- gerundet ergibt das je nach Gewichtswerten eine
              // doppelte Zahl am Rand.
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) => Text(
                '${value.round()} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (maxX - minX) / 3 < 1 ? 1 : (maxX - minX) / 3,
              // Gleicher Grund wie oben: verhindert ein doppelt gerendertes
              // Datum am Rand, wenn der exakte erste/letzte Zeitstempel
              // knapp neben einem Intervall-Tick landet.
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.round());
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${date.day}.${date.month}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.round());
              return LineTooltipItem(
                '${_formatWeight(spot.y)} kg\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: _formatDate(date),
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
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
            ),
            barWidth: 4,
            shadow: Shadow(color: color.withValues(alpha: 0.6), blurRadius: 16),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isLast = index == lastIndex;
                final isPr = spot.y == maxWeight;
                if (isPr) {
                  return FlDotCirclePainter(
                    radius: isLast ? 7 : 5,
                    color: Colors.amber,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF1C1C1E),
                  );
                }
                return FlDotCirclePainter(
                  radius: isLast ? 6 : 3.5,
                  color: isLast ? color : const Color(0xFF1C1C1E),
                  strokeWidth: 2,
                  strokeColor: color,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return ValueListenableBuilder<List<Exercise>>(
          valueListenable: StrengthData.exercises,
          builder: (context, exercises, _) {
            final current = exercises.firstWhere(
              (e) =>
                  e.nameKey == widget.exercise.nameKey &&
                  e.customName == widget.exercise.customName,
              orElse: () => widget.exercise,
            );
            return Scaffold(
              appBar: AppBar(title: Text(current.displayName(s))),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showEntryDialog(context, s, current),
                icon: const Icon(Icons.add),
                label: Text(s('newEntry')),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CupertinoSlidingSegmentedControl<_DetailTab>(
                        groupValue: _tab,
                        backgroundColor: const Color(0xFF1C1C1E),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        children: {
                          _DetailTab.entries: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Text(
                              s('entriesTab'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _DetailTab.progress: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Text(
                              s('progressTab'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (value) {
                          if (value != null) setState(() => _tab = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: _tab == _DetailTab.entries
                          ? _buildEntriesList(context, s, current)
                          : _buildProgressChart(context, s, current),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
