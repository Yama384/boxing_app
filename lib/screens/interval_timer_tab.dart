import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../time_format.dart';
import '../widgets/circular_timer_display.dart';

enum _Phase { round, pause }

class IntervalTimerTab extends StatefulWidget {
  const IntervalTimerTab({super.key});

  @override
  State<IntervalTimerTab> createState() => _IntervalTimerTabState();
}

class _IntervalTimerTabState extends State<IntervalTimerTab>
    with SingleTickerProviderStateMixin {
  final _roundsController = TextEditingController(text: '3');
  final _roundMinutesController = TextEditingController(text: '3');
  final _roundSecondsController = TextEditingController(text: '00');
  final _pauseMinutesController = TextEditingController(text: '1');
  final _pauseSecondsController = TextEditingController(text: '00');
  final _audioPlayer = AudioPlayer();

  late final AnimationController _ringController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  late final Animation<double> _ringProgress = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(_ringController);

  Timer? _timer;
  int _totalRounds = 3;
  int _roundDuration = 3 * 60;
  int _pauseDuration = 60;

  int _currentRound = 1;
  _Phase _phase = _Phase.round;
  int _remainingSeconds = 3 * 60;

  bool _isRunning = false;
  bool _hasStarted = false;
  bool _isFinished = false;

  bool get _canEditSettings => !_isRunning && !_hasStarted;

  void _start() {
    if (_isRunning) return;

    if (!_hasStarted) {
      final rounds = int.tryParse(_roundsController.text) ?? 0;
      final roundMinutes = int.tryParse(_roundMinutesController.text) ?? 0;
      final roundSeconds = int.tryParse(_roundSecondsController.text) ?? 0;
      final pauseMinutes = int.tryParse(_pauseMinutesController.text) ?? 0;
      final pauseSeconds = int.tryParse(_pauseSecondsController.text) ?? 0;

      final roundDuration = roundMinutes * 60 + roundSeconds;
      if (rounds <= 0 || roundDuration <= 0) return;

      _totalRounds = rounds;
      _roundDuration = roundDuration;
      _pauseDuration = pauseMinutes * 60 + pauseSeconds;
      _currentRound = 1;
      _phase = _Phase.round;
      _remainingSeconds = roundDuration;
      _ringController
        ..duration = Duration(seconds: roundDuration)
        ..value = 0;
    }

    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });

    _ringController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _advancePhase(timer);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _advancePhase(Timer timer) {
    if (_phase == _Phase.round && _currentRound >= _totalRounds) {
      timer.cancel();
      _ringController.stop();
      setState(() {
        _remainingSeconds = 0;
        _isRunning = false;
        _isFinished = true;
      });
      _playAlert();
      return;
    }

    _playAlert();

    final int nextPhaseDuration;
    if (_phase == _Phase.round) {
      if (_pauseDuration > 0) {
        nextPhaseDuration = _pauseDuration;
        setState(() {
          _phase = _Phase.pause;
          _remainingSeconds = _pauseDuration;
        });
      } else {
        nextPhaseDuration = _roundDuration;
        setState(() {
          _currentRound++;
          _phase = _Phase.round;
          _remainingSeconds = _roundDuration;
        });
      }
    } else {
      nextPhaseDuration = _roundDuration;
      setState(() {
        _currentRound++;
        _phase = _Phase.round;
        _remainingSeconds = _roundDuration;
      });
    }

    _ringController
      ..duration = Duration(seconds: nextPhaseDuration)
      ..value = 0
      ..forward();
  }

  void _pause() {
    _timer?.cancel();
    _ringController.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    _ringController
      ..stop()
      ..value = 0;
    setState(() {
      _isRunning = false;
      _hasStarted = false;
      _isFinished = false;
      _currentRound = 1;
      _phase = _Phase.round;
      _remainingSeconds = _roundDuration;
    });
  }

  Future<void> _playAlert() async {
    if (!AppSettings.soundEnabled.value) return;
    await _audioPlayer.play(AssetSource('sounds/bell.wav'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _roundsController.dispose();
    _roundMinutesController.dispose();
    _roundSecondsController.dispose();
    _pauseMinutesController.dispose();
    _pauseSecondsController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  static const _timeFontWeight = FontWeight.bold;
  static const _timeFontFeatures = [FontFeature.tabularFigures()];

  Widget _buildSettingsInput(BuildContext context, AppStrings s) {
    final color = Theme.of(context).colorScheme.primary;
    final labelStyle = TextStyle(fontSize: 14, color: Colors.grey.shade400);
    final fieldStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color);

    Widget numberField(TextEditingController controller, double width) {
      return SizedBox(
        width: width,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: fieldStyle,
          decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
        ),
      );
    }

    return Column(
      children: [
        Text(s('rounds'), style: labelStyle),
        const SizedBox(height: 4),
        numberField(_roundsController, 70),
        const SizedBox(height: 24),
        Text(s('roundDuration'), style: labelStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            numberField(_roundMinutesController, 70),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: fieldStyle)),
            numberField(_roundSecondsController, 70),
          ],
        ),
        const SizedBox(height: 24),
        Text(s('pause'), style: labelStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            numberField(_pauseMinutesController, 70),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: fieldStyle)),
            numberField(_pauseSecondsController, 70),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPause = _phase == _Phase.pause;
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        final numberColor = _isFinished
            ? Colors.red
            : (isPause ? Colors.blueAccent : Theme.of(context).colorScheme.primary);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_canEditSettings)
                _buildSettingsInput(context, s)
              else ...[
                Text(
                  _isFinished
                      ? s('trainingDone')
                      : (isPause ? s('pause') : '${s('round')} $_currentRound / $_totalRounds'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isPause ? Colors.blueAccent : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                CircularTimerDisplay(
                  progress: _ringProgress,
                  color: numberColor,
                  child: Text(
                    formatSeconds(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: _timeFontWeight,
                      fontFeatures: _timeFontFeatures,
                      color: numberColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isFinished ? null : (_isRunning ? _pause : _start),
                    child: Text(_isRunning ? s('pause') : s('start')),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _reset,
                    child: Text(s('reset')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
