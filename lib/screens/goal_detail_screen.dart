import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/goal_rating.dart';
import '../models/improvement_goal.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'create_goal_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final ImprovementGoal goal;

  static const _ratingOptions = [
    GoalRatingValue.none,
    GoalRatingValue.partial,
    GoalRatingValue.good,
    GoalRatingValue.great,
  ];

  String _ratingLabel(GoalRatingValue value, AppStrings s) {
    switch (value) {
      case GoalRatingValue.none:
        return s('goalRatingNone');
      case GoalRatingValue.partial:
        return s('goalRatingPartial');
      case GoalRatingValue.good:
        return s('goalRatingGood');
      case GoalRatingValue.great:
        return s('goalRatingGreat');
    }
  }

  Future<void> _rateToday(BuildContext context, AppStrings s, ImprovementGoal current) async {
    final rating = await showModalBottomSheet<GoalRatingValue>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s('rateGoalToday'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final value in _ratingOptions)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(value),
                        child: Column(
                          children: [
                            Text(goalRatingEmoji(value), style: const TextStyle(fontSize: 34)),
                            const SizedBox(height: 6),
                            Text(
                              _ratingLabel(value, s),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (rating != null) {
      LogbookData.addGoalRating(GoalRating(goalId: current.id, date: DateTime.now(), rating: rating));
    }
  }

  Future<void> _showCompletedCelebration(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, value, _) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 56),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _setStatus(ImprovementGoal current, GoalStatus status) {
    LogbookData.updateGoal(
      current.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        completedAt: status == GoalStatus.completed ? DateTime.now() : null,
      ),
    );
  }

  void _edit(BuildContext context, ImprovementGoal current) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateGoalScreen(existingGoal: current)),
    );
  }

  Future<void> _delete(BuildContext context, AppStrings s, ImprovementGoal current) async {
    final confirmed = await confirmDelete(context, s);
    if (!confirmed) return;
    LogbookData.deleteGoal(current);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return ValueListenableBuilder<List<ImprovementGoal>>(
          valueListenable: LogbookData.goals,
          builder: (context, allGoals, _) {
            final matches = allGoals.where((g) => g.id == goal.id);
            final current = matches.isEmpty ? goal : matches.first;
            final primary = Theme.of(context).colorScheme.primary;
            final history = LogbookData.ratingsForGoal(current.id);

            return Scaffold(
              appBar: AppBar(
                title: Text(current.title, overflow: TextOverflow.ellipsis),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _edit(context, current);
                        case 'pause':
                          _setStatus(current, GoalStatus.paused);
                        case 'reactivate':
                          _setStatus(current, GoalStatus.active);
                        case 'complete':
                          _showCompletedCelebration(context);
                          _setStatus(current, GoalStatus.completed);
                        case 'delete':
                          _delete(context, s, current);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(s('editGoal'))),
                      if (current.status == GoalStatus.active)
                        PopupMenuItem(value: 'pause', child: Text(s('markPaused'))),
                      if (current.status == GoalStatus.paused)
                        PopupMenuItem(value: 'reactivate', child: Text(s('reactivate'))),
                      if (current.status != GoalStatus.completed)
                        PopupMenuItem(value: 'complete', child: Text(s('markCompleted'))),
                      PopupMenuItem(value: 'delete', child: Text(s('delete'))),
                    ],
                  ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Text(skillAreaEmoji(current.category), style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            skillAreaLabel(current.category, s),
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            goalStatusLabel(current.status, s),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                          ),
                        ),
                      ],
                    ),
                    if (current.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        current.description,
                        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(s('goalProgress'), style: TextStyle(color: Colors.grey.shade400)),
                        const Spacer(),
                        Text(
                          '${current.progress}%',
                          style: TextStyle(fontWeight: FontWeight.w800, color: primary, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: current.progress / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(primary),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (current.status != GoalStatus.completed)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _rateToday(context, s, current),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(s('rateGoalToday')),
                        ),
                      ),
                    const SizedBox(height: 28),
                    Text(
                      s('goalHistory'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (history.isEmpty)
                      Text(s('noEntriesFound'), style: TextStyle(color: Colors.grey.shade500))
                    else
                      for (final rating in history.reversed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Text(goalRatingEmoji(rating.rating), style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Text(
                                '${rating.date.day}.${rating.date.month}.${rating.date.year}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              if (rating.note.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rating.note,
                                    style: TextStyle(color: Colors.grey.shade400),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
