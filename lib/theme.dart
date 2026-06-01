import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/skin.dart';

/// Font helpers for the kawaii calculator. Colours now live on [CalcSkin];
/// callers pass colours via `.copyWith(color: ...)` or the `color` argument.
class Kawaii {
  static TextStyle display(double size) => GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle key(double size) => GoogleFonts.baloo2(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );

  static TextStyle ui(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.mPlusRounded1c(fontSize: size, fontWeight: weight, color: color);
}

ThemeData buildAppTheme(CalcSkin skin) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: skin.isDark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: skin.accentColor,
    scaffoldBackgroundColor: skin.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.mPlusRounded1cTextTheme(base.textTheme)
        .apply(bodyColor: skin.primaryTextColor, displayColor: skin.primaryTextColor),
  );
}
