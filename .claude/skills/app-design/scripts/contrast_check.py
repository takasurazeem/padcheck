#!/usr/bin/env python3
"""Check WCAG 2.x contrast for token pairs in every mode.

Usage:
  python3 contrast_check.py design/tokens/tokens.json
  python3 contrast_check.py tokens.json --pair color.text.primary color.surface.default 4.5
  python3 contrast_check.py tokens.json --json

Pairs come from root "$extensions"."app-design"."contrast" ({"fg", "bg", "min"}) plus any --pair.
Semi-transparent foregrounds are composited over the background; semi-transparent backgrounds
over white (light modes) or black (dark modes). Exit code 1 if any pair fails in any mode.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tokens_lib as tl  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("tokens")
    ap.add_argument("--pair", nargs=3, action="append", metavar=("FG", "BG", "MIN"), default=[])
    ap.add_argument("--json", action="store_true", help="print machine-readable results")
    args = ap.parse_args()

    tree = tl.load(args.tokens)
    tokens = tl.flatten(tree)
    modes, pairs = tl.settings(tree)
    pairs = list(pairs) + [{"fg": f, "bg": b, "min": float(m)} for f, b, m in args.pair]
    if not pairs:
        print("No contrast pairs. Add them under $extensions.app-design.contrast or pass --pair.")
        return 2

    results, failures = [], 0
    for pair in pairs:
        need = float(pair.get("min", 4.5))
        for mode in modes:
            backdrop = (0, 0, 0, 1) if "dark" in mode else (1, 1, 1, 1)
            try:
                bg = tl.parse_color(tl.resolve(tokens, pair["bg"], mode))
                fg = tl.parse_color(tl.resolve(tokens, pair["fg"], mode))
            except (KeyError, ValueError) as e:
                results.append({"fg": pair["fg"], "bg": pair["bg"], "mode": mode, "error": str(e)})
                failures += 1
                continue
            bg = tl.composite(bg, backdrop) if bg[3] < 1 else bg
            fg = tl.composite(fg, bg) if fg[3] < 1 else fg
            ratio = tl.contrast(fg, bg)
            ok = ratio + 1e-9 >= need
            failures += 0 if ok else 1
            results.append({"fg": pair["fg"], "bg": pair["bg"], "mode": mode, "ratio": round(ratio, 2),
                            "min": need, "pass": ok, "fg_hex": tl.to_hex(fg, False), "bg_hex": tl.to_hex(bg, False)})

    if args.json:
        print(json.dumps({"failures": failures, "results": results}, indent=2))
    else:
        width = max(len(r["fg"]) + len(r["bg"]) for r in results) + 4
        for r in results:
            label = "%s on %s" % (r["fg"], r["bg"])
            if "error" in r:
                print("ERROR  %-*s %-18s %s" % (width, label, r["mode"], r["error"]))
            else:
                print("%s  %-*s %-18s %5.2f:1 (needs %g)  %s on %s" % (
                    "PASS" if r["pass"] else "FAIL", width, label, r["mode"], r["ratio"], r["min"], r["fg_hex"], r["bg_hex"]))
        print("\n%d check(s), %d failure(s) across modes: %s" % (len(results), failures, ", ".join(modes)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
