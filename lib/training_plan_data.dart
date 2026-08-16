import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/training_session.dart';

/// Feste Wochenroutine, persistiert über SharedPreferences (siehe
/// LogbookData) -- überlebt damit einen App-Neustart.
class TrainingPlanData {
  TrainingPlanData._();

  static const _weekKey = 'training_plan_week';

  static final ValueNotifier<Map<Weekday, List<TrainingSession>>> week =
      ValueNotifier<Map<Weekday, List<TrainingSession>>>({
    Weekday.monday: [],
    Weekday.tuesday: [],
    Weekday.wednesday: [],
    Weekday.thursday: [],
    Weekday.friday: [],
    Weekday.saturday: [],
    Weekday.sunday: [],
  });

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    final weekJson = prefs.getString(_weekKey);
    if (weekJson != null) {
      final decoded = jsonDecode(weekJson) as Map<String, dynamic>;
      week.value = {
        for (final day in Weekday.values)
          day: [
            for (final item in (decoded[day.name] as List<dynamic>? ?? const []))
              TrainingSession.fromJson(item as Map<String, dynamic>),
          ],
      };
    }
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _weekKey,
      jsonEncode({
        for (final entry in week.value.entries)
          entry.key.name: [for (final s in entry.value) s.toJson()],
      }),
    );
  }

  static void addSession(Weekday day, TrainingSession session) {
    week.value = {
      ...week.value,
      day: [...week.value[day]!, session],
    };
    _persist();
  }

  static void removeSession(Weekday day, TrainingSession session) {
    week.value = {
      ...week.value,
      day: week.value[day]!.where((s) => !identical(s, session)).toList(),
    };
    _persist();
  }

  static void updateSession(
    Weekday day,
    TrainingSession oldSession,
    TrainingSession newSession,
  ) {
    week.value = {
      ...week.value,
      day: [
        for (final s in week.value[day]!)
          if (identical(s, oldSession)) newSession else s,
      ],
    };
    _persist();
  }
}
