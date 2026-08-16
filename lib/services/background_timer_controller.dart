import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:live_activities/live_activities.dart';
import 'timer_foreground_task.dart';
import 'timer_notifications.dart';

/// Muss mit der App Group ID übereinstimmen, die beim manuellen Xcode-Setup
/// für die Widget Extension vergeben wird (siehe ios/LIVE_ACTIVITY_SETUP.md).
const _liveActivityAppGroupId = 'group.com.example.boxingApp.timer';

/// Koordiniert, was passiert, wenn ein laufender Timer/Intervall in den
/// Hintergrund geht bzw. wieder in den Vordergrund kommt:
/// - Android: startet einen Vordergrunddienst mit laufend aktualisierter
///   Benachrichtigung (zuverlässig, App-Prozess bleibt aktiv).
/// - iOS: plant lokale Benachrichtigungen für jeden kommenden Phasenwechsel,
///   da eigener Code dort nicht zuverlässig im Hintergrund weiterlaufen kann.
///
/// Bewusst nicht als Ersatz für die App-eigene Anzeige gedacht: sobald die
/// App wieder im Vordergrund ist, übernimmt sie die Anzeige wieder selbst
/// (Restzeit wird aus dem gespeicherten Ziel-Zeitpunkt neu berechnet, nicht
/// weitergezählt) -- [leaveBackground] räumt dann alle Hintergrund-Spuren
/// wieder auf.
class BackgroundTimerController {
  BackgroundTimerController._();

  static bool _foregroundTaskInitialized = false;

  static final _liveActivities = LiveActivities();
  static bool _liveActivitiesInitialized = false;
  static String? _activeActivityId;

  static Future<void> _initLiveActivitiesIfNeeded() async {
    if (_liveActivitiesInitialized) return;
    _liveActivitiesInitialized = true;
    await _liveActivities.init(appGroupId: _liveActivityAppGroupId);
  }

  static void _initForegroundTaskIfNeeded() {
    if (_foregroundTaskInitialized) return;
    _foregroundTaskInitialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'timer_service',
        channelName: 'Laufender Timer',
        channelDescription:
            'Zeigt die verbleibende Zeit, während die App im Hintergrund ist',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  /// Muss einmal aufgerufen werden, bevor irgendeine Kommunikation mit dem
  /// Hintergrunddienst stattfindet (z.B. in main()).
  static void initApp() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Fragt die nötigen Berechtigungen ab -- bewusst erst beim ersten
  /// Timer-Start aufrufen, nicht automatisch bei App-Start, damit der
  /// Nutzer den Zusammenhang sieht.
  static Future<void> requestPermissions() async {
    await TimerNotifications.requestPermission();
    if (Platform.isAndroid) {
      final permission = await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    }
  }

  static Future<void> enterBackground(List<TimerPhase> phases) async {
    if (phases.isEmpty) return;

    if (Platform.isAndroid) {
      _initForegroundTaskIfNeeded();
      await saveTimerPhasesForBackgroundTask(phases);
      final first = phases.first;
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: first.activeLabel,
        notificationText: _formatDuration(first.at.difference(DateTime.now())),
        callback: timerForegroundTaskCallback,
      );
    } else {
      for (var i = 0; i < phases.length; i++) {
        await TimerNotifications.schedule(
          id: 9000 + i,
          title: phases[i].alertTitle,
          body: phases[i].alertBody,
          at: phases[i].at,
          soundAsset: phases[i].sound,
        );
      }
      if (Platform.isIOS) {
        await _startLiveActivity(phases.first);
      }
    }
  }

  /// Startet die Sperrbildschirm-/Dynamic-Island-Anzeige für die aktuelle
  /// Phase. Der Countdown selbst tickt danach nativ in SwiftUI weiter
  /// (`Text(timerInterval:)`), ohne dass die App im Hintergrund laufen
  /// müsste. Einschränkung ohne eigenen Push-Server: bei einem
  /// Intervall-Timer mit mehreren Phasen wechselt die angezeigte
  /// Phasen-Beschriftung (z.B. "Runde 1/2" -> "Pause") während die App im
  /// Hintergrund ist NICHT automatisch mit -- nur die Zahl zählt korrekt
  /// weiter. Beim nächsten App-Start/Vordergrund wird sie wieder korrekt.
  static Future<void> _startLiveActivity(TimerPhase current) async {
    await _initLiveActivitiesIfNeeded();
    if (!await _liveActivities.areActivitiesEnabled()) return;
    _activeActivityId = await _liveActivities.createActivity(
      'boxing_app_timer',
      {
        'label': current.activeLabel,
        'endTimeMillis': current.at.millisecondsSinceEpoch,
      },
      iOSEnableRemoteUpdates: false,
    );
  }

  /// Aufräumen, wenn die App wieder im Vordergrund ist oder der Timer
  /// manuell pausiert/zurückgesetzt wird -- unabhängig davon, ob gerade
  /// überhaupt etwas im Hintergrund lief (dann sind die Aufrufe No-Ops).
  static Future<void> leaveBackground() async {
    await TimerNotifications.cancelAll();
    if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    if (Platform.isIOS && _activeActivityId != null) {
      await _liveActivities.endActivity(_activeActivityId!);
      _activeActivityId = null;
    }
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
