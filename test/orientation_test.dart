// Checks the calculator at true portrait AND landscape aspect ratios:
// does it overflow, and how big do the keycaps end up?
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawaii_calc/calculator_screen.dart';
import 'package:kawaii_calc/theme.dart';
import 'package:kawaii_calc/theme/skins.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const cases = <String, Size>{
    'portrait tall 390x844': Size(390, 844),
    'portrait short 360x640': Size(360, 640),
    'landscape 844x390': Size(844, 390),
    'landscape 740x360': Size(740, 360),
  };

  cases.forEach((name, size) {
    testWidgets('layout at $name', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(defaultSkin), home: const Scaffold(body: CalculatorScreen())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$name overflow');

      // Measure the '7' keycap to see if keys are a usable size.
      final key7 = tester.getSize(find.ancestor(
        of: find.text('7'),
        matching: find.byType(AspectRatio),
      ));
      // ignore: avoid_print
      print('$name -> key "7" = ${key7.width.toStringAsFixed(0)}x${key7.height.toStringAsFixed(0)}');
    });
  });
}
