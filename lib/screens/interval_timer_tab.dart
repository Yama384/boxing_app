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

enum _Phase { round, pause }

/// Rein rechnerischer Phasenübergang ohne Seiteneffekt: was kommt nach
/// [phase]/[round]? `null` heißt, das Training ist damit beendet. Wird
/// sowohl von der Live-Anzeige (_advancePhase) als auch von der
/// Vorausberechnung für den Hintergrund-Dienst (_computeRemainingPhases)
/// genutzt, damit beide niemals auseinanderlaufen können.
class _Step {
  const _Step({
    required this.phase,
    required this.round,
    required this.durationSeconds,
  });

  final _Phase phase;
  final int round;
  final int durationSeconds;
}

class IntervalTimerTab extends StatefulWidget {
  const IntervalTimerTab({super.key});

  @override
  State<IntervalTimerTab> createState() => _IntervalTimerTabState();
}

class _IntervalTimerTabState extends State<IntervalTimerTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _roundsController = TextEditingController(text: '3');
  final _roundMinutesController = TextEditingController(text: '03');
  final _roundSecondsController = TextEditingController(text: '00');
  final _pauseMinutesController = TextEditingController(text: '01');
  final _pauseSecondsController = TextEditingController(text: '00');
  final _roundMinutesFocus = FocusNode();
  final _roundSecondsFocus = FocusNode();
  final _pauseMinutesFocus = FocusNode();
  final _pauseSecondsFocus = FocusNode();
  final _audioPlayer = AudioPlayer();

  late final AnimationController _ringController;
  late final Animation<double> _ringProgress;

  Timer? _timer;
  int _totalRounds = 3;
  int _roundDuration = 3 * 60;
  int _pauseDuration = 60;

  int _currentRound = 1;
  _Phase _phase = _Phase.round;
  int _remainingSeconds = 3 * 60;

  // Ziel-Zeitpunkt der aktuellen Phase statt reinem Countdown -- siehe
  // simple_timer_tab.dart für die Begründung. Hier zusätzlich wichtig, weil
  // beim Rückkehren aus dem Hintergrund ggf. mehrere Phasen (Runde -> Pause
  // -> nächste Runde ...) bereits abgelaufen sein können.
  DateTime? _endTime;

  bool _isRunning = false;
  bool _hasStarted = false;
  bool _isFinished = false;

  bool get _canEditSettings => !_isRunning && !_hasStarted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ringProgress = Tween<double>(begin: 1, end: 0).animate(_ringController);
    for (final entry in {
      _roundMinutesFocus: _roundMinutesController,
      _roundSecondsFocus: _roundSecondsController,
      _pauseMinutesFocus: _pauseMinutesController,
      _pauseSecondsFocus: _pauseSecondsController,
    }.entries) {
      entry.key.addListener(() => _padOnBlur(entry.key, entry.value));
    }
  }

  // Zeigt einstellige Eingaben (z.B. "3") beim Verlassen des Felds
  // zweistellig an ("03") -- passend zur laufenden Anzeige. Gilt bewusst
  // nicht für die Rundenanzahl, die bleibt einstellig zulässig.
  void _padOnBlur(FocusNode node, TextEditingController controller) {
    if (node.hasFocus) return;
    if (controller.text.length == 1) {
      controller.text = controller.text.padLeft(2, '0');
    } else if (controller.text.isEmpty) {
      controller.text = '00';
    }
  }

  _Step? _nextStep(_Phase phase, int round) {
    if (phase == _Phase.round && round >= _totalRounds) return null;
    if (phase == _Phase.round && _pauseDuration > 0) {
      return _Step(
        phase: _Phase.pause,
        round: round,
        durationSeconds: _pauseDuration,
      );
    }
    return _Step(
      phase: _Phase.round,
      round: round + 1,
      durationSeconds: _roundDuration,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning || _endTime == null) return;
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      final s = AppStrings.of(AppSettings.locale.value);
      BackgroundTimerController.enterBackground(_computeRemainingPhases(s));
    } else if (state == AppLifecycleState.resumed) {
      BackgroundTimerController.leaveBackground();
      _syncFromEndTime();
      if (_isRunning) _startTicking();
    }
  }

  /// Alle noch kommenden Phasenwechsel ab dem aktuellen Ziel-Zeitpunkt --
  /// für den Hintergrund-Dienst/die geplanten Benachrichtigungen. Auf 60
  /// begrenzt, damit auf iOS nie mehr als das dortige Limit für geplante
  /// Benachrichtigungen (64) erreicht wird -- für ein reales Training weit
  /// mehr als genug.
  List<TimerPhase> _computeRemainingPhases(AppStrings s) {
    final phases = <TimerPhase>[];
    var time = _endTime!;
    var phase = _phase;
    var round = _currentRound;

    while (phases.length < 60) {
      final next = _nextStep(phase, round);
      final sound = phase == _Phase.round ? 'bell' : 'buzzer';
      final activeLabel = phase == _Phase.round
          ? '${s('round')} $round / $_totalRounds'
          : s('pause');
      final alertTitle = next == null
          ? s('trainingDone')
          : (next.phase == _Phase.pause
                ? s('pause')
                : '${s('round')} ${next.round} / $_totalRounds');
      phases.add(
        TimerPhase(
          at: time,
          activeLabel: activeLabel,
          alertTitle: alertTitle,
          alertBody: s('timer'),
          sound: sound,
        ),
      );
      if (next == null) break;
      time = time.add(Duration(seconds: next.durationSeconds));
      phase = next.phase;
      round = next.round;
    }
    return phases;
  }

  void _start() {
    if (_isRunning) return;
    BackgroundTimerController.requestPermissions();

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
      _advancePhase();
    } else {
      setState(() => _remainingSeconds = remaining);
    }
  }

  void _advancePhase() {
    final next = _nextStep(_phase, _currentRound);
    if (next == null) {
      _timer?.cancel();
      _ringController.stop();
      setState(() {
        _remainingSeconds = 0;
        _isRunning = false;
        _isFinished = true;
      });
      _playAlert(_Phase.round);
      return;
    }

    _playAlert(_phase);
    setState(() {
      _phase = next.phase;
      _currentRound = next.round;
      _remainingSeconds = next.durationSeconds;
    });
    _endTime = DateTime.now().add(Duration(seconds: next.durationSeconds));
    _ringController
      ..duration = Duration(seconds: next.durationSeconds)
      ..value = 0
      ..forward();
  }

  // Nach Rückkehr aus dem Hintergrund: springt über alle Phasen, die
  // inzwischen abgelaufen sind (ggf. mehrere -- Runde, Pause, nächste
  // Runde, ...), bis die aktuell laufende Phase gefunden ist, und setzt
  // Anzeige + Ring exakt auf deren Fortschritt. Kein erneutes _playAlert()
  // hier -- falls Phasen während des Hintergrunds zu Ende gingen, hat der
  // Hintergrund-Dienst/die Benachrichtigung den Ton bereits gespielt.
  void _syncFromEndTime() {
    var time = _endTime!;
    var phase = _phase;
    var round = _currentRound;
    final now = DateTime.now();

    while (time.isBefore(now)) {
      final next = _nextStep(phase, round);
      if (next == null) {
        setState(() {
          _phase = phase;
          _currentRound = round;
          _remainingSeconds = 0;
          _isRunning = false;
          _isFinished = true;
        });
        _timer?.cancel();
        _ringController
          ..stop()
          ..value = 1;
        return;
      }
      time = time.add(Duration(seconds: next.durationSeconds));
      phase = next.phase;
      round = next.round;
    }

    final remaining = time.difference(now).inSeconds;
    final phaseDuration = phase == _Phase.round ? _roundDuration : _pauseDuration;
    final elapsed = (phaseDuration - remaining).clamp(0, phaseDuration);
    setState(() {
      _phase = phase;
      _currentRound = round;
      _remainingSeconds = remaining;
    });
    _endTime = time;
    _ringController
      ..duration = Duration(seconds: phaseDuration)
      ..value = phaseDuration == 0 ? 0 : elapsed / phaseDuration
      ..forward();
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
      _isFinished = false;
      _currentRound = 1;
      _phase = _Phase.round;
      _remainingSeconds = _roundDuration;
    });
  }

  /// Rundenende (inkl. Trainingsende) läutet die Glocke, Pausenende spielt
  /// den Buzzer -- unterschiedliche Sounds, damit man ohne hinzuschauen
  /// hört, ob gerade eine Runde oder eine Pause zu Ende gegangen ist.
  Future<void> _playAlert(_Phase endingPhase) async {
    if (!AppSettings.soundEnabled.value) return;
    final sound = endingPhase == _Phase.round
        ? 'sounds/bell.wav'
        : 'sounds/buzzer.wav';
    await _audioPlayer.play(AssetSource(sound));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ringController.dispose();
    _roundsController.dispose();
    _roundMinutesController.dispose();
    _roundSecondsController.dispose();
    _pauseMinutesController.dispose();
    _pauseSecondsController.dispose();
    _roundMinutesFocus.dispose();
    _roundSecondsFocus.dispose();
    _pauseMinutesFocus.dispose();
    _pauseSecondsFocus.dispose();
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

  Widget _buildSettingsInput(BuildContext context, AppStrings s) {
    final color = Theme.of(context).colorScheme.primary;
    final labelStyle = TextStyle(fontSize: 14, color: Colors.grey.shade400);
    final fieldStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      fontFeatures: _timeFontFeatures,
      color: color,
    );

    // Feste Pixelbreiten sind Rätselraten (siehe simple_timer_tab.dart) --
    // die Breite direkt aus dem Style ausmessen, statt eines fixen Werts,
    // der bei diesem Font zu wenig Platz für zwei Ziffern ließ.
    final digitsPainter = TextPainter(
      text: TextSpan(text: '00', style: fieldStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final fieldWidth = digitsPainter.width + 20;

    // Das globale InputDecorationTheme (main.dart) füllt Textfelder mit
    // einer abgerundeten Box und großzügigem Innenabstand -- passend für
    // Dialoge, aber hier zu breit für die schmalen Ziffernfelder (führte zum
    // Abschneiden der zweiten Ziffer). Stattdessen der schlichte Unterstrich,
    // wie auch beim einfachen Timer.
    final fieldDecoration = InputDecoration(
      isDense: true,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: 2),
      ),
    );

    Widget numberField(
      TextEditingController controller, {
      FocusNode? focusNode,
      int? maxValue,
    }) {
      return SizedBox(
        width: fieldWidth,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: fieldStyle,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
            if (maxValue != null) MaxValueTextInputFormatter(maxValue),
          ],
          decoration: fieldDecoration,
        ),
      );
    }

    return Column(
      children: [
        Text(s('rounds'), style: labelStyle),
        const SizedBox(height: 4),
        numberField(_roundsController),
        const SizedBox(height: 24),
        Text(s('roundDuration'), style: labelStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            numberField(_roundMinutesController, focusNode: _roundMinutesFocus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(':', style: fieldStyle),
            ),
            numberField(
              _roundSecondsController,
              focusNode: _roundSecondsFocus,
              maxValue: 59,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(s('pause'), style: labelStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            numberField(_pauseMinutesController, focusNode: _pauseMinutesFocus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(':', style: fieldStyle),
            ),
            numberField(
              _pauseSecondsController,
              focusNode: _pauseSecondsFocus,
              maxValue: 59,
            ),
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
            : (isPause
                  ? Colors.blueAccent
                  : Theme.of(context).colorScheme.primary);
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
                      : (isPause
                            ? s('pause')
                            : '${s('round')} $_currentRound / $_totalRounds'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isPause
                        ? Colors.blueAccent
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                CircularTimerDisplay(
                  progress: _ringProgress,
                  color: numberColor,
                  child: Text(
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
              ],
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
