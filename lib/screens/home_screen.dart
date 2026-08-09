import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import 'coming_soon_screen.dart';
import 'settings_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    s('appTitle').toUpperCase(),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s('tagline'),
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _ModuleCard(
                          icon: Icons.timer,
                          label: s('timer'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TimerScreen()),
                          ),
                        ),
                        _ModuleCard(
                          icon: Icons.fitness_center,
                          label: s('strength'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ComingSoonScreen(
                                titleKey: 'strength',
                                icon: Icons.fitness_center,
                              ),
                            ),
                          ),
                        ),
                        _ModuleCard(
                          icon: Icons.event_note,
                          label: s('trainingPlan'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ComingSoonScreen(
                                titleKey: 'trainingPlan',
                                icon: Icons.event_note,
                              ),
                            ),
                          ),
                        ),
                        _ModuleCard(
                          icon: Icons.menu_book,
                          label: s('logbook'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ComingSoonScreen(
                                titleKey: 'logbook',
                                icon: Icons.menu_book,
                              ),
                            ),
                          ),
                        ),
                        _ModuleCard(
                          icon: Icons.settings,
                          label: s('settings'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 44,
                color: primary,
                shadows: [
                  Shadow(color: primary.withValues(alpha: 0.45), blurRadius: 10),
                  Shadow(color: primary.withValues(alpha: 0.2), blurRadius: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
