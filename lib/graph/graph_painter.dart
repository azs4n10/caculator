import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine.dart';
import '../theme/skin.dart';

class PlotFn {
  final RealFn f;
  final Color color;
  const PlotFn(this.f, this.color);
}

/// Draws a Cartesian plane with grid, axes, tick labels and one or more
/// y = f(x) curves. Curves break at non-finite values and across steep jumps
/// (vertical asymptotes like tan).
class GraphPainter extends CustomPainter {
  final List<PlotFn> fns;
  final double xMin, xMax, yMin, yMax;
  final CalcSkin skin;

  GraphPainter({
    required this.fns,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.skin,
  });

  double _sx(double x, double w) => (x - xMin) / (xMax - xMin) * w;
  double _sy(double y, double h) => h - (y - yMin) / (yMax - yMin) * h;

  static double _niceStep(double range, int target) {
    if (range <= 0) return 1;
    final raw = range / target;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final norm = raw / mag;
    final step = norm < 1.5 ? 1.0 : (norm < 3 ? 2.0 : (norm < 7 ? 5.0 : 10.0));
    return step * mag;
  }

  String _fmt(double v, double step) {
    if (v.abs() < step / 1000) return '0';
    final decimals = step < 1 ? (math.log(1 / step) / math.ln10).ceil().clamp(0, 4) : 0;
    return v.toStringAsFixed(decimals);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = skin.paper);

    final grid = Paint()
      ..color = skin.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = skin.inkSoft
      ..strokeWidth = 1.6;

    final xStep = _niceStep(xMax - xMin, 8);
    final yStep = _niceStep(yMax - yMin, 8);

    // Vertical grid + x tick labels.
    for (var x = (xMin / xStep).ceil() * xStep; x <= xMax; x += xStep) {
      final px = _sx(x, w);
      canvas.drawLine(Offset(px, 0), Offset(px, h), grid);
      if ((x).abs() > xStep / 1000) {
        _label(canvas, _fmt(x, xStep), Offset(px + 3, _sy(0, h).clamp(0, h - 14) + 2));
      }
    }
    // Horizontal grid + y tick labels.
    for (var y = (yMin / yStep).ceil() * yStep; y <= yMax; y += yStep) {
      final py = _sy(y, h);
      canvas.drawLine(Offset(0, py), Offset(w, py), grid);
      if ((y).abs() > yStep / 1000) {
        _label(canvas, _fmt(y, yStep), Offset(_sx(0, w).clamp(2, w - 30) + 3, py + 2));
      }
    }

    // Axes.
    if (yMin <= 0 && yMax >= 0) {
      final py = _sy(0, h);
      canvas.drawLine(Offset(0, py), Offset(w, py), axis);
    }
    if (xMin <= 0 && xMax >= 0) {
      final px = _sx(0, w);
      canvas.drawLine(Offset(px, 0), Offset(px, h), axis);
    }

    // Curves.
    final dx = (xMax - xMin) / w;
    for (final plot in fns) {
      final paint = Paint()
        ..color = plot.color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      var pen = false; // is the path "down" (has a current point)?
      double? prevPy;
      for (var i = 0; i <= w; i++) {
        final x = xMin + i * dx;
        final y = plot.f(x);
        if (!y.isFinite) {
          pen = false;
          prevPy = null;
          continue;
        }
        final px = i.toDouble();
        final py = _sy(y, h);
        // Break across steep jumps (asymptotes) to avoid spurious verticals.
        final jump = prevPy != null && (py - prevPy).abs() > h * 1.5;
        if (!pen || jump) {
          path.moveTo(px, py);
          pen = true;
        } else {
          path.lineTo(px, py);
        }
        prevPy = py;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: skin.inkSoft, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.xMin != xMin ||
      old.xMax != xMax ||
      old.yMin != yMin ||
      old.yMax != yMax ||
      old.skin.id != skin.id ||
      old.fns != fns;
}
