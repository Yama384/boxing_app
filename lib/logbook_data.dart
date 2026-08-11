import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/goal_rating.dart';
import 'models/improvement_goal.dart';
import 'models/pain_entry.dart';
import 'models/sparring_log.dart';
import 'models/training_entry.dart';

/// Logbuch-Daten, persistiert über SharedPreferences (JSON-serialisierte
/// Listen) -- siehe auch StrengthData/TrainingPlanData, die demselben Muster
/// folgen.
class LogbookData {
  LogbookData._();

  static const _entriesKey = 'logbook_entries';
  static const _goalsKey = 'logbook_goals';
  static const _goalRatingsKey = 'logbook_goal_ratings';

  static final ValueNotifier<List<TrainingEntry>> entries =
      ValueNotifier<List<TrainingEntry>>([]);
  static final ValueNotifier<List<ImprovementGoal>> goals =
      ValueNotifier<List<ImprovementGoal>>([]);
  static final ValueNotifier<List<GoalRating>> goalRatings =
      ValueNotifier<List<GoalRating>>([]);

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    final entriesJson = prefs.getString(_entriesKey);
    if (entriesJson != null) {
      entries.value = [
        for (final item in jsonDecode(entriesJson) as List<dynamic>)
          TrainingEntry.fromJson(item as Map<String, dynamic>),
      ];
    }

    final goalsJson = prefs.getString(_goalsKey);
    if (goalsJson != null) {
      goals.value = [
        for (final item in jsonDecode(goalsJson) as List<dynamic>)
          ImprovementGoal.fromJson(item as Map<String, dynamic>),
      ];
    }

    final goalRatingsJson = prefs.getString(_goalRatingsKey);
    if (goalRatingsJson != null) {
      goalRatings.value = [
        for (final item in jsonDecode(goalRatingsJson) as List<dynamic>)
          GoalRating.fromJson(item as Map<String, dynamic>),
      ];
    }
  }

  static Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _entriesKey,
      jsonEncode([for (final e in entries.value) e.toJson()]),
    );
  }

  static Future<void> _persistGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _goalsKey,
      jsonEncode([for (final g in goals.value) g.toJson()]),
    );
  }

  static Future<void> _persistGoalRatings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _goalRatingsKey,
      jsonEncode([for (final r in goalRatings.value) r.toJson()]),
    );
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // --- Trainingseinträge ---

  static TrainingEntry addEntry({
    required DateTime date,
    required TrainingType trainingType,
    required TrainingIntensity intensity,
    required int rating,
    Mood? mood,
    String goal = '',
    int? durationMinutes,
    String whatWentWell = '',
    String whatWentBad = '',
    String improvement = '',
    SessionType? sessionType,
    List<String> additionalSports = const [],
    int? rpe,
    int? energyLevelPre,
    int? focusLevelPre,
    int? sleepQuality,
    List<PainEntry> painEntries = const [],
    List<String> techniquesPracticed = const [],
    List<String> positionalFocus = const [],
    int? techniqueSuccessRating,
    SparringLog? sparringLog,
    String? keyTakeaway,
  }) {
    final now = DateTime.now();
    final entry = TrainingEntry(
      id: _newId(),
      date: date,
      trainingType: trainingType,
      intensity: intensity,
      rating: rating,
      mood: mood,
      goal: goal,
      durationMinutes: durationMinutes,
      whatWentWell: whatWentWell,
      whatWentBad: whatWentBad,
      improvement: improvement,
      createdAt: now,
      updatedAt: now,
      sessionType: sessionType,
      additionalSports: additionalSports,
      rpe: rpe,
      energyLevelPre: energyLevelPre,
      focusLevelPre: focusLevelPre,
      sleepQuality: sleepQuality,
      painEntries: painEntries,
      techniquesPracticed: techniquesPracticed,
      positionalFocus: positionalFocus,
      techniqueSuccessRating: techniqueSuccessRating,
      sparringLog: sparringLog,
      keyTakeaway: keyTakeaway,
    );
    entries.value = [...entries.value, entry];
    _persistEntries();
    return entry;
  }

  static void deleteEntry(TrainingEntry entry) {
    entries.value = entries.value.where((e) => e.id != entry.id).toList();
    _persistEntries();
  }

  static void restoreEntry(TrainingEntry entry) {
    entries.value = [...entries.value, entry];
    _persistEntries();
  }

  // --- Verbesserungsziele ---

  static ImprovementGoal addGoal({
    required String title,
    required String description,
    required SkillArea category,
    required GoalPriority priority,
  }) {
    final now = DateTime.now();
    final goal = ImprovementGoal(
      id: _newId(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
    goals.value = [...goals.value, goal];
    _persistGoals();
    return goal;
  }

  static void updateGoal(ImprovementGoal updated) {
    goals.value = [
      for (final g in goals.value) if (g.id == updated.id) updated else g,
    ];
    _persistGoals();
  }

  static void deleteGoal(ImprovementGoal goal) {
    goals.value = goals.value.where((g) => g.id != goal.id).toList();
    goalRatings.value = goalRatings.value.where((r) => r.goalId != goal.id).toList();
    _persistGoals();
    _persistGoalRatings();
  }

  static void restoreGoal(ImprovementGoal goal) {
    goals.value = [...goals.value, goal];
    _persistGoals();
  }

  /// Wichtigstes aktives Ziel für "Dein Fokus heute": höchste Priorität
  /// zuerst, bei Gleichstand das zuletzt bearbeitete.
  static ImprovementGoal? get focusGoal {
    final active = goals.value.where((g) => g.status == GoalStatus.active).toList();
    if (active.isEmpty) return null;
    const priorityOrder = {GoalPriority.high: 0, GoalPriority.medium: 1, GoalPriority.low: 2};
    active.sort((a, b) {
      final byPriority = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (byPriority != 0) return byPriority;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return active.first;
  }

  // --- Zielbewertungen ---

  static void addGoalRating(GoalRating rating) {
    goalRatings.value = [...goalRatings.value, rating];
    _persistGoalRatings();

    final matches = goals.value.where((g) => g.id == rating.goalId);
    if (matches.isEmpty) return;
    final goal = matches.first;
    final delta = switch (rating.rating) {
      GoalRatingValue.none => -5,
      GoalRatingValue.partial => 5,
      GoalRatingValue.good => 10,
      GoalRatingValue.great => 15,
    };
    final newProgress = (goal.progress + delta).clamp(0, 100);
    updateGoal(goal.copyWith(progress: newProgress, updatedAt: DateTime.now()));
  }

  static List<GoalRating> ratingsForGoal(String goalId) {
    return goalRatings.value.where((r) => r.goalId == goalId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- Dashboard-Statistiken ---

  static int get trainingDaysCount {
    final days = entries.value.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    return days.length;
  }

  static int get currentStreak {
    final days = entries.value.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
