import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../models/achievement.dart';

/// Einzelne Erfolgs-Kachel: freigeschaltet zeigt Emoji + farbigen Ring,
/// gesperrt nur eine blasse Silhouette mit Schloss-Icon. Tap öffnet immer
/// ein Detail-Sheet (Titel/Beschreibung/Datum bzw. Sperr-Hinweis).
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.unlockedAt,
    required this.s,
  });

  final Achievement achievement;
  final bool unlocked;
  final DateTime? unlockedAt;
  final AppStrings s;

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? primary.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.25,
                        child: Text(
                          achievement.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s(achievement.titleKey),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unlocked && unlockedAt != null
                                ? s('achievementUnlockedOn').replaceFirst(
                                    '{date}',
                                    _formatDate(unlockedAt!),
                                  )
                                : s('achievementLockedHint'),
                            style: TextStyle(
                              fontSize: 12,
                              color: unlocked ? primary : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  s(achievement.descriptionKey),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unlocked
                    ? primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: unlocked
                    ? Border.all(
                        color: primary.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? Text(
                      achievement.emoji,
                      style: const TextStyle(fontSize: 24),
                    )
                  : Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              s(achievement.titleKey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: unlocked ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
