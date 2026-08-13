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

  void _startTour() {
    CoachGuide.markSeen(_introId);
    final s = AppStrings.of(AppSettings.locale.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCoachTour(
        context,
        steps: [
          CoachTourStep(anchorKey: _addKey, message: s('coachTourStrengthIntro')),
        ],
        nextLabel: s('coachTourNext'),
        doneLabel: s('coachTourDone'),
        skipLabel: s('coachTourSkip'),
      );
    });
  }

  Future<void> _showAddExerciseDialog(BuildContext context, AppStrings s) async {
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
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
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

  String _subtitleFor(Exercise exercise, AppStrings s) {
    if (exercise.entries.isEmpty) return s('noEntriesYet');
    final last = exercise.entries.last;
    final date = '${last.timestamp.day}.${last.timestamp.month}.${last.timestamp.year}';
    return '${s('lastEntry')}: ${last.weight} kg ($date)';
  }

  void _deleteExercise(Exercise exercise) {
    StrengthData.removeExercise(exercise);
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
                          builder: (_) => ExerciseDetailScreen(exercise: exercise),
                        ),
                      ),
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
