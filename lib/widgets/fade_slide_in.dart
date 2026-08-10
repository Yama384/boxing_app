import 'package:flutter/material.dart';

/// Ziert ein neu erscheinendes Widget (z.B. eine frisch angelegte Ziel-Karte)
/// einmalig mit einer kurzen Fade-/Slide-Einblendung. Läuft nur beim ersten
/// Build des jeweiligen Elements, nicht bei jedem Rebuild -- solange der
/// Aufrufer für jedes Element einen stabilen `key` (z.B. die ID) vergibt.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
        );
      },
      child: child,
    );
  }
}
