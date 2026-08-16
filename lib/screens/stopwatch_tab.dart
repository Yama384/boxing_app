import 'dart:async';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../services/background_timer_controller.dart';
import '../time_format.dart';
import '../widgets/circular_timer_display.dart';

class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> with WidgetsBindingObserver {
  Timer? _timer;

  // Wie bei den anderen Tabs: verstrichene Zeit wird aus einem festen
  // Start-Zeitpunkt neu berechnet statt hochgezählt, damit sie auch nach
  // einem Aufenthalt im Hintergrund (wo der Dart-Timer nicht zuverlässig
  // weiterläuft) exakt stimmt. _baseSeconds sammelt die Zeit aus bereits
  // abgeschlossenen Lauf-Abschnitten vor einer Pause.
  int _baseSeconds = 0;
  DateTime? _segmentStart;
  bool _isRunning = false;

  int get _seconds {
    if (_isRunning && _segmentStart != null) {
      return _baseSeconds + DateTime.now().difference(_segmentStart!).inSeconds;
    }
    return _baseSeconds;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) return;
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {});
      _startTicking();
    }
  }

  void _start() {
    if (_isRunning) return;
    BackgroundTimerController.requestPermissions();
    _segmentStart = DateTime.now();
    setState(() => _isRunning = true);

    final s = AppStrings.of(AppSettings.locale.value);
    BackgroundTimerController.startStopwatchLiveActivity(
      s('stopwatch'),
      _segmentStart!.subtract(Duration(seconds: _baseSeconds)),
    );

    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  void _pause() {
    _baseSeconds = _seconds;
    _segmentStart = null;
    _timer?.cancel();
    BackgroundTimerController.endLiveActivity();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    BackgroundTimerController.endLiveActivity();
    setState(() {
      _isRunning = false;
      _baseSeconds = 0;
      _segmentStart = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularTimerDisplay(
                progress: const AlwaysStoppedAnimation(1.0),
                child: Text(
                  formatSeconds(_seconds),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRunning ? _pause : _start,
                    child: Text(_isRunning ? s('pause') : s('start')),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(onPressed: _reset, child: Text(s('reset'))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
