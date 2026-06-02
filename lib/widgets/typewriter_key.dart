import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../theme/key_texture.dart';
import 'keycap_painter.dart';

/// A round keycap whose surface is rendered by a GLSL material shader
/// (per-pixel diffuse + specular + rim AO), with a soft cast shadow for depth
/// and a press animation. Crystal stays real BackdropFilter glass.
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

        final raised = <BoxShadow>[
          BoxShadow(color: _d(0.22), offset: Offset(w * 0.03, h * 0.055), blurRadius: h * 0.13),
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 2), blurRadius: 5),
        ];
        final pressed = <BoxShadow>[
          BoxShadow(color: _d(0.14), offset: Offset(0, h * 0.012), blurRadius: h * 0.035),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: crystal ? crystalShadow : (_down ? pressed : raised),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (crystal) ...[
                  _crystalGlass(),
                  CustomPaint(painter: KeycapPainter(color: widget.color, texture: t, pressed: _down ? 1 : 0)),
                ] else
                  CustomPaint(painter: KeycapPainter(color: widget.color, texture: t, pressed: _down ? 1 : 0)),
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

  // Real see-through base: a frosted blur with only a faint tint. The shader
  // overlay (texture 2) adds the fresnel rim + glint on top.
  Widget _crystalGlass() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
