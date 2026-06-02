// Measures exact header geometry at 360px to see whether the trailing controls
// (RAD / ∫ / 履歴) actually fit on-screen, deterministically (no flaky web shots).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/calculator_screen.dart';
import 'package:kawaii_calc/theme.dart';
import 'package:kawaii_calc/theme/skins.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('header trailing controls fit at 360', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(defaultSkin), home: const Scaffold(body: CalculatorScreen())),
    );
    await tester.pumpAndSettle();

    final rad = tester.getRect(find.text('RAD'));
    final graph = tester.getRect(find.text('📈'));
    final cas = tester.getRect(find.text('∫'));
    final hist = tester.getRect(find.text('履歴'));
    // ignore: avoid_print
    print('RAD=$rad\nGRAPH=$graph\nCAS=$cas\nHIST=$hist');

    expect(rad.right, lessThanOrEqualTo(360), reason: 'RAD off-screen: $rad');
    expect(graph.right, lessThanOrEqualTo(360), reason: '📈 off-screen: $graph');
    expect(cas.right, lessThanOrEqualTo(360), reason: '∫ off-screen: $cas');
    expect(hist.right, lessThanOrEqualTo(360), reason: '履歴 off-screen: $hist');
  });
}
