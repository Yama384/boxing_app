import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'interval_timer_tab.dart';
import 'simple_timer_tab.dart';
import 'stopwatch_tab.dart';

enum _TimerMode { stopwatch, simple, interval }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  _TimerMode _mode = _TimerMode.stopwatch;

  Widget _buildBody() {
    switch (_mode) {
      case _TimerMode.stopwatch:
        return const StopwatchTab();
      case _TimerMode.simple:
        return const SimpleTimerTab();
      case _TimerMode.interval:
        return const IntervalTimerTab();
    }
  }

  Widget _segmentLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: CupertinoSlidingSegmentedControl<_TimerMode>(
                groupValue: _mode,
                backgroundColor: const Color(0xFF1C1C1E),
                thumbColor: Theme.of(context).colorScheme.primary,
                children: {
                  _TimerMode.stopwatch: _segmentLabel('Stoppuhr'),
                  _TimerMode.simple: _segmentLabel('Timer'),
                  _TimerMode.interval: _segmentLabel('Intervalle'),
                },
                onValueChanged: (value) {
                  if (value != null) setState(() => _mode = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
