import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calculator_screen.dart';
import 'theme.dart';
import 'theme/skin.dart';
import 'theme/skins.dart';
import 'theme/skin_scope.dart';

const _kSkinId = 'skin_id';

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
  late CalcSkin _skin =
      skinById(widget.prefs.getString(_kSkinId) ?? defaultSkin.id);

  void _select(CalcSkin s) {
    setState(() => _skin = s);
    widget.prefs.setString(_kSkinId, s.id); // remembered across restarts
  }

  @override
  Widget build(BuildContext context) {
    return SkinScope(
      skin: _skin,
      onSelect: _select,
      child: MaterialApp(
        title: 'Calculator',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(_skin),
        home: const Scaffold(body: CalculatorScreen()),
      ),
    );
  }
}
