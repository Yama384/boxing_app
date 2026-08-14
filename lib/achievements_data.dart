import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logbook_data.dart';
import 'models/achievement.dart';

/// Ob ein Achievement freigeschaltet ist, wird live aus [LogbookData]
/// berechnet (siehe [context]/[isUnlocked]) -- kein eigener, dopplungsanfäl-
/// liger Zustand dafür. Persistiert wird hier nur *wann* ein Achievement
/// zum ersten Mal erreicht wurde, damit das Datum stabil bleibt (Muster wie
/// [CoachGuide], nur zusätzlich mit Zeitstempel statt nur einem Set).
class AchievementsData {
  AchievementsData._();

  static const _unlockedKey = 'achievements_unlocked_dates';

  static final ValueNotifier<Map<String, DateTime>> unlockedDates =
      ValueNotifier<Map<String, DateTime>>({});

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_unlockedKey);
    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      unlockedDates.value = decoded.map(
        (id, date) => MapEntry(id, DateTime.parse(date as String)),
      );
    }
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _unlockedKey,
      jsonEncode(
        unlockedDates.value.map(
          (id, date) => MapEntry(id, date.toIso8601String()),
        ),
      ),
    );
  }

  static AchievementContext context() {
    return AchievementContext(
      entries: LogbookData.entries.value,
      goals: LogbookData.goals.value,
      longestStreak: LogbookData.longestStreak,
    );
  }

  static bool isUnlocked(Achievement achievement) =>
      achievement.isUnlocked(context());

  /// Beim Öffnen der Achievements-Sektion aufgerufen: prüft alle Achievements
  /// gegen den aktuellen Datenstand und merkt sich für neu erreichte das
  /// heutige Datum. Mehrfacher Aufruf ist unkritisch -- bereits erfasste
  /// Achievements werden nicht überschrieben.
  static void syncUnlocked() {
    final ctx = context();
    final now = DateTime.now();
    var changed = false;
    final updated = {...unlockedDates.value};
    for (final achievement in achievementCatalog) {
      if (updated.containsKey(achievement.id)) continue;
      if (achievement.isUnlocked(ctx)) {
        updated[achievement.id] = now;
        changed = true;
      }
    }
    if (!changed) return;
    unlockedDates.value = updated;
    _persist();
  }
}
