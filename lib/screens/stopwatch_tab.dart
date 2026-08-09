import 'dart:async';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../time_format.dart';
import '../widgets/circular_timer_display.dart';

class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _seconds = 0;
    });
  }

  @override
  void dispose() {
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
