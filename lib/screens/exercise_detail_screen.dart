import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../models/exercise.dart';
import '../strength_data.dart';

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

  Future<void> _showAddEntryDialog(
    BuildContext context,
    AppStrings s,
    Exercise current,
  ) async {
    final weightController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s('newEntry')),
          content: TextField(
            controller: weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s('maxWeightKg')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s('add')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final weight =
        double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0;
    if (weight <= 0) return;
    StrengthData.addEntryTo(
      current,
      SessionEntry(weight: weight, timestamp: DateTime.now()),
    );
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
  }

  void _deleteEntry(
    BuildContext context,
    AppStrings s,
    Exercise current,
    SessionEntry entry,
  ) {
    StrengthData.removeEntryFrom(current, entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s('entryDeleted')),
        action: SnackBarAction(
          label: s('undo'),
          onPressed: () => StrengthData.addEntryTo(current, entry),
        ),
      ),
    );
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
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return Dismissible(
          key: ObjectKey(entry),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteEntry(context, s, current, entry),
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text('${entry.weight} kg'),
            subtitle: Text(_formatDate(entry.timestamp)),
          ),
        );
      },
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
          child: Text(
            s('notEnoughData'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 32, 24, 24),
      // Eigene "Zeichnen"-Animation: die Linie wächst kontrolliert von
      // links (minX) nach rechts (maxX), statt fl_charts eingebauter
      // Animation zu nutzen (die nur bei Datenänderungen greift, nicht
      // beim erneuten Anzeigen desselben Diagramms). Weil dieses Widget
      // bei jedem Tab-Wechsel neu gebaut wird, startet TweenAnimationBuilder
      // jedes Mal wieder bei 0.
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
    );
  }

  Widget _buildChart(
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.round()}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxX - minX) / 3 < 1 ? 1 : (maxX - minX) / 3,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.round());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
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
              return LineTooltipItem(
                '${spot.y} kg',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
            ),
            barWidth: 4,
            shadow: Shadow(color: color.withValues(alpha: 0.6), blurRadius: 16),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isLast = index == lastIndex;
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
                onPressed: () => _showAddEntryDialog(context, s, current),
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
