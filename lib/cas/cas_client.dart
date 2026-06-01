import 'dart:convert';
import 'package:http/http.dart' as http;

/// One result "card" returned by the CAS backend (a labelled LaTeX value).
class CasCard {
  final String title;
  final String latex;
  final String text;
  CasCard(this.title, this.latex, this.text);

  factory CasCard.fromJson(Map<String, dynamic> j) =>
      CasCard(j['title'] as String? ?? '', j['latex'] as String? ?? '', j['text'] as String? ?? '');
}

class CasResponse {
  final bool ok;
  final String? error;
  final String? inputLatex;
  final List<CasCard> results;
  CasResponse({required this.ok, this.error, this.inputLatex, this.results = const []});
}

/// Talks to the SymPy FastAPI backend (see `backend/main.py`).
///
/// Override [baseUrl] per platform:
/// - web / desktop / iOS simulator: http://localhost:8000
/// - Android emulator: http://10.0.2.2:8000
/// - real device / production: your deployed URL
class CasClient {
  final String baseUrl;
  CasClient({this.baseUrl = 'http://localhost:8000'});

  Future<bool> ping() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<CasResponse> analyze(String expr) => _post('/api/analyze', {'expr': expr, 'action': 'analyze'});

  Future<CasResponse> action(String expr, String action) =>
      _post('/api/cas', {'expr': expr, 'action': action});

  Future<CasResponse> _post(String path, Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (j['ok'] != true) {
        return CasResponse(ok: false, error: j['error'] as String? ?? 'CAS エラー');
      }
      // /api/cas returns a single result; /api/analyze returns a list.
      final List<CasCard> cards;
      if (j['results'] is List) {
        cards = (j['results'] as List).map((e) => CasCard.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        cards = [
          CasCard(_actionLabel(body['action'] as String?), j['result_latex'] as String? ?? '',
              j['result_text'] as String? ?? ''),
        ];
      }
      return CasResponse(ok: true, inputLatex: j['input_latex'] as String?, results: cards);
    } catch (e) {
      return CasResponse(ok: false, error: 'サーバにつながらないみたい 🙀\n($e)');
    }
  }

  static String _actionLabel(String? a) => switch (a) {
        'simplify' => 'かんたんに',
        'expand' => '展開',
        'factor' => '因数分解',
        'derivative' => '微分',
        'integral' => '積分',
        'solve' => '解',
        _ => 'けっか',
      };
}
