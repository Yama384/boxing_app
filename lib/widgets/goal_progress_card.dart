import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../models/improvement_goal.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal, required this.s, this.onTap});

  final ImprovementGoal goal;
  final AppStrings s;
  final VoidCallback? onTap;

  Color _priorityColor() {
    switch (goal.priority) {
      case GoalPriority.high:
        return Colors.redAccent;
      case GoalPriority.medium:
        return Colors.orangeAccent;
      case GoalPriority.low:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final priorityColor = _priorityColor();
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(skillAreaEmoji(goal.category), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor, width: 1),
                    ),
                    child: Text(
                      goalPriorityLabel(goal.priority, s),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: priorityColor),
                    ),
                  ),
                ],
              ),
              if (goal.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(s('goalProgress'), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  Text(
                    '${goal.progress}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: goal.progress / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(primary),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
