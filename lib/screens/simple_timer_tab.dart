import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../max_value_text_input_formatter.dart';
import '../services/background_timer_controller.dart';
import '../services/timer_foreground_task.dart';
import '../time_format.dart';
import '../widgets/circular_timer_display.dart';

class SimpleTimerTab extends StatefulWidget {
  const SimpleTimerTab({super.key});

  @override
  State<SimpleTimerTab> createState() => _SimpleTimerTabState();
}

class _SimpleTimerTabState extends State<SimpleTimerTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _minutesController = TextEditingController(text: '03');
  final _secondsController = TextEditingController(text: '00');
  final _minutesFocus = FocusNode();
  final _secondsFocus = FocusNode();
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

  // Ziel-Zeitpunkt statt Countdown-Zähler: die verbleibende Zeit wird immer
  // aus der aktuellen Uhrzeit neu berechnet, statt Sekunde für Sekunde
  // heruntergezählt. Dadurch bleibt die Anzeige exakt, auch wenn die App
  // zwischenzeitlich im Hintergrund war (kurz angehalten oder komplett
  // pausiert) -- ein reiner Zähler würde in der Zeit einfach stehen bleiben.
  DateTime? _endTime;
  int _remainingSeconds = 3 * 60;
  bool _isRunning = false;
  bool _hasStarted = false;

  bool get _isFinished => _hasStarted && _remainingSeconds == 0;
  bool get _canEditTime => !_isRunning && !_hasStarted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _minutesFocus.addListener(
      () => _padOnBlur(_minutesFocus, _minutesController),
    );
    _secondsFocus.addListener(
      () => _padOnBlur(_secondsFocus, _secondsController),
    );
  }

  // Zeigt einstellige Eingaben (z.B. "3") beim Verlassen des Felds
  // zweistellig an ("03") -- passend zur laufenden Anzeige, die über
  // formatSeconds() immer zweistellig ist.
  void _padOnBlur(FocusNode node, TextEditingController controller) {
    if (node.hasFocus) return;
    if (controller.text.length == 1) {
      controller.text = controller.text.padLeft(2, '0');
    } else if (controller.text.isEmpty) {
      controller.text = '00';
    }
  }

  // App geht in den Hintergrund (Sperrbildschirm, Home-Taste, App-Wechsel)
  // oder kommt zurück -- läuft gerade ein Timer, übernimmt currently ein
  // Vordergrunddienst/geplante Benachrichtigung die Anzeige/den Alarm, bis
  // die App wieder sichtbar ist (siehe BackgroundTimerController).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning || _endTime == null) return;
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      final s = AppStrings.of(AppSettings.locale.value);
      BackgroundTimerController.enterBackground([
        TimerPhase(
          at: _endTime!,
          activeLabel: s('timer'),
          alertTitle: s('timeUp'),
          alertBody: s('timer'),
          sound: 'bell',
        ),
      ]);
    } else if (state == AppLifecycleState.resumed) {
      BackgroundTimerController.leaveBackground();
      _syncFromEndTime();
      if (_remainingSeconds > 0) _startTicking();
    }
  }

  void _start() {
    if (_isRunning) return;
    BackgroundTimerController.requestPermissions();

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

    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });

    _ringController.forward();
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      setState(() {
        _remainingSeconds = 0;
        _isRunning = false;
      });
      _playAlert();
    } else {
      setState(() => _remainingSeconds = remaining);
    }
  }

  // Nach Rückkehr aus dem Hintergrund: verbleibende Zeit aus dem
  // gespeicherten Ziel-Zeitpunkt neu berechnen statt weiterzuzählen. Kein
  // erneuter _playAlert() beim Übergang in den fertigen Zustand hier --
  // falls der Timer während des Hintergrunds abgelaufen ist, hat die
  // Benachrichtigung den Ton bereits gespielt.
  void _syncFromEndTime() {
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    setState(() {
      if (remaining <= 0) {
        _remainingSeconds = 0;
        _isRunning = false;
        _ringController.value = 1;
      } else {
        _remainingSeconds = remaining;
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _ringController.stop();
    BackgroundTimerController.leaveBackground();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    _ringController
      ..stop()
      ..value = 0;
    BackgroundTimerController.leaveBackground();
    _endTime = null;
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ringController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocus.dispose();
    _secondsFocus.dispose();
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
    // Das globale InputDecorationTheme (main.dart) füllt Textfelder mit
    // einer abgerundeten Box -- passend für Dialoge, aber hier groß genug,
    // um den Fortschrittsring im Hintergrund komplett zu verdecken. Für die
    // Ziffern im Ring wird deshalb explizit auf den schlichten Unterstrich
    // zurückgesetzt (filled:false + eigene enabled/focusedBorder), statt die
    // Theme-Defaults zu erben.
    final timeInputDecoration = InputDecoration(
      isDense: true,
      filled: false,
      contentPadding: const EdgeInsets.only(bottom: 2),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: editableColor, width: 2),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: _minutesController,
            focusNode: _minutesFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            strutStyle: _timeStrutStyle,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: timeInputDecoration,
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
            focusNode: _secondsFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: editStyle,
            strutStyle: _timeStrutStyle,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
              const MaxValueTextInputFormatter(59),
            ],
            decoration: timeInputDecoration,
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
