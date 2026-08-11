import 'package:flutter/material.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppSettings.seedColor,
      builder: (context, seedColor, _) {
        return MaterialApp(
          title: 'Boxing App',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
