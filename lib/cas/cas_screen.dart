import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../theme/skin_scope.dart';
import 'cas_client.dart';

/// The Solver (CAS) panel: send an expression to the SymPy backend and
/// show symbolic results — simplify / expand / factor / differentiate /
/// integrate / solve. This is the WolframAlpha-class layer.
class CasScreen extends StatefulWidget {
  final String initialExpr;
  const CasScreen({super.key, this.initialExpr = ''});

  @override
  State<CasScreen> createState() => _CasScreenState();
}

class _CasScreenState extends State<CasScreen> {
  final _client = CasClient();
  late final TextEditingController _ctrl;
  bool _loading = false;
  bool? _online;
  CasResponse? _resp;

  static const _actions = [
    ('All', 'analyze'),
    ('Simplify', 'simplify'),
    ('Expand', 'expand'),
    ('Factor', 'factor'),
    ('Derivative', 'derivative'),
    ('Integral', 'integral'),
    ('Solve = 0', 'solve'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialExpr);
    _client.ping().then((v) => mounted ? setState(() => _online = v) : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run(String action) async {
    final expr = _ctrl.text.trim();
    if (expr.isEmpty) return;
    setState(() => _loading = true);
    final r = action == 'analyze'
        ? await _client.analyze(expr)
        : await _client.action(expr, action);
    if (!mounted) return;
    setState(() {
      _resp = r;
      _loading = false;
      _online = r.ok ? true : _online;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.bgGradient.first,
        foregroundColor: skin.ink,
        title: Text('Solver ∫', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
        actions: [_statusChip(skin)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input(skin),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final a in _actions) _chip(skin, a.$1, a.$2)],
            ),
            const SizedBox(height: 16),
            Expanded(child: _results(skin)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(CalcSkin skin) {
    final (txt, col) = switch (_online) {
      true => ('● Server OK', const Color(0xFF3FAE7A)),
      false => ('● Offline', skin.accent),
      _ => ('● Checking', skin.inkSoft),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Text(txt, style: Kawaii.ui(12, weight: FontWeight.w700, color: col)),
      ),
    );
  }

  Widget _input(CalcSkin skin) {
    return Container(
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: skin.divider),
      ),
      child: TextField(
        controller: _ctrl,
        style: Kawaii.display(20).copyWith(color: skin.ink),
        decoration: InputDecoration(
          hintText: 'Enter an expression (e.g. x^2+3x+2)',
          hintStyle: Kawaii.ui(13, color: skin.inkSoft),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(Icons.auto_awesome_rounded, color: skin.accent),
            tooltip: 'Analyze',
            onPressed: () => _run('analyze'),
          ),
        ),
        onSubmitted: (_) => _run('analyze'),
      ),
    );
  }

  Widget _chip(CalcSkin skin, String label, String action) {
    return GestureDetector(
      onTap: () => _run(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: skin.funcFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skin.funcEdge),
        ),
        child: Text(label, style: Kawaii.ui(13, weight: FontWeight.w800, color: skin.ink)),
      ),
    );
  }

  Widget _results(CalcSkin skin) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: skin.accent));
    }
    final r = _resp;
    if (r == null) {
      return Center(
        child: Text('Enter an expression and tap a button 🐱', style: Kawaii.ui(14, color: skin.inkSoft)),
      );
    }
    if (!r.ok) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🙀', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(r.error ?? 'Error', textAlign: TextAlign.center, style: Kawaii.ui(14, color: skin.ink)),
            const SizedBox(height: 12),
            Text('Tip: start the backend with\nuvicorn main:app --port 8000',
                textAlign: TextAlign.center, style: Kawaii.ui(12, color: skin.inkSoft)),
          ]),
        ),
      );
    }
    return ListView(
      children: [
        if (r.inputLatex != null) _inputEcho(skin, r.inputLatex!),
        for (final c in r.results) _card(skin, c),
      ],
    );
  }

  Widget _inputEcho(CalcSkin skin, String latex) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text('Input: ', style: Kawaii.ui(12, color: skin.inkSoft)),
          Flexible(child: _tex(skin, latex, 18, skin.inkSoft)),
        ]),
      );

  Widget _card(CalcSkin skin, CasCard c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: skin.isDark ? 0.25 : 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: skin.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.title, style: Kawaii.ui(13, weight: FontWeight.w800, color: skin.accent)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _tex(skin, c.latex, 24, skin.ink, fallback: c.text),
          ),
        ],
      ),
    );
  }

  Widget _tex(CalcSkin skin, String latex, double size, Color color, {String? fallback}) {
    return Math.tex(
      latex,
      textStyle: Kawaii.display(size).copyWith(color: color),
      onErrorFallback: (_) => Text(fallback ?? latex, style: Kawaii.display(size).copyWith(color: color)),
    );
  }
}
