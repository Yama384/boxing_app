import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';

/// Platzhalter für Module, die noch nicht gebaut sind (Kraftübungen,
/// Trainingsplan, Logbuch) -- vermeidet Navigations-Sackgassen, ohne dass
/// jedes Modul schon eine echte Implementierung braucht.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.titleKey, required this.icon});

  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          appBar: AppBar(title: Text(s(titleKey))),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  s('comingSoon'),
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
