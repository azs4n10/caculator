import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/key_texture.dart';

/// The compiled keycap shader, loaded once in `main()`. Null until loaded (or
/// if shaders are unavailable on the platform), in which case the painter falls
/// back to a flat fill.
ui.FragmentProgram? keycapProgram;

Future<void> loadKeycapShader() async {
  try {
    keycapProgram = await ui.FragmentProgram.fromAsset('shaders/keycap.frag');
  } catch (_) {
    keycapProgram = null;
  }
}

int _texIndex(KeyTexture t) => switch (t) {
      KeyTexture.glossy => 0,
      KeyTexture.matte => 1,
      KeyTexture.crystal => 2,
      KeyTexture.jelly => 3,
    };

/// Paints a single keycap surface (circle) using the GLSL material shader.
class KeycapPainter extends CustomPainter {
  final Color color;
  final KeyTexture texture;
  final double pressed;
  KeycapPainter({required this.color, required this.texture, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final prog = keycapProgram;
    if (prog == null) {
      canvas.drawOval(Offset.zero & size, Paint()..color = color);
      return;
    }
    final sh = prog.fragmentShader();
    sh.setFloat(0, size.width);
    sh.setFloat(1, size.height);
    sh.setFloat(2, color.r);
    sh.setFloat(3, color.g);
    sh.setFloat(4, color.b);
    sh.setFloat(5, color.a);
    sh.setFloat(6, _texIndex(texture).toDouble());
    sh.setFloat(7, pressed);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sh);
  }

  @override
  bool shouldRepaint(KeycapPainter old) =>
      old.color != color || old.texture != texture || old.pressed != pressed;
}
