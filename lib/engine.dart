import 'package:math_expressions/math_expressions.dart';

/// A compiled single-variable function y = f(x).
typedef RealFn = double Function(double x);

/// Result of a calculation: either a formatted value or an error.
class CalcResult {
  final bool ok;
  final String text; // formatted value or error message
  final double? value;
  const CalcResult.ok(this.text, this.value) : ok = true;
  const CalcResult.err(this.text)
      : ok = false,
        value = null;
}

enum AngleMode { rad, deg }

/// Converts the on-screen ("kawaii") expression into a form that
/// math_expressions' GrammarParser understands, then evaluates it.
///
/// Design notes:
/// - GrammarParser does NOT support named constants, so we expand π and e to
///   numeric literals.
/// - log(...) on the keypad means base-10, emitted as log(10, ...).
/// - Degree mode injects a radian conversion into trig arguments and converts
///   inverse-trig results back to degrees.
/// - Implicit multiplication (2π, 3(4), )(, 2sin(...)) is inserted automatically.
class CalculatorEngine {
  static const _pi = '(3.141592653589793)';
  static const _e = '(2.718281828459045)';
  static const _deg2rad = '(0.017453292519943295)';
  static const _rad2deg = '(57.29577951308232)';

  static const _functions = {
    'sin', 'cos', 'tan', //
    'arcsin', 'arccos', 'arctan',
    'ln', 'log', 'sqrt', 'abs',
  };
  static const _degIn = {'sin', 'cos', 'tan'};
  static const _degOut = {'arcsin', 'arccos', 'arctan'};

  CalcResult evaluate(String display, {AngleMode angle = AngleMode.rad}) {
    final src = display.trim();
    if (src.isEmpty) return const CalcResult.err('');
    try {
      final normalized = _normalize(src, angle);
      final exp = GrammarParser().parse(normalized);
      final evaluator = RealEvaluator(ContextModel());
      final num raw = evaluator.evaluate(exp);
      final v = raw.toDouble();
      if (v.isNaN) return const CalcResult.err('undefined');
      if (v.isInfinite) return const CalcResult.err('∞ too big');
      return CalcResult.ok(formatNumber(v), v);
    } catch (_) {
      return const CalcResult.err('check expression');
    }
  }

  /// Compiles an expression containing the variable `x` into a fast, reusable
  /// function for plotting (parse once, evaluate for many x). Returns null if
  /// the expression can't be parsed. The returned function yields NaN for x
  /// values where evaluation fails (e.g. log of a negative) so callers can
  /// break the curve there.
  RealFn? compile(String display, {AngleMode angle = AngleMode.rad}) {
    final src = display.trim();
    if (src.isEmpty) return null;
    try {
      final normalized = _normalize(src, angle);
      final exp = GrammarParser().parse(normalized);
      final ctx = ContextModel();
      final eval = RealEvaluator(ctx);
      // Probe once so an immediately-invalid expression returns null.
      ctx.bindVariableName('x', Number(0));
      eval.evaluate(exp);
      return (double x) {
        ctx.bindVariableName('x', Number(x));
        try {
          return eval.evaluate(exp).toDouble();
        } catch (_) {
          return double.nan;
        }
      };
    } catch (_) {
      return null;
    }
  }

  /// Public for testing.
  String normalizeForTest(String display, AngleMode angle) =>
      _normalize(display, angle);

  String _normalize(String display, AngleMode angle) {
    var s = display
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-') // U+2212 minus
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll('%', '*0.01');
    s = _expandFactorials(s);
    final tokens = _tokenize(s);
    return _emit(tokens, angle);
  }

  /// Replaces integer factorials like `5!` with their computed value.
  String _expandFactorials(String s) {
    final re = RegExp(r'(\d+)!');
    while (re.hasMatch(s)) {
      s = s.replaceAllMapped(re, (m) {
        final n = int.parse(m.group(1)!);
        if (n > 170) throw const FormatException('factorial too large');
        double f = 1;
        for (var i = 2; i <= n; i++) {
          f *= i;
        }
        return f.toString();
      });
    }
    return s;
  }

  List<_Tok> _tokenize(String s) {
    final toks = <_Tok>[];
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if (_isDigit(c) || c == '.') {
        var j = i;
        while (j < s.length && (_isDigit(s[j]) || s[j] == '.')) {
          j++;
        }
        toks.add(_Tok(_TokKind.number, s.substring(i, j)));
        i = j;
        continue;
      }
      if (_isLetter(c)) {
        var j = i;
        while (j < s.length && _isLetter(s[j])) {
          j++;
        }
        final word = s.substring(i, j);
        if (_functions.contains(word)) {
          toks.add(_Tok(_TokKind.func, word));
        } else if (word == 'pi') {
          toks.add(_Tok(_TokKind.constant, _pi));
        } else if (word == 'e') {
          toks.add(_Tok(_TokKind.constant, _e));
        } else {
          // Unknown identifier — let the parser reject it.
          toks.add(_Tok(_TokKind.constant, word));
        }
        i = j;
        continue;
      }
      switch (c) {
        case '(':
          toks.add(_Tok(_TokKind.lparen, '('));
          break;
        case ')':
          toks.add(_Tok(_TokKind.rparen, ')'));
          break;
        case ',':
          toks.add(_Tok(_TokKind.comma, ','));
          break;
        default:
          toks.add(_Tok(_TokKind.op, c));
      }
      i++;
    }
    return _insertImplicitMultiplication(toks);
  }

  List<_Tok> _insertImplicitMultiplication(List<_Tok> toks) {
    final out = <_Tok>[];
    for (var i = 0; i < toks.length; i++) {
      final t = toks[i];
      if (out.isNotEmpty) {
        final p = out.last;
        final leftCloses = p.kind == _TokKind.number ||
            p.kind == _TokKind.rparen ||
            p.kind == _TokKind.constant;
        final rightOpens = t.kind == _TokKind.number ||
            t.kind == _TokKind.lparen ||
            t.kind == _TokKind.func ||
            t.kind == _TokKind.constant;
        // Never split a function from its argument paren.
        if (leftCloses && rightOpens && p.kind != _TokKind.func) {
          out.add(_Tok(_TokKind.op, '*'));
        }
      }
      out.add(t);
    }
    return out;
  }

  String _emit(List<_Tok> toks, AngleMode angle) {
    final deg = angle == AngleMode.deg;
    final buf = StringBuffer();
    final parenSuffix = <String>[]; // suffix to emit before matching ')'
    String? pendingPrefix; // injected right after the next '('
    String? pendingSuffix; // attached to the next '(' for its ')'

    for (final t in toks) {
      switch (t.kind) {
        case _TokKind.func:
          if (t.text == 'log') {
            buf.write('log');
            pendingPrefix = '10,';
          } else if (deg && _degIn.contains(t.text)) {
            buf.write(t.text);
            pendingPrefix = '$_deg2rad*';
          } else if (deg && _degOut.contains(t.text)) {
            buf.write('(');
            buf.write(t.text);
            pendingSuffix = '*$_rad2deg)';
          } else {
            buf.write(t.text);
          }
          break;
        case _TokKind.lparen:
          buf.write('(');
          if (pendingPrefix != null) {
            buf.write(pendingPrefix);
            pendingPrefix = null;
          }
          parenSuffix.add(pendingSuffix ?? '');
          pendingSuffix = null;
          break;
        case _TokKind.rparen:
          buf.write(')');
          if (parenSuffix.isNotEmpty) {
            buf.write(parenSuffix.removeLast());
          }
          break;
        default:
          buf.write(t.text);
      }
    }
    return buf.toString();
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) ^ 0x30 <= 9;
  static bool _isLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
  }

  /// Formats a double the way a friendly calculator should: no trailing zeros,
  /// scientific notation only when the magnitude demands it, float noise
  /// rounded away.
  static String formatNumber(double v) {
    if (v == 0) return '0';
    final abs = v.abs();
    if (abs >= 1e12 || abs < 1e-9) {
      var s = v.toStringAsExponential(8);
      // Trim trailing zeros in the mantissa.
      s = s.replaceAllMapped(RegExp(r'(\.\d*?)0+e'), (m) => '${m[1]}e');
      s = s.replaceAll('.e', 'e');
      return s;
    }
    // Round to 12 significant digits to kill IEEE noise.
    final rounded = double.parse(v.toStringAsPrecision(12));
    var s = rounded.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}

enum _TokKind { number, func, constant, op, lparen, rparen, comma }

class _Tok {
  final _TokKind kind;
  final String text;
  _Tok(this.kind, this.text);
}
