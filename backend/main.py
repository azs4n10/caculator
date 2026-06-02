"""Kawaii Calc — SymPy CAS backend.

A small FastAPI service that gives the Flutter app WolframAlpha-class *symbolic*
math: simplify / expand / factor / differentiate / integrate / solve, plus an
``/api/analyze`` endpoint that returns everything relevant about an expression
at once (the Wolfram-like "just tell me about this" experience).

Run locally:
    pip install -r requirements.txt
    uvicorn main:app --reload --port 8000
"""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sympy as sp
from sympy.parsing.sympy_parser import (
    parse_expr,
    standard_transformations,
    implicit_multiplication_application,
    convert_xor,
)

app = FastAPI(title="Kawaii Calc CAS", version="0.1.0")

# Allow the Flutter web app (any origin during development) to call us.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_TRANSFORMS = standard_transformations + (
    implicit_multiplication_application,
    convert_xor,
)


def _preprocess(s: str) -> str:
    """Map the calculator's kawaii glyphs to SymPy-parseable text."""
    return (
        s.replace("×", "*")
        .replace("÷", "/")
        .replace("−", "-")  # U+2212
        .replace("√", "sqrt")
        .replace("π", "pi")
        .replace("∞", "oo")
        .replace("ln", "log")  # natural log
    )


def _parse(s: str) -> sp.Expr:
    return parse_expr(_preprocess(s), transformations=_TRANSFORMS, evaluate=True)


def _pick_var(expr: sp.Expr, var: str | None) -> sp.Symbol:
    if var:
        return sp.Symbol(var)
    syms = sorted(expr.free_symbols, key=lambda x: x.name)
    return syms[0] if syms else sp.Symbol("x")


def _card(title: str, value: sp.Basic) -> dict[str, Any]:
    return {"title": title, "latex": sp.latex(value), "text": str(value)}


class CasRequest(BaseModel):
    expr: str
    action: str = "analyze"  # simplify|expand|factor|derivative|integral|solve|analyze
    var: str | None = None


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok", "sympy": sp.__version__}


@app.post("/api/cas")
def cas(req: CasRequest) -> dict[str, Any]:
    """Run a single named action and return one result card."""
    try:
        # Equations are handled by solve regardless of the requested action.
        if "=" in req.expr and req.action in ("solve", "analyze"):
            return _solve_equation(req.expr, req.var)

        expr = _parse(req.expr)
        var = _pick_var(expr, req.var)
        result = {
            "simplify": lambda: sp.simplify(expr),
            "expand": lambda: sp.expand(expr),
            "factor": lambda: sp.factor(expr),
            "derivative": lambda: sp.diff(expr, var),
            "integral": lambda: sp.integrate(expr, var),
            "solve": lambda: sp.FiniteSet(*sp.solve(expr, var)),
        }.get(req.action, lambda: sp.simplify(expr))()
        return {
            "ok": True,
            "input_latex": sp.latex(expr),
            "result_latex": sp.latex(result),
            "result_text": str(result),
            "action": req.action,
        }
    except Exception as e:  # noqa: BLE001 — surface any CAS failure to the client
        return {"ok": False, "error": str(e)}


@app.post("/api/analyze")
def analyze(req: CasRequest) -> dict[str, Any]:
    """Return every relevant fact about an expression (Wolfram-like summary)."""
    try:
        if "=" in req.expr:
            return _solve_equation(req.expr, req.var)

        expr = _parse(req.expr)
        cards: list[dict[str, Any]] = []

        if not expr.free_symbols:
            # A constant — give exact and decimal forms.
            simp = sp.nsimplify(expr) if expr.is_number else sp.simplify(expr)
            cards.append(_card("Simplified", sp.simplify(expr)))
            try:
                cards.append(_card("Decimal", sp.N(expr, 12)))
            except Exception:  # noqa: BLE001
                pass
            return {"ok": True, "input_latex": sp.latex(expr), "results": cards}

        var = _pick_var(expr, req.var)

        def add(title: str, fn) -> None:
            try:
                cards.append(_card(title, fn()))
            except Exception:  # noqa: BLE001 — best-effort per card
                pass

        add("Simplified", lambda: sp.simplify(expr))
        add("Expanded", lambda: sp.expand(expr))
        add("Factored", lambda: sp.factor(expr))
        add(f"d/d{var}", lambda: sp.diff(expr, var))
        add(f"∫ d{var}", lambda: sp.integrate(expr, var))
        add(f"Solve = 0 ({var})", lambda: sp.FiniteSet(*sp.solve(expr, var)))

        return {"ok": True, "input_latex": sp.latex(expr), "results": cards}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "error": str(e)}


def _solve_equation(raw: str, var: str | None) -> dict[str, Any]:
    left, right = raw.split("=", 1)
    lhs, rhs = _parse(left), _parse(right)
    eq = sp.Eq(lhs, rhs)
    v = _pick_var(lhs - rhs, var)
    sols = sp.solve(eq, v)
    sol_set = sp.FiniteSet(*sols)
    return {
        "ok": True,
        "input_latex": sp.latex(eq),
        "results": [
            {"title": f"Solution ({v})", "latex": sp.latex(sol_set), "text": str(sol_set)}
        ],
    }
