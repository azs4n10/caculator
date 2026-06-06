import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings.dart';
import '../theme.dart';
import '../theme/skin_scope.dart';
import 'countries.dart';
import 'country_picker.dart';
import 'tool_ui.dart';

/// Discount (sale price) calculator: original price minus a percentage or a
/// flat amount off → what you pay and what you save. Shows a tax-included line
/// for the selected country when it has a sales tax.
class DiscountScreen extends StatefulWidget {
  final String? initialValue;
  const DiscountScreen({super.key, this.initialValue});
  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  late final _price = TextEditingController(text: widget.initialValue ?? '');
  final _discount = TextEditingController();
  bool _isPercent = true;

  String get _currency => countryByCode(countryCode).currency;

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  ({double? saved, double? finalPrice}) _compute() {
    final price = double.tryParse(_price.text.trim());
    final disc = double.tryParse(_discount.text.trim()) ?? 0;
    if (price == null || price < 0) return (saved: null, finalPrice: null);
    final saved = _isPercent ? price * (disc / 100) : disc.clamp(0, price).toDouble();
    return (saved: saved, finalPrice: price - saved);
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final r = _compute();
    final country = countryByCode(countryCode);
    final withTax = (r.finalPrice == null || country.taxRate == 0)
        ? null
        : r.finalPrice! * (1 + country.taxRate / 100);
    String money(double? v) => v == null ? '—' : formatMoney(v, _currency);

    return ToolScaffold(
      skin: skin,
      title: 'Discount',
      icon: Icons.sell_rounded,
      actions: [
        useInCalcAction(context, skin,
            () => r.finalPrice == null ? null : bareNumber(r.finalPrice!, decimals: currencyDecimals(_currency))),
      ],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _price,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            style: Kawaii.display(28).copyWith(color: skin.ink),
            decoration: kawaiiInput(skin, 'Original price ($_currency)'),
          ),
          const SizedBox(height: 16),
          // Percent vs flat-amount mode.
          Row(
            children: [
              selectChip(skin, '% OFF', _isPercent, () => setState(() => _isPercent = true), expand: true),
              const SizedBox(width: 10),
              selectChip(skin, 'Amount off', !_isPercent, () => setState(() => _isPercent = false), expand: true),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _discount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            style: Kawaii.display(24).copyWith(color: skin.ink),
            decoration: kawaiiInput(skin, _isPercent ? 'Discount %' : 'Amount off ($_currency)'),
          ),
          if (_isPercent) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in const [10, 20, 30, 50, 70])
                  selectChip(skin, '$p%', _discount.text.trim() == '$p',
                      () => setState(() => _discount.text = '$p')),
              ],
            ),
          ],
          const SizedBox(height: 24),
          toolCard(
            skin,
            child: Column(
              children: [
                resultRow(skin, 'You save', money(r.saved)),
                Divider(height: 1, color: skin.divider),
                resultRow(skin, 'You pay', money(r.finalPrice), big: true),
                if (withTax != null) ...[
                  Divider(height: 1, color: skin.divider),
                  resultRow(skin, 'With tax (${trimRate(country.taxRate)}%)', money(withTax)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
