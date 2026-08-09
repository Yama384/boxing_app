import '../app_strings.dart';

/// Ein Eintrag der Maximalkraft für eine einzelne Trainingssession -- bewusst
/// nur ein Wert pro Übung pro Session (kein Satz-für-Satz-Tracking), damit
/// klar ist, wie man die App benutzt: nach jedem Training einmal pro Übung
/// eintragen, fertig.
class SessionEntry {
  const SessionEntry({required this.weight, required this.timestamp});

  final double weight;
  final DateTime timestamp;
}

/// Eine Übung ist entweder vordefiniert (`nameKey`, wird übersetzt) oder vom
/// Nutzer selbst hinzugefügt (`customName`, wird 1:1 angezeigt -- Freitext
/// lässt sich nicht automatisch übersetzen).
class Exercise {
  const Exercise({this.nameKey, this.customName, this.entries = const []})
    : assert(nameKey != null || customName != null);

  final String? nameKey;
  final String? customName;
  final List<SessionEntry> entries;

  String displayName(AppStrings s) => customName ?? s(nameKey!);

  Exercise addEntry(SessionEntry entry) {
    return Exercise(nameKey: nameKey, customName: customName, entries: [...entries, entry]);
  }

  Exercise removeEntry(SessionEntry entry) {
    return Exercise(
      nameKey: nameKey,
      customName: customName,
      entries: entries.where((e) => !identical(e, entry)).toList(),
    );
  }
}
