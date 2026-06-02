import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'font_scope.dart';
import 'fonts.dart';
import 'skin.dart';
import 'skins.dart';
import 'skin_scope.dart';

/// Bottom sheet to pick the appearance: font + colour theme (Light / Dark).
/// Reads the live scopes so selections update immediately.
class SkinPicker extends StatelessWidget {
  const SkinPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final skinScope = SkinScope.of(context);
    final fontScope = FontScope.of(context);
    final skin = skinScope.skin;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.66,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: skin.divider, borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.palette_rounded, color: skin.accentColor, size: 20),
                const SizedBox(width: 8),
                Text('Appearance', style: Kawaii.ui(18, weight: FontWeight.w800, color: skin.ink)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  _label(skin, 'Font'),
                  _fontSelector(skin, fontScope),
                  const SizedBox(height: 16),
                  _label(skin, 'Light'),
                  _grid(skinScope, lightSkins),
                  const SizedBox(height: 16),
                  _label(skin, 'Dark'),
                  _grid(skinScope, darkSkins),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(CalcSkin skin, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: Kawaii.ui(14, weight: FontWeight.w800, color: skin.inkSoft)),
      );

  Widget _fontSelector(CalcSkin skin, FontScope fontScope) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final f in appFonts)
          GestureDetector(
            onTap: () => fontScope.onSelect(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: skin.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: f.id == fontScope.font.id ? skin.accentColor : skin.dividerColor,
                  width: f.id == fontScope.font.id ? 2.5 : 1,
                ),
              ),
              child: Text(
                f.name,
                style: GoogleFonts.getFont(f.family,
                    fontSize: 15, fontWeight: FontWeight.w700, color: skin.primaryTextColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _grid(SkinScope skinScope, List<CalcSkin> skins) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [for (final s in skins) _card(skinScope, s)],
    );
  }

  Widget _card(SkinScope skinScope, CalcSkin s) {
    final selected = s.id == skinScope.skin.id;
    return GestureDetector(
      onTap: () => skinScope.onSelect(s),
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
            Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
