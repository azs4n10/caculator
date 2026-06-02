// Smoke test: the graph screen builds and paints without errors, and seeds a
// plot from the initial expression.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/graph/graph_screen.dart';
import 'package:kawaii_calc/theme.dart';
import 'package:kawaii_calc/theme/skins.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('graph screen builds and seeds sin(x)', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 760);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(defaultSkin), home: const GraphScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
    // Seeded with sin(x) when no initial expression is given.
    expect(find.text('Add function'), findsOneWidget);
  });

  testWidgets('graph screen seeds from initial expression with x', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 760);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(defaultSkin), home: const GraphScreen(initialExpr: 'x^2-3')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('x^2-3'), findsOneWidget);
  });
}
