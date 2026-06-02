/// A selectable UI font. [family] is a Google Fonts family name.
class AppFont {
  final String id;
  final String name;
  final String family;
  const AppFont(this.id, this.name, this.family);
}

const List<AppFont> appFonts = [
  AppFont('rounded', 'Rounded', 'Baloo 2'),
  AppFont('sans', 'Sans-serif', 'Inter'),
  AppFont('serif', 'Serif', 'Noto Serif'),
  AppFont('mono', 'Typewriter', 'JetBrains Mono'),
];

const AppFont defaultFont = AppFont('rounded', 'Rounded', 'Baloo 2');

AppFont fontById(String id) =>
    appFonts.firstWhere((f) => f.id == id, orElse: () => defaultFont);
