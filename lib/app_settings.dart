import 'package:flutter/material.dart';

/// App-weite Einstellungen. Ein ValueNotifier pro Einstellung reicht für
/// diesen Umfang -- kein State-Management-Paket (Provider/Riverpod) nötig.
/// Jeder Screen, der einen dieser Notifier mit ValueListenableBuilder
/// beobachtet, aktualisiert sich automatisch, wenn sich der Wert ändert.
class AppSettings {
  AppSettings._();

  static final ValueNotifier<Color> seedColor = ValueNotifier<Color>(Colors.redAccent);
  static final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('de'));
}
