import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/exercise.dart';

/// Hält die Kraftübungs-Daten, persistiert über SharedPreferences (siehe
/// LogbookData) -- überlebt damit einen App-Neustart.
class StrengthData {
  StrengthData._();

  static const _exercisesKey = 'strength_exercises';

  static final ValueNotifier<List<Exercise>> exercises = ValueNotifier<List<Exercise>>([
    const Exercise(nameKey: 'exerciseBenchPress'),
    const Exercise(nameKey: 'exerciseSquat'),
    const Exercise(nameKey: 'exerciseDeadlift'),
    const Exercise(nameKey: 'exerciseShoulderPress'),
    const Exercise(nameKey: 'exercisePullUp'),
    const Exercise(nameKey: 'exerciseRow'),
  ]);

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    final exercisesJson = prefs.getString(_exercisesKey);
    if (exercisesJson != null) {
      exercises.value = [
        for (final item in jsonDecode(exercisesJson) as List<dynamic>)
          Exercise.fromJson(item as Map<String, dynamic>),
      ];
    }
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _exercisesKey,
      jsonEncode([for (final e in exercises.value) e.toJson()]),
    );
  }

  static void addExercise(String customName) {
    exercises.value = [...exercises.value, Exercise(customName: customName)];
    _persist();
  }

  static void addEntryTo(Exercise target, SessionEntry entry) {
    exercises.value = [
      for (final exercise in exercises.value)
        if (identical(exercise, target)) exercise.addEntry(entry) else exercise,
    ];
    _persist();
  }

  static void removeEntryFrom(Exercise target, SessionEntry entry) {
    exercises.value = [
      for (final exercise in exercises.value)
        if (identical(exercise, target)) exercise.removeEntry(entry) else exercise,
    ];
    _persist();
  }

  static void removeExercise(Exercise target) {
    exercises.value = exercises.value.where((e) => !identical(e, target)).toList();
    _persist();
  }
}
