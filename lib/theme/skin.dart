import 'package:flutter/material.dart';

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
Color _darken(Color c, [double t = 0.10]) => _mix(c, Colors.black, t);
Color _lighten(Color c, [double t = 0.10]) => _mix(c, Colors.white, t);

/// A kawaii colour scheme. The base palette mirrors the flipclock app's skins;
/// the calculator needs more colour roles than a clock (number / operator /
/// function / clear / equals / 2nd keys), so those are *derived* from the base
/// palette here — keeping every skin consistent and easy to add.
@immutable
class CalcSkin {
  const CalcSkin({
    required this.id,
    required this.name,
    required this.isDark,
    required this.background,
    required this.cardBackground,
    required this.digitColor,
    required this.accentColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.primaryTextColor,
    required this.subTextColor,
    required this.dividerColor,
  });

  final String id;
  final String name;
  final bool isDark;
  final Color background;
  final Color cardBackground;
  final Color digitColor;
  final Color accentColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color primaryTextColor;
  final Color subTextColor;
  final Color dividerColor;

  // --- Semantic roles ---
  Color get ink => primaryTextColor;
  Color get inkSoft => subTextColor;
  Color get accent => accentColor;
  Color get paper => cardBackground;
  Color get result => digitColor;
  Color get divider => dividerColor;

  List<Color> get bgGradient =>
      [background, _mix(background, isDark ? Colors.black : accentColor, isDark ? 0.10 : 0.06)];

  double get _edgeT => isDark ? 0.24 : 0.17;

  // Number keys — the calm surface.
  Color get numFill => cardBackground;
  Color get numEdge => _darken(cardBackground, _edgeT);
  Color get numText => primaryTextColor;

  // Operator keys — soft tint of the button hue.
  Color get opFill => _mix(buttonColor, cardBackground, 0.60);
  Color get opEdge => _darken(opFill, _edgeT);
  Color get opText => primaryTextColor;

  // Function keys — soft tint of the accent hue.
  Color get funcFill => _mix(accentColor, cardBackground, 0.60);
  Color get funcEdge => _darken(funcFill, _edgeT);
  Color get funcText => primaryTextColor;

  // Clear keys — a blended in-between tint so they read distinct.
  Color get clearFill => _mix(_mix(buttonColor, accentColor, 0.5), cardBackground, 0.50);
  Color get clearEdge => _darken(clearFill, _edgeT);
  Color get clearText => primaryTextColor;

  // Equals — the one saturated "go" key.
  Color get eqFill => buttonColor;
  Color get eqEdge => _darken(buttonColor, _edgeT);
  Color get eqText => buttonTextColor;

  // 2nd (active) — saturated accent.
  Color get secondFill => accentColor;
  Color get secondEdge => _darken(accentColor, _edgeT);
  Color get secondText => buttonTextColor;

  // Mascot.
  Color get mascotFace =>
      isDark ? _lighten(cardBackground, 0.07) : _mix(cardBackground, Colors.white, 0.35);
  Color get mascotInk => primaryTextColor;
  Color get mascotBlush => accentColor;
  Color get mascotEar => _mix(accentColor, cardBackground, 0.25);

  // Chip background (header pills).
  Color get chipBg => isDark ? _lighten(cardBackground, 0.04) : cardBackground;
}
