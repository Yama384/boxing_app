import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _colorOptions = <String, Color>{
    'colorRed': Colors.redAccent,
    'colorGreen': Color.fromARGB(255, 0, 200, 103),
    'colorBlue': Colors.blueAccent,
    'colorOrange': Colors.orangeAccent,
    'colorPurple': Colors.purpleAccent,
    'colorTeal': Colors.tealAccent,
  };

  static const _languageOptions = <String, Locale>{
    'Deutsch': Locale('de'),
    'English': Locale('en'),
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          appBar: AppBar(title: Text(s('settings'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                s('language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: _languageOptions.entries.map((entry) {
                  final isSelected = entry.value == locale;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    onSelected: (_) => AppSettings.setLocale(entry.value),
                  );
                }).toList(),
              ),
              const Divider(height: 48),
              Text(
                s('colorDesign'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s('colorDesignSubtitle'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<Color>(
                valueListenable: AppSettings.seedColor,
                builder: (context, selectedColor, _) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: _colorOptions.entries.map((entry) {
                      final isSelected = entry.value == selectedColor;
                      return GestureDetector(
                        onTap: () => AppSettings.setSeedColor(entry.value),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(s(entry.key), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const Divider(height: 48),
              Text(
                s('timer'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.soundEnabled,
                builder: (context, enabled, _) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s('soundToggleTitle')),
                    subtitle: Text(s('soundToggleSubtitle')),
                    value: enabled,
                    onChanged: (value) => AppSettings.setSoundEnabled(value),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
