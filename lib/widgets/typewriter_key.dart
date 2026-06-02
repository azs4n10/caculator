import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../theme/key_texture.dart';

/// A soft, cushioned ROUND keycap. It's lit from the top-left (a white
/// highlight) and shaded to the bottom-right (a soft drop shadow), with a
/// radial dome gradient, so it reads as a puffy pillow — the key3 feel, kept
/// circular. [texture] swaps the material: glossy cushion / matte / clear
/// crystal / jelly. Fills its parent box — wrap in a square (AspectRatio 1).
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

  static const _mathAxis = {'×', '÷', '−', '-', '+', '='};
  double _dy(double size) => _mathAxis.contains(widget.label) ? size * 0.09 : 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final t = widget.texture;
        final shift = h * 0.045;
        final crystal = t == KeyTexture.crystal;
        const dome = Alignment(-0.35, -0.45); // highlight toward the top-left

        // Soft cushion lighting: white highlight top-left, soft dark shadow
        // bottom-right.
        final raised = <BoxShadow>[
          BoxShadow(color: _d(0.20), offset: Offset(w * 0.04, h * 0.06), blurRadius: h * 0.15),
          BoxShadow(color: Colors.white.withValues(alpha: 0.5), offset: Offset(-w * 0.035, -h * 0.05), blurRadius: h * 0.12),
        ];
        final pressed = <BoxShadow>[
          BoxShadow(color: _d(0.13), offset: Offset(w * 0.012, h * 0.018), blurRadius: h * 0.04),
          BoxShadow(color: Colors.white.withValues(alpha: 0.28), offset: Offset(-w * 0.01, -h * 0.012), blurRadius: h * 0.03),
        ];
        final crystalShadow = <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: _down ? 0.06 : 0.16), offset: Offset(0, _down ? 1 : 3.5), blurRadius: _down ? 3 : 7),
        ];

        Gradient? capGradient;
        switch (t) {
          case KeyTexture.matte:
            capGradient = RadialGradient(center: dome, radius: 1.0, colors: [_l(0.10), widget.color, _d(0.04)], stops: const [0, 0.6, 1]);
            break;
          case KeyTexture.glossy:
            capGradient = RadialGradient(center: dome, radius: 1.0, colors: [_l(0.34), widget.color, _d(0.07)], stops: const [0, 0.58, 1]);
            break;
          case KeyTexture.jelly:
            capGradient = RadialGradient(center: dome, radius: 1.0, colors: [
              widget.color.withValues(alpha: 0.6),
              widget.color.withValues(alpha: 0.78),
              _d(0.06).withValues(alpha: 0.78),
            ], stops: const [0, 0.58, 1]);
            break;
          case KeyTexture.crystal:
            capGradient = null;
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(top: _down ? shift : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: capGradient,
              boxShadow: crystal ? crystalShadow : (_down ? pressed : raised),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (crystal) _crystal(),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.12),
                    child: Transform.translate(
                      offset: Offset(0, _dy(h * widget.sizeFactor)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(widget.label, style: Kawaii.key(h * widget.sizeFactor).copyWith(color: widget.textColor)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crystal() {
    // Clear glass — a real BackdropFilter so the background shows through.
    final glass = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x6BFFFFFF), Color(0x1FFFFFFF), Color(0x14000000)],
            stops: [0, 0.55, 1],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
        ),
      ),
    );
    return ClipOval(child: glass);
  }
}
