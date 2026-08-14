import 'improvement_goal.dart';
import 'training_entry.dart';

/// Alles, was ein [Achievement] zum Prüfen braucht -- einmal pro Aufruf aus
/// [LogbookData] zusammengebaut, damit die einzelnen Prüf-Funktionen nicht
/// selbst auf die Datenschicht zugreifen müssen (bleiben reine Funktionen).
class AchievementContext {
  const AchievementContext({
    required this.entries,
    required this.goals,
    required this.longestStreak,
  });

  final List<TrainingEntry> entries;
  final List<ImprovementGoal> goals;

  /// Längste je erreichte Serie -- bewusst nicht die *aktuelle* Serie:
  /// Achievements sind einmal erreichte Meilensteine und dürfen nicht
  /// wieder "verschwinden", nur weil die laufende Serie gerissen ist.
  final int longestStreak;
}

/// Ein Meilenstein, der rein aus bereits vorhandenen Trainings-/Zieldaten
/// abgeleitet wird -- keine eigene Dateneingabe nötig. `isUnlocked` ist eine
/// reine Funktion über den aktuellen Datenstand; persistiert wird an anderer
/// Stelle (siehe `achievements_data.dart`) nur, *wann* ein Achievement zum
/// ersten Mal erreicht wurde.
class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.titleKey,
    required this.descriptionKey,
    required this.isUnlocked,
  });

  final String id;
  final String emoji;
  final String titleKey;
  final String descriptionKey;
  final bool Function(AchievementContext ctx) isUnlocked;
}

bool _hasComeback(List<TrainingEntry> entries) {
  final days =
      entries
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .toSet()
          .toList()
        ..sort();
  for (var i = 1; i < days.length; i++) {
    if (days[i].difference(days[i - 1]).inDays > 7) return true;
  }
  return false;
}

final List<Achievement> achievementCatalog = [
  Achievement(
    id: 'first_entry',
    emoji: '🥇',
    titleKey: 'achievementFirstEntryTitle',
    descriptionKey: 'achievementFirstEntryDesc',
    isUnlocked: (ctx) => ctx.entries.isNotEmpty,
  ),
  Achievement(
    id: 'streak_3',
    emoji: '🔥',
    titleKey: 'achievementStreak3Title',
    descriptionKey: 'achievementStreak3Desc',
    isUnlocked: (ctx) => ctx.longestStreak >= 3,
  ),
  Achievement(
    id: 'streak_7',
    emoji: '🔥',
    titleKey: 'achievementStreak7Title',
    descriptionKey: 'achievementStreak7Desc',
    isUnlocked: (ctx) => ctx.longestStreak >= 7,
  ),
  Achievement(
    id: 'streak_30',
    emoji: '🔥',
    titleKey: 'achievementStreak30Title',
    descriptionKey: 'achievementStreak30Desc',
    isUnlocked: (ctx) => ctx.longestStreak >= 30,
  ),
  Achievement(
    id: 'sessions_10',
    emoji: '🥊',
    titleKey: 'achievementSessions10Title',
    descriptionKey: 'achievementSessions10Desc',
    isUnlocked: (ctx) => ctx.entries.length >= 10,
  ),
  Achievement(
    id: 'sessions_50',
    emoji: '🥊',
    titleKey: 'achievementSessions50Title',
    descriptionKey: 'achievementSessions50Desc',
    isUnlocked: (ctx) => ctx.entries.length >= 50,
  ),
  Achievement(
    id: 'sessions_100',
    emoji: '💯',
    titleKey: 'achievementSessions100Title',
    descriptionKey: 'achievementSessions100Desc',
    isUnlocked: (ctx) => ctx.entries.length >= 100,
  ),
  Achievement(
    id: 'first_sparring',
    emoji: '🥋',
    titleKey: 'achievementFirstSparringTitle',
    descriptionKey: 'achievementFirstSparringDesc',
    isUnlocked: (ctx) =>
        ctx.entries.any((e) => e.sessionType == SessionType.sparring),
  ),
  Achievement(
    id: 'first_goal_completed',
    emoji: '🏆',
    titleKey: 'achievementFirstGoalTitle',
    descriptionKey: 'achievementFirstGoalDesc',
    isUnlocked: (ctx) => ctx.goals.any((g) => g.status == GoalStatus.completed),
  ),
  Achievement(
    id: 'five_techniques_session',
    emoji: '🧠',
    titleKey: 'achievementFiveTechniquesTitle',
    descriptionKey: 'achievementFiveTechniquesDesc',
    isUnlocked: (ctx) =>
        ctx.entries.any((e) => e.techniquesPracticed.length >= 5),
  ),
  Achievement(
    id: 'comeback',
    emoji: '🔁',
    titleKey: 'achievementComebackTitle',
    descriptionKey: 'achievementComebackDesc',
    isUnlocked: (ctx) => _hasComeback(ctx.entries),
  ),
  Achievement(
    id: 'goal_master_3',
    emoji: '🎯',
    titleKey: 'achievementGoalMasterTitle',
    descriptionKey: 'achievementGoalMasterDesc',
    isUnlocked: (ctx) =>
        ctx.goals.where((g) => g.status == GoalStatus.completed).length >= 3,
  ),
];
