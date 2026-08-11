import 'dart:async';
import 'package:flutter/material.dart';

/// Ein Schritt einer geführten Tour: welches Feld erklärt wird ([anchorKey])
/// und der kurze Erklärtext dazu.
class CoachTourStep {
  const CoachTourStep({required this.anchorKey, required this.message});

  final GlobalKey anchorKey;
  final String message;
}

/// Startet eine geführte Tour über mehrere Felder der aktuellen Seite: jedes
/// Feld wird per Spotlight (abgedunkelter Rest, Loch um das Feld) hervor-
/// gehoben, dazu eine Sprechblase mit Erklärung + "Weiter"-Button. Scrollt
/// Felder außerhalb des sichtbaren Bereichs automatisch ins Bild.
Future<void> showCoachTour(
  BuildContext context, {
  required List<CoachTourStep> steps,
  required String nextLabel,
  required String doneLabel,
  required String skipLabel,
}) {
  if (steps.isEmpty) return Future<void>.value();
  final overlayState = Overlay.of(context);
  late OverlayEntry entry;
  final completer = Completer<void>();

  void finish() {
    if (completer.isCompleted) return;
    entry.remove();
    completer.complete();
  }

  entry = OverlayEntry(
    builder: (overlayContext) => _CoachTourOverlay(
      steps: steps,
      nextLabel: nextLabel,
      doneLabel: doneLabel,
      skipLabel: skipLabel,
      onFinished: finish,
    ),
  );
  overlayState.insert(entry);
  return completer.future;
}

class _CoachTourOverlay extends StatefulWidget {
  const _CoachTourOverlay({
    required this.steps,
    required this.nextLabel,
    required this.doneLabel,
    required this.skipLabel,
    required this.onFinished,
  });

  final List<CoachTourStep> steps;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final VoidCallback onFinished;

  @override
  State<_CoachTourOverlay> createState() => _CoachTourOverlayState();
}

class _CoachTourOverlayState extends State<_CoachTourOverlay> {
  int _index = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateCurrent());
  }

  Future<void> _locateCurrent() async {
    final step = widget.steps[_index];
    final targetContext = step.anchorKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
    }
    if (!mounted) return;
    final renderObject = step.anchorKey.currentContext?.findRenderObject();
    Rect? rect;
    if (renderObject is RenderBox && renderObject.attached) {
      final offset = renderObject.localToGlobal(Offset.zero);
      rect = (offset & renderObject.size).inflate(8);
    }
    if (rect == null) {
      // Ziel-Widget aktuell nicht im Baum (z.B. Empty-State) -- Schritt
      // überspringen statt eines leeren, abgedunkelten Bildschirms.
      _next();
      return;
    }
    setState(() => _targetRect = rect);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _targetRect = null;
    });
    _locateCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;
    final mq = MediaQuery.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(size: mq.size, painter: _SpotlightPainter(_targetRect)),
            ),
            if (_targetRect != null) _buildBubble(context, step, isLast, mq, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, CoachTourStep step, bool isLast, MediaQueryData mq, Color primary) {
    final rect = _targetRect!;
    final screenHeight = mq.size.height;
    final spaceBelow = screenHeight - rect.bottom - mq.padding.bottom;
    final showBelow = spaceBelow > 170 || rect.top < 170;

    return Positioned(
      top: showBelow ? rect.bottom + 12 : null,
      bottom: showBelow ? null : (screenHeight - rect.top) + 12,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_index),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          alignment: showBelow ? Alignment.topCenter : Alignment.bottomCenter,
          scale: value.clamp(0, 1.1),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        ),
        child: GestureDetector(
          onTap: () {}, // Taps auf die Blase sollen nicht durch zum Hintergrund-Advance durchschlagen
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.message, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${_index + 1}/${widget.steps.length}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onFinished,
                      child: Text(widget.skipLabel),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
                      child: Text(isLast ? widget.doneLabel : widget.nextLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.holeRect);

  final Rect? holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;
    canvas.saveLayer(screenRect, Paint());
    canvas.drawRect(screenRect, Paint()..color = Colors.black.withValues(alpha: 0.75));
    final hole = holeRect;
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(14)),
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => oldDelegate.holeRect != holeRect;
}
