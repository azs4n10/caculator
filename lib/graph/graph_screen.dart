import 'package:flutter/material.dart';
import '../engine.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../theme/skin_scope.dart';
import 'graph_painter.dart';

const _palette = [
  Color(0xFFEC4899), // pink
  Color(0xFF5B9BF0), // blue
  Color(0xFF2FB39B), // teal
  Color(0xFFF59E42), // orange
];

class _FnEntry {
  final TextEditingController ctrl;
  final Color color;
  RealFn? fn;
  bool get valid => fn != null || ctrl.text.trim().isEmpty;
  _FnEntry(String text, this.color) : ctrl = TextEditingController(text: text);
}

/// Graph: plot y = f(x) for one or more functions, with pinch/drag zoom & pan,
/// and a value table.
class GraphScreen extends StatefulWidget {
  final String initialExpr;
  const GraphScreen({super.key, this.initialExpr = ''});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final _engine = CalculatorEngine();
  late final List<_FnEntry> _fns;
  AngleMode _angle = AngleMode.rad;

  double _xMin = -10, _xMax = 10, _yMin = -10, _yMax = 10;
  Offset _lastFocal = Offset.zero;
  double _lastScale = 1;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialExpr.contains('x') ? widget.initialExpr : 'sin(x)';
    _fns = [_FnEntry(seed, _palette[0])];
    _recompileAll();
  }

  @override
  void dispose() {
    for (final f in _fns) {
      f.ctrl.dispose();
    }
    super.dispose();
  }

  void _recompileAll() {
    for (final e in _fns) {
      final t = e.ctrl.text.trim();
      e.fn = t.isEmpty ? null : _engine.compile(t, angle: _angle);
    }
  }

  void _addFn() {
    if (_fns.length >= 4) return;
    setState(() => _fns.add(_FnEntry('', _palette[_fns.length % _palette.length])));
  }

  void _removeFn(int i) {
    setState(() {
      _fns[i].ctrl.dispose();
      _fns.removeAt(i);
    });
  }

  void _zoom(double factor) {
    setState(() {
      final cx = (_xMin + _xMax) / 2, cy = (_yMin + _yMax) / 2;
      _xMin = cx + (_xMin - cx) * factor;
      _xMax = cx + (_xMax - cx) * factor;
      _yMin = cy + (_yMin - cy) * factor;
      _yMax = cy + (_yMax - cy) * factor;
    });
  }

  void _reset() => setState(() {
        _xMin = -10;
        _xMax = 10;
        _yMin = -10;
        _yMax = 10;
      });

  void _onScaleStart(ScaleStartDetails d) {
    _lastFocal = d.localFocalPoint;
    _lastScale = 1;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    setState(() {
      final w = size.width, h = size.height;
      // Zoom around the focal point.
      final scaleDelta = d.scale / _lastScale;
      _lastScale = d.scale;
      final fx = _xMin + d.localFocalPoint.dx / w * (_xMax - _xMin);
      final fy = _yMax - d.localFocalPoint.dy / h * (_yMax - _yMin);
      _xMin = fx + (_xMin - fx) / scaleDelta;
      _xMax = fx + (_xMax - fx) / scaleDelta;
      _yMin = fy + (_yMin - fy) / scaleDelta;
      _yMax = fy + (_yMax - fy) / scaleDelta;
      // Pan by focal movement.
      final fd = d.localFocalPoint - _lastFocal;
      _lastFocal = d.localFocalPoint;
      final dxData = -fd.dx / w * (_xMax - _xMin);
      final dyData = fd.dy / h * (_yMax - _yMin);
      _xMin += dxData;
      _xMax += dxData;
      _yMin += dyData;
      _yMax += dyData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final plots = [
      for (final e in _fns)
        if (e.fn != null) PlotFn(e.fn!, e.color),
    ];
    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.bgGradient.first,
        foregroundColor: skin.ink,
        title: Text('Graph', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
        actions: [
          _angleToggle(skin),
          IconButton(
            tooltip: 'Value table',
            icon: Icon(Icons.table_chart_rounded, color: skin.accent),
            onPressed: () => _showTable(skin),
          ),
        ],
      ),
      body: Column(
        children: [
          _inputs(skin),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (_, c) {
                          final size = Size(c.maxWidth, c.maxHeight);
                          return GestureDetector(
                            onScaleStart: _onScaleStart,
                            onScaleUpdate: (d) => _onScaleUpdate(d, size),
                            child: CustomPaint(
                              size: size,
                              painter: GraphPainter(
                                fns: plots,
                                xMin: _xMin, xMax: _xMax, yMin: _yMin, yMax: _yMax,
                                skin: skin,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(right: 10, bottom: 10, child: _zoomControls(skin)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _angleToggle(CalcSkin skin) => Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() {
              _angle = _angle == AngleMode.rad ? AngleMode.deg : AngleMode.rad;
              _recompileAll();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: skin.funcFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: skin.funcEdge),
              ),
              child: Text(_angle == AngleMode.rad ? 'RAD' : 'DEG',
                  style: Kawaii.ui(12, weight: FontWeight.w800, color: skin.ink)),
            ),
          ),
        ),
      );

  Widget _inputs(CalcSkin skin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          for (var i = 0; i < _fns.length; i++) _inputRow(skin, i),
          if (_fns.length < 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addFn,
                icon: Icon(Icons.add_rounded, color: skin.accent, size: 20),
                label: Text('Add function', style: Kawaii.ui(13, weight: FontWeight.w700, color: skin.accent)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputRow(CalcSkin skin, int i) {
    final e = _fns[i];
    final bad = e.ctrl.text.trim().isNotEmpty && e.fn == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('y =', style: Kawaii.display(15).copyWith(color: skin.inkSoft)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: skin.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bad ? Colors.redAccent.withValues(alpha: 0.6) : skin.divider),
              ),
              child: TextField(
                controller: e.ctrl,
                style: Kawaii.display(16).copyWith(color: skin.ink),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'f(x), e.g. x^2-3, sin(x)',
                  hintStyle: Kawaii.ui(12, color: skin.inkSoft),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setState(_recompileAll),
              ),
            ),
          ),
          if (_fns.length > 1)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: skin.inkSoft),
              onPressed: () => _removeFn(i),
            ),
        ],
      ),
    );
  }

  Widget _zoomControls(CalcSkin skin) {
    Widget btn(IconData ic, VoidCallback onTap) => Material(
          color: skin.paper.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(8), child: Icon(ic, color: skin.ink, size: 22)),
          ),
        );
    return Column(
      children: [
        btn(Icons.add_rounded, () => _zoom(0.8)),
        const SizedBox(height: 8),
        btn(Icons.remove_rounded, () => _zoom(1.25)),
        const SizedBox(height: 8),
        btn(Icons.center_focus_strong_rounded, _reset),
      ],
    );
  }

  void _showTable(CalcSkin skin) {
    const rows = 13;
    final step = (_xMax - _xMin) / (rows - 1);
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.table_chart_rounded, color: skin.accent),
                const SizedBox(width: 8),
                Text('Value table', style: Kawaii.ui(17, weight: FontWeight.w800, color: skin.ink)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 38,
                    columns: [
                      DataColumn(label: Text('x', style: Kawaii.display(14).copyWith(color: skin.inkSoft))),
                      for (final e in _fns)
                        DataColumn(
                          label: Text(e.ctrl.text.trim().isEmpty ? 'y' : e.ctrl.text.trim(),
                              style: Kawaii.display(13).copyWith(color: e.color)),
                        ),
                    ],
                    rows: [
                      for (var r = 0; r < rows; r++)
                        _tableRow(skin, _xMin + r * step),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _tableRow(CalcSkin skin, double x) {
    String cell(_FnEntry e) {
      if (e.fn == null) return '—';
      final y = e.fn!(x);
      return y.isFinite ? CalculatorEngine.formatNumber(y) : '—';
    }

    return DataRow(cells: [
      DataCell(Text(CalculatorEngine.formatNumber(x), style: Kawaii.display(13).copyWith(color: skin.ink))),
      for (final e in _fns) DataCell(Text(cell(e), style: Kawaii.display(13).copyWith(color: skin.ink))),
    ]);
  }
}
