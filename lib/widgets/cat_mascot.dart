import 'package:flutter/material.dart';
import '../theme/skin.dart';

enum CatMood { idle, happy, error }

/// A tiny vector cat that reacts to the calculator's state. Colours come from
/// the active [CalcSkin] so it matches every theme.
class CatMascot extends StatelessWidget {
  final CatMood mood;
  final double size;
  final CalcSkin skin;
  const CatMascot({super.key, this.mood = CatMood.idle, this.size = 48, required this.skin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CatPainter(mood, skin)),
    );
  }
}

class _CatPainter extends CustomPainter {
  final CatMood mood;
  final CalcSkin skin;
  _CatPainter(this.mood, this.skin);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final face = Paint()..color = skin.mascotFace;
    final outline = Paint()
      ..color = skin.inkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final ear = Paint()..color = skin.mascotEar;
    final ink = Paint()
      ..color = skin.mascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    final blush = Paint()..color = skin.mascotBlush.withValues(alpha: 0.55);

    Path tri(Offset a, Offset b, Offset c) =>
        Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..close();
    canvas.drawPath(tri(Offset(w * 0.18, h * 0.30), Offset(w * 0.30, h * 0.05), Offset(w * 0.44, h * 0.22)), ear);
    canvas.drawPath(tri(Offset(w * 0.82, h * 0.30), Offset(w * 0.70, h * 0.05), Offset(w * 0.56, h * 0.22)), ear);

    final headRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.74, height: h * 0.66);
    final head = RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.34));
    canvas.drawRRect(head, face);
    canvas.drawRRect(head, outline);

    canvas.drawCircle(Offset(w * 0.28, h * 0.62), w * 0.07, blush);
    canvas.drawCircle(Offset(w * 0.72, h * 0.62), w * 0.07, blush);

    final lEye = Offset(w * 0.37, h * 0.52);
    final rEye = Offset(w * 0.63, h * 0.52);

    switch (mood) {
      case CatMood.idle:
        final dot = Paint()..color = skin.mascotInk;
        canvas.drawCircle(lEye, w * 0.045, dot);
        canvas.drawCircle(rEye, w * 0.045, dot);
        final smile = Path()
          ..moveTo(w * 0.44, h * 0.66)
          ..quadraticBezierTo(w * 0.5, h * 0.72, w * 0.56, h * 0.66);
        canvas.drawPath(smile, ink);
        break;
      case CatMood.happy:
        for (final c in [lEye, rEye]) {
          final p = Path()
            ..moveTo(c.dx - w * 0.05, c.dy + h * 0.01)
            ..quadraticBezierTo(c.dx, c.dy - h * 0.05, c.dx + w * 0.05, c.dy + h * 0.01);
          canvas.drawPath(p, ink);
        }
        final smile = Path()
          ..moveTo(w * 0.42, h * 0.65)
          ..quadraticBezierTo(w * 0.5, h * 0.76, w * 0.58, h * 0.65);
        canvas.drawPath(smile, ink);
        break;
      case CatMood.error:
        final dot = Paint()..color = skin.mascotInk;
        canvas.drawCircle(lEye, w * 0.05, dot);
        canvas.drawCircle(rEye, w * 0.05, dot);
        canvas.drawCircle(Offset(w * 0.5, h * 0.69), w * 0.045, ink);
        break;
    }

    final wh = Paint()
      ..color = skin.inkSoft.withValues(alpha: 0.7)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.02, h * 0.55), Offset(w * 0.2, h * 0.57), wh);
    canvas.drawLine(Offset(w * 0.02, h * 0.63), Offset(w * 0.2, h * 0.63), wh);
    canvas.drawLine(Offset(w * 0.98, h * 0.55), Offset(w * 0.8, h * 0.57), wh);
    canvas.drawLine(Offset(w * 0.98, h * 0.63), Offset(w * 0.8, h * 0.63), wh);
  }

  @override
  bool shouldRepaint(_CatPainter old) => old.mood != mood || old.skin.id != skin.id;
}
