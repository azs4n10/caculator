import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A chunky 3D keycap that depresses when tapped — the "typewriter" feel.
///
/// The cap sits on a darker [edge] "stem"; pressing translates the cap down
/// onto the stem and softens its shadow, mimicking a mechanical key travel.
class TypewriterKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color edge;
  final Color textColor;
  final double fontSize;
  final double height;
  final Widget? child;

  const TypewriterKey({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.edge,
    required this.textColor,
    this.fontSize = 24,
    this.height = 58,
    this.child,
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
    const travel = 5.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        _press();
      },
      child: SizedBox(
        height: widget.height + travel,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.edge,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 55),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _down ? travel : 0,
              child: Container(
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: widget.edge.withValues(alpha: 0.5), width: 1),
                  boxShadow: _down
                      ? []
                      : [
                          BoxShadow(
                            color: widget.edge.withValues(alpha: 0.55),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: widget.child ??
                    Text(widget.label, style: Kawaii.key(widget.fontSize).copyWith(color: widget.textColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
