import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'timer_notifications.dart';

/// Ein einzelner Phasenwechsel (Rundenende, Pausenende, Timerende), den der
/// Hintergrund-Dienst überwachen soll, während die App im Hintergrund ist.
class TimerPhase {
  const TimerPhase({
    required this.at,
    required this.activeLabel,
    required this.alertTitle,
    required this.alertBody,
    required this.sound,
  });

  final DateTime at;

  /// Was gerade läuft, bis [at] erreicht ist (z.B. "Runde 1 / 2") -- für die
  /// laufend aktualisierte Countdown-Anzeige.
  final String activeLabel;

  /// Was bei Erreichen von [at] als Alarm-Benachrichtigung angezeigt wird
  /// (beschreibt die neue, jetzt startende Phase, z.B. "Pause").
  final String alertTitle;
  final String alertBody;

  /// 'bell' (Rundenende) oder 'buzzer' (Pausenende) -- Dateiname ohne
  /// Endung, wie in android/app/src/main/res/raw abgelegt.
  final String sound;

  Map<String, dynamic> toJson() => {
    'at': at.millisecondsSinceEpoch,
    'activeLabel': activeLabel,
    'alertTitle': alertTitle,
    'alertBody': alertBody,
    'sound': sound,
  };

  factory TimerPhase.fromJson(Map<String, dynamic> json) => TimerPhase(
    at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    activeLabel: json['activeLabel'] as String,
    alertTitle: json['alertTitle'] as String,
    alertBody: json['alertBody'] as String,
    sound: json['sound'] as String,
  );
}

const _phasesDataKey = 'timer_phases';

/// Muss vor [FlutterForegroundTask.startService] aufgerufen werden --
/// übergibt die Liste kommender Phasenwechsel an den Task-Handler, da
/// dieser in einer eigenen Isolate läuft und keinen direkten Zugriff auf
/// den State des aufrufenden Screens hat.
Future<void> saveTimerPhasesForBackgroundTask(List<TimerPhase> phases) {
  return FlutterForegroundTask.saveData(
    key: _phasesDataKey,
    value: jsonEncode(phases.map((p) => p.toJson()).toList()),
  );
}

/// Einstiegspunkt für die Hintergrund-Isolate -- muss eine top-level oder
/// static Funktion mit diesem Pragma sein, sonst entfernt der Compiler sie
/// beim Tree-Shaking, weil sie nur von nativem Code aus aufgerufen wird.
@pragma('vm:entry-point')
void timerForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_TimerTaskHandler());
}

/// Läuft in der Hintergrund-Isolate, solange die App im Hintergrund ist und
/// ein Timer/Intervall aktiv ist. Zählt selbst im Sekundentakt anhand der
/// festen Ziel-Zeitpunkte (nicht durch Herunterzählen -- dadurch bleibt die
/// Anzeige auch bei kurzen System-Aussetzern korrekt) und aktualisiert die
/// Benachrichtigung, bis alle Phasen durch sind.
class _TimerTaskHandler extends TaskHandler {
  List<TimerPhase> _phases = const [];
  int _nextIndex = 0;
  int _notificationId = 9000;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await FlutterForegroundTask.getData<String>(
      key: _phasesDataKey,
    );
    if (raw == null) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    _phases = decoded
        .map((e) => TimerPhase.fromJson(e as Map<String, dynamic>))
        .toList();
    await TimerNotifications.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_phases.isEmpty) return;
    final now = DateTime.now();

    while (_nextIndex < _phases.length &&
        !_phases[_nextIndex].at.isAfter(now)) {
      final phase = _phases[_nextIndex];
      TimerNotifications.showNow(
        id: _notificationId++,
        title: phase.alertTitle,
        body: phase.alertBody,
        soundAsset: phase.sound,
      );
      _nextIndex++;
    }

    if (_nextIndex >= _phases.length) {
      FlutterForegroundTask.stopService();
      return;
    }

    final remaining = _phases[_nextIndex].at.difference(now);
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(
      2,
      '0',
    );
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(
      2,
      '0',
    );
    FlutterForegroundTask.updateService(
      notificationTitle: _phases[_nextIndex].activeLabel,
      notificationText: '$minutes:$seconds',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _phases = const [];
    _nextIndex = 0;
  }
}
