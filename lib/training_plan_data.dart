import 'package:flutter/material.dart';
import 'models/training_session.dart';

/// Feste Wochenroutine, nur im Arbeitsspeicher gehalten (siehe StrengthData).
class TrainingPlanData {
  TrainingPlanData._();

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

  static void addSession(Weekday day, TrainingSession session) {
    week.value = {
      ...week.value,
      day: [...week.value[day]!, session],
    };
  }

  static void removeSession(Weekday day, TrainingSession session) {
    week.value = {
      ...week.value,
      day: week.value[day]!.where((s) => !identical(s, session)).toList(),
    };
  }
}
