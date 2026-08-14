import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../coach_guide.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
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
  static const _introId = 'timer_intro';
  final _modeSwitchKey = GlobalKey();

  _TimerMode _mode = _TimerMode.stopwatch;

  @override
  void initState() {
    super.initState();
    if (!CoachGuide.hasSeen(_introId)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startTour();
      });
    }
  }

  // showCoachTour() wird hier bewusst direkt aufgerufen statt in einem
  // addPostFrameCallback: _startTour() läuft entweder aus dem Future.delayed
  // in initState() (der Baum ist da längst gebaut) oder aus einem direkten
  // Tap auf das Guide-Icon -- letzterer löst selbst kein setState/keinen
  // neuen Frame aus, wodurch der Callback sonst erst beim nächsten
  // zufälligen Rebuild feuert (Tour erscheint verzögert oder gar nicht).
  void _startTour() {
    CoachGuide.markSeen(_introId);
    final s = AppStrings.of(AppSettings.locale.value);
    showCoachTour(
      context,
      steps: [
        CoachTourStep(
          anchorKey: _modeSwitchKey,
          message: s('coachTourTimerModes'),
        ),
      ],
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
  }

  // IndexedStack statt eines Switches: die drei Tabs bleiben beim Umschalten
  // dauerhaft gemountet, statt bei jedem Wechsel disposed und neu gebaut zu
  // werden (inkl. AnimationController/Timer-Neuaufbau). Das macht den
  // Tab-Wechsel spürbar flüssiger und lässt eine laufende Stoppuhr/einen
  // laufenden Timer im Hintergrund weiterlaufen, statt sie zurückzusetzen.
  Widget _buildBody() {
    return IndexedStack(
      index: _mode.index,
      children: const [StopwatchTab(), SimpleTimerTab(), IntervalTimerTab()],
    );
  }

  Widget _segmentLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          appBar: AppBar(
            title: Text(s('timer')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: CoachAvatarIcon(onTap: _startTour)),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: CupertinoSlidingSegmentedControl<_TimerMode>(
                    key: _modeSwitchKey,
                    groupValue: _mode,
                    backgroundColor: const Color(0xFF1C1C1E),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    children: {
                      _TimerMode.stopwatch: _segmentLabel(s('stopwatch')),
                      _TimerMode.simple: _segmentLabel(s('timer')),
                      _TimerMode.interval: _segmentLabel(s('interval')),
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
      },
    );
  }
}
