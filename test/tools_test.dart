// Smoke + logic tests for the new tools (circle, tax). google_fonts runtime
// fetching is disabled so fonts fall back silently (no network). The currency
// tool isn't tested here because it performs a live HTTP fetch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/tools/circle_screen.dart';
import 'package:kawaii_calc/tools/split_screen.dart';
import 'package:kawaii_calc/tools/tax_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('circle: radius 2 → diameter 4', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CircleScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pump();

    // Diameter = 2 * 2 = 4 is shown in the results card.
    expect(find.text('4'), findsWidgets);
    expect(find.text('Circumference'), findsWidgets);
  });

  testWidgets('tax: 100 pre-tax at 10% → total 110', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TaxScreen()));
    await tester.pumpAndSettle();

    // First field = amount; the rate field defaults to Japan's 10%.
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();

    expect(find.textContaining('110 JPY'), findsWidgets); // total incl. tax
    expect(find.textContaining('10 JPY'), findsWidgets); // tax portion
  });

  testWidgets('split: 100 between 2 people → 50 each', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplitScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();

    // Default 2 people, no tip → 50 JPY each (Japan is the default country).
    expect(find.textContaining('50 JPY'), findsWidgets);
  });

  testWidgets('circle accepts an initial value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CircleScreen(initialValue: '3')));
    await tester.pumpAndSettle();

    // radius 3 → diameter 6 shown without any typing.
    expect(find.text('6'), findsWidgets);
  });
}
