import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../theme/skin_scope.dart';
import 'countries.dart';
import 'tool_ui.dart';

/// Split-the-bill (割り勘) helper: a bill amount, an optional tip, and a number
/// of people → what each person pays. Currency follows the selected country.
class SplitScreen extends StatefulWidget {
  final String? initialValue;
  const SplitScreen({super.key, this.initialValue});
  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  late final _bill = TextEditingController(text: widget.initialValue ?? '');
  int _people = 2;
  double _tip = 0; // percent

  String get _currency => countryByCode(countryCode).currency;

  @override
  void dispose() {
    _bill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final bill = double.tryParse(_bill.text.trim());
    final total = bill == null ? null : bill * (1 + _tip / 100);
    final each = total == null ? null : total / _people;
    String money(double? v) => v == null ? '—' : formatMoney(v, _currency);

    return ToolScaffold(
      skin: skin,
      title: 'Split',
      icon: Icons.groups_rounded,
      actions: [
        useInCalcAction(context, skin,
            () => each == null ? null : bareNumber(each, decimals: currencyDecimals(_currency))),
      ],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _bill,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            style: Kawaii.display(28).copyWith(color: skin.ink),
            decoration: kawaiiInput(skin, 'Bill amount ($_currency)'),
          ),
          const SizedBox(height: 20),
          // People stepper
          Row(
            children: [
              Expanded(child: Text('People', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink))),
              _round(skin, Icons.remove_rounded, () {
                if (_people > 1) setState(() => _people--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('$_people', style: Kawaii.display(26).copyWith(color: skin.ink)),
              ),
              _round(skin, Icons.add_rounded, () => setState(() => _people++)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Tip', style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in const [0.0, 5.0, 10.0, 15.0, 20.0])
                selectChip(skin, t == 0 ? 'None' : '${t.toStringAsFixed(0)}%', _tip == t,
                    () => setState(() => _tip = t)),
            ],
          ),
          const SizedBox(height: 24),
          toolCard(
            skin,
            child: Column(
              children: [
                resultRow(skin, 'Total${_tip > 0 ? ' (with tip)' : ''}', money(total)),
                Divider(height: 1, color: skin.divider),
                resultRow(skin, 'Each ($_people)', money(each), big: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _round(CalcSkin skin, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: skin.funcFill,
            shape: BoxShape.circle,
            border: Border.all(color: skin.funcEdge),
          ),
          child: Icon(icon, color: skin.ink, size: 22),
        ),
      );
}
