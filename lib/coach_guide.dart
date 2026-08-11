import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Merkt sich, welche Coach-Guide-Einführungen (kleiner Boxer/Coach-Charakter,
/// siehe [CoachBubble]) der Nutzer schon automatisch gesehen hat, damit sie
/// nicht bei jedem Besuch erneut aufploppen. Manuelles Erneut-Ansehen über
/// Antippen des Boxer-Icons ist davon unabhängig und funktioniert immer.
class CoachGuide {
  CoachGuide._();

  static const _seenKey = 'coach_guide_seen';

  static final ValueNotifier<Set<String>> _seen = ValueNotifier<Set<String>>({});

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    _seen.value = (prefs.getStringList(_seenKey) ?? const []).toSet();
  }

  static bool hasSeen(String id) => _seen.value.contains(id);

  static void markSeen(String id) {
    if (_seen.value.contains(id)) return;
    _seen.value = {..._seen.value, id};
    SharedPreferences.getInstance().then((prefs) => prefs.setStringList(_seenKey, _seen.value.toList()));
  }
}
