import 'package:flutter/widgets.dart';
import 'skin.dart';
import 'skins.dart';

/// Provides the current [CalcSkin] to the widget tree and a callback to change
/// it. Widgets read `SkinScope.of(context)` and rebuild when the skin changes.
class SkinScope extends InheritedWidget {
  final CalcSkin skin;
  final ValueChanged<CalcSkin> onSelect;

  const SkinScope({
    super.key,
    required this.skin,
    required this.onSelect,
    required super.child,
  });

  static SkinScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SkinScope>();
    // Fall back to the default skin so widgets (and tests) work without a host.
    return scope ??
        SkinScope(skin: defaultSkin, onSelect: (_) {}, child: const SizedBox.shrink());
  }

  /// Convenience: just the active skin.
  static CalcSkin skinOf(BuildContext context) => of(context).skin;

  @override
  bool updateShouldNotify(SkinScope old) => old.skin.id != skin.id;
}
