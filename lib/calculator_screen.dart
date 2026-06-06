import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cas/cas_screen.dart';
import 'settings.dart';
import 'engine.dart';
import 'graph/graph_screen.dart';
import 'theme.dart';
import 'theme/key_texture.dart';
import 'theme/skin.dart';
import 'theme/skin_picker.dart';
import 'theme/skin_scope.dart';
import 'theme/texture_scope.dart';
import 'tools/circle_screen.dart';
import 'tools/countries.dart';
import 'tools/country_picker.dart';
import 'tools/currency_screen.dart';
import 'tools/split_screen.dart';
import 'tools/tax_screen.dart';
import 'tools/tool_ui.dart';
import 'widgets/typewriter_key.dart';

class HistoryEntry {
  final String expr;
  final String result;
  HistoryEntry(this.expr, this.result);
}

enum _Cat { number, op, func, pink, mint, second }

class _K {
  final String label;
  final String? insert;
  final _Act act;
  final _Cat cat;
  const _K(this.label, {this.insert, this.act = _Act.insert, this.cat = _Cat.number});
}

enum _Act { insert, clear, back, equals, sign }

class _FK {
  final String label;
  final String insert;
  final String? label2;
  final String? insert2;
  final bool isSecond;
  const _FK(this.label, this.insert, {this.label2, this.insert2, this.isSecond = false});
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _engine = CalculatorEngine();
  String _expr = '';
  String _result = '';
  String _preview = '';
  AngleMode _angle = AngleMode.rad;
  bool _justEvaluated = false;
  bool _funcOpen = false;
  bool _second = false;
  KeyTexture _texture = KeyTexture.glossy;
  final List<HistoryEntry> _history = [];

  static const _pad = <_K>[
    _K('C', act: _Act.clear, cat: _Cat.pink),
    _K('⌫', act: _Act.back, cat: _Cat.pink),
    _K('%', insert: '%', cat: _Cat.op),
    _K('÷', insert: '÷', cat: _Cat.op),
    _K('7'), _K('8'), _K('9'), _K('×', insert: '×', cat: _Cat.op),
    _K('4'), _K('5'), _K('6'), _K('−', insert: '−', cat: _Cat.op),
    _K('1'), _K('2'), _K('3'), _K('+', insert: '+', cat: _Cat.op),
    _K('+/−', act: _Act.sign, cat: _Cat.op),
    _K('0'),
    _K('.', insert: '.'),
    _K('=', act: _Act.equals, cat: _Cat.mint),
  ];

  static const _funcs = <_FK>[
    _FK('2nd', '', isSecond: true),
    _FK('sin', 'sin(', label2: 'sin⁻¹', insert2: 'arcsin('),
    _FK('cos', 'cos(', label2: 'cos⁻¹', insert2: 'arccos('),
    _FK('tan', 'tan(', label2: 'tan⁻¹', insert2: 'arctan('),
    _FK('π', 'π'),
    _FK('ln', 'ln(', label2: 'eˣ', insert2: 'e^('),
    _FK('log', 'log(', label2: '10ˣ', insert2: '10^('),
    _FK('√', '√(', label2: 'x²', insert2: '^2'),
    _FK('xʸ', '^'),
    _FK('e', 'e'),
    _FK('(', '('),
    _FK(')', ')'),
    _FK('|x|', 'abs('),
    _FK('n!', '!'),
    _FK('Ans', '__ANS__'),
    _FK('+Tax', '__TAX+__'),
    _FK('−Tax', '__TAX-__'),
  ];

  void _onKey(_K k) {
    switch (k.act) {
      case _Act.clear:
        setState(() {
          _expr = '';
          _result = '';
          _preview = '';
          _justEvaluated = false;
        });
        return;
      case _Act.back:
        setState(() {
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
          _recompute();
        });
        return;
      case _Act.sign:
        setState(() {
          if (_expr.startsWith('−')) {
            _expr = _expr.substring(1);
          } else if (_expr.isNotEmpty) {
            _expr = '−$_expr';
          }
          _recompute();
        });
        return;
      case _Act.equals:
        _evaluate();
        return;
      case _Act.insert:
        _insert(k.insert ?? k.label);
    }
  }

  void _insert(String ins) {
    tapHaptic();
    setState(() {
      if (ins == '__ANS__') ins = _result.isEmpty ? '' : _result;
      if (_justEvaluated) {
        final isOp = '+−×÷^'.contains(ins);
        _expr = isOp ? '$_result$ins' : ins;
        _result = '';
        _justEvaluated = false;
      } else {
        _expr += ins;
      }
      _recompute();
    });
  }

  // Function/constant vocabulary for autocomplete: (typed name, what to insert).
  static const _vocab = <(String, String)>[
    ('sin', 'sin('), ('cos', 'cos('), ('tan', 'tan('),
    ('arcsin', 'arcsin('), ('arccos', 'arccos('), ('arctan', 'arctan('),
    ('ln', 'ln('), ('log', 'log('), ('sqrt', '√('), ('abs', 'abs('),
    ('pi', 'π'),
  ];

  /// Completions matching the run of letters at the end of the expression.
  /// Empty when the expression doesn't end in a partial identifier.
  List<(String, String)> get _suggestions {
    final m = RegExp(r'[A-Za-z]+$').firstMatch(_expr);
    if (m == null) return const [];
    final p = m.group(0)!.toLowerCase();
    final out = <(String, String)>[];
    for (final v in _vocab) {
      if (v.$1.startsWith(p)) out.add(v);
      if (out.length >= 6) break;
    }
    return out;
  }

  /// Replaces the trailing partial identifier with a full function/constant.
  void _acceptSuggestion(String insert) {
    selectHaptic();
    setState(() {
      final m = RegExp(r'[A-Za-z]+$').firstMatch(_expr);
      if (m != null) _expr = _expr.substring(0, m.start);
      _expr += insert;
      _recompute();
    });
  }

  // Physical-keyboard support (PC / web). Tab accepts the top suggestion.
  KeyEventResult _handleKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.tab) {
      final s = _suggestions;
      if (s.isEmpty) return KeyEventResult.ignored;
      _acceptSuggestion(s.first.$2);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _evaluate();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace) {
      _onKey(const _K('⌫', act: _Act.back, cat: _Cat.pink));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _onKey(const _K('C', act: _Act.clear, cat: _Cat.pink));
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (ch != null && ch.length == 1) {
      if (ch == '=') {
        _evaluate();
        return KeyEventResult.handled;
      }
      const map = {'*': '×', '/': '÷', '-': '−'};
      if (RegExp(r'^[0-9A-Za-z.+\-*/^!%()]$').hasMatch(ch)) {
        _insert(map[ch] ?? ch);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _recompute() {
    if (_expr.trim().isEmpty) {
      _preview = '';
      return;
    }
    final r = _engine.evaluate(_expr, angle: _angle);
    _preview = (r.ok && r.text != _expr) ? r.text : '';
  }

  void _evaluate() {
    if (_expr.trim().isEmpty) return;
    mediumHaptic();
    final r = _engine.evaluate(_expr, angle: _angle);
    setState(() {
      if (r.ok) {
        _result = r.text;
        _preview = '';
        _justEvaluated = true;
        _history.insert(0, HistoryEntry(_expr, r.text));
      } else {
        _result = r.text;
        _preview = '';
      }
    });
  }

  void _loadHistory(HistoryEntry h) {
    setState(() {
      _expr = h.expr;
      _result = h.result;
      _justEvaluated = true;
      _recompute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    _texture = TextureScope.textureOf(context);
    return Container(
      decoration: BoxDecoration(
        // Subtle radial vignette gives the backdrop depth so keys don't float
        // on a flat colour.
        gradient: RadialGradient(
          center: const Alignment(0, -0.28),
          radius: 1.2,
          colors: [
            Color.lerp(skin.background, Colors.white, skin.isDark ? 0.0 : 0.05)!,
            skin.background,
            Color.lerp(skin.background, Colors.black, skin.isDark ? 0.12 : 0.07)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: LayoutBuilder(
            builder: (_, c) {
              // Wide / landscape: put functions beside the number pad so keys
              // stay big instead of shrinking to the (short) height.
              final wide = c.maxWidth > c.maxHeight * 1.25;
              return wide ? _landscapeBody(skin) : _portraitBody(skin);
            },
          ),
        ),
      ),
    );
  }

  Widget _portraitBody(CalcSkin skin) {
    return Column(
      children: [
        _header(skin),
        _display(skin),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              children: [
                _suggestionBar(skin),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _funcOpen ? _funcTray(skin) : const SizedBox(width: double.infinity),
                ),
                _funcToggleBar(skin),
                const SizedBox(height: 10),
                Expanded(child: _grid(skin, _pad, 4, gap: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _landscapeBody(CalcSkin skin) {
    return Column(
      children: [
        _header(skin),
        _display(skin, compact: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _suggestionBar(skin),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Functions always visible on the left (no drawer needed here).
                Expanded(flex: 5, child: _funcGrid(skin, 5)),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: _grid(skin, _pad, 4, gap: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Lays the function keys into a grid that fills its height (used in
  /// landscape, where the ƒ(x) drawer isn't needed).
  Widget _funcGrid(CalcSkin skin, int cols) {
    final rows = <Widget>[];
    for (var i = 0; i < _funcs.length; i += cols) {
      final slice = _funcs.sublist(i, (i + cols).clamp(0, _funcs.length));
      rows.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) const SizedBox(width: 10),
                Expanded(child: _funcKey(skin, slice[j])),
              ],
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _header(CalcSkin skin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Calculator',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
          ),
          _angleToggle(skin),
          const SizedBox(width: 5),
          _iconChip(skin, Icons.show_chart_rounded, _openGraph),
          const SizedBox(width: 5),
          _chip(skin, '∫', _openCas),
          const SizedBox(width: 5),
          _iconChip(skin, Icons.history_rounded, _showHistory),
          const SizedBox(width: 5),
          _iconChip(skin, Icons.grid_view_rounded, _openTools),
          const SizedBox(width: 5),
          _iconChip(skin, Icons.settings_rounded, _openSettings),
        ],
      ),
    );
  }

  // Header buttons share the RAD chip's look: filled, edged, ink-coloured.
  BoxDecoration _chipDeco(CalcSkin skin) => BoxDecoration(
        color: skin.funcFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.funcEdge),
      );

  Widget _chip(CalcSkin skin, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: _chipDeco(skin),
        child: Text(label, style: Kawaii.ui(14, weight: FontWeight.w800, color: skin.ink)),
      ),
    );
  }

  Widget _iconChip(CalcSkin skin, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: _chipDeco(skin),
        child: Icon(icon, size: 19, color: skin.ink),
      ),
    );
  }

  Widget _angleToggle(CalcSkin skin) {
    return GestureDetector(
      onTap: () => setState(() {
        _angle = _angle == AngleMode.rad ? AngleMode.deg : AngleMode.rad;
        selectHaptic();
        _recompute();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: skin.funcFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: skin.funcEdge),
        ),
        child: Text(_angle == AngleMode.rad ? 'RAD' : 'DEG',
            style: Kawaii.ui(13, weight: FontWeight.w800, color: skin.ink)),
      ),
    );
  }

  Widget _display(CalcSkin skin, {bool compact = false}) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, compact ? 6 : 8, 12, 4),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 10 : 16),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 60 : 110),
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: skin.isDark ? 0.25 : 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: skin.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(_expr.isEmpty ? '　' : _expr, style: Kawaii.display(compact ? 20 : 26).copyWith(color: skin.ink)),
          ),
          SizedBox(height: compact ? 4 : 8),
          if (_justEvaluated || _result.isNotEmpty)
            Text(_result, style: Kawaii.display(compact ? 28 : 40).copyWith(color: skin.result))
          else if (_preview.isNotEmpty)
            Text('= $_preview', style: Kawaii.display(compact ? 18 : 22).copyWith(color: skin.inkSoft)),
        ],
      ),
    );
  }

  /// A slim bar of autocomplete chips that appears while the expression ends in
  /// a partial function name. Tap a chip (or press Tab for the first) to
  /// complete it. Hidden — collapsed to zero height — when there's nothing to
  /// suggest.
  Widget _suggestionBar(CalcSkin skin) {
    final s = _suggestions;
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: s.isEmpty
          ? const SizedBox(width: double.infinity)
          : Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final e = s[i];
                  final primary = i == 0;
                  return GestureDetector(
                    onTap: () => _acceptSuggestion(e.$2),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: primary ? skin.eqFill : skin.funcFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: skin.funcEdge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.$1,
                              style: Kawaii.ui(15,
                                  weight: FontWeight.w700, color: skin.ink)),
                          if (primary) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: skin.ink.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('⇥',
                                  style: Kawaii.ui(12,
                                      weight: FontWeight.w800, color: skin.ink)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _funcToggleBar(CalcSkin skin) {
    return GestureDetector(
      onTap: () => setState(() {
        _funcOpen = !_funcOpen;
        selectHaptic();
      }),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: skin.funcFill.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skin.funcEdge.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_funcOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                color: skin.ink),
            const SizedBox(width: 4),
            Text(_funcOpen ? 'Hide functions' : 'ƒ(x) functions',
                style: Kawaii.ui(14, weight: FontWeight.w800, color: skin.ink)),
          ],
        ),
      ),
    );
  }

  Widget _funcTray(CalcSkin skin) {
    const cols = 5;
    final rows = <Widget>[];
    for (var i = 0; i < _funcs.length; i += cols) {
      final slice = _funcs.sublist(i, (i + cols).clamp(0, _funcs.length));
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) const SizedBox(width: 9),
                Expanded(child: _funcKey(skin, slice[j])),
              ],
            ],
          ),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  Widget _funcKey(CalcSkin skin, _FK f) {
    if (f.isSecond) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: TypewriterKey(
            label: '2nd',
            color: _second ? skin.secondFill : skin.funcFill,
            edge: _second ? skin.secondEdge : skin.funcEdge,
            textColor: _second ? skin.secondText : skin.funcText,
            texture: _texture,
            sizeFactor: 0.40,
            onTap: () => setState(() => _second = !_second),
          ),
        ),
      );
    }
    final showAlt = _second && f.label2 != null;
    final label = showAlt ? f.label2! : f.label;
    final insert = showAlt ? f.insert2! : f.insert;
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: TypewriterKey(
          label: label,
          color: skin.funcFill,
          edge: skin.funcEdge,
          textColor: skin.funcText,
          texture: _texture,
          sizeFactor: 0.40,
          onTap: () {
            if (insert == '__TAX+__') {
              _applyTax(true);
            } else if (insert == '__TAX-__') {
              _applyTax(false);
            } else {
              _insert(insert);
            }
          },
        ),
      ),
    );
  }

  /// Quick tax on the current value using the selected country's rate.
  /// [add] = make it tax-included; otherwise extract the pre-tax amount.
  void _applyTax(bool add) {
    final seed = _seedValue();
    final n = double.tryParse(seed ?? '');
    if (n == null) return;
    final c = countryByCode(countryCode);
    final f = c.taxRate / 100;
    final out = add ? n * (1 + f) : n / (1 + f);
    final s = bareNumber(out, decimals: currencyDecimals(c.currency));
    mediumHaptic();
    setState(() {
      _history.insert(0, HistoryEntry('$seed ${add ? '+' : '−'}tax ${trimRate(c.taxRate)}%', s));
      _expr = '';
      _result = s;
      _justEvaluated = true;
      _preview = '';
    });
  }

  Widget _grid(CalcSkin skin, List<_K> keys, int cols, {required double gap}) {
    final rows = <Widget>[];
    for (var i = 0; i < keys.length; i += cols) {
      final slice = keys.sublist(i, (i + cols).clamp(0, keys.length));
      rows.add(Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: gap / 2),
          child: Row(
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: _keyWidget(skin, slice[j])),
              ],
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _keyWidget(CalcSkin skin, _K k) {
    final (color, edge, text) = switch (k.cat) {
      _Cat.number => (skin.numFill, skin.numEdge, skin.numText),
      _Cat.op => (skin.opFill, skin.opEdge, skin.opText),
      _Cat.func => (skin.funcFill, skin.funcEdge, skin.funcText),
      _Cat.pink => (skin.clearFill, skin.clearEdge, skin.clearText),
      _Cat.mint => (skin.eqFill, skin.eqEdge, skin.eqText),
      _Cat.second => (skin.secondFill, skin.secondEdge, skin.secondText),
    };
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: TypewriterKey(
          label: k.label,
          color: color,
          edge: edge,
          textColor: text,
          texture: _texture,
          onTap: () => _onKey(k),
        ),
      ),
    );
  }

  void _openCas() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CasScreen(initialExpr: _expr),
    ));
  }

  void _openGraph() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GraphScreen(initialExpr: _expr),
    ));
  }

  /// The current value (evaluated) to seed a tool's first field with, or null.
  String? _seedValue() {
    if (_justEvaluated && _result.isNotEmpty) return _result;
    if (_expr.trim().isEmpty) return null;
    final r = _engine.evaluate(_expr, angle: _angle);
    return r.ok ? r.text : null;
  }

  /// Opens a tool seeded with the current value; if the tool returns a number
  /// ("use in calculator"), it replaces the expression.
  void _openTool(Widget Function(String? seed) build) async {
    final seed = _seedValue();
    final res = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => build(seed)),
    );
    if (res != null && res.isNotEmpty) {
      setState(() {
        _expr = res;
        _result = '';
        _justEvaluated = false;
        _recompute();
      });
    }
  }

  void _openTools() {
    final skin = SkinScope.skinOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) {
        Widget tile(IconData icon, String title, String sub, Widget Function(String?) build) => ListTile(
              leading: Icon(icon, color: skin.accent),
              title: Text(title, style: Kawaii.ui(15, weight: FontWeight.w800, color: skin.ink)),
              subtitle: Text(sub, style: Kawaii.ui(12.5, color: skin.inkSoft)),
              trailing: Icon(Icons.chevron_right_rounded, color: skin.inkSoft),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openTool(build);
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                  child: Row(children: [
                    Icon(Icons.grid_view_rounded, color: skin.accent),
                    const SizedBox(width: 8),
                    Text('Tools', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
                  ]),
                ),
                tile(Icons.circle_outlined, 'Circle', 'Radius, diameter, circumference, area, sphere',
                    (s) => CircleScreen(initialValue: s)),
                tile(Icons.percent_rounded, 'Tax', 'Add or remove a country\'s tax',
                    (s) => TaxScreen(initialValue: s)),
                tile(Icons.currency_exchange_rounded, 'Currency', 'Live exchange rates',
                    (s) => CurrencyScreen(initialAmount: s)),
                tile(Icons.groups_rounded, 'Split', 'Split a bill, with optional tip',
                    (s) => SplitScreen(initialValue: s)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSkinPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SkinScope.skinOf(context).paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SkinPicker(),
    );
  }

  void _openSettings() {
    final skin = SkinScope.skinOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.settings_rounded, color: skin.accent),
                  const SizedBox(width: 8),
                  Text('Settings', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
                ]),
                const SizedBox(height: 18),
                // Angle
                Row(children: [
                  Expanded(child: Text('Angle', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink))),
                  for (final m in AngleMode.values) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _angle = m;
                          _recompute();
                        });
                        setSheet(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _angle == m ? skin.accent : skin.funcFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: skin.funcEdge),
                        ),
                        child: Text(m == AngleMode.rad ? 'RAD' : 'DEG',
                            style: Kawaii.ui(13, weight: FontWeight.w800, color: _angle == m ? skin.buttonTextColor : skin.ink)),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                // Haptics
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Haptic feedback', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink)),
                  value: hapticsEnabled,
                  onChanged: (v) => setSheet(() => setHaptics(v)),
                ),
                // Country (drives the Tax tool's default rate & currency)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.public_rounded, color: skin.accent),
                  title: Text('Country', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink)),
                  subtitle: Text('${countryByCode(countryCode).name} · ${countryByCode(countryCode).taxName} ${trimRate(countryByCode(countryCode).taxRate)}%',
                      style: Kawaii.ui(12.5, color: skin.inkSoft)),
                  trailing: Icon(Icons.chevron_right_rounded, color: skin.inkSoft),
                  onTap: () async {
                    final picked = await showCountryPicker(sheetCtx, skin, countryByCode(countryCode));
                    if (picked != null) {
                      setCountry(picked.code);
                      setSheet(() {});
                    }
                  },
                ),
                // Appearance
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.palette_rounded, color: skin.accent),
                  title: Text('Theme, font & texture', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink)),
                  trailing: Icon(Icons.chevron_right_rounded, color: skin.inkSoft),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _openSkinPicker();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    final skin = SkinScope.skinOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _HistorySheet(skin: skin, history: _history, onTap: (h) {
        Navigator.pop(context);
        _loadHistory(h);
      }),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final CalcSkin skin;
  final List<HistoryEntry> history;
  final void Function(HistoryEntry) onTap;
  const _HistorySheet({required this.skin, required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.history_rounded, color: skin.accent),
              const SizedBox(width: 8),
              Text('History', style: Kawaii.ui(17, weight: FontWeight.w800, color: skin.ink)),
            ]),
          ),
          if (history.isEmpty)
            Expanded(child: Center(child: Text('No calculations yet', style: Kawaii.ui(15, color: skin.inkSoft))))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: history.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: skin.divider),
                itemBuilder: (_, i) {
                  final h = history[i];
                  return ListTile(
                    onTap: () => onTap(h),
                    title: Text(h.expr, style: Kawaii.display(15).copyWith(color: skin.inkSoft)),
                    subtitle: Text('= ${h.result}', style: Kawaii.display(20).copyWith(color: skin.ink)),
                    trailing: Icon(Icons.north_west_rounded, size: 18, color: skin.inkSoft),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
