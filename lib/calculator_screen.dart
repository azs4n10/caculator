import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cas/cas_screen.dart';
import 'engine.dart';
import 'theme.dart';
import 'theme/skin.dart';
import 'theme/skin_picker.dart';
import 'theme/skin_scope.dart';
import 'widgets/cat_mascot.dart';
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
  CatMood _mood = CatMood.idle;
  AngleMode _angle = AngleMode.rad;
  bool _justEvaluated = false;
  bool _funcOpen = false;
  bool _second = false;
  final List<HistoryEntry> _history = [];

  static const _pad = <_K>[
    _K('C', act: _Act.clear, cat: _Cat.pink),
    _K('⌫', act: _Act.back, cat: _Cat.pink),
    _K('%', insert: '%', cat: _Cat.op),
    _K('÷', insert: '÷', cat: _Cat.op),
    _K('7'), _K('8'), _K('9'), _K('×', insert: '×', cat: _Cat.op),
    _K('4'), _K('5'), _K('6'), _K('−', insert: '−', cat: _Cat.op),
    _K('1'), _K('2'), _K('3'), _K('+', insert: '+', cat: _Cat.op),
    _K('±', act: _Act.sign, cat: _Cat.op),
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
  ];

  void _onKey(_K k) {
    switch (k.act) {
      case _Act.clear:
        setState(() {
          _expr = '';
          _result = '';
          _preview = '';
          _mood = CatMood.idle;
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
    final r = _engine.evaluate(_expr, angle: _angle);
    setState(() {
      if (r.ok) {
        _result = r.text;
        _preview = '';
        _mood = CatMood.happy;
        _justEvaluated = true;
        _history.insert(0, HistoryEntry(_expr, r.text));
      } else {
        _result = r.text;
        _preview = '';
        _mood = CatMood.error;
      }
    });
  }

  void _loadHistory(HistoryEntry h) {
    setState(() {
      _expr = h.expr;
      _result = h.result;
      _justEvaluated = true;
      _mood = CatMood.idle;
      _recompute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skin.bgGradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header(skin),
            _display(skin),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _funcOpen ? _funcTray(skin) : const SizedBox(width: double.infinity),
                    ),
                    _funcToggleBar(skin),
                    const SizedBox(height: 6),
                    Expanded(child: _grid(skin, _pad, 4, fontSize: 24, gap: 8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(CalcSkin skin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 0),
      child: Row(
        children: [
          CatMascot(mood: _mood, size: 40, skin: skin),
          const SizedBox(width: 8),
          Expanded(
            child: Text('ぷにぷに関数電卓',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Kawaii.ui(17, weight: FontWeight.w800, color: skin.ink)),
          ),
          _angleToggle(skin),
          const SizedBox(width: 5),
          _chip(skin, '🎨', skin.accent, _openSkinPicker),
          const SizedBox(width: 5),
          _chip(skin, '∫', skin.accent, _openCas),
          const SizedBox(width: 5),
          _chip(skin, '履歴', skin.inkSoft, _showHistory),
        ],
      ),
    );
  }

  Widget _chip(CalcSkin skin, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: skin.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: Kawaii.ui(13, weight: FontWeight.w800, color: color)),
      ),
    );
  }

  Widget _angleToggle(CalcSkin skin) {
    return GestureDetector(
      onTap: () => setState(() {
        _angle = _angle == AngleMode.rad ? AngleMode.deg : AngleMode.rad;
        HapticFeedback.selectionClick();
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

  Widget _display(CalcSkin skin) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
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
            child: Text(_expr.isEmpty ? '　' : _expr, style: Kawaii.display(26).copyWith(color: skin.ink)),
          ),
          const SizedBox(height: 8),
          if (_justEvaluated || _result.isNotEmpty)
            Text(_result, style: Kawaii.display(40).copyWith(color: skin.result))
          else if (_preview.isNotEmpty)
            Text('= $_preview', style: Kawaii.display(22).copyWith(color: skin.inkSoft)),
        ],
      ),
    );
  }

  Widget _funcToggleBar(CalcSkin skin) {
    return GestureDetector(
      onTap: () => setState(() {
        _funcOpen = !_funcOpen;
        HapticFeedback.selectionClick();
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
            Text(_funcOpen ? 'かんすうを とじる' : 'ƒ(x) かんすう',
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
        child: Row(
          children: [
            for (var j = 0; j < slice.length; j++) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(child: _funcKey(skin, slice[j])),
            ],
          ],
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  Widget _funcKey(CalcSkin skin, _FK f) {
    if (f.isSecond) {
      return TypewriterKey(
        label: '2nd',
        color: _second ? skin.secondFill : skin.funcFill,
        edge: _second ? skin.secondEdge : skin.funcEdge,
        textColor: _second ? skin.secondText : skin.funcText,
        fontSize: 15,
        height: 46,
        onTap: () => setState(() => _second = !_second),
      );
    }
    final showAlt = _second && f.label2 != null;
    final label = showAlt ? f.label2! : f.label;
    final insert = showAlt ? f.insert2! : f.insert;
    return TypewriterKey(
      label: label,
      color: skin.funcFill,
      edge: skin.funcEdge,
      textColor: skin.funcText,
      fontSize: 15,
      height: 46,
      onTap: () => _insert(insert),
    );
  }

  Widget _grid(CalcSkin skin, List<_K> keys, int cols, {required double fontSize, required double gap}) {
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
                Expanded(child: _keyWidget(skin, slice[j], fontSize)),
              ],
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _keyWidget(CalcSkin skin, _K k, double fontSize) {
    final (color, edge, text) = switch (k.cat) {
      _Cat.number => (skin.numFill, skin.numEdge, skin.numText),
      _Cat.op => (skin.opFill, skin.opEdge, skin.opText),
      _Cat.func => (skin.funcFill, skin.funcEdge, skin.funcText),
      _Cat.pink => (skin.clearFill, skin.clearEdge, skin.clearText),
      _Cat.mint => (skin.eqFill, skin.eqEdge, skin.eqText),
      _Cat.second => (skin.secondFill, skin.secondEdge, skin.secondText),
    };
    return LayoutBuilder(
      builder: (_, c) => TypewriterKey(
        label: k.label,
        color: color,
        edge: edge,
        textColor: text,
        fontSize: fontSize,
        height: (c.maxHeight - 5).clamp(34, 70).toDouble(),
        onTap: () => _onKey(k),
      ),
    );
  }

  void _openCas() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CasScreen(initialExpr: _expr),
    ));
  }

  void _openSkinPicker() {
    final scope = SkinScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: scope.skin.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SkinPicker(current: scope.skin, onSelect: scope.onSelect),
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
              Text('けいさん履歴', style: Kawaii.ui(17, weight: FontWeight.w800, color: skin.ink)),
            ]),
          ),
          if (history.isEmpty)
            Expanded(child: Center(child: Text('まだ計算してないよ 🐾', style: Kawaii.ui(15, color: skin.inkSoft))))
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
