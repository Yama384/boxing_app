import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../models/pain_entry.dart';

/// Vereinfachte Körper-Silhouette (Vorderansicht) mit einem Punkt pro
/// [BodyZone], der nach Häufigkeit eingefärbt ist -- ergänzt die exakte
/// Balkenliste um einen Blick, der auf einen Schlag zeigt, wo es wehtut.
/// `other` hat keine anatomische Position und wird bewusst nicht gezeigt
/// (bleibt nur in der Balkenliste sichtbar).
class BodyPainMap extends StatefulWidget {
  const BodyPainMap({super.key, required this.counts, required this.s});

  final Map<BodyZone, int> counts;
  final AppStrings s;

  @override
  State<BodyPainMap> createState() => _BodyPainMapState();
}

class _BodyPainMapState extends State<BodyPainMap> {
  BodyZone? _selected;

  void _handleTapUp(TapUpDetails details, Size size) {
    final tap = details.localPosition;
    BodyZone? closest;
    var closestDistance = double.infinity;
    for (final entry in _bodyZonePositions.entries) {
      final point = Offset(
        entry.value.dx * size.width,
        entry.value.dy * size.height,
      );
      final distance = (tap - point).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = entry.key;
      }
    }
    // Nur reagieren, wenn nah genug an einem Punkt getippt wurde.
    if (closestDistance <= 28) {
      setState(() => _selected = closest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = widget.counts.values.isEmpty
        ? 0
        : widget.counts.values.reduce(math.max);
    // Dieselbe Akzentfarbe wie die bestehende Balkenliste (_painZones), damit
    // Karte und Liste als ein zusammengehöriges Paar wirken.
    const accent = Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.62,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapUp: (details) => _handleTapUp(details, size),
                child: CustomPaint(
                  size: size,
                  painter: _BodySilhouettePainter(
                    counts: widget.counts,
                    maxCount: maxCount,
                    accentColor: accent,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _selected == null
              ? widget.s('bodyMapTapHint')
              : '${bodyZoneLabel(_selected!, widget.s)}: ${widget.counts[_selected!] ?? 0}x',
          style: TextStyle(
            fontSize: 12,
            color: _selected == null ? Colors.grey.shade500 : Colors.white,
            fontWeight: _selected == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Anatomisch angenäherte Positionen als Anteil der Zeichenfläche (0-1),
/// links/rechts hier konsequent als Bildschirm-links/-rechts verstanden
/// (kein echtes Front/Rück-Modell -- reicht für eine grobe Übersicht).
const _bodyZonePositions = <BodyZone, Offset>{
  BodyZone.head: Offset(0.5, 0.07),
  BodyZone.neck: Offset(0.5, 0.155),
  BodyZone.shoulderLeft: Offset(0.28, 0.205),
  BodyZone.shoulderRight: Offset(0.72, 0.205),
  BodyZone.elbowLeft: Offset(0.16, 0.36),
  BodyZone.elbowRight: Offset(0.84, 0.36),
  BodyZone.wristLeft: Offset(0.1, 0.52),
  BodyZone.wristRight: Offset(0.9, 0.52),
  BodyZone.ribs: Offset(0.5, 0.29),
  BodyZone.upperBack: Offset(0.36, 0.33),
  BodyZone.lowerBack: Offset(0.64, 0.33),
  BodyZone.hipLeft: Offset(0.4, 0.5),
  BodyZone.hipRight: Offset(0.6, 0.5),
  BodyZone.kneeLeft: Offset(0.4, 0.72),
  BodyZone.kneeRight: Offset(0.6, 0.72),
  BodyZone.ankleLeft: Offset(0.4, 0.92),
  BodyZone.ankleRight: Offset(0.6, 0.92),
  BodyZone.footLeft: Offset(0.4, 0.97),
  BodyZone.footRight: Offset(0.6, 0.97),
};

class _BodySilhouettePainter extends CustomPainter {
  _BodySilhouettePainter({
    required this.counts,
    required this.maxCount,
    required this.accentColor,
  });

  final Map<BodyZone, int> counts;
  final int maxCount;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.035);
    final limbPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Kopf
    final headCenter = Offset(w * 0.5, h * 0.07);
    final headRadius = h * 0.045;
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, outline);

    // Rumpf: Schultern -> Taille
    final torso = Path()
      ..moveTo(w * 0.30, h * 0.185)
      ..lineTo(w * 0.70, h * 0.185)
      ..quadraticBezierTo(w * 0.66, h * 0.34, w * 0.60, h * 0.48)
      ..lineTo(w * 0.40, h * 0.48)
      ..quadraticBezierTo(w * 0.34, h * 0.34, w * 0.30, h * 0.185)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, outline);

    void limb(Offset a, Offset b, Offset c, double width) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, limbPaint..strokeWidth = width);
    }

    // Arme: Schulter -> Ellbogen -> Handgelenk
    limb(
      Offset(w * 0.28, h * 0.20),
      Offset(w * 0.16, h * 0.36),
      Offset(w * 0.1, h * 0.52),
      w * 0.075,
    );
    limb(
      Offset(w * 0.72, h * 0.20),
      Offset(w * 0.84, h * 0.36),
      Offset(w * 0.9, h * 0.52),
      w * 0.075,
    );

    // Beine: Hüfte -> Knie -> Knöchel
    limb(
      Offset(w * 0.42, h * 0.475),
      Offset(w * 0.4, h * 0.72),
      Offset(w * 0.4, h * 0.92),
      w * 0.09,
    );
    limb(
      Offset(w * 0.58, h * 0.475),
      Offset(w * 0.6, h * 0.72),
      Offset(w * 0.6, h * 0.92),
      w * 0.09,
    );

    // Füße
    for (final dx in [0.4, 0.6]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * dx, h * 0.965),
          width: w * 0.1,
          height: h * 0.03,
        ),
        fill,
      );
    }

    // Schmerz-Punkte
    for (final entry in _bodyZonePositions.entries) {
      final count = counts[entry.key] ?? 0;
      final center = Offset(entry.value.dx * w, entry.value.dy * h);
      final intensity = maxCount == 0 ? 0.0 : count / maxCount;
      final radius = count == 0 ? 4.0 : 7.0 + intensity * 7.0;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = count == 0
              ? Colors.white.withValues(alpha: 0.12)
              : accentColor.withValues(alpha: 0.35 + intensity * 0.5),
      );
      if (count > 0) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.maxCount != maxCount;
  }
}
