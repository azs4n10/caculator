import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../theme/key_texture.dart';

/// A soft, cushioned rounded-square keycap (modelled on the key3 reference):
/// a raised cap lit from the top-left (light highlight) and shaded to the
/// bottom-right (soft drop shadow), with an inflated glossy top face. [texture]
/// swaps the material: glossy cushion / matte / clear crystal / jelly.
/// Fills its parent box — wrap in a square (AspectRatio 1).
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
        final r = BorderRadius.circular(h * 0.30);
        final shift = h * 0.05;
        final crystal = t == KeyTexture.crystal;

        // Raised cushion: white highlight at the top-left, soft dark shadow at
        // the bottom-right.
        final raised = <BoxShadow>[
          BoxShadow(color: _d(0.20), offset: Offset(w * 0.045, h * 0.06), blurRadius: h * 0.16),
          BoxShadow(color: Colors.white.withValues(alpha: 0.5), offset: Offset(-w * 0.035, -h * 0.05), blurRadius: h * 0.12),
        ];
        final pressed = <BoxShadow>[
          BoxShadow(color: _d(0.13), offset: Offset(w * 0.012, h * 0.018), blurRadius: h * 0.04),
          BoxShadow(color: Colors.white.withValues(alpha: 0.28), offset: Offset(-w * 0.01, -h * 0.012), blurRadius: h * 0.03),
        ];
        final crystalShadow = <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: _down ? 0.06 : 0.16), offset: Offset(0, _down ? 1 : 3.5), blurRadius: _down ? 3 : 7),
        ];

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
            decoration: BoxDecoration(borderRadius: r, boxShadow: crystal ? crystalShadow : (_down ? pressed : raised)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                crystal ? _crystal(r) : _solidCap(t, r, w, h),
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

  Widget _solidCap(KeyTexture t, BorderRadius r, double w, double h) {
    final base = t == KeyTexture.jelly ? widget.color.withValues(alpha: 0.74) : widget.color;
    final topFace = t == KeyTexture.matte
        ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_l(0.12), _d(0.03)])
        : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_l(0.42), _l(0.10), _d(0.05)], stops: const [0, 0.5, 1]);
    return DecoratedBox(
      decoration: BoxDecoration(color: base, borderRadius: r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: h * 0.10,
            left: w * 0.13,
            right: w * 0.13,
            bottom: h * 0.22,
            child: DecoratedBox(decoration: BoxDecoration(gradient: topFace, borderRadius: BorderRadius.circular(h * 0.22))),
          ),
        ],
      ),
    );
  }

  Widget _crystal(BorderRadius r) {
    // Clear glass cushion: a real BackdropFilter so the background shows through.
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
          borderRadius: r,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
        ),
      ),
    );
    return ClipRRect(borderRadius: r, child: glass);
  }
}
