import 'package:flutter/material.dart';
import 'models/exercise.dart';

/// Hält die Kraftübungs-Daten nur im Arbeitsspeicher -- bewusst (noch) keine
/// dauerhafte Speicherung. Kommt als eigener Schritt später dazu.
class StrengthData {
  StrengthData._();

  static final ValueNotifier<List<Exercise>> exercises = ValueNotifier<List<Exercise>>([
    const Exercise(nameKey: 'exerciseBenchPress'),
    const Exercise(nameKey: 'exerciseSquat'),
    const Exercise(nameKey: 'exerciseDeadlift'),
    const Exercise(nameKey: 'exerciseShoulderPress'),
    const Exercise(nameKey: 'exercisePullUp'),
    const Exercise(nameKey: 'exerciseRow'),
  ]);

  static void addExercise(String customName) {
    exercises.value = [...exercises.value, Exercise(customName: customName)];
  }

  static void addEntryTo(Exercise target, SessionEntry entry) {
    exercises.value = [
      for (final exercise in exercises.value)
        if (identical(exercise, target)) exercise.addEntry(entry) else exercise,
    ];
  }

  static void removeEntryFrom(Exercise target, SessionEntry entry) {
    exercises.value = [
      for (final exercise in exercises.value)
        if (identical(exercise, target)) exercise.removeEntry(entry) else exercise,
    ];
  }

  static void removeExercise(Exercise target) {
    exercises.value = exercises.value.where((e) => !identical(e, target)).toList();
  }

  static void insertExerciseAt(int index, Exercise exercise) {
    final updated = [...exercises.value];
    updated.insert(index.clamp(0, updated.length), exercise);
    exercises.value = updated;
  }
}
