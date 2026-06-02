# ぷにぷに関数電卓 🐱 (kawaii_calc)

かわいい系の**関数電卓＋グラフ／ビューワ**アプリ。MATLAB や WolframAlpha を開かなくても、
ふだんの数学計算をかわいく速くこなすのが目標です。Flutter 製（iOS / Android / Web）。

## 特徴（開発中）
- 🧮 関数電卓：三角関数・逆三角・log/ln・√・指数・階乗・度数/弧度(DEG/RAD)
- ⌨️ タイプライター風 3D キーパッド（押下アニメ＋触覚フィードバック）
- 🐱 計算状態に反応するねこマスコット
- 📜 計算履歴ビューワ（タップで再利用）
- ライブプレビュー（入力中に `= 結果` を薄く表示）

## ロードマップ
- [x] フェーズ0: 環境構築・プロジェクト雛形・Pages CI
- [x] フェーズ1: 関数電卓コア＋タイプライター鍵盤＋履歴
- [ ] フェーズ2: 構造化数式入力（分数・指数・根号）＋値テーブル
- [ ] フェーズ3: グラフ（y=f(x)・複数重ね描き・ズーム/パン）
- [ ] フェーズ4: 行列・ベクトル・線形代数（数値）
- [ ] フェーズ5: 微積（数値微分/積分＋記号微分）
- [ ] フェーズ6: SymPy バックエンド（本格記号計算）／手書き入力(Mathpix)

## 開発
```bash
flutter pub get
flutter test            # 計算エンジンのユニットテスト
flutter run -d chrome   # Web で起動
```

## Web で確認・配布（GitHub Pages）
公開URL: **https://azs4n10.github.io/caculator/**

GitHub Actions は使いません（このアカウントは Actions が課金ロックのため）。
代わりに **`gh-pages` ブランチにビルド済みファイルを置くブランチ配信**で公開します
（flipclock と同じ方式）。更新したいときは:

```bash
# 1) リポジトリ名に合わせた base-href でビルド
flutter build web --release --base-href "/caculator/"

# 2) build/web の中身を gh-pages ブランチへ force-push
cd build/web
touch .nojekyll
rm -rf .git && git init -b gh-pages
git add -A && git commit -m "Deploy web build"
git push -f https://github.com/azs4n10/caculator.git gh-pages
```

初回のみ: リポジトリ Settings → Pages → **Source: Deploy from a branch → `gh-pages` / root**。
数十秒で公開URLが更新されます。

## アーキテクチャ
- `lib/engine.dart` … 画面表記 → math_expressions への正規化＋評価（DEG/RAD・暗黙の積・階乗・π/e展開）
- `lib/calculator_screen.dart` … 画面・キーパッド・履歴
- `lib/widgets/typewriter_key.dart` … 3D キーキャップ
- `lib/widgets/cat_mascot.dart` … ねこマスコット（CustomPaint）
- `lib/theme.dart` … パステル配色＆フォント
- 計算は当面オフライン数値中心。本格的な記号計算は将来 SymPy バックエンドへ（ハイブリッド方針）。
