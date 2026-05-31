import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Nexus owl mascot.
/// [mood] changes the eye expression.
/// [size] controls overall scale.
enum OwlMood { neutral, happy, thinking, excited, sad }

class OwlMascot extends StatefulWidget {
  final double size;
  final OwlMood mood;
  final bool animate;

  const OwlMascot({
    super.key,
    this.size = 120,
    this.mood = OwlMood.neutral,
    this.animate = true,
  });

  @override
  State<OwlMascot> createState() => _OwlMascotState();
}

class _OwlMascotState extends State<OwlMascot> with TickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late AnimationController _bobCtrl;
  late Animation<double> _bobAnim;

  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bobAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _bobCtrl.repeat(reverse: true);
      _scheduleBlink();
    }
  }

  void _scheduleBlink() {
    final delay = Duration(milliseconds: 2500 + math.Random().nextInt(2000));
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);
        _scheduleBlink();
      });
    });
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bobAnim,
      builder: (_, __) {
        final bobOffset = widget.animate ? _bobAnim.value * 6.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, bobOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size * 1.15,
            child: CustomPaint(
              painter: _OwlPainter(
                mood: widget.mood,
                isBlinking: _isBlinking,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OwlPainter extends CustomPainter {
  final OwlMood mood;
  final bool isBlinking;

  static const Color _teal = Color(0xFF0EC4A0);
  static const Color _tealDark = Color(0xFF0A9A80);
  static const Color _tealLight = Color(0xFF4DD9C0);
  static const Color _navy = Color(0xFF0A1628);
  static const Color _amber = Color(0xFFF5A524);
  static const Color _white = Colors.white;

  const _OwlPainter({required this.mood, required this.isBlinking});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Body ─────────────────────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_tealLight, _teal, _tealDark],
      ).createShader(Rect.fromLTWH(0, h * 0.25, w, h * 0.7));

    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.72, height: h * 0.62),
      topLeft: const Radius.circular(100),
      topRight: const Radius.circular(100),
      bottomLeft: const Radius.circular(40),
      bottomRight: const Radius.circular(40),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // ── Belly patch ───────────────────────────────────────────────────────────
    final bellyPaint = Paint()..color = _white.withOpacity(0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.73), width: w * 0.40, height: h * 0.32),
      bellyPaint,
    );

    // ── Wings ─────────────────────────────────────────────────────────────────
    final wingPaint = Paint()
      ..color = _tealDark.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Left wing
    final lWing = Path()
      ..moveTo(w * 0.14, h * 0.58)
      ..cubicTo(w * 0.01, h * 0.52, w * 0.00, h * 0.72, w * 0.10, h * 0.82)
      ..cubicTo(w * 0.14, h * 0.72, w * 0.18, h * 0.65, w * 0.14, h * 0.58)
      ..close();
    canvas.drawPath(lWing, wingPaint);

    // Right wing
    final rWing = Path()
      ..moveTo(w * 0.86, h * 0.58)
      ..cubicTo(w * 0.99, h * 0.52, w * 1.00, h * 0.72, w * 0.90, h * 0.82)
      ..cubicTo(w * 0.86, h * 0.72, w * 0.82, h * 0.65, w * 0.86, h * 0.58)
      ..close();
    canvas.drawPath(rWing, wingPaint);

    // ── Ear tufts ─────────────────────────────────────────────────────────────
    final tuftPaint = Paint()..color = _tealDark;

    // Left tuft
    final lTuft = Path()
      ..moveTo(w * 0.32, h * 0.26)
      ..lineTo(w * 0.25, h * 0.04)
      ..lineTo(w * 0.42, h * 0.22)
      ..close();
    canvas.drawPath(lTuft, tuftPaint);

    // Right tuft
    final rTuft = Path()
      ..moveTo(w * 0.68, h * 0.26)
      ..lineTo(w * 0.75, h * 0.04)
      ..lineTo(w * 0.58, h * 0.22)
      ..close();
    canvas.drawPath(rTuft, tuftPaint);

    // ── Face disk ─────────────────────────────────────────────────────────────
    final facePaint = Paint()..color = _tealLight.withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.42), width: w * 0.62, height: h * 0.44),
      facePaint,
    );

    // ── Eyes ──────────────────────────────────────────────────────────────────
    _drawEye(canvas, w * 0.335, h * 0.40, w * 0.115);
    _drawEye(canvas, w * 0.665, h * 0.40, w * 0.115);

    // ── Beak ──────────────────────────────────────────────────────────────────
    final beakPaint = Paint()..color = _amber;
    final beak = Path()
      ..moveTo(w * 0.5, h * 0.455)
      ..lineTo(w * 0.44, h * 0.505)
      ..lineTo(w * 0.5, h * 0.530)
      ..lineTo(w * 0.56, h * 0.505)
      ..close();
    canvas.drawPath(beak, beakPaint);

    // ── Feet ──────────────────────────────────────────────────────────────────
    final feetPaint = Paint()
      ..color = _amber
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    // Left foot
    canvas.drawLine(Offset(w * 0.37, h * 0.955), Offset(w * 0.25, h * 0.985), feetPaint);
    canvas.drawLine(Offset(w * 0.37, h * 0.955), Offset(w * 0.35, h * 0.998), feetPaint);
    canvas.drawLine(Offset(w * 0.37, h * 0.955), Offset(w * 0.45, h * 0.985), feetPaint);

    // Right foot
    canvas.drawLine(Offset(w * 0.63, h * 0.955), Offset(w * 0.55, h * 0.985), feetPaint);
    canvas.drawLine(Offset(w * 0.63, h * 0.955), Offset(w * 0.65, h * 0.998), feetPaint);
    canvas.drawLine(Offset(w * 0.63, h * 0.955), Offset(w * 0.75, h * 0.985), feetPaint);
  }

  void _drawEye(Canvas canvas, double cx, double cy, double r) {
    // Outer white ring
    final outerPaint = Paint()..color = _white;
    canvas.drawCircle(Offset(cx, cy), r, outerPaint);

    // Teal iris
    final irisPaint = Paint()..color = _teal.withOpacity(0.25);
    canvas.drawCircle(Offset(cx, cy), r * 0.72, irisPaint);

    if (isBlinking) {
      // Blink: draw a horizontal line covering the eye
      final blinkPaint = Paint()
        ..color = _tealDark
        ..strokeWidth = r * 0.55
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - r * 0.55, cy), Offset(cx + r * 0.55, cy), blinkPaint);
    } else {
      // Pupil
      final pupilPaint = Paint()..color = _navy;
      canvas.drawCircle(Offset(cx + r * 0.08, cy - r * 0.05), r * 0.40, pupilPaint);

      // Pupil shine
      final shinePaint = Paint()..color = _white;
      canvas.drawCircle(Offset(cx + r * 0.16, cy - r * 0.16), r * 0.12, shinePaint);

      // Mood eyebrows
      _drawBrow(canvas, cx, cy, r);
    }

    // Eye ring outline
    final ringPaint = Paint()
      ..color = _teal.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);
  }

  void _drawBrow(Canvas canvas, double cx, double cy, double r) {
    final browPaint = Paint()
      ..color = _tealDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeCap = StrokeCap.round;

    final isLeft = cx < 0.5; // rough check
    switch (mood) {
      case OwlMood.happy:
        // Arched brow
        final p = Path()
          ..moveTo(cx - r * 0.55, cy - r * 1.05)
          ..quadraticBezierTo(cx, cy - r * 1.35, cx + r * 0.55, cy - r * 1.05);
        canvas.drawPath(p, browPaint);
      case OwlMood.thinking:
        // Straight brow tilted
        canvas.drawLine(
          Offset(cx - r * 0.55, cy - r * (isLeft ? 1.10 : 0.95)),
          Offset(cx + r * 0.55, cy - r * (isLeft ? 0.95 : 1.10)),
          browPaint,
        );
      case OwlMood.excited:
        // Raised arched brow
        final p = Path()
          ..moveTo(cx - r * 0.60, cy - r * 1.20)
          ..quadraticBezierTo(cx, cy - r * 1.55, cx + r * 0.60, cy - r * 1.20);
        canvas.drawPath(p, browPaint);
      case OwlMood.sad:
        // Drooping brow
        final p = Path()
          ..moveTo(cx - r * 0.55, cy - r * (isLeft ? 0.95 : 1.10))
          ..quadraticBezierTo(cx, cy - r * 0.85, cx + r * 0.55, cy - r * (isLeft ? 1.10 : 0.95));
        canvas.drawPath(p, browPaint);
      case OwlMood.neutral:
        // Gentle arch
        final p = Path()
          ..moveTo(cx - r * 0.50, cy - r * 1.02)
          ..quadraticBezierTo(cx, cy - r * 1.22, cx + r * 0.50, cy - r * 1.02);
        canvas.drawPath(p, browPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OwlPainter old) =>
      old.isBlinking != isBlinking || old.mood != mood;
}
