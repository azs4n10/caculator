// Renders the calculator at real phone viewport sizes and asserts there is no
// layout overflow — closed, with the function drawer open, and with 2nd active.
// google_fonts runtime fetching is disabled so fonts fall back silently (no
// network); RenderFlex overflow still surfaces via tester.takeException().
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/calculator_screen.dart';
import 'package:kawaii_calc/theme.dart';
import 'package:kawaii_calc/theme/skins.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const phones = <String, Size>{
    'tiny (320×568)': Size(320, 568),
    'small Android (360×640)': Size(360, 640),
    'iPhone SE (375×667)': Size(375, 667),
    'iPhone 14 Pro (393×852)': Size(393, 852),
    'Pixel tall (412×915)': Size(412, 915),
  };

  phones.forEach((name, size) {
    testWidgets('no overflow on $name', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(defaultSkin), home: const Scaffold(body: CalculatorScreen())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$name — default');

      // Core keys are present and laid out. (Operators like = are drawn as
      // vector glyphs, not text, so we check a digit and the clear key.)
      expect(find.text('7'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Open the function drawer.
      await tester.tap(find.text('ƒ(x) functions'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$name — drawer open');
      expect(find.text('sin'), findsOneWidget);

      // Activate 2nd (inverse functions).
      await tester.tap(find.text('2nd'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$name — 2nd active');
      expect(find.text('sin⁻¹'), findsOneWidget);
    });
  });
}
