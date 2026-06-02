import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A retro typewriter keycap (think Lofree / Qwerkywriter): a round cap sitting
/// on a darker stem, with a metallic rim ring. Pressing drops the cap onto the
/// stem. Fills its parent box — wrap in a square (AspectRatio 1) for a true
/// circle. Set [round] = false for a rounded-square cap (used by small keys).
class TypewriterKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color edge;
  final Color textColor;
  final double fontSize;
  final bool round;

  const TypewriterKey({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.edge,
    required this.textColor,
    this.fontSize = 24,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final travel = (c.maxHeight * 0.10).clamp(3.0, 7.0);
        final shape = widget.round ? BoxShape.circle : BoxShape.rectangle;
        final radius = widget.round ? null : BorderRadius.circular(c.maxWidth * 0.30);

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
              // Stem (the post the cap rests on).
              Positioned(
                left: 0,
                right: 0,
                top: travel,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: widget.edge, shape: shape, borderRadius: radius),
                ),
              ),
              // Cap.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 55),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _down ? travel : 0,
                bottom: _down ? 0 : travel,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Glossy dome: lighter at the top, fading to the fill — gives
                    // every key (even white ones) a consistent 3D read.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(widget.color, Colors.white, 0.16)!, widget.color],
                    ),
                    shape: shape,
                    borderRadius: radius,
                    // Rim uses the (darker) edge colour so the cap is always
                    // outlined, regardless of how light the fill is.
                    border: Border.all(color: widget.edge, width: widget.round ? 1.6 : 1.3),
                    boxShadow: _down
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              offset: const Offset(0, 2.5),
                              blurRadius: 5,
                            ),
                          ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          style: Kawaii.key(widget.fontSize).copyWith(color: widget.textColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
