import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../models/training_session.dart';
import '../training_plan_data.dart';
import '../widgets/coach_bubble.dart';

const _categoryColors = <String, Color>{
  'categoryStrength': Colors.orangeAccent,
  'categoryBoxing': Colors.redAccent,
  'categorySparring': Colors.purpleAccent,
  'categoryCardio': Colors.lightGreenAccent,
  'categoryTechnique': Colors.lightBlueAccent,
  'categoryRest': Colors.blueGrey,
};

const _customCategoryColors = <Color>[
  Colors.tealAccent,
  Colors.pinkAccent,
  Colors.amberAccent,
  Colors.cyanAccent,
  Colors.deepOrangeAccent,
];

Color _colorForSession(TrainingSession session) {
  final key = session.categoryKey;
  if (key != null) return _categoryColors[key] ?? Colors.grey;
  final name = session.customCategory!;
  final index =
      name.codeUnits.fold<int>(0, (sum, c) => sum + c) %
      _customCategoryColors.length;
  return _customCategoryColors[index];
}

class TrainingPlanScreen extends StatelessWidget {
  const TrainingPlanScreen({super.key});

  void _deleteSession(
    BuildContext context,
    AppStrings s,
    Weekday day,
    TrainingSession session,
  ) {
    TrainingPlanData.removeSession(day, session);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s('sessionDeleted')),
        action: SnackBarAction(
          label: s('undo'),
          onPressed: () => TrainingPlanData.addSession(day, session),
        ),
      ),
    );
  }

  Future<void> _showAddSessionDialog(
    BuildContext context,
    AppStrings s,
    Weekday day,
  ) async {
    final customController = TextEditingController();
    String? selectedKey;

    final session = await showDialog<TrainingSession>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final canAdd =
                selectedKey != null || customController.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(s('addSession')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in predefinedCategoryKeys)
                          ChoiceChip(
                            label: Text(s(key)),
                            selected: selectedKey == key,
                            onSelected: (_) => setDialogState(() {
                              selectedKey = selectedKey == key ? null : key;
                              if (selectedKey != null) customController.clear();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customController,
                      decoration: InputDecoration(
                        labelText: s('customCategoryLabel'),
                      ),
                      onChanged: (value) => setDialogState(() {
                        if (value.trim().isNotEmpty) selectedKey = null;
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(s('cancel')),
                ),
                FilledButton(
                  onPressed: !canAdd
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                          selectedKey != null
                              ? TrainingSession(categoryKey: selectedKey)
                              : TrainingSession(
                                  customCategory: customController.text.trim(),
                                ),
                        ),
                  child: Text(s('add')),
                ),
              ],
            );
          },
        );
      },
    );

    if (session != null) {
      TrainingPlanData.addSession(day, session);
    }
  }

  Widget _sessionCard(
    BuildContext context,
    AppStrings s,
    Weekday day,
    TrainingSession session,
  ) {
    final color = _colorForSession(session);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            session.displayCategory(s),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteSession(context, s, day, session),
            child: const Icon(Icons.close, size: 16, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(
    BuildContext context,
    AppStrings s,
    Weekday day,
    List<TrainingSession> sessions,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weekdayLabel(day, s).toUpperCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: primary,
                ),
              ),
              if (sessions.length < 2)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showAddSessionDialog(context, s, day),
                  child: Icon(Icons.add_circle_outline, color: primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Text(
              s('noSessionsPlanned'),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final session in sessions)
                  _sessionCard(context, s, day, session),
              ],
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
        return Scaffold(
          appBar: AppBar(title: Text(s('trainingPlan'))),
          // Coach-Guide als Body-Overlay (nicht AppBar-Actions) -- die AppBar
          // schneidet überlaufende Kind-Inhalte ab, siehe logbook_screen.dart.
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder<Map<Weekday, List<TrainingSession>>>(
                valueListenable: TrainingPlanData.week,
                builder: (context, week, _) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final day in Weekday.values)
                        _dayCard(context, s, day, week[day]!),
                    ],
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 20,
                child: CoachBubble(
                  introId: 'training_plan_intro',
                  side: CoachBubbleSide.right,
                  messages: [s('coachPlanIntro1'), s('coachPlanIntro2'), s('coachPlanIntro3')],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
