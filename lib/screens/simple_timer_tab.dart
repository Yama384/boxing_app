import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../time_format.dart';

class SimpleTimerTab extends StatefulWidget {
  const SimpleTimerTab({super.key});

  @override
  State<SimpleTimerTab> createState() => _SimpleTimerTabState();
}

class _SimpleTimerTabState extends State<SimpleTimerTab> {
  final _minutesController = TextEditingController(text: '3');
  final _secondsController = TextEditingController(text: '00');
  final _audioPlayer = AudioPlayer();

  Timer? _timer;
  int _totalSeconds = 3 * 60;
  int _remainingSeconds = 3 * 60;
  bool _isRunning = false;
  bool _hasStarted = false;

  bool get _isFinished => _hasStarted && _remainingSeconds == 0;
  bool get _canEditTime => !_isRunning && !_hasStarted;

  void _start() {
    if (_isRunning) return;

    if (!_hasStarted) {
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;
      final total = minutes * 60 + seconds;
      if (total <= 0) return;
      _totalSeconds = total;
      _remainingSeconds = total;
    }

    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        _playAlert();
      } else {
        setState(() => _remainingSeconds--);
      }
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
      _hasStarted = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  Future<void> _playAlert() async {
    if (!AppSettings.soundEnabled.value) return;
    await _audioPlayer.play(AssetSource('sounds/bell.wav'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minutesController.dispose();
    _secondsController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  static const _timeFontSize = 72.0;
  static const _timeFontWeight = FontWeight.bold;
  static const _timeFontFeatures = [FontFeature.tabularFigures()];

  Widget _buildTimeInput(BuildContext context) {
    final editableColor = Theme.of(context).colorScheme.primary;
    final editStyle = TextStyle(
      fontSize: _timeFontSize,
      fontWeight: _timeFontWeight,
      fontFeatures: _timeFontFeatures,
      color: editableColor,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: editStyle),
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _secondsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_canEditTime)
            _buildTimeInput(context)
          else
            Text(
              formatSeconds(_remainingSeconds),
              style: TextStyle(
                fontSize: _timeFontSize,
                fontWeight: _timeFontWeight,
                fontFeatures: _timeFontFeatures,
                color: _isFinished ? Colors.red : null,
              ),
            ),
          if (_isFinished)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Zeit abgelaufen!',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
            ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isFinished ? null : (_isRunning ? _pause : _start),
                child: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
