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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final t = widget.texture;
        final travel = (c.maxHeight * (t == KeyTexture.jelly ? 0.13 : 0.10))
            .clamp(3.0, t == KeyTexture.jelly ? 9.0 : 7.0);
        const bw = 1.5;

        Color stem = widget.edge;
        Widget capBg;

        switch (t) {
          case KeyTexture.matte:
            capBg = _circle(color: widget.color, border: widget.edge, shadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.09), offset: const Offset(0, 1.5), blurRadius: 3),
            ]);
            break;
          case KeyTexture.glossy:
            capBg = _circle(gradient: [_l(0.16), widget.color], border: widget.edge, shadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.13), offset: const Offset(0, 2.5), blurRadius: 5),
            ]);
            break;
          case KeyTexture.jelly:
            stem = widget.edge.withValues(alpha: 0.5);
            capBg = _circle(color: widget.color.withValues(alpha: 0.72), border: widget.edge.withValues(alpha: 0.5), shadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 9),
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), offset: const Offset(0, 2), blurRadius: 5),
            ]);
            break;
          case KeyTexture.crystal:
            stem = widget.edge.withValues(alpha: 0.3);
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
    Color? color,
    List<Color>? gradient,
    required Color border,
    required List<BoxShadow> shadow,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient == null ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
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
