import 'package:flutter/material.dart';
import 'skin.dart';

// Palette values mirror the flipclock app's skins (5 light + 5 dark).

// ---- Light ----
const yumekawaSkin = CalcSkin(
  id: 'yumekawa', name: 'Yumekawa', isDark: false,
  background: Color(0xFFFCE7F3), cardBackground: Color(0xFFFFFFFF),
  digitColor: Color(0xFFBE5A8F), accentColor: Color(0xFFC4A8E1),
  buttonColor: Color(0xFFF8A5C2), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFF6B4858), subTextColor: Color(0xFFB89AA8),
  dividerColor: Color(0xFFF5D2E1),
);

const lavenderSkin = CalcSkin(
  id: 'lavender', name: 'Lavender Dream', isDark: false,
  background: Color(0xFFF1E8FF), cardBackground: Color(0xFFFFFFFF),
  digitColor: Color(0xFF8C6BB5), accentColor: Color(0xFFFFB6D9),
  buttonColor: Color(0xFFB69CE8), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFF5E4A7A), subTextColor: Color(0xFFA897C2),
  dividerColor: Color(0xFFE3D6F5),
);

const mintPeachSkin = CalcSkin(
  id: 'mint_peach', name: 'Mint Peach', isDark: false,
  background: Color(0xFFF5F9F4), cardBackground: Color(0xFFFFF5EE),
  digitColor: Color(0xFF5C8D89), accentColor: Color(0xFFFFB088),
  buttonColor: Color(0xFF88C9BF), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFF4A6B68), subTextColor: Color(0xFF9CB6B0),
  dividerColor: Color(0xFFDDE8E0),
);

const beigeRoseSkin = CalcSkin(
  id: 'beige_rose', name: 'Beige Rose', isDark: false,
  background: Color(0xFFF5EBE0), cardBackground: Color(0xFFE8D5C4),
  digitColor: Color(0xFF8B5A6B), accentColor: Color(0xFFD4A5A5),
  buttonColor: Color(0xFFC9A88D), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFF6B4858), subTextColor: Color(0xFFB8A398),
  dividerColor: Color(0xFFD6BFAE),
);

const sugarPinkSkin = CalcSkin(
  id: 'sugar_pink', name: 'Sugar Pink', isDark: false,
  background: Color(0xFFFFFFFF), cardBackground: Color(0xFFFFE4EC),
  digitColor: Color(0xFFF472B6), accentColor: Color(0xFFFBCFE8),
  buttonColor: Color(0xFFEC4899), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFF8B2A6B), subTextColor: Color(0xFFD4A5BF),
  dividerColor: Color(0xFFFBCFE8),
);

// ---- Dark ----
const nightStarSkin = CalcSkin(
  id: 'night_star', name: 'Night Star', isDark: true,
  background: Color(0xFF2A2342), cardBackground: Color(0xFF3D3460),
  digitColor: Color(0xFFFFC0E2), accentColor: Color(0xFFB69CE8),
  buttonColor: Color(0xFFEC4899), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFFF5EBE0), subTextColor: Color(0xFFB8A8D0),
  dividerColor: Color(0xFF4A4170),
);

const midnightPlumSkin = CalcSkin(
  id: 'midnight_plum', name: 'Midnight Plum', isDark: true,
  background: Color(0xFF1E1B2E), cardBackground: Color(0xFF2E2A45),
  digitColor: Color(0xFFE8B7D4), accentColor: Color(0xFFB69CE8),
  buttonColor: Color(0xFFD96BA0), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFFEDE7F5), subTextColor: Color(0xFFA89CC0),
  dividerColor: Color(0xFF3A3556),
);

const cocoaNightSkin = CalcSkin(
  id: 'cocoa_night', name: 'Cocoa Night', isDark: true,
  background: Color(0xFF2B2320), cardBackground: Color(0xFF3D332F),
  digitColor: Color(0xFFF0C9B0), accentColor: Color(0xFFD9A299),
  buttonColor: Color(0xFFC97B84), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFFF0E6DE), subTextColor: Color(0xFFB5A89E),
  dividerColor: Color(0xFF4A3F3A),
);

const galaxySkin = CalcSkin(
  id: 'galaxy', name: 'Galaxy', isDark: true,
  background: Color(0xFF161A30), cardBackground: Color(0xFF272C4A),
  digitColor: Color(0xFFB9C7FF), accentColor: Color(0xFFE0A7E8),
  buttonColor: Color(0xFF7C8CE0), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFFE6EAF7), subTextColor: Color(0xFF98A0C2),
  dividerColor: Color(0xFF323862),
);

const charcoalRoseSkin = CalcSkin(
  id: 'charcoal_rose', name: 'Charcoal Rose', isDark: true,
  background: Color(0xFF242022), cardBackground: Color(0xFF353033),
  digitColor: Color(0xFFEAB8C4), accentColor: Color(0xFFC99AA8),
  buttonColor: Color(0xFFCE7E92), buttonTextColor: Color(0xFFFFFFFF),
  primaryTextColor: Color(0xFFF0E8EC), subTextColor: Color(0xFFAEA2A8),
  dividerColor: Color(0xFF453E42),
);

const List<CalcSkin> lightSkins = [
  yumekawaSkin, lavenderSkin, mintPeachSkin, beigeRoseSkin, sugarPinkSkin,
];
const List<CalcSkin> darkSkins = [
  nightStarSkin, midnightPlumSkin, cocoaNightSkin, galaxySkin, charcoalRoseSkin,
];
const List<CalcSkin> allSkins = [...lightSkins, ...darkSkins];

const CalcSkin defaultSkin = yumekawaSkin;

CalcSkin skinById(String id) =>
    allSkins.firstWhere((s) => s.id == id, orElse: () => defaultSkin);
