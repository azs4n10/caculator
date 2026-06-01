import 'package:flutter_test/flutter_test.dart';
import 'package:kawaii_calc/engine.dart';

void main() {
  final e = CalculatorEngine();

  String evalRad(String s) => e.evaluate(s, angle: AngleMode.rad).text;
  String evalDeg(String s) => e.evaluate(s, angle: AngleMode.deg).text;

  group('basic arithmetic', () {
    test('precedence', () => expect(evalRad('1+2*3'), '7'));
    test('kawaii operators', () => expect(evalRad('2×3÷4'), '1.5'));
    test('power', () => expect(evalRad('2^10'), '1024'));
    test('parentheses', () => expect(evalRad('(1+2)*(3+4)'), '21'));
  });

  group('implicit multiplication', () {
    test('number·paren', () => expect(evalRad('2(3+4)'), '14'));
    test('paren·paren', () => expect(evalRad('(2)(3)'), '6'));
    test('number·pi', () => expect(evalRad('2π'), '6.28318530718'));
  });

  group('scientific functions', () {
    test('sqrt symbol', () => expect(evalRad('√(9)'), '3'));
    test('sqrt func', () => expect(evalRad('sqrt(16)'), '4'));
    test('log base 10', () => expect(evalRad('log(100)'), '2'));
    test('ln of e', () => expect(evalRad('ln(e)'), '1'));
    test('abs of negative', () => expect(evalRad('abs(−5)'), '5'));
    test('factorial', () => expect(evalRad('5!'), '120'));
    test('percent', () => expect(evalRad('50%'), '0.5'));
  });

  group('angle modes', () {
    test('rad sin(0)', () => expect(evalRad('sin(0)'), '0'));
    test('deg sin(30)', () => expect(evalDeg('sin(30)'), '0.5'));
    test('deg cos(60)', () => expect(evalDeg('cos(60)'), '0.5'));
    test('deg arcsin(1)', () => expect(evalDeg('arcsin(1)'), '90'));
  });

  group('errors', () {
    test('malformed', () => expect(e.evaluate('1+').ok, false));
    test('empty', () => expect(e.evaluate('').ok, false));
    test('div by zero', () => expect(e.evaluate('1/0').ok, false));
  });
}
