import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../theme/key_texture.dart';

/// A round keycap on a stem with a rim. Pressing drops the cap onto the stem.
/// The [texture] changes the tactile material:
///  - glossy: a lit dome,
///  - matte: flat,
///  - crystal: REAL glass — a BackdropFilter blurs whatever is behind the key
///    so the background genuinely shows through (not a painted fake),
///  - jelly: squishy gloss with a coloured soft shadow.
/// Fills its parent box — wrap in a square (AspectRatio 1) for a true circle.
class TypewriterKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color edge;
  final Color textColor;
  final KeyTexture texture;
  final double sizeFactor;
  final bool round;

  const TypewriterKey({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.edge,
    required this.textColor,
    this.texture = KeyTexture.glossy,
    this.sizeFactor = 0.46,
    this.round = true,
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
        final shape = widget.round ? BoxShape.circle : BoxShape.rectangle;
        final radius = widget.round ? null : BorderRadius.circular(c.maxWidth * 0.30);
        final travelFactor = t == KeyTexture.jelly ? 0.15 : 0.10;
        final travel = (c.maxHeight * travelFactor).clamp(3.0, t == KeyTexture.jelly ? 10.0 : 7.0);
        final bw = widget.round ? 1.6 : 1.3;

        // Stem colour: transparent for crystal so the real background shows.
        final Color stem = t == KeyTexture.crystal ? Colors.transparent : widget.edge;

        final cap = _cap(t, shape, radius, bw);
        final sheen = _sheen(t, c);

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
              if (t != KeyTexture.crystal)
                Positioned(
                  left: 0,
                  right: 0,
                  top: travel,
                  bottom: 0,
                  child: DecoratedBox(decoration: BoxDecoration(color: stem, shape: shape, borderRadius: radius)),
                ),
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
                    cap,
                    ?sheen,
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

  /// The cap background for the given texture.
  Widget _cap(KeyTexture t, BoxShape shape, BorderRadius? radius, double bw) {
    final shadow = _down
        ? <BoxShadow>[]
        : [BoxShadow(color: Colors.black.withValues(alpha: 0.13), offset: const Offset(0, 2.5), blurRadius: 5)];

    switch (t) {
      case KeyTexture.matte:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: shape,
            borderRadius: radius,
            border: Border.all(color: widget.edge, width: bw),
            boxShadow: _down ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.09), offset: const Offset(0, 1.5), blurRadius: 3)],
          ),
        );

      case KeyTexture.jelly:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_l(0.32), widget.color]),
            shape: shape,
            borderRadius: radius,
            border: Border.all(color: widget.edge.withValues(alpha: 0.6), width: bw),
            boxShadow: _down
                ? []
                : [
                    BoxShadow(color: widget.color.withValues(alpha: 0.5), offset: const Offset(0, 5), blurRadius: 11),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(0, 3), blurRadius: 6),
                  ],
          ),
        );

      case KeyTexture.glossy:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_l(0.16), widget.color]),
            shape: shape,
            borderRadius: radius,
            border: Border.all(color: widget.edge, width: bw),
            boxShadow: shadow,
          ),
        );

      case KeyTexture.crystal:
        // Real glass: blur whatever is painted behind the key, with only a faint
        // frost tint on top, so the background genuinely shows through.
        final glass = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: shape,
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: bw),
            ),
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            // shadow only (transparent fill) for a little depth
            DecoratedBox(
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: radius,
                boxShadow: _down ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(0, 3), blurRadius: 7)],
              ),
            ),
            if (widget.round) ClipOval(child: glass) else ClipRRect(borderRadius: radius!, child: glass),
          ],
        );
    }
  }

  /// Optional glossy highlight blob near the top of the cap.
  Widget? _sheen(KeyTexture t, BoxConstraints c) {
    final alpha = switch (t) {
      KeyTexture.jelly => 0.5,
      KeyTexture.crystal => 0.4,
      _ => 0.0,
    };
    if (alpha == 0) return null;
    return Positioned(
      top: c.maxHeight * 0.10,
      left: c.maxWidth * 0.24,
      right: c.maxWidth * 0.24,
      height: c.maxHeight * 0.22,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(c.maxHeight * 0.2),
        ),
      ),
    );
  }
}
