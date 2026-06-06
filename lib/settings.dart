import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight app settings (persisted). Kept as a small global so the keypad
/// and sheets can read/write without threading a controller everywhere.
SharedPreferences? _prefs;

bool hapticsEnabled = true;

/// ISO 3166-1 alpha-2 code of the user's selected country. Drives the tax
/// calculator's default rate/label and the converter's default currency.
String countryCode = 'JP';

void initSettings(SharedPreferences prefs) {
  _prefs = prefs;
  hapticsEnabled = prefs.getBool('haptics') ?? true;
  countryCode = prefs.getString('country') ?? 'JP';
}

void setHaptics(bool v) {
  hapticsEnabled = v;
  _prefs?.setBool('haptics', v);
}

void setCountry(String code) {
  countryCode = code;
  _prefs?.setString('country', code);
}

void tapHaptic() {
  if (hapticsEnabled) HapticFeedback.lightImpact();
}

void selectHaptic() {
  if (hapticsEnabled) HapticFeedback.selectionClick();
}

void mediumHaptic() {
  if (hapticsEnabled) HapticFeedback.mediumImpact();
}
