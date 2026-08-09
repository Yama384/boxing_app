import 'package:flutter/material.dart';
import '../app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _colorOptions = <String, Color>{
    'Rot': Colors.redAccent,
    'Grün': Color.fromARGB(255, 0, 200, 103),
    'Blau': Colors.blueAccent,
    'Orange': Colors.orangeAccent,
    'Lila': Colors.purpleAccent,
    'Türkis': Colors.tealAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Farbdesign',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Standard: Rot -- wähle deine eigene Akzentfarbe',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<Color>(
            valueListenable: AppSettings.seedColor,
            builder: (context, selected, _) {
              return Wrap(
                spacing: 20,
                runSpacing: 16,
                children: _colorOptions.entries.map((entry) {
                  final isSelected = entry.value == selected;
                  return GestureDetector(
                    onTap: () => AppSettings.seedColor.value = entry.value,
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
                        Text(entry.key, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(height: 48),
          const Text(
            'Timer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.soundEnabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Signalton bei Zeitablauf'),
                subtitle: const Text(
                  'Boxglocke abspielen, wenn der Timer abläuft',
                ),
                value: enabled,
                onChanged: (value) => AppSettings.soundEnabled.value = value,
              );
            },
          ),
        ],
      ),
    );
  }
}
