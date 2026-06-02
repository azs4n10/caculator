import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../theme/key_texture.dart';

/// A round keycap on a stem. Pressing drops the cap onto the stem. Only the
/// material changes with [texture]:
///  - matte: flat,
///  - glossy: a soft top-lit dome (gradient, no highlight blob),
///  - crystal: clear glass — a BackdropFilter blurs what's behind so the
///    background genuinely shows through,
///  - jelly: translucent frosted gummy (the background tints through).
/// Fills its parent box — wrap in a square (AspectRatio 1) for a true circle.
class TypewriterKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color edge;
  final Color textColor;
  final KeyTexture texture;
  final double sizeFactor;

  const TypewriterKey({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.edge,
    required this.textColor,
    this.texture = KeyTexture.glossy,
    this.sizeFactor = 0.46,
  });

  @override
  State<TypewriterKey> createState() => _TypewriterKeyState();
}

class _TypewriterKeyState extends State<TypewriterKey> {
  bool _down = false;

  void _press() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  Color _l(double t) => Color.lerp(widget.color, Colors.white, t)!;
  Color _d(double t) => Color.lerp(widget.color, Colors.black, t)!;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final t = widget.texture;
        final travel = (c.maxHeight * (t == KeyTexture.jelly ? 0.15 : 0.13))
            .clamp(4.0, t == KeyTexture.jelly ? 11.0 : 9.0);
        const bw = 1.5;
        // Convex dome: bright near the top, shaded at the rim — reads 3D without
        // a discrete highlight blob.
        const domeCenter = Alignment(-0.1, -0.45);

        Color stem = widget.edge;
        Widget capBg;

        switch (t) {
          case KeyTexture.matte:
            capBg = _circle(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_l(0.05), widget.color, _d(0.05)], stops: const [0, 0.5, 1]),
              border: widget.edge,
              shadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), offset: const Offset(0, 2), blurRadius: 4)],
            );
            break;
          case KeyTexture.glossy:
            capBg = _circle(
              gradient: RadialGradient(center: domeCenter, radius: 0.95, colors: [_l(0.24), widget.color, _d(0.08)], stops: const [0, 0.55, 1]),
              border: widget.edge,
              shadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), offset: const Offset(0, 3.5), blurRadius: 6)],
            );
            break;
          case KeyTexture.jelly:
            stem = widget.edge.withValues(alpha: 0.55);
            capBg = _circle(
              gradient: RadialGradient(center: domeCenter, radius: 0.95, colors: [
                widget.color.withValues(alpha: 0.55),
                widget.color.withValues(alpha: 0.76),
                _d(0.06).withValues(alpha: 0.76),
              ], stops: const [0, 0.55, 1]),
              border: widget.edge.withValues(alpha: 0.5),
              shadow: [
                BoxShadow(color: widget.color.withValues(alpha: 0.45), offset: const Offset(0, 5), blurRadius: 10),
                BoxShadow(color: Colors.black.withValues(alpha: 0.10), offset: const Offset(0, 2), blurRadius: 5),
              ],
            );
            break;
          case KeyTexture.crystal:
            stem = widget.edge.withValues(alpha: 0.35);
            capBg = _crystal(bw);
            break;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) {
            setState(() => _down = false);
            _press();
          },
          child: Stack(
            children: [
              // Stem (gives the cap its depth).
              Positioned(
                left: 0,
                right: 0,
                top: travel,
                bottom: 0,
                child: DecoratedBox(decoration: BoxDecoration(color: stem, shape: BoxShape.circle)),
              ),
              // Cap.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 55),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _down ? travel : 0,
                bottom: _down ? 0 : travel,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    capBg,
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: c.maxWidth * 0.12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(widget.label,
                              style: Kawaii.key(c.maxHeight * widget.sizeFactor).copyWith(color: widget.textColor)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circle({
    Gradient? gradient,
    Color? color,
    required Color border,
    required List<BoxShadow> shadow,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: _down ? [] : shadow,
      ),
    );
  }

  Widget _crystal(double bw) {
    final glass = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: bw),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _down ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(0, 3), blurRadius: 7)],
          ),
        ),
        ClipOval(child: glass),
      ],
    );
  }
}
