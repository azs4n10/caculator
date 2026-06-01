# Kawaii Calc — SymPy CAS バックエンド

WolframAlpha級の**記号計算**（簡約・展開・因数分解・微分・積分・solve）を提供する
FastAPI + SymPy のサーバ。Flutter アプリの「おりこう計算 ∫」画面から呼ばれます。

## ローカル起動
```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# mac/Linux:
# source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
- ヘルスチェック: http://localhost:8000/api/health
- API ドキュメント（自動生成）: http://localhost:8000/docs

## エンドポイント
| メソッド | パス | 内容 |
|---|---|---|
| GET  | `/api/health` | 稼働確認 |
| POST | `/api/analyze` | 式を投げると関連結果を**まとめて**返す（Wolfram風） |
| POST | `/api/cas` | 単一アクション（`simplify`/`expand`/`factor`/`derivative`/`integral`/`solve`） |

リクエスト例:
```bash
curl -X POST http://localhost:8000/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"expr":"x^2+3x+2"}'
```
`=` を含む式（例 `x^2-5x+6=0`）は自動で solve します。`×÷−√π` などの電卓表記もそのまま受け付けます。

## アプリからの接続先（baseUrl）
`lib/cas/cas_client.dart` の `baseUrl` を環境に合わせて変更：
- Web / デスクトップ / iOSシミュレータ … `http://localhost:8000`
- Android エミュレータ … `http://10.0.2.2:8000`
- 実機 / 本番 … デプロイ先の URL

## 本番デプロイ（GitHub Pages の Web版から使う場合）
GitHub Pages は静的ホスティングなので、このサーバは**別途ホスティング**が必要です（Render / Fly.io / Railway など）。
最小例（Render）:
1. このリポジトリを連携し、`backend/` をルートに指定
2. Build: `pip install -r requirements.txt`
3. Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. 払い出された URL を `baseUrl` に設定

CORS は全オリジン許可済み（開発用）。本番では許可オリジンを絞ってください（`main.py` の `allow_origins`）。

## 注意
- CAS では `log` は**自然対数**として扱います（電卓画面の `log` は常用対数=底10）。底10は `log(x, 10)`。
- 重い式は計算に時間がかかることがあります（クライアント側は12秒でタイムアウト）。
