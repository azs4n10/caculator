// Verifies the physical-keyboard input + function autocomplete on the
// calculator screen: typing letters surfaces matching suggestion chips, and
// pressing Tab completes the top one. google_fonts runtime fetching is disabled
// so fonts fall back silently (no network).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/calculator_screen.dart';
import 'package:kawaii_calc/theme.dart';
import 'package:kawaii_calc/theme/skins.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(defaultSkin), home: const Scaffold(body: CalculatorScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('typing letters shows function suggestions', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyS, character: 's');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI, character: 'i');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
    await tester.pump();

    // The "sin" suggestion chip is present (alongside the display text).
    expect(find.text('sin'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab completes the top suggestion', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO, character: 'o');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS, character: 's');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // The expression display now contains the completed call "cos(".
    expect(find.text('cos('), findsOneWidget);
  });

  testWidgets('digits and operators type into the expression', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2, character: '2');
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadMultiply, character: '*');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3, character: '3');
    await tester.pump();

    // '*' is mapped to the on-screen '×'.
    expect(find.text('2×3'), findsOneWidget);
  });
}
