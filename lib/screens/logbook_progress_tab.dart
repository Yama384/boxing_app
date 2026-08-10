import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/improvement_goal.dart';
import '../models/skill_rating.dart';

class LogbookProgressTab extends StatefulWidget {
  const LogbookProgressTab({super.key, required this.s});

  final AppStrings s;

  @override
  State<LogbookProgressTab> createState() => _LogbookProgressTabState();
}

class _LogbookProgressTabState extends State<LogbookProgressTab> {
  SkillArea _area = SkillArea.technique;

  Widget _buildAreaPicker() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final area in SkillArea.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${skillAreaEmoji(area)} ${skillAreaLabel(area, widget.s)}'),
                selected: _area == area,
                onSelected: (_) => setState(() => _area = area),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _rateSkill(BuildContext context, String skillKey) async {
    final ratings = LogbookData.ratingsForSkill(_area, skillKey);
    var value = ratings.isNotEmpty ? ratings.last.value : 5.0;

    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.s(skillKey),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.s('selfAssessmentNote'), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        ),
                      ),
                    ),
                    Slider(
                      value: value,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      onChanged: (v) => setSheetState(() => value = v),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(value),
                        child: Text(widget.s('done')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      LogbookData.addSkillRating(SkillRating(area: _area, skillKey: skillKey, value: result, date: DateTime.now()));
    }
  }

  Widget _buildChart(BuildContext context, List<SkillRating> ratings) {
    final color = Theme.of(context).colorScheme.primary;
    final spots = [
      for (final r in ratings) FlSpot(r.date.millisecondsSinceEpoch.toDouble(), r.value),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, meta) => Text(
                '${value.round()}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  void _showSkillDetail(BuildContext context, String skillKey, List<SkillRating> ratings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.s(skillKey),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (ratings.length < 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(widget.s('notEnoughSkillData'), style: TextStyle(color: Colors.grey.shade500)),
                  )
                else
                  SizedBox(height: 200, child: _buildChart(context, ratings)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillCard(BuildContext context, String skillKey) {
    final ratings = LogbookData.ratingsForSkill(_area, skillKey);
    final primary = Theme.of(context).colorScheme.primary;
    final delta = ratings.length >= 2 ? ratings.last.value - ratings.first.value : 0.0;

    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSkillDetail(context, skillKey, ratings),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.s(skillKey),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    if (ratings.isEmpty)
                      Text(
                        widget.s('notEnoughSkillData'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      )
                    else if (ratings.length == 1)
                      Text(
                        ratings.first.value.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            '${ratings.first.value.toStringAsFixed(1)} → ${ratings.last.value.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: delta >= 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _rateSkill(context, skillKey),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Icons.add, size: 18, color: primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = predefinedSkillKeys[_area]!;
    return ValueListenableBuilder<List<SkillRating>>(
      valueListenable: LogbookData.skillRatings,
      builder: (context, _, _) {
        return Column(
          children: [
            const SizedBox(height: 16),
            _buildAreaPicker(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.s('selfAssessmentNote'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: skills.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildSkillCard(context, skills[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}
