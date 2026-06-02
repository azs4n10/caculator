import 'package:flutter/widgets.dart';
import 'key_texture.dart';

/// Provides the current keycap [TextureOption] to the tree.
class TextureScope extends InheritedWidget {
  final TextureOption option;
  final ValueChanged<TextureOption> onSelect;

  const TextureScope({
    super.key,
    required this.option,
    required this.onSelect,
    required super.child,
  });

  static TextureScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TextureScope>();
    return scope ??
        const TextureScope(option: defaultTexture, onSelect: _noop, child: SizedBox.shrink());
  }

  static KeyTexture textureOf(BuildContext context) => of(context).option.texture;

  static void _noop(TextureOption _) {}

  @override
  bool updateShouldNotify(TextureScope old) => old.option.id != option.id;
}
