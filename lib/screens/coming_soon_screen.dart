import 'package:flutter/material.dart';

/// Platzhalter für Module, die noch nicht gebaut sind (Kraftübungen,
/// Trainingsplan, Logbuch) -- vermeidet Navigations-Sackgassen, ohne dass
/// jedes Modul schon eine echte Implementierung braucht.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Bald verfügbar',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
