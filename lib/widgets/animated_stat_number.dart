import 'package:flutter/material.dart';

class AnimatedStatNumber extends StatelessWidget {
  const AnimatedStatNumber({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final numberColor = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return Text(
              '$animatedValue',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: numberColor),
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
