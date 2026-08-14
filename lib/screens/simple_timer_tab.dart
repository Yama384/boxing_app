import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../max_value_text_input_formatter.dart';
import '../time_format.dart';
import '../widgets/circular_timer_display.dart';

class SimpleTimerTab extends StatefulWidget {
  const SimpleTimerTab({super.key});

  @override
  State<SimpleTimerTab> createState() => _SimpleTimerTabState();
}

class _SimpleTimerTabState extends State<SimpleTimerTab>
    with SingleTickerProviderStateMixin {
  final _minutesController = TextEditingController(text: '3');
  final _secondsController = TextEditingController(text: '00');
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
      _ringController
        ..duration = Duration(seconds: total)
        ..value = 0;
    }

    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });

    _ringController.forward();

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
    _ringController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  static const _timeFontWeight = FontWeight.bold;
  static const _timeFontFeatures = [FontFeature.tabularFigures()];
  // Ohne festen height/strutStyle sitzen die Ziffern durch die
  // Schrift-Metrik (Ascent/Descent) nicht exakt in der Zeilenmitte und
  // wirken dadurch im Kreis nach oben verschoben.
  static const _timeFontHeight = 1.0;
  static const _timeStrutStyle = StrutStyle(
    fontSize: 56,
    height: 1,
    forceStrutHeight: true,
  );

  Widget _buildTimeInput(BuildContext context) {
    final editableColor = Theme.of(context).colorScheme.primary;
    final editStyle = TextStyle(
      fontSize: 56,
      height: _timeFontHeight,
      fontWeight: _timeFontWeight,
      fontFeatures: _timeFontFeatures,
      color: editableColor,
    );
    // Feste Pixelbreiten für die Eingabefelder sind Rätselraten -- die
    // tatsächliche Breite von "00" hängt vom Font-Rendering des jeweiligen
    // Geräts ab. Stattdessen die Breite direkt aus dem Style ausmessen und
    // etwas Puffer für Cursor/Kerning dazugeben.
    final digitsPainter = TextPainter(
      text: TextSpan(text: '00', style: editStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final fieldWidth = digitsPainter.width + 24;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            strutStyle: _timeStrutStyle,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 2),
              border: UnderlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(':', style: editStyle, strutStyle: _timeStrutStyle),
        ),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: _secondsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            strutStyle: _timeStrutStyle,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
              const MaxValueTextInputFormatter(59),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 2),
              border: UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        final numberColor = _isFinished
            ? Colors.red
            : Theme.of(context).colorScheme.primary;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularTimerDisplay(
                progress: _ringProgress,
                color: numberColor,
                child: _canEditTime
                    ? _buildTimeInput(context)
                    : Text(
                        formatSeconds(_remainingSeconds),
                        textAlign: TextAlign.center,
                        strutStyle: _timeStrutStyle,
                        style: TextStyle(
                          fontSize: 56,
                          height: _timeFontHeight,
                          fontWeight: _timeFontWeight,
                          fontFeatures: _timeFontFeatures,
                          color: numberColor,
                        ),
                      ),
              ),
              if (_isFinished)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s('timeUp'),
                    style: const TextStyle(fontSize: 20, color: Colors.red),
                  ),
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isFinished
                        ? null
                        : (_isRunning ? _pause : _start),
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
