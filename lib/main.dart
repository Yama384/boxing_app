import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'achievements_data.dart';
import 'app_settings.dart';
import 'coach_guide.dart';
import 'logbook_data.dart';
import 'screens/home_screen.dart';
import 'strength_data.dart';
import 'training_plan_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogbookData.load();
  await StrengthData.load();
  await TrainingPlanData.load();
  await CoachGuide.load();
  await AchievementsData.load();
  runApp(const MyApp());
}

/// `.SF Pro Text` ist kein gebündelter Font, sondern ein von iOS/macOS
/// reservierter Systemschrift-Name -- Flutter löst ihn dort automatisch zur
/// echten San-Francisco-Schrift auf. Auf anderen Plattformen bleibt die
/// Standard-Materialschrift (Roboto), da der Name dort ins Leere liefe.
bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppSettings.seedColor,
      builder: (context, seedColor, _) {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          title: 'Boxing App',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: colorScheme,
            fontFamily: _isApplePlatform ? '.SF Pro Text' : null,
            // Kein Material-Ripple beim Antippen -- iOS kennt keine
            // ausbreitenden Kreise, nur ein dezentes Abdunkeln/Aufhellen der
            // gedrückten Fläche.
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.white.withValues(alpha: 0.06),
            // Ohne globales Theme fallen TextFields ohne eigene Decoration
            // (z.B. in AlertDialogs) auf Materials Standard-Unterstrich
            // zurück -- optisch der auffälligste "Android"-Marker. Abgerundet
            // + gefüllt passt zu den Feldern, die im Rest der App schon
            // manuell so gestylt sind.
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
