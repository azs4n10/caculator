/// The tactile "material" of the keycaps.
enum KeyTexture { glossy, matte, crystal, jelly }

class TextureOption {
  final KeyTexture texture;
  final String id;
  final String name;
  const TextureOption(this.texture, this.id, this.name);
}

const List<TextureOption> keyTextures = [
  TextureOption(KeyTexture.glossy, 'glossy', 'Glossy'),
  TextureOption(KeyTexture.matte, 'matte', 'Matte'),
  TextureOption(KeyTexture.crystal, 'crystal', 'Crystal'),
  TextureOption(KeyTexture.jelly, 'jelly', 'Jelly'),
];

const TextureOption defaultTexture = TextureOption(KeyTexture.glossy, 'glossy', 'Glossy');

TextureOption textureById(String id) =>
    keyTextures.firstWhere((t) => t.id == id, orElse: () => defaultTexture);
