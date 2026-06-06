import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine.dart';
import '../theme.dart';
import '../theme/skin_scope.dart';
import 'tool_ui.dart';

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
  final String? initialValue;
  const CircleScreen({super.key, this.initialValue});
  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  _Known _known = _Known.radius;
  late final _ctrl = TextEditingController(text: widget.initialValue ?? '');

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
    String fmt(double? v) => v == null ? '—' : CalculatorEngine.formatNumber(v);
    final rows = <(String, double?)>[
      ('Radius', r),
      ('Diameter', r == null ? null : 2 * r),
      ('Circumference', r == null ? null : 2 * math.pi * r),
      ('Area', r == null ? null : math.pi * r * r),
    ];
    final sphere = <(String, double?)>[
      ('Sphere surface', r == null ? null : 4 * math.pi * r * r),
      ('Sphere volume', r == null ? null : 4 / 3 * math.pi * r * r * r),
    ];

    return ToolScaffold(
      skin: skin,
      title: 'Circle',
      icon: Icons.circle_outlined,
      actions: [
        useInCalcAction(context, skin, () {
          final a = r == null ? null : math.pi * r * r;
          return a == null ? null : bareNumber(a, decimals: 6);
        }),
      ],
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
                selectChip(skin, k.label, _known == k, () => setState(() => _known = k)),
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
            decoration: kawaiiInput(skin, _known.label),
          ),
          const SizedBox(height: 22),
          toolCard(
            skin,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: skin.divider),
                  resultRow(skin, rows[i].$1, fmt(rows[i].$2)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('As a sphere', style: Kawaii.ui(14, weight: FontWeight.w700, color: skin.inkSoft)),
          const SizedBox(height: 10),
          toolCard(
            skin,
            child: Column(
              children: [
                for (var i = 0; i < sphere.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: skin.divider),
                  resultRow(skin, sphere[i].$1, fmt(sphere[i].$2)),
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
    );
  }
}
