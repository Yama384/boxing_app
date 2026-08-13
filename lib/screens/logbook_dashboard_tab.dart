import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/improvement_goal.dart';
import '../models/training_entry.dart';
import '../widgets/animated_stat_number.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/goal_progress_card.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class LogbookDashboardTab extends StatelessWidget {
  const LogbookDashboardTab({
    super.key,
    required this.s,
    this.streakKey,
    this.focusKey,
    this.goalsKey,
  });

  final AppStrings s;

  /// Anker für die Logbuch-Guide-Tour (siehe logbook_screen.dart) -- optional,
  /// damit dieses Widget auch ohne Tour-Anbindung nutzbar bleibt.
  final GlobalKey? streakKey;
  final GlobalKey? focusKey;
  final GlobalKey? goalsKey;

  Widget _statTile(int value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
      child: AnimatedStatNumber(value: value, label: label),
    );
  }

  Widget _buildStreakHero(BuildContext context, int streak) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.25), const Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          AnimatedStatNumber(value: streak, label: s('statStreak'), color: Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int entryCount, int activeGoals, int completedGoals) {
    return Column(
      children: [
        KeyedSubtree(
          key: streakKey,
          child: _buildStreakHero(context, LogbookData.currentStreak),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statTile(entryCount, s('statEntries'))),
            const SizedBox(width: 12),
            Expanded(child: _statTile(LogbookData.trainingDaysCount, s('statTrainingDays'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statTile(activeGoals, s('statActiveGoals'))),
            const SizedBox(width: 12),
            Expanded(child: _statTile(completedGoals, s('statCompletedGoals'))),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusSection(BuildContext context, ImprovementGoal? focusGoal) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                s('todaysFocus').toUpperCase(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (focusGoal == null) ...[
            Text(s('noFocusYet'), style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(s('setFocus')),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: focusGoal)),
              ),
              child: Text(
                '🎯 ${focusGoal.title}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            if (focusGoal.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                s('todaysTask'),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(focusGoal.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, List<ImprovementGoal> activeGoals) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s('myGoals'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
              ),
              child: Icon(Icons.add_circle_outline, color: primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeGoals.isEmpty)
          Text(s('noGoalsYet'), style: TextStyle(color: Colors.grey.shade500))
        else
          for (final goal in activeGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FadeSlideIn(
                key: ValueKey(goal.id),
                child: GoalProgressCard(
                  goal: goal,
                  s: s,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  /// Pausierte/abgeschlossene Ziele verschwinden sonst nach dem Pausieren
  /// spurlos aus der UI -- ohne diese Sektion gibt es keinen Weg mehr zurück
  /// zum GoalDetailScreen (fortsetzen/löschen/bearbeiten).
  Widget _buildOtherGoalsSection(BuildContext context, List<ImprovementGoal> otherGoals) {
    if (otherGoals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          s('otherGoals'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 12),
        for (final goal in otherGoals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeSlideIn(
              key: ValueKey(goal.id),
              child: Opacity(
                opacity: 0.7,
                child: GoalProgressCard(
                  goal: goal,
                  s: s,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              s('developmentStarts'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              s('developmentStartsSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrainingEntry>>(
      valueListenable: LogbookData.entries,
      builder: (context, entries, _) {
        return ValueListenableBuilder<List<ImprovementGoal>>(
          valueListenable: LogbookData.goals,
          builder: (context, goals, _) {
            if (entries.isEmpty && goals.isEmpty) {
              return _buildEmptyState();
            }
            final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final otherGoals = goals.where((g) => g.status != GoalStatus.active).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _buildStatsGrid(context, entries.length, activeGoals.length, completedGoals),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: focusKey,
                  child: _buildFocusSection(context, LogbookData.focusGoal),
                ),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: goalsKey,
                  child: _buildGoalsSection(context, activeGoals),
                ),
                _buildOtherGoalsSection(context, otherGoals),
              ],
            );
          },
        );
      },
    );
  }
}
