import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings.dart';
import '../theme.dart';
import '../theme/skin_scope.dart';
import 'countries.dart';
import 'country_picker.dart';
import 'tool_ui.dart';

class TaxScreen extends StatefulWidget {
  final String? initialValue;
  const TaxScreen({super.key, this.initialValue});
  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late Country _country = countryByCode(countryCode);
  late final _amount = TextEditingController(text: widget.initialValue ?? '');
  late final _rate = TextEditingController(text: trimRate(_country.taxRate));
  bool _amountIncludesTax = false; // false = amount is pre-tax

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool _rateIs(double r) => (double.tryParse(_rate.text.trim()) ?? -1) == r;
  void _setRate(double r) => setState(() => _rate.text = trimRate(r));

  void _pickCountry() async {
    final skin = SkinScope.skinOf(context);
    final picked = await showCountryPicker(context, skin, _country);
    if (picked != null) {
      setState(() {
        _country = picked;
        _rate.text = trimRate(picked.taxRate);
      });
      setCountry(picked.code);
    }
  }

  ({double? net, double? tax, double? gross}) _compute() {
    final amount = double.tryParse(_amount.text.trim());
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final f = rate / 100;
    if (amount == null || amount < 0) return (net: null, tax: null, gross: null);
    if (_amountIncludesTax) {
      final net = amount / (1 + f);
      return (net: net, tax: amount - net, gross: amount);
    }
    return (net: amount, tax: amount * f, gross: amount + amount * f);
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final r = _compute();
    String money(double? v) => v == null ? '—' : formatMoney(v, _country.currency);

    return ToolScaffold(
      skin: skin,
      title: 'Tax',
      icon: Icons.percent_rounded,
      actions: [
        useInCalcAction(context, skin,
            () => r.gross == null ? null : bareNumber(r.gross!, decimals: currencyDecimals(_country.currency))),
      ],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Country selector
          GestureDetector(
            onTap: _pickCountry,
            child: toolCard(
              skin,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.public_rounded, color: skin.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_country.name, style: Kawaii.ui(16, weight: FontWeight.w800, color: skin.ink)),
                  ),
                  Text(_country.taxName, style: Kawaii.ui(13, weight: FontWeight.w600, color: skin.inkSoft)),
                  Icon(Icons.expand_more_rounded, color: skin.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rate presets — standard vs the reduced rate (e.g. Japan's 8% on
          // food). The rate field stays editable for anything custom.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              selectChip(skin, 'Standard ${trimRate(_country.taxRate)}%',
                  _rateIs(_country.taxRate), () => _setRate(_country.taxRate)),
              if (_country.reducedRate != null)
                selectChip(skin, 'Reduced ${trimRate(_country.reducedRate!)}%',
                    _rateIs(_country.reducedRate!), () => _setRate(_country.reducedRate!)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => setState(() {}),
                  style: Kawaii.display(24).copyWith(color: skin.ink),
                  decoration: kawaiiInput(skin, 'Amount'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => setState(() {}),
                  style: Kawaii.display(24).copyWith(color: skin.ink),
                  decoration: kawaiiInput(skin, 'Rate %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              selectChip(skin, 'Enter pre-tax', !_amountIncludesTax,
                  () => setState(() => _amountIncludesTax = false),
                  expand: true),
              const SizedBox(width: 10),
              selectChip(skin, 'Enter tax-included', _amountIncludesTax,
                  () => setState(() => _amountIncludesTax = true),
                  expand: true),
            ],
          ),
          const SizedBox(height: 22),
          toolCard(
            skin,
            child: Column(
              children: [
                resultRow(skin, 'Net (pre-tax)', money(r.net)),
                Divider(height: 1, color: skin.divider),
                resultRow(skin, 'Tax', money(r.tax)),
                Divider(height: 1, color: skin.divider),
                resultRow(skin, 'Total (incl. tax)', money(r.gross), big: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
