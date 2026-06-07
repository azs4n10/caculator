import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../settings.dart';
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
    tapHaptic();
    widget.onTap();
  }

  Color _d(double t) => Color.lerp(widget.color, Colors.black, t)!;

  // Operator glyphs are drawn as crisp vector strokes (not font characters) so
  // they sit *exactly* centred in the round keycap regardless of the chosen
  // font — font glyphs for × ÷ − + = sit high on the math axis and never
  // centre reliably across fonts.
  static const _vectorOps = {'×', '÷', '−', '-', '+', '='};

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

        // A subtle rim so keys stay defined against the background — lighter on
        // dark keys (dark themes), darker on light keys.
        final dark = widget.color.computeLuminance() < 0.45;
        final borderColor = dark
            ? Color.lerp(widget.color, Colors.white, 0.32)!
            : Color.lerp(widget.color, Colors.black, 0.10)!;

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
              border: crystal ? null : Border.all(color: borderColor, width: dark ? 1.3 : 1.0),
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
                if (_vectorOps.contains(widget.label))
                  CustomPaint(
                    painter: _OpGlyphPainter(
                      label: widget.label,
                      color: widget.textColor,
                      sizeFactor: widget.sizeFactor,
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(widget.label, style: Kawaii.key(h * widget.sizeFactor).copyWith(color: widget.textColor)),
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

/// Draws the calculator operators (× ÷ − + =) as rounded vector strokes,
/// perfectly centred in the keycap. Sized to roughly match the digit glyphs.
class _OpGlyphPainter extends CustomPainter {
  final String label;
  final Color color;
  final double sizeFactor;
  _OpGlyphPainter({required this.label, required this.color, required this.sizeFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final m = size.shortestSide;
    final e = m * sizeFactor * 0.34; // half-extent of the symbol
    final sw = m * sizeFactor * 0.135; // stroke width
    final stroke = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    switch (label) {
      case '−':
      case '-':
        canvas.drawLine(c + Offset(-e, 0), c + Offset(e, 0), stroke);
        break;
      case '+':
        canvas.drawLine(c + Offset(-e, 0), c + Offset(e, 0), stroke);
        canvas.drawLine(c + Offset(0, -e), c + Offset(0, e), stroke);
        break;
      case '×':
        final d = e * 0.8; // diagonals read larger, so trim a little
        canvas.drawLine(c + Offset(-d, -d), c + Offset(d, d), stroke);
        canvas.drawLine(c + Offset(-d, d), c + Offset(d, -d), stroke);
        break;
      case '÷':
        canvas.drawLine(c + Offset(-e, 0), c + Offset(e, 0), stroke);
        final dot = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(c + Offset(0, -e * 0.86), sw * 0.62, dot);
        canvas.drawCircle(c + Offset(0, e * 0.86), sw * 0.62, dot);
        break;
      case '=':
        final gap = e * 0.46;
        canvas.drawLine(c + Offset(-e, -gap), c + Offset(e, -gap), stroke);
        canvas.drawLine(c + Offset(-e, gap), c + Offset(e, gap), stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(_OpGlyphPainter old) =>
      old.label != label || old.color != color || old.sizeFactor != sizeFactor;
}
