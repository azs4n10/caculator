import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine.dart';
import '../settings.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../theme/skin_scope.dart';
import 'countries.dart';
import 'country_picker.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});
  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late Country _country = countryByCode(countryCode);
  final _amount = TextEditingController();
  late final _rate = TextEditingController(text: trimRate(_country.taxRate));
  bool _amountIncludesTax = false; // false = amount is pre-tax

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final amount = double.tryParse(_amount.text.trim());
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final f = rate / 100;

    double? net, tax, gross;
    if (amount != null && amount >= 0) {
      if (_amountIncludesTax) {
        gross = amount;
        net = amount / (1 + f);
        tax = gross - net;
      } else {
        net = amount;
        tax = amount * f;
        gross = net + tax;
      }
    }

    String money(double? v) =>
        v == null ? '—' : '${CalculatorEngine.formatNumber(double.parse(v.toStringAsFixed(2)))} ${_country.currency}';

    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.bgGradient.first,
        foregroundColor: skin.ink,
        title: Text('Tax', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Country selector
            GestureDetector(
              onTap: _pickCountry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: skin.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: skin.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: skin.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_country.name,
                          style: Kawaii.ui(16, weight: FontWeight.w800, color: skin.ink)),
                    ),
                    Text(_country.taxName,
                        style: Kawaii.ui(13, weight: FontWeight.w600, color: skin.inkSoft)),
                    Icon(Icons.expand_more_rounded, color: skin.inkSoft),
                  ],
                ),
              ),
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
                    decoration: _dec(skin, 'Amount'),
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
                    decoration: _dec(skin, 'Rate %'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Pre-tax vs tax-included toggle
            Row(
              children: [
                _seg(skin, 'Enter pre-tax', !_amountIncludesTax,
                    () => setState(() => _amountIncludesTax = false)),
                const SizedBox(width: 10),
                _seg(skin, 'Enter tax-included', _amountIncludesTax,
                    () => setState(() => _amountIncludesTax = true)),
              ],
            ),
            const SizedBox(height: 22),
            _resultCard(skin, money(net), money(tax), money(gross)),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(CalcSkin skin, String label) => InputDecoration(
        labelText: label,
        labelStyle: Kawaii.ui(13, weight: FontWeight.w700, color: skin.inkSoft),
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
      );

  Widget _seg(CalcSkin skin, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? skin.accent : skin.funcFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: skin.funcEdge),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: Kawaii.ui(12.5,
                  weight: FontWeight.w800, color: active ? skin.buttonTextColor : skin.ink)),
        ),
      ),
    );
  }

  Widget _resultCard(CalcSkin skin, String net, String tax, String gross) {
    Widget row(String k, String v, {bool big = false}) => Padding(
          padding: EdgeInsets.symmetric(vertical: big ? 6 : 12),
          child: Row(
            children: [
              Expanded(child: Text(k, style: Kawaii.ui(big ? 16 : 15, weight: FontWeight.w700, color: skin.inkSoft))),
              Text(v, style: Kawaii.display(big ? 26 : 19).copyWith(color: big ? skin.accent : skin.ink)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: skin.divider),
      ),
      child: Column(
        children: [
          row('Net (pre-tax)', net),
          Divider(height: 1, color: skin.divider),
          row('Tax', tax),
          Divider(height: 1, color: skin.divider),
          row('Total (incl. tax)', gross, big: true),
        ],
      ),
    );
  }
}
