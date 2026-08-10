import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import 'add_training_entry_screen.dart';
import 'logbook_dashboard_tab.dart';
import 'logbook_history_tab.dart';
import 'logbook_progress_tab.dart';

enum _LogbookView { dashboard, history, progress }

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  _LogbookView _view = _LogbookView.dashboard;

  Widget _buildBody(AppStrings s) {
    switch (_view) {
      case _LogbookView.dashboard:
        return LogbookDashboardTab(s: s);
      case _LogbookView.history:
        return LogbookHistoryTab(s: s);
      case _LogbookView.progress:
        return LogbookProgressTab(s: s);
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
          body: SafeArea(
            child: Column(
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
                      _LogbookView.progress: _segmentLabel(s('logbookProgressTab')),
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
