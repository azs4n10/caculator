import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../engine.dart';
import '../settings.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../theme/skin_scope.dart';
import 'countries.dart';

/// Currencies supported by the Frankfurter (ECB) API.
const _currencies = <String>[
  'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP', 'HKD',
  'HUF', 'IDR', 'ILS', 'INR', 'JPY', 'KRW', 'MXN', 'NOK', 'NZD', 'PHP',
  'PLN', 'SEK', 'SGD', 'THB', 'TRY', 'USD', 'ZAR',
];

// Last fetched rates per base, kept across screen opens for an offline fallback.
final Map<String, Map<String, double>> _rateCache = {};
String? _ratesDate;

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late String _from = _initialFrom();
  String _to = 'USD';
  final _amount = TextEditingController(text: '1');
  bool _loading = false;
  String? _error;

  static String _initialFrom() {
    final c = countryByCode(countryCode).currency;
    return _currencies.contains(c) ? c : 'JPY';
  }

  @override
  void initState() {
    super.initState();
    if (_from == _to) _to = _from == 'USD' ? 'JPY' : 'USD';
    _fetch();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('https://api.frankfurter.app/latest?from=$_from');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = (body['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      rates[_from] = 1.0; // base to itself
      _rateCache[_from] = rates;
      _ratesDate = body['date'] as String?;
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _rateCache.containsKey(_from)
              ? 'Offline — showing last saved rates'
              : 'Could not load rates. Check your connection.';
        });
      }
    }
  }

  double? get _converted {
    final a = double.tryParse(_amount.text.trim());
    final rates = _rateCache[_from];
    if (a == null || rates == null) return null;
    final r = rates[_to];
    if (r == null) return null;
    return a * r;
  }

  void _swap() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
    if (!_rateCache.containsKey(_from)) {
      _fetch();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = SkinScope.skinOf(context);
    final out = _converted;
    final rate = _rateCache[_from]?[_to];

    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.bgGradient.first,
        foregroundColor: skin.ink,
        title: Text('Currency', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
        actions: [
          IconButton(
            tooltip: 'Refresh rates',
            icon: Icon(Icons.refresh_rounded, color: skin.accent),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              style: Kawaii.display(28).copyWith(color: skin.ink),
              decoration: InputDecoration(
                labelText: 'Amount',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _picker(skin, 'From', _from, (v) {
                  setState(() => _from = v);
                  _rateCache.containsKey(v) ? setState(() {}) : _fetch();
                })),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: _swap,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: skin.funcFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: skin.funcEdge),
                      ),
                      child: Icon(Icons.swap_horiz_rounded, color: skin.ink),
                    ),
                  ),
                ),
                Expanded(child: _picker(skin, 'To', _to, (v) => setState(() => _to = v))),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: skin.paper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: skin.divider),
              ),
              child: Column(
                children: [
                  if (_loading)
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(strokeWidth: 3, color: skin.accent),
                    )
                  else ...[
                    Text(
                      out == null ? '—' : '${CalculatorEngine.formatNumber(double.parse(out.toStringAsFixed(2)))} $_to',
                      style: Kawaii.display(34).copyWith(color: skin.accent),
                    ),
                    const SizedBox(height: 8),
                    if (rate != null)
                      Text('1 $_from = ${CalculatorEngine.formatNumber(double.parse(rate.toStringAsFixed(4)))} $_to',
                          style: Kawaii.ui(13, weight: FontWeight.w600, color: skin.inkSoft)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Center(child: Text(_error!, textAlign: TextAlign.center, style: Kawaii.ui(13, weight: FontWeight.w600, color: skin.inkSoft)))
            else if (_ratesDate != null)
              Center(child: Text('ECB rates · $_ratesDate', style: Kawaii.ui(12, weight: FontWeight.w600, color: skin.inkSoft))),
          ],
        ),
      ),
    );
  }

  Widget _picker(CalcSkin skin, String label, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: skin.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: skin.paper,
          icon: Icon(Icons.expand_more_rounded, color: skin.inkSoft),
          style: Kawaii.display(20).copyWith(color: skin.ink),
          items: [
            for (final c in _currencies)
              DropdownMenuItem(value: c, child: Text(c, style: Kawaii.display(18).copyWith(color: skin.ink))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
