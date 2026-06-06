import 'package:flutter/material.dart';
import '../engine.dart';
import '../theme.dart';
import '../theme/skin.dart';

/// Shared "kawaii" building blocks so every tool screen matches the home
/// calculator's soft, pastel look (same radial-vignette backdrop, rounded
/// cards, themed inputs and chips).

/// The same gentle radial vignette the calculator home uses, so tool screens
/// don't look flat next to it.
BoxDecoration kawaiiBgDeco(CalcSkin skin) => BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.25,
        colors: [
          Color.lerp(skin.background, Colors.white, skin.isDark ? 0.0 : 0.05)!,
          skin.background,
          Color.lerp(skin.background, Colors.black, skin.isDark ? 0.12 : 0.07)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );

/// A tool screen shell: vignette background + a soft, transparent AppBar with a
/// cute title. Use [actions] for things like "use in calculator".
class ToolScaffold extends StatelessWidget {
  final CalcSkin skin;
  final String title;
  final IconData icon;
  final List<Widget> actions;
  final Widget child;
  const ToolScaffold({
    super.key,
    required this.skin,
    required this.title,
    required this.icon,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kawaiiBgDeco(skin),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: skin.ink,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: skin.accent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
            ],
          ),
          actions: actions,
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}

/// A pastel rounded card with a soft drop shadow.
Widget toolCard(CalcSkin skin, {required Widget child, EdgeInsets? padding}) => Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: skin.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: skin.isDark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

/// A themed text field decoration matching the cards.
InputDecoration kawaiiInput(CalcSkin skin, String label) => InputDecoration(
      labelText: label,
      labelStyle: Kawaii.ui(13, weight: FontWeight.w700, color: skin.inkSoft),
      filled: true,
      fillColor: skin.paper,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: skin.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: skin.accent, width: 2),
      ),
    );

/// A pill selector chip; [active] fills it with the accent colour.
Widget selectChip(CalcSkin skin, String label, bool active, VoidCallback onTap, {bool expand = false}) {
  final chip = GestureDetector(
    onTap: onTap,
    child: Container(
      // Only fill width when expanded in a Row; in a Wrap leave intrinsic so
      // chips sit side by side (a Container with alignment set would stretch).
      alignment: expand ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? skin.accent : skin.funcFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: skin.funcEdge),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: Kawaii.ui(12.5, weight: FontWeight.w800, color: active ? skin.buttonTextColor : skin.ink)),
    ),
  );
  return expand ? Expanded(child: chip) : chip;
}

/// A key→value row used inside result cards. [big] is for the headline value.
Widget resultRow(CalcSkin skin, String label, String value, {bool big = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: big ? 8 : 13),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Kawaii.ui(big ? 16 : 15, weight: FontWeight.w700, color: skin.inkSoft)),
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: Kawaii.display(big ? 26 : 20).copyWith(color: big ? skin.accent : skin.ink)),
          ),
        ],
      ),
    );

/// AppBar action that returns a bare number string to the calculator.
Widget useInCalcAction(BuildContext context, CalcSkin skin, String? Function() value) => IconButton(
      tooltip: 'Use in calculator',
      icon: Icon(Icons.keyboard_return_rounded, color: skin.accent),
      onPressed: () {
        final v = value();
        if (v != null && v.isNotEmpty) Navigator.pop(context, v);
      },
    );

// Currencies with no minor unit — show whole numbers.
const _zeroDecimal = {'JPY', 'KRW', 'HUF', 'ISK', 'CLP', 'VND'};

/// Formats a monetary value with the right number of decimals for [currency]
/// and appends the code, e.g. "1,234 JPY" or "12.34 USD".
String formatMoney(double v, String currency) {
  final dec = _zeroDecimal.contains(currency) ? 0 : 2;
  return '${CalculatorEngine.formatNumber(double.parse(v.toStringAsFixed(dec)))} $currency';
}

/// Bare formatted number (no unit) for sending back to the calculator.
String bareNumber(double v, {int decimals = 2}) =>
    CalculatorEngine.formatNumber(double.parse(v.toStringAsFixed(decimals)));
