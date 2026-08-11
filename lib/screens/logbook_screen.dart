import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../coach_guide.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
import 'add_training_entry_screen.dart';
import 'logbook_dashboard_tab.dart';
import 'logbook_history_tab.dart';

enum _LogbookView { dashboard, history }

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

  void _startTour() {
    CoachGuide.markSeen(_introId);
    if (_view != _LogbookView.dashboard) setState(() => _view = _LogbookView.dashboard);
    final s = AppStrings.of(AppSettings.locale.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCoachTour(
        context,
        steps: [
          CoachTourStep(anchorKey: _streakKey, message: s('coachTipDashboard')),
          CoachTourStep(anchorKey: _focusKey, message: s('coachTourFocusSection')),
          CoachTourStep(anchorKey: _goalsKey, message: s('coachTourGoalsSection')),
        ],
        nextLabel: s('coachTourNext'),
        doneLabel: s('coachTourDone'),
        skipLabel: s('coachTourSkip'),
      );
    });
  }

  Widget _buildBody(AppStrings s) {
    switch (_view) {
      case _LogbookView.dashboard:
        return LogbookDashboardTab(s: s, streakKey: _streakKey, focusKey: _focusKey, goalsKey: _goalsKey);
      case _LogbookView.history:
        return LogbookHistoryTab(s: s);
    }
  }

  Widget _segmentLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
          appBar: AppBar(title: Text(s('logbook'))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddTrainingEntryScreen()),
            ),
            icon: const Icon(Icons.add),
            label: Text(s('addTrainingEntry')),
          ),
          // Bewusst als Stack-Overlay im Body statt in den AppBar-Actions:
          // die AppBar (NavigationToolbar) schneidet überlaufende Kind-Inhalte
          // ab, wodurch die Sprechblase unsichtbar wurde. Der Scaffold-Body hat
          // dagegen kein Clipping, die Blase legt sich frei über den Inhalt.
          body: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: CupertinoSlidingSegmentedControl<_LogbookView>(
                        groupValue: _view,
                        backgroundColor: const Color(0xFF1C1C1E),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        children: {
                          _LogbookView.dashboard: _segmentLabel(s('logbookDashboardTab')),
                          _LogbookView.history: _segmentLabel(s('logbookHistoryTab')),
                        },
                        onValueChanged: (value) {
                          if (value != null) setState(() => _view = value);
                        },
                      ),
                    ),
                    Expanded(child: _buildBody(s)),
                  ],
                ),
                Positioned(
                  top: 10,
                  right: 20,
                  child: CoachAvatarIcon(onTap: _startTour),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
