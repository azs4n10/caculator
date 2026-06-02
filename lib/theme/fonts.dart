/// A selectable UI font. [family] is a Google Fonts family name.
class AppFont {
  final String id;
  final String name;
  final String family;
  const AppFont(this.id, this.name, this.family);
}

// Light, soft typefaces that suit a cute pastel UI (kept to families that
// include a 700 weight so headings never fall back).
const List<AppFont> appFonts = [
  AppFont('quicksand', 'Quicksand', 'Quicksand'),
  AppFont('comfortaa', 'Comfortaa', 'Comfortaa'),
  AppFont('poppins', 'Poppins', 'Poppins'),
  AppFont('nunito', 'Nunito', 'Nunito'),
  AppFont('mono', 'Typewriter', 'JetBrains Mono'),
];

const AppFont defaultFont = AppFont('quicksand', 'Quicksand', 'Quicksand');

AppFont fontById(String id) =>
    appFonts.firstWhere((f) => f.id == id, orElse: () => defaultFont);
