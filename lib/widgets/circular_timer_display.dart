import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Kreisförmiger Fortschrittsring. `progress` ist eine echte Flutter-
/// Animation (nicht nur ein einzelner double-Wert) -- dadurch zeichnet sich
/// der Ring bei jedem Frame (60x pro Sekunde) neu, unabhängig davon, wie oft
/// der restliche Screen (z.B. die Sekunden-Anzeige) aktualisiert wird. Das
/// verhindert das "Ruckeln", das bei kurzen Timern entsteht, wenn der Ring
/// nur einmal pro Sekunde springt.
class CircularTimerDisplay extends StatelessWidget {
  const CircularTimerDisplay({
    super.key,
    required this.progress,
    required this.child,
    this.size = 240,
    this.strokeWidth = 14,
    this.color,
  });

  /// Fortschritt von 0.0 (leer) bis 1.0 (voll).
  final Animation<double> progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, appear, ring) {
        return Opacity(
          opacity: appear.clamp(0.0, 1.0),
          child: Transform.scale(scale: appear, child: ring),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _RingPainter(
                    progress: progress.value.clamp(0.0, 1.0),
                    color: ringColor,
                    trackColor: ringColor.withValues(alpha: 0.15),
                    strokeWidth: strokeWidth,
                  ),
                );
              },
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
