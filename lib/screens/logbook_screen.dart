import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../coach_guide.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
import 'add_training_entry_screen.dart';
import 'logbook_analysis_tab.dart';
import 'logbook_dashboard_tab.dart';
import 'logbook_history_tab.dart';

enum _LogbookView { dashboard, history, analysis }

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  _LogbookView _view = _LogbookView.dashboard;

  final _streakKey = GlobalKey();
  final _achievementsKey = GlobalKey();
  final _focusKey = GlobalKey();
  final _goalsKey = GlobalKey();
  final _historySearchKey = GlobalKey();
  final _historyFilterKey = GlobalKey();
  final _analysisRecordsKey = GlobalKey();
  final _analysisRadarKey = GlobalKey();
  final _analysisRangeKey = GlobalKey();
  final _analysisPainKey = GlobalKey();

  static String _introIdFor(_LogbookView view) => 'logbook_intro_${view.name}';

  @override
  void initState() {
    super.initState();
    if (!CoachGuide.hasSeen(_introIdFor(_LogbookView.dashboard))) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startTour();
      });
    }
  }

  List<CoachTourStep> _stepsFor(_LogbookView view, AppStrings s) {
    return switch (view) {
      _LogbookView.dashboard => [
        CoachTourStep(anchorKey: _streakKey, message: s('coachTipDashboard')),
        CoachTourStep(
          anchorKey: _achievementsKey,
          message: s('coachTourAchievementsSection'),
        ),
        CoachTourStep(
          anchorKey: _focusKey,
          message: s('coachTourFocusSection'),
        ),
        CoachTourStep(
          anchorKey: _goalsKey,
          message: s('coachTourGoalsSection'),
        ),
      ],
      _LogbookView.history => [
        CoachTourStep(
          anchorKey: _historySearchKey,
          message: s('coachTourHistorySearch'),
        ),
        CoachTourStep(
          anchorKey: _historyFilterKey,
          message: s('coachTourHistoryFilter'),
        ),
      ],
      _LogbookView.analysis => [
        CoachTourStep(
          anchorKey: _analysisRecordsKey,
          message: s('coachTourAnalysisRecords'),
        ),
        CoachTourStep(
          anchorKey: _analysisRadarKey,
          message: s('coachTourAnalysisRadar'),
        ),
        CoachTourStep(
          anchorKey: _analysisRangeKey,
          message: s('coachTourAnalysisRange'),
        ),
        CoachTourStep(
          anchorKey: _analysisPainKey,
          message: s('coachTourAnalysisPain'),
        ),
      ],
    };
  }

  // showCoachTour() wird hier bewusst direkt aufgerufen statt in einem
  // addPostFrameCallback: _startTour() läuft entweder aus dem Future.delayed
  // in initState()/beim Tab-Wechsel (der Baum ist da längst gebaut) oder aus
  // einem direkten Tap auf das Guide-Icon -- letzterer löst selbst kein
  // setState/keinen neuen Frame aus, wodurch der Callback sonst erst beim
  // nächsten zufälligen Rebuild feuert (Tour erscheint verzögert oder gar
  // nicht).
  //
  // Die Tour erklärt bewusst immer den *aktuell sichtbaren* Tab statt fix
  // das Dashboard -- kein erzwungener Tab-Wechsel mehr nötig, und alle drei
  // Seiten (Übersicht/Historie/Auswertung) bekommen so ihre eigene Erklärung.
  void _startTour() {
    CoachGuide.markSeen(_introIdFor(_view));
    final s = AppStrings.of(AppSettings.locale.value);
    showCoachTour(
      context,
      steps: _stepsFor(_view, s),
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
  }

  void _onViewChanged(_LogbookView? value) {
    if (value == null) return;
    setState(() => _view = value);
    if (!CoachGuide.hasSeen(_introIdFor(value))) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _view == value) _startTour();
      });
    }
  }

  // IndexedStack statt eines Switches: Dashboard und Historie bleiben beim
  // Umschalten dauerhaft gemountet (siehe timer_screen.dart), statt bei
  // jedem Wechsel disposed und neu gebaut zu werden -- das spart die
  // Rebuild-Kosten pro Tab-Wechsel und Such-/Filter-Eingaben in der
  // Historie gehen beim Zurückwechseln nicht verloren.
  Widget _buildBody(AppStrings s) {
    return IndexedStack(
      index: _view.index,
      children: [
        LogbookDashboardTab(
          s: s,
          streakKey: _streakKey,
          achievementsKey: _achievementsKey,
          focusKey: _focusKey,
          goalsKey: _goalsKey,
        ),
        LogbookHistoryTab(
          s: s,
          searchKey: _historySearchKey,
          filterKey: _historyFilterKey,
        ),
        LogbookAnalysisTab(
          s: s,
          recordsKey: _analysisRecordsKey,
          radarKey: _analysisRadarKey,
          rangeKey: _analysisRangeKey,
          painKey: _analysisPainKey,
        ),
      ],
    );
  }

  Widget _segmentLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
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
            title: Text(s('logbook')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: CoachAvatarIcon(onTap: _startTour)),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddTrainingEntryScreen()),
            ),
            icon: const Icon(Icons.add),
            label: Text(s('addTrainingEntry')),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: CupertinoSlidingSegmentedControl<_LogbookView>(
                    groupValue: _view,
                    backgroundColor: const Color(0xFF1C1C1E),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    children: {
                      _LogbookView.dashboard: _segmentLabel(
                        s('logbookDashboardTab'),
                      ),
                      _LogbookView.history: _segmentLabel(
                        s('logbookHistoryTab'),
                      ),
                      _LogbookView.analysis: _segmentLabel(
                        s('logbookAnalysisTab'),
                      ),
                    },
                    onValueChanged: _onViewChanged,
                  ),
                ),
                Expanded(child: _buildBody(s)),
              ],
            ),
          ),
        );
      },
    );
  }
}
