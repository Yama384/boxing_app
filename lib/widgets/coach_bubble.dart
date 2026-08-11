import 'dart:async';
import 'package:flutter/material.dart';
import '../coach_guide.dart';

enum CoachBubbleSide { left, right }

/// Der runde Boxer-Avatar allein, ohne Sprechblasen-Logik -- wird sowohl von
/// [CoachBubble] als auch vom [CoachTour]-Trigger-Icon genutzt.
class CoachAvatarIcon extends StatelessWidget {
  const CoachAvatarIcon({super.key, required this.onTap, this.size = 28});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: primary.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(size * 0.08),
          child: Image.asset('assets/images/coach_boxer.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Kleiner Boxer/Coach-Charakter als Info-Guide: ein antippbares Icon, das
/// bei Bedarf eine dezente Sprechblase mit ein bis drei kurzen Sätzen zeigt.
///
/// Zwei Modi:
/// - `introId` gesetzt: ploppt beim allerersten Mal automatisch kurz auf
///   (Nachrichten-Sequenz, Auto-Advance), danach nur noch per Antippen erneut.
/// - `introId` null: reiner Kontext-Tipp, erscheint nur auf Antippen.
///
/// Bewusst kein `Overlay`/Portal, sondern ein lokaler `Stack` mit
/// `clipBehavior: Clip.none` -- die Blase legt sich über umliegenden Inhalt,
/// statt ihn zu verschieben, und bleibt so garantiert "nicht blockierend".
class CoachBubble extends StatefulWidget {
  const CoachBubble({
    super.key,
    required this.messages,
    this.introId,
    this.size = 28,
    this.side = CoachBubbleSide.left,
  });

  final List<String> messages;
  final String? introId;
  final double size;
  final CoachBubbleSide side;

  @override
  State<CoachBubble> createState() => _CoachBubbleState();
}

class _CoachBubbleState extends State<CoachBubble> {
  bool _visible = false;
  int _messageIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    final introId = widget.introId;
    if (introId != null && !CoachGuide.hasSeen(introId)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _open(markIntroSeen: true);
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _open({bool markIntroSeen = false}) {
    if (markIntroSeen && widget.introId != null) {
      CoachGuide.markSeen(widget.introId!);
    }
    setState(() {
      _visible = true;
      _messageIndex = 0;
    });
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(seconds: 4), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_messageIndex < widget.messages.length - 1) {
      setState(() => _messageIndex++);
      _scheduleAutoAdvance();
    } else {
      _close();
    }
  }

  void _close() {
    _autoTimer?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  void _toggle() {
    if (_visible) {
      _close();
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isLeft = widget.side == CoachBubbleSide.left;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoachAvatarIcon(onTap: _toggle, size: widget.size),
        if (_visible)
          Positioned(
            top: widget.size + 6,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_messageIndex),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                alignment: isLeft ? Alignment.topLeft : Alignment.topRight,
                scale: value.clamp(0, 1.2),
                child: Opacity(opacity: value.clamp(0, 1), child: child),
              ),
              child: GestureDetector(
                onTap: _advance,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withValues(alpha: 0.35)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          widget.messages[_messageIndex],
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                      GestureDetector(
                        onTap: _close,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6, top: 1),
                          child: Icon(Icons.close_rounded, size: 15, color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
