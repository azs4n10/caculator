# Calculator

A scientific calculator with a built-in graph viewer and a symbolic-math
(CAS) panel — so you don't have to reach for MATLAB or WolframAlpha for
everyday math. Built with Flutter (iOS / Android / Web), with a soft pastel
UI, round typewriter-style keycaps, and 10 light/dark themes.

**Live demo:** https://azs4n10.github.io/caculator/

## Features
- **Scientific calculator** — trigonometry, inverse trig (`2nd`), `ln` / `log₁₀`,
  `√`, powers, factorial, `π` / `e`, `RAD` / `DEG`, implicit multiplication.
- **Graph viewer** — plot `y = f(x)`, overlay up to 4 colour-coded functions,
  pinch/drag zoom & pan, and a value table.
- **Solver (CAS)** — simplify, expand, factor, differentiate, integrate, and
  solve equations symbolically (WolframAlpha-class) via a SymPy backend.
- **Themes** — 5 light + 5 dark skins, remembered across launches.
- Round typewriter keycaps, a reactive mascot, live result preview, and history.
- Responsive: a portrait layout with a slide-up function drawer, and a
  landscape layout with the functions beside the number pad.

## Develop
```bash
flutter pub get
flutter test            # engine, responsive, header, graph & orientation tests
flutter run -d chrome   # run on the web
```

The Solver (CAS) talks to a local Python backend — see [`backend/README.md`](backend/README.md):
```bash
cd backend
python -m venv .venv && .venv\Scripts\activate   # (mac/Linux: source .venv/bin/activate)
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

## Deploy (GitHub Pages)
Published from the `gh-pages` branch (GitHub Actions is not used on this account):
GitHub Pages caches assets for 10 min, so two things keep updates from sticking
stale: `--pwa-strategy=none` (no service worker) + appending a `?v=<hash>` query
to the entry scripts (cache-busting).
```bash
flutter build web --release --pwa-strategy=none --base-href "/caculator/"
cd build/web
V=$(git -C ../.. rev-parse --short HEAD)
sed -i "s#flutter_bootstrap.js#flutter_bootstrap.js?v=$V#g" index.html
sed -i "s#main.dart.js#main.dart.js?v=$V#g" flutter_bootstrap.js
touch .nojekyll
rm -rf .git && git init -b gh-pages
git add -A && git commit -m "Deploy web build"
git push -f https://github.com/azs4n10/caculator.git gh-pages
```
(A kill-switch `flutter_service_worker.js` is also deployed so any old service
worker on a visitor's browser self-unregisters.)
First time only: repository Settings → Pages → **Source: Deploy from a branch → `gh-pages` / root**.

## Architecture
- `lib/engine.dart` — parses on-screen notation into `math_expressions`
  (DEG/RAD, implicit multiplication, factorial, `π`/`e`); `compile()` builds a
  fast `f(x)` for plotting.
- `lib/calculator_screen.dart` — calculator UI, keypad, history (portrait &
  landscape layouts).
- `lib/graph/` — graph painter and screen.
- `lib/cas/` — Solver UI and HTTP client for the backend.
- `lib/theme/` — theme model, the 10 skins, and the theme picker.
- `lib/widgets/` — round typewriter keycap and the mascot.
- `backend/` — FastAPI + SymPy service for symbolic math.
