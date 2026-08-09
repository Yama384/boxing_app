import 'package:flutter/material.dart';

const Map<String, Map<String, String>> _translations = {
  'de': {
    'appTitle': 'Boxing App',
    'tagline': 'Train. Track. Win.',
    'timer': 'Timer',
    'stopwatch': 'Stoppuhr',
    'interval': 'Intervalle',
    'strength': 'Kraftübungen',
    'trainingPlan': 'Trainingsplan',
    'logbook': 'Logbuch',
    'settings': 'Einstellungen',
    'comingSoon': 'Bald verfügbar',
    'colorDesign': 'Farbdesign',
    'colorDesignSubtitle': 'Standard: Rot -- wähle deine eigene Akzentfarbe',
    'language': 'Sprache',
    'start': 'Start',
    'pause': 'Pause',
    'reset': 'Reset',
    'timeUp': 'Zeit abgelaufen!',
    'trainingDone': 'Training beendet',
    'round': 'Runde',
    'rounds': 'Runden',
    'roundDuration': 'Rundendauer',
    'min': 'Min',
    'sec': 'Sek',
    'soundToggleTitle': 'Signalton bei Zeitablauf',
    'soundToggleSubtitle': 'Boxglocke abspielen, wenn der Timer abläuft',
    'colorRed': 'Rot',
    'colorGreen': 'Grün',
    'colorBlue': 'Blau',
    'colorOrange': 'Orange',
    'colorPurple': 'Lila',
    'colorTeal': 'Türkis',
  },
  'en': {
    'appTitle': 'Boxing App',
    'tagline': 'Train. Track. Win.',
    'timer': 'Timer',
    'stopwatch': 'Stopwatch',
    'interval': 'Intervals',
    'strength': 'Strength Training',
    'trainingPlan': 'Training Plan',
    'logbook': 'Logbook',
    'settings': 'Settings',
    'comingSoon': 'Coming soon',
    'colorDesign': 'Color Theme',
    'colorDesignSubtitle': 'Default: Red -- choose your own accent color',
    'language': 'Language',
    'start': 'Start',
    'pause': 'Pause',
    'reset': 'Reset',
    'timeUp': 'Time is up!',
    'trainingDone': 'Training finished',
    'round': 'Round',
    'rounds': 'Rounds',
    'roundDuration': 'Round duration',
    'min': 'Min',
    'sec': 'Sec',
    'soundToggleTitle': 'Sound when time is up',
    'soundToggleSubtitle': 'Play the boxing bell when the timer ends',
    'colorRed': 'Red',
    'colorGreen': 'Green',
    'colorBlue': 'Blue',
    'colorOrange': 'Orange',
    'colorPurple': 'Purple',
    'colorTeal': 'Teal',
  },
};

/// Kleine, selbstgebaute Übersetzungslösung statt Flutters offiziellem
/// l10n-Codegen (ARB-Dateien + flutter gen-l10n) -- für den aktuellen Umfang
/// (~25 Texte, 2 Sprachen) reicht eine einfache Lookup-Tabelle.
class AppStrings {
  const AppStrings(this._map);

  factory AppStrings.of(Locale locale) {
    return AppStrings(_translations[locale.languageCode] ?? _translations['de']!);
  }

  final Map<String, String> _map;

  String call(String key) => _map[key] ?? key;
}
