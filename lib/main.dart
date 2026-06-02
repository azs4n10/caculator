import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calculator_screen.dart';
import 'theme.dart';
import 'theme/fonts.dart';
import 'theme/font_scope.dart';
import 'theme/skin.dart';
import 'theme/skins.dart';
import 'theme/skin_scope.dart';

const _kSkinId = 'skin_id';
const _kFontId = 'font_id';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(KawaiiCalcApp(prefs: prefs));
}

class KawaiiCalcApp extends StatefulWidget {
  final SharedPreferences prefs;
  const KawaiiCalcApp({super.key, required this.prefs});

  @override
  State<KawaiiCalcApp> createState() => _KawaiiCalcAppState();
}

class _KawaiiCalcAppState extends State<KawaiiCalcApp> {
  late CalcSkin _skin = skinById(widget.prefs.getString(_kSkinId) ?? defaultSkin.id);
  late AppFont _font = fontById(widget.prefs.getString(_kFontId) ?? defaultFont.id);

  void _selectSkin(CalcSkin s) {
    setState(() => _skin = s);
    widget.prefs.setString(_kSkinId, s.id);
  }

  void _selectFont(AppFont f) {
    setState(() => _font = f);
    widget.prefs.setString(_kFontId, f.id);
  }

  @override
  Widget build(BuildContext context) {
    Kawaii.family = _font.family; // applied before the tree is built
    return SkinScope(
      skin: _skin,
      onSelect: _selectSkin,
      child: FontScope(
        font: _font,
        onSelect: _selectFont,
        child: MaterialApp(
          title: 'Calculator',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(_skin),
          home: const Scaffold(body: CalculatorScreen()),
        ),
      ),
    );
  }
}
