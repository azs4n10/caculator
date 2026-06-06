import 'package:flutter/material.dart';
import '../theme.dart';
import '../theme/skin.dart';
import 'countries.dart';

String trimRate(double r) =>
    r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();

/// Bottom-sheet list of countries. Returns the chosen [Country] or null.
Future<Country?> showCountryPicker(BuildContext context, CalcSkin skin, Country selected) {
  return showModalBottomSheet<Country>(
    context: context,
    backgroundColor: skin.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CountrySheet(skin: skin, selected: selected),
  );
}

class _CountrySheet extends StatelessWidget {
  final CalcSkin skin;
  final Country selected;
  const _CountrySheet({required this.skin, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.public_rounded, color: skin.accent),
              const SizedBox(width: 8),
              Text('Country', style: Kawaii.ui(17, weight: FontWeight.w800, color: skin.ink)),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: kCountries.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: skin.divider),
              itemBuilder: (_, i) {
                final c = kCountries[i];
                final sel = c.code == selected.code;
                return ListTile(
                  onTap: () => Navigator.pop(context, c),
                  title: Text(c.name, style: Kawaii.ui(15, weight: FontWeight.w700, color: skin.ink)),
                  subtitle: Text('${c.taxName} · ${trimRate(c.taxRate)}% · ${c.currency}',
                      style: Kawaii.ui(12.5, color: skin.inkSoft)),
                  trailing: sel ? Icon(Icons.check_circle_rounded, color: skin.accent) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
