import 'package:flutter/widgets.dart';
import 'fonts.dart';

/// Provides the current [AppFont] to the tree and a callback to change it.
class FontScope extends InheritedWidget {
  final AppFont font;
  final ValueChanged<AppFont> onSelect;

  const FontScope({
    super.key,
    required this.font,
    required this.onSelect,
    required super.child,
  });

  static FontScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FontScope>();
    return scope ??
        const FontScope(font: defaultFont, onSelect: _noop, child: SizedBox.shrink());
  }

  static void _noop(AppFont _) {}

  @override
  bool updateShouldNotify(FontScope old) => old.font.id != font.id;
}
