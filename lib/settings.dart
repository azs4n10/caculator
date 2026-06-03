import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight app settings (persisted). Kept as a small global so the keypad
/// and sheets can read/write without threading a controller everywhere.
SharedPreferences? _prefs;

bool hapticsEnabled = true;

void initSettings(SharedPreferences prefs) {
  _prefs = prefs;
  hapticsEnabled = prefs.getBool('haptics') ?? true;
}

void setHaptics(bool v) {
  hapticsEnabled = v;
  _prefs?.setBool('haptics', v);
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
