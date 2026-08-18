import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-weite Einstellungen, persistiert über SharedPreferences -- gleiches
/// Muster wie LogbookData/StrengthData/TrainingPlanData. Ein ValueNotifier
/// pro Einstellung reicht für diesen Umfang -- kein State-Management-Paket
/// (Provider/Riverpod) nötig. Jeder Screen, der einen dieser Notifier mit
/// ValueListenableBuilder beobachtet, aktualisiert sich automatisch, wenn
/// sich der Wert ändert. Änderungen laufen über setSeedColor/setSoundEnabled/
/// setLocale statt direkter `.value =`-Zuweisung, damit sie dabei gleich
/// gespeichert werden.
class AppSettings {
  AppSettings._();

  static const _seedColorKey = 'app_settings_seed_color';
  static const _soundEnabledKey = 'app_settings_sound_enabled';
  static const _localeKey = 'app_settings_locale';

  static final ValueNotifier<Color> seedColor = ValueNotifier<Color>(Colors.redAccent);
  static final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('de'));

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    final colorValue = prefs.getInt(_seedColorKey);
    if (colorValue != null) seedColor.value = Color(colorValue);

    final sound = prefs.getBool(_soundEnabledKey);
    if (sound != null) soundEnabled.value = sound;

    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) locale.value = Locale(localeCode);
  }

  static Future<void> setSeedColor(Color color) async {
    seedColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  static Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }
}
