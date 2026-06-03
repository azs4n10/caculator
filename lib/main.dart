import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calculator_screen.dart';
import 'settings.dart';
import 'theme.dart';
import 'theme/fonts.dart';
import 'theme/font_scope.dart';
import 'theme/key_texture.dart';
import 'theme/skin.dart';
import 'theme/skins.dart';
import 'theme/skin_scope.dart';
import 'theme/texture_scope.dart';
import 'widgets/keycap_painter.dart';

const _kSkinId = 'skin_id';
const _kFontId = 'font_id';
const _kTextureId = 'key_texture';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadKeycapShader();
  final prefs = await SharedPreferences.getInstance();
  initSettings(prefs);
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
  late TextureOption _texture = textureById(widget.prefs.getString(_kTextureId) ?? defaultTexture.id);

  void _selectSkin(CalcSkin s) {
    setState(() => _skin = s);
    widget.prefs.setString(_kSkinId, s.id);
  }

  void _selectFont(AppFont f) {
    setState(() => _font = f);
    widget.prefs.setString(_kFontId, f.id);
  }

  void _selectTexture(TextureOption t) {
    setState(() => _texture = t);
    widget.prefs.setString(_kTextureId, t.id);
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
        child: TextureScope(
          option: _texture,
          onSelect: _selectTexture,
          child: MaterialApp(
            title: 'Calculator',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(_skin),
            home: const Scaffold(body: CalculatorScreen()),
          ),
        ),
      ),
    );
  }
}
