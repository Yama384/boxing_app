import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../coach_guide.dart';
import '../models/training_session.dart';
import '../training_plan_data.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
import '../widgets/confirm_delete_dialog.dart';

const _categoryColors = <String, Color>{
  'categoryStrength': Colors.orangeAccent,
  'categoryBoxing': Colors.redAccent,
  'categorySparring': Colors.purpleAccent,
  'categoryCardio': Colors.lightGreenAccent,
  'categoryTechnique': Colors.lightBlueAccent,
  'categoryRest': Colors.blueGrey,
};

const _categoryEmojis = <String, String>{
  'categoryStrength': '🏋️',
  'categoryBoxing': '🥊',
  'categorySparring': '🥋',
  'categoryCardio': '🏃',
  'categoryTechnique': '🎯',
  'categoryRest': '😴',
};

const _customCategoryEmoji = '📌';

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

String _emojiForSession(TrainingSession session) {
  final key = session.categoryKey;
  if (key != null) return _categoryEmojis[key] ?? '🔸';
  return _customCategoryEmoji;
}

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  static const _introId = 'training_plan_intro';
  final _weekKey = GlobalKey();
  final _summaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (!CoachGuide.hasSeen(_introId)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startTour();
      });
    }
  }

  // showCoachTour() wird hier bewusst direkt aufgerufen statt in einem
  // addPostFrameCallback: _startTour() läuft entweder aus dem Future.delayed
  // in initState() (der Baum ist da längst gebaut) oder aus einem direkten
  // Tap auf das Guide-Icon -- letzterer löst selbst kein setState/keinen
  // neuen Frame aus, wodurch der Callback sonst erst beim nächsten
  // zufälligen Rebuild feuert (Tour erscheint verzögert oder gar nicht;
  // auf diesem statischen Screen ohne Tabs/Animationen kam sie so gut wie
  // nie, weil hier kaum je ein unabhängiger Rebuild passiert).
  void _startTour() {
    CoachGuide.markSeen(_introId);
    final s = AppStrings.of(AppSettings.locale.value);
    final steps = [
      CoachTourStep(anchorKey: _weekKey, message: s('coachPlanIntro1')),
      CoachTourStep(anchorKey: _weekKey, message: s('coachPlanIntro2')),
      CoachTourStep(anchorKey: _summaryKey, message: s('coachPlanSummary')),
      CoachTourStep(anchorKey: _weekKey, message: s('coachPlanIntro3')),
    ].where((step) => step.anchorKey.currentContext != null).toList();
    showCoachTour(
      context,
      steps: steps,
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    AppStrings s,
    Weekday day,
    TrainingSession session,
  ) async {
    final confirmed = await confirmDelete(context, s);
    if (!confirmed) return;
    TrainingPlanData.removeSession(day, session);
  }

  /// Sammelt alle bereits im Plan verwendeten eigenen Kategorienamen, damit
  /// sie im Dialog als Schnellauswahl angeboten werden können, statt sie bei
  /// jeder neuen Einheit erneut eintippen zu müssen. Reihenfolge: erstes
  /// Auftreten Montag bis Sonntag, Duplikate entfernt.
  List<String> _recentCustomCategories() {
    final seen = <String>{};
    final names = <String>[];
    for (final day in Weekday.values) {
      for (final session in TrainingPlanData.week.value[day]!) {
        final name = session.customCategory;
        if (name == null) continue;
        if (seen.add(name)) names.add(name);
      }
    }
    return names.take(8).toList();
  }

  Future<void> _showSessionDialog(
    BuildContext context,
    AppStrings s,
    Weekday day, {
    TrainingSession? existing,
  }) async {
    final customController = TextEditingController(
      text: existing?.customCategory ?? '',
    );
    String? selectedKey = existing?.categoryKey;
    final recentCategories = _recentCustomCategories()
        .where((name) => name != existing?.customCategory)
        .toList();

    final session = await showDialog<TrainingSession>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final canAdd =
                selectedKey != null || customController.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(s(existing == null ? 'addSession' : 'editSession')),
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
                            label: Text('${_categoryEmojis[key]} ${s(key)}'),
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
                    if (recentCategories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        s('planRecentCategories'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final name in recentCategories)
                            ActionChip(
                              avatar: const Text(_customCategoryEmoji),
                              label: Text(name),
                              onPressed: () => setDialogState(() {
                                customController.text = name;
                                selectedKey = null;
                              }),
                            ),
                        ],
                      ),
                    ],
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
                  child: Text(s(existing == null ? 'add' : 'save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (session == null) return;
    if (existing != null) {
      TrainingPlanData.updateSession(day, existing, session);
    } else {
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
    return Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            _showSessionDialog(context, s, day, existing: session),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_emojiForSession(session), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                session.displayCategory(s),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _deleteSession(context, s, day, session),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 15, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
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
    final isToday = day.index == DateTime.now().weekday - 1;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: primary.withValues(alpha: 0.7), width: 1.6)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s('planToday').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (sessions.length < 2)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showSessionDialog(context, s, day),
                  child: Icon(Icons.add_circle_outline, color: primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: sessions.isEmpty
                ? Text(
                    s('noSessionsPlanned'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final session in sessions)
                        _sessionCard(context, s, day, session),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String value, String label, Color color) {
    return Expanded(
      child: Container(
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
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    AppStrings s,
    Map<Weekday, List<TrainingSession>> week,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    var trainingSessions = 0;
    var restDays = 0;
    for (final sessions in week.values) {
      if (sessions.isEmpty) continue;
      if (sessions.every((session) => session.isRest)) {
        restDays++;
      } else {
        trainingSessions += sessions.where((session) => !session.isRest).length;
      }
    }
    return KeyedSubtree(
      key: _summaryKey,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _summaryTile(
              '$trainingSessions',
              s('analysisSessionsInRange'),
              primary,
            ),
            const SizedBox(width: 12),
            _summaryTile('$restDays', s('planRestDays'), Colors.blueGrey),
          ],
        ),
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
          appBar: AppBar(
            title: Text(s('trainingPlan')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: CoachAvatarIcon(onTap: _startTour)),
              ),
            ],
          ),
          body: ValueListenableBuilder<Map<Weekday, List<TrainingSession>>>(
            valueListenable: TrainingPlanData.week,
            builder: (context, week, _) {
              return ListView(
                key: _weekKey,
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryCard(context, s, week),
                  for (final day in Weekday.values)
                    _dayCard(context, s, day, week[day]!),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
