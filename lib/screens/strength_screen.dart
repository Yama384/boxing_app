import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../coach_guide.dart';
import '../models/exercise.dart';
import '../strength_data.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'exercise_detail_screen.dart';

class StrengthScreen extends StatefulWidget {
  const StrengthScreen({super.key});

  @override
  State<StrengthScreen> createState() => _StrengthScreenState();
}

class _StrengthScreenState extends State<StrengthScreen> {
  static const _introId = 'strength_intro';
  final _addKey = GlobalKey();

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
  // zufälligen Rebuild feuert (Tour erscheint verzögert oder gar nicht).
  void _startTour() {
    CoachGuide.markSeen(_introId);
    final s = AppStrings.of(AppSettings.locale.value);
    showCoachTour(
      context,
      steps: [
        CoachTourStep(anchorKey: _addKey, message: s('coachTourStrengthIntro')),
      ],
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
  }

  Future<void> _showAddExerciseDialog(
    BuildContext context,
    AppStrings s,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s('addExercise')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: s('exerciseName')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s('cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(s('add')),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) {
      StrengthData.addExercise(name);
    }
  }

  /// Nur für selbst angelegte Übungen aufrufbar (siehe onLongPress unten) --
  /// vordefinierte Übungen hängen an einem Übersetzungs-Key, nicht an einem
  /// Freitext-Namen, der sich umbenennen ließe.
  Future<void> _showRenameExerciseDialog(
    BuildContext context,
    AppStrings s,
    Exercise exercise,
  ) async {
    final controller = TextEditingController(text: exercise.customName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s('renameExercise')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: s('exerciseName')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s('cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(s('save')),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) {
      StrengthData.renameExercise(exercise, name);
    }
  }

  String _subtitleFor(Exercise exercise, AppStrings s) {
    if (exercise.entries.isEmpty) return s('noEntriesYet');
    final last = exercise.entries.last;
    final date =
        '${last.timestamp.day}.${last.timestamp.month}.${last.timestamp.year}';
    final maxWeight = exercise.entries
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);
    final lastLine = '${s('lastEntry')}: ${last.weight} kg ($date)';
    // Bestleistung nur extra zeigen, wenn sie nicht ohnehin der letzte
    // Eintrag ist -- sonst wäre es dieselbe Zahl zweimal.
    if (maxWeight == last.weight) return lastLine;
    return '$lastLine · ${s('personalRecord')}: $maxWeight kg';
  }

  void _deleteExercise(Exercise exercise) {
    StrengthData.removeExercise(exercise);
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              s('noExercisesYet'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s('noExercisesYetSubtitle'),
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
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          appBar: AppBar(
            title: Text(s('strength')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: CoachAvatarIcon(onTap: _startTour)),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            key: _addKey,
            onPressed: () => _showAddExerciseDialog(context, s),
            child: const Icon(Icons.add),
          ),
          body: ValueListenableBuilder<List<Exercise>>(
            valueListenable: StrengthData.exercises,
            builder: (context, exercises, _) {
              if (exercises.isEmpty) return _buildEmptyState(s);
              return ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Dismissible(
                    key: ObjectKey(exercise),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => confirmDelete(context, s),
                    onDismissed: (_) => _deleteExercise(exercise),
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(exercise.displayName(s)),
                      subtitle: Text(_subtitleFor(exercise, s)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exercise: exercise),
                        ),
                      ),
                      // Nur eigene Übungen haben einen Freitext-Namen, den
                      // man umbenennen könnte -- vordefinierte sind über
                      // einen Übersetzungs-Key fest benannt.
                      onLongPress: exercise.customName == null
                          ? null
                          : () =>
                                _showRenameExerciseDialog(context, s, exercise),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
