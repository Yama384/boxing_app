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
  static const _introId = 'logbook_intro';

  _LogbookView _view = _LogbookView.dashboard;

  final _streakKey = GlobalKey();
  final _focusKey = GlobalKey();
  final _goalsKey = GlobalKey();

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
    if (_view != _LogbookView.dashboard) {
      setState(() => _view = _LogbookView.dashboard);
    }
    final s = AppStrings.of(AppSettings.locale.value);
    showCoachTour(
      context,
      steps: [
        CoachTourStep(anchorKey: _streakKey, message: s('coachTipDashboard')),
        CoachTourStep(
          anchorKey: _focusKey,
          message: s('coachTourFocusSection'),
        ),
        CoachTourStep(
          anchorKey: _goalsKey,
          message: s('coachTourGoalsSection'),
        ),
      ],
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
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
          focusKey: _focusKey,
          goalsKey: _goalsKey,
        ),
        LogbookHistoryTab(s: s),
        LogbookAnalysisTab(s: s),
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
                    onValueChanged: (value) {
                      if (value != null) setState(() => _view = value);
                    },
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
