import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/skin.dart';

/// Font helpers. [family] is the currently selected Google Fonts family — set
/// once per build from the FontScope so every call picks up the user's choice.
/// Colours live on [CalcSkin]; callers pass them via `.copyWith`/`color`.
class Kawaii {
  static String family = 'Baloo 2';

  static TextStyle key(double size) =>
      GoogleFonts.getFont(family, fontSize: size, fontWeight: FontWeight.w700, height: 1.0);

  static TextStyle display(double size) => GoogleFonts.getFont(family,
      fontSize: size, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  static TextStyle ui(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.getFont(family, fontSize: size, fontWeight: weight, color: color);
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
