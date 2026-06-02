import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/skin.dart';

/// Font helpers. [family] is the currently selected Google Fonts family — set
/// once per build from the FontScope so every call picks up the user's choice.
/// Colours live on [CalcSkin]; callers pass them via `.copyWith`/`color`.
class Kawaii {
  static String family = 'Quicksand';

  // Cute typefaces top out at weight 700; keep below that so headings never
  // fall back to a default font. Lighter weights also read as less "loud".
  static FontWeight _cap(FontWeight w) => w.value > FontWeight.w700.value ? FontWeight.w700 : w;

  static TextStyle key(double size) =>
      GoogleFonts.getFont(family, fontSize: size, fontWeight: FontWeight.w600, height: 1.0);

  static TextStyle display(double size) =>
      GoogleFonts.getFont(family, fontSize: size, fontWeight: FontWeight.w600, letterSpacing: -0.2);

  static TextStyle ui(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.getFont(family, fontSize: size, fontWeight: _cap(weight), color: color);
}

ThemeData buildAppTheme(CalcSkin skin) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: skin.isDark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: skin.accentColor,
    scaffoldBackgroundColor: skin.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.getTextTheme(Kawaii.family, base.textTheme)
        .apply(bodyColor: skin.primaryTextColor, displayColor: skin.primaryTextColor),
  );
}
