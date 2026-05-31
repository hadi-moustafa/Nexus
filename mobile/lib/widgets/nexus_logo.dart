import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws the Nexus globe-compass logo in pure Flutter canvas.
/// Drop-in widget — size it via [size].
class NexusLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const NexusLogo({super.key, this.size = 120, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _GlobeCompassPainter()),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.10),
          Text(
            'NEXUS',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size * 0.30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A1628),
              letterSpacing: size * 0.04,
            ),
          ),
          SizedBox(height: size * 0.01),
          Text(
            'NEWS APP',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: size * 0.115,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628).withOpacity(0.55),
              letterSpacing: size * 0.03,
            ),
          ),
        ],
      ],
    );
  }
}

/// Same logo but text is white — for use on dark/teal backgrounds.
class NexusLogoDark extends StatelessWidget {
  final double size;
  final bool showText;

  const NexusLogoDark({super.key, this.size = 120, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _GlobeCompassPainter()),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.10),
          Text(
            'NEXUS',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size * 0.30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: size * 0.04,
            ),
          ),
          SizedBox(height: size * 0.01),
          Text(
            'NEWS APP',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: size * 0.115,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: size * 0.03,
            ),
          ),
        ],
      ],
    );
  }
}

class _GlobeCompassPainter extends CustomPainter {
  static const Color _navy = Color(0xFF0A1628);
  static const Color _teal = Color(0xFF0EC4A0);
  static const Color _tealLight = Color(0xFF4DD9C0);
  static const Color _orange = Color(0xFFF5A524);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;

    // ── Compass needle paints ────────────────────────────────────────────────
    final compassFill = Paint()
      ..color = _navy
      ..style = PaintingStyle.fill;

    final compassFillLight = Paint()
      ..color = _navy.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    // ── Globe line paint ─────────────────────────────────────────────────────
    final globeLinePaint = Paint()
      ..color = _teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round;

    final globeLineFaintPaint = Paint()
      ..color = _tealLight.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.016
      ..strokeCap = StrokeCap.round;

    // ── Clip to sphere ────────────────────────────────────────────────────────
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    // ── Draw compass needles (behind globe) ──────────────────────────────────
    _drawCompassNeedles(canvas, cx, cy, r, size, compassFill, compassFillLight);

    // ── Globe sphere background ───────────────────────────────────────────────
    final sphereBg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          const Color(0xFFE8F9F6),
          const Color(0xFFD0F4EE),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, sphereBg);

    // ── Clip and draw globe lines ─────────────────────────────────────────────
    canvas.save();
    canvas.clipPath(clipPath);

    // Latitude lines (horizontal ellipses at varying vertical positions)
    final latitudes = [-0.60, -0.30, 0.0, 0.30, 0.60];
    for (final lat in latitudes) {
      final y = cy + lat * r;
      final halfWidth = r * math.sqrt(1 - lat * lat);
      final rect = Rect.fromCenter(
        center: Offset(cx, y),
        width: halfWidth * 2,
        height: halfWidth * 0.28,
      );
      canvas.drawArc(rect, 0, math.pi * 2, false,
          lat == 0.0 ? globeLinePaint : globeLineFaintPaint);
    }

    // Longitude lines (vertical ellipses at varying angles)
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.55,
        height: r * 2,
      );
      final paint = (i == 0 || i == 3) ? globeLinePaint : globeLineFaintPaint;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      canvas.restore();
    }

    // Two sweeping S-curve style arcs (the distinctive swirl lines)
    final swirlPaint = Paint()
      ..color = _teal.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(cx - r, cy);
    path1.cubicTo(
      cx - r * 0.4, cy - r * 0.9,
      cx + r * 0.4, cy + r * 0.9,
      cx + r, cy,
    );
    canvas.drawPath(path1, swirlPaint);

    final path2 = Path();
    path2.moveTo(cx, cy - r);
    path2.cubicTo(
      cx + r * 0.9, cy - r * 0.4,
      cx - r * 0.9, cy + r * 0.4,
      cx, cy + r,
    );
    canvas.drawPath(path2, swirlPaint);

    canvas.restore(); // clip

    // ── Globe outline ─────────────────────────────────────────────────────────
    final outlinePaint = Paint()
      ..color = _navy.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012;
    canvas.drawCircle(Offset(cx, cy), r, outlinePaint);

    // ── Orange star sparkle (roughly at 2 o'clock on sphere) ─────────────────
    final starCx = cx + r * 0.52;
    final starCy = cy - r * 0.38;
    _drawStar(canvas, starCx, starCy, size.width * 0.085, 8, _orange);

    canvas.restore();
  }

  void _drawCompassNeedles(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Size size,
    Paint dark,
    Paint light,
  ) {
    final tip = r * 1.40;
    final base = r * 0.12;

    // North needle
    final north = Path()
      ..moveTo(cx, cy - tip)
      ..lineTo(cx - base, cy - r * 0.88)
      ..lineTo(cx + base, cy - r * 0.88)
      ..close();
    canvas.drawPath(north, dark);

    // South needle
    final south = Path()
      ..moveTo(cx, cy + tip)
      ..lineTo(cx - base, cy + r * 0.88)
      ..lineTo(cx + base, cy + r * 0.88)
      ..close();
    canvas.drawPath(south, dark);

    // East needle
    final east = Path()
      ..moveTo(cx + tip, cy)
      ..lineTo(cx + r * 0.88, cy - base)
      ..lineTo(cx + r * 0.88, cy + base)
      ..close();
    canvas.drawPath(east, light);

    // West needle
    final west = Path()
      ..moveTo(cx - tip, cy)
      ..lineTo(cx - r * 0.88, cy - base)
      ..lineTo(cx - r * 0.88, cy + base)
      ..close();
    canvas.drawPath(west, light);
  }

  void _drawStar(
      Canvas canvas, double cx, double cy, double radius, int points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final innerRadius = radius * 0.42;
    final step = math.pi / points;

    for (int i = 0; i < points * 2; i++) {
      final angle = i * step - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
