// Engine behaviour is covered by engine_test.dart. Widget tests that pump the
// full app are intentionally omitted here because google_fonts performs network
// font fetches that are flaky under `flutter test`.
import 'package:flutter_test/flutter_test.dart';
import 'package:kawaii_calc/engine.dart';

void main() {
  test('engine smoke test', () {
    expect(CalculatorEngine().evaluate('1+1').text, '2');
  });
}
