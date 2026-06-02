import 'package:flutter/material.dart';
import '../theme.dart';
import 'skin.dart';
import 'skins.dart';

/// Bottom sheet to pick a skin, grouped into Light and Dark.
class SkinPicker extends StatelessWidget {
  final CalcSkin current;
  final ValueChanged<CalcSkin> onSelect;
  const SkinPicker({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.66,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: current.divider, borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.palette_rounded, color: current.accentColor, size: 20),
                const SizedBox(width: 8),
                Text('Themes', style: Kawaii.ui(18, weight: FontWeight.w800, color: current.ink)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  _section(current, 'Light'),
                  _grid(lightSkins),
                  const SizedBox(height: 16),
                  _section(current, 'Dark'),
                  _grid(darkSkins),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(CalcSkin skin, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: Kawaii.ui(14, weight: FontWeight.w800, color: skin.inkSoft)),
      );

  Widget _grid(List<CalcSkin> skins) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [for (final s in skins) _card(s)],
    );
  }

  Widget _card(CalcSkin s) {
    final selected = s.id == current.id;
    return GestureDetector(
      onTap: () => onSelect(s),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.bgGradient,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? s.accentColor : s.dividerColor,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _swatch(s.cardBackground),
                _swatch(s.buttonColor),
                _swatch(s.accentColor),
                _swatch(s.digitColor),
                const Spacer(),
                if (selected) Icon(Icons.check_circle_rounded, color: s.accentColor, size: 20),
              ],
            ),
            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Kawaii.ui(14, weight: FontWeight.w800, color: s.primaryTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
      );
}
