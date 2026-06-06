import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine.dart';
import '../theme.dart';
import '../theme/skin_scope.dart';

/// Which circle quantity the user is entering; the rest are derived.
enum _Known { radius, diameter, circumference, area }

extension on _Known {
  String get label => switch (this) {
        _Known.radius => 'Radius',
        _Known.diameter => 'Diameter',
        _Known.circumference => 'Circumference',
        _Known.area => 'Area',
      };
}

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});
  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  _Known _known = _Known.radius;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Radius implied by the current input, or null if blank/invalid.
  double? get _radius {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v < 0) return null;
    return switch (_known) {
      _Known.radius => v,
      _Known.diameter => v / 2,
      _Known.circumference => v / (2 * math.pi),
      _Known.area => math.sqrt(v / math.pi),
    };
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final r = _radius;
    final rows = <(String, double?)>[
      ('Radius', r),
      ('Diameter', r == null ? null : 2 * r),
      ('Circumference', r == null ? null : 2 * math.pi * r),
      ('Area', r == null ? null : math.pi * r * r),
    ];

    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.bgGradient.first,
        foregroundColor: skin.ink,
        title: Text('Circle', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text('I know the…', style: Kawaii.ui(14, weight: FontWeight.w700, color: skin.inkSoft)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in _Known.values)
                  GestureDetector(
                    onTap: () => setState(() => _known = k),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _known == k ? skin.accent : skin.funcFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: skin.funcEdge),
                      ),
                      child: Text(k.label,
                          style: Kawaii.ui(13,
                              weight: FontWeight.w800,
                              color: _known == k ? skin.buttonTextColor : skin.ink)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              style: Kawaii.display(26).copyWith(color: skin.ink),
              decoration: InputDecoration(
                labelText: _known.label,
                labelStyle: Kawaii.ui(14, weight: FontWeight.w700, color: skin.inkSoft),
                filled: true,
                fillColor: skin.paper,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: skin.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: skin.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: skin.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: skin.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: skin.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(rows[i].$1,
                                style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.inkSoft)),
                          ),
                          Text(
                            rows[i].$2 == null ? '—' : CalculatorEngine.formatNumber(rows[i].$2!),
                            style: Kawaii.display(20).copyWith(color: skin.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text('Using π ≈ 3.14159',
                  style: Kawaii.ui(12, weight: FontWeight.w600, color: skin.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}
