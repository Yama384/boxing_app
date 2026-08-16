import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// System-Benachrichtigungen für Runden-/Timer-Ende -- der Teil, der
/// zuverlässig auslöst, selbst wenn die App im Hintergrund ist oder (auf
/// iOS) gar keinen eigenen Code mehr ausführen darf. Alle Zeitpunkte sind
/// relative Kurzzeitspannen (Minuten), daher genügt UTC als Referenz --
/// die tatsächliche Zeitzone des Geräts spielt für "in 3 Minuten" keine
/// Rolle, nur bei Kalenderrechnung über Tage/DST-Grenzen hinweg.
class TimerNotifications {
  TimerNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'timer_alerts';
  static const _channelName = 'Timer-Benachrichtigungen';
  static const _channelDescription = 'Runden-, Pausen- und Timer-Ende';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
  }

  /// Muss vor dem ersten Start eines Timers aufgerufen werden (z.B. beim
  /// Antippen von "Start"), nicht automatisch bei App-Start -- sonst sieht
  /// der Nutzer die Berechtigungsabfrage ohne erkennbaren Zusammenhang.
  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  static NotificationDetails _detailsFor(String soundAsset) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundAsset),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: '$soundAsset.wav',
        ),
      );

  /// Feuert sofort -- genutzt vom Android-Vordergrunddienst, der selbst im
  /// Sekundentakt läuft und den richtigen Moment daher direkt erkennt,
  /// statt sich auf eine vom Betriebssystem verwaltete geplante
  /// Benachrichtigung zu verlassen.
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String soundAsset,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _detailsFor(soundAsset),
    );
  }

  /// Plant eine Benachrichtigung für einen Zeitpunkt in der Zukunft --
  /// genutzt auf iOS, wo kein eigener Code zuverlässig im Hintergrund
  /// laufen kann, um den richtigen Moment selbst zu erkennen.
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String soundAsset,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _detailsFor(soundAsset),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  static Future<void> cancelAll() => _plugin.cancelAll();
}
