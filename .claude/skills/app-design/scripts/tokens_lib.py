"""Shared helpers for app-design token scripts (stdlib only, Python 3.9+).

Token file format: W3C DTCG JSON. A token is an object with "$value" (and usually "$type").
"{group.token}" references another token. The default "$value" is the light mode; other modes
live in token["$extensions"]["app-design"]["modes"][mode]. Root-level
"$extensions"["app-design"] may list "modes" and "contrast" pairs.
"""
import json
import re

REF = re.compile(r"^\{([^{}]+)\}$")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def flatten(tree, prefix=(), inherited_type=None, out=None):
    """Return {"a.b.c": token_dict} for every token, with "$type" inherited from groups."""
    if out is None:
        out = {}
    group_type = tree.get("$type", inherited_type) if isinstance(tree, dict) else inherited_type
    for key, value in tree.items():
        if key.startswith("$") or not isinstance(value, dict):
            continue
        path = prefix + (key,)
        if "$value" in value:
            token = dict(value)
            token.setdefault("$type", group_type)
            out[".".join(path)] = token
        else:
            flatten(value, path, group_type, out)
    return out


def settings(tree):
    ext = tree.get("$extensions", {}).get("app-design", {})
    modes = ext.get("modes") or ["light", "dark"]
    if "light" not in modes:
        modes = ["light"] + list(modes)
    return modes, ext.get("contrast", [])


def mode_chain(mode):
    """Fallback order for a mode: exact, then dark (for dark-*), then the default (light)."""
    chain = [mode]
    if mode != "dark" and "dark" in mode:
        chain.append("dark")
    return chain


def raw_value(token, mode):
    modes = token.get("$extensions", {}).get("app-design", {}).get("modes", {})
    if mode != "light":
        for m in mode_chain(mode):
            if m in modes:
                return modes[m]
    return token["$value"]


def resolve(tokens, path, mode, seen=None):
    """Resolve a token's value in a mode, following references (references resolve in the same mode)."""
    seen = seen or set()
    if path in seen:
        raise ValueError("Reference cycle at " + path)
    if path not in tokens:
        raise KeyError("Unknown token " + path)
    value = raw_value(tokens[path], mode)
    return resolve_value(tokens, value, mode, seen | {path})


def resolve_value(tokens, value, mode, seen=frozenset()):
    if isinstance(value, str):
        m = REF.match(value.strip())
        if m:
            return resolve(tokens, m.group(1), mode, set(seen))
    if isinstance(value, list):
        out = []
        for item in value:
            r = resolve_value(tokens, item, mode, seen)
            out.extend(r if isinstance(r, list) else [r])
        return out
    if isinstance(value, dict):
        return {k: resolve_value(tokens, v, mode, seen) for k, v in value.items()}
    return value


def is_primitive(path):
    return ".primitive." in path or path.startswith("primitive.")


# Names that mean "the platform's system UI font" in a CSS font stack.
SYSTEM_FONT_NAMES = {"-apple-system", "BlinkMacSystemFont", "system-ui", "ui-sans-serif",
                     "SF Pro", "SF Pro Text", "SF Pro Display", "San Francisco"}


def has_modes(token):
    return bool(token.get("$extensions", {}).get("app-design", {}).get("modes"))


def depends_on_mode(tokens, path, modes):
    values = set()
    for mode in modes:
        values.add(json.dumps(resolve(tokens, path, mode), sort_keys=True))
    return len(values) > 1


# ---- colors ---------------------------------------------------------------

def parse_color(value):
    """Return (r, g, b, a) floats 0..1 from hex, rgb()/rgba(), or a DTCG color object."""
    if isinstance(value, dict):
        comps = value.get("components") or [0, 0, 0]
        if value.get("hex"):
            return parse_color(value["hex"])
        return (float(comps[0]), float(comps[1]), float(comps[2]), float(value.get("alpha", 1)))
    s = str(value).strip()
    if s.startswith("#"):
        h = s[1:]
        if len(h) in (3, 4):
            h = "".join(c * 2 for c in h)
        if len(h) not in (6, 8):
            raise ValueError("Bad hex color " + s)
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
        return (r, g, b, a)
    m = re.match(r"rgba?\(([^)]+)\)", s)
    if m:
        parts = [p.strip() for p in re.split(r"[,\s/]+", m.group(1)) if p.strip()]
        r, g, b = (float(p.rstrip("%")) / (100 if p.endswith("%") else 255) for p in parts[:3])
        a = float(parts[3].rstrip("%")) / (100 if parts[3].endswith("%") else 1) if len(parts) > 3 else 1.0
        return (r, g, b, a)
    raise ValueError("Unsupported color " + s)


def to_hex(rgba, with_alpha=None):
    r, g, b, a = rgba
    out = "#" + "".join("%02X" % round(max(0, min(1, c)) * 255) for c in (r, g, b))
    if with_alpha or (with_alpha is None and a < 0.999):
        out += "%02X" % round(a * 255)
    return out


def composite(top, bottom):
    """Alpha-composite top over an opaque bottom."""
    r1, g1, b1, a = top
    r2, g2, b2, _ = bottom
    return (r1 * a + r2 * (1 - a), g1 * a + g2 * (1 - a), b1 * a + b2 * (1 - a), 1.0)


def luminance(rgba):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b, _ = rgba
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(fg, bg):
    l1, l2 = luminance(fg), luminance(bg)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


# ---- names and units ------------------------------------------------------

def camel(path, drop_first=False):
    parts = path.split(".")
    if drop_first and len(parts) > 1:
        parts = parts[1:]
    words = []
    for p in parts:
        words.extend(w for w in re.split(r"[^A-Za-z0-9]+", p) if w)
    name = words[0].lower() + "".join(w[:1].upper() + w[1:] for w in words[1:]) if words else "token"
    if name[0].isdigit():
        name = "v" + name
    return name


def pascal(path):
    c = camel(path)
    return c[:1].upper() + c[1:]


def kebab(path):
    return re.sub(r"[^A-Za-z0-9]+", "-", path).strip("-").lower()


def number(value):
    """'8px' / '0.5rem' / 8 -> float in px (rem assumes 16px)."""
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, dict) and "value" in value:
        unit = value.get("unit", "px")
        return float(value["value"]) * (16 if unit == "rem" else 1)
    s = str(value).strip()
    m = re.match(r"^(-?[\d.]+)\s*(px|pt|dp|rem|em|ms|s)?$", s)
    if not m:
        raise ValueError("Not a number: " + s)
    n, unit = float(m.group(1)), m.group(2) or ""
    if unit in ("rem", "em"):
        n *= 16
    if unit == "s":
        n *= 1000
    return n


def fmt(n):
    return ("%d" % n) if float(n).is_integer() else ("%g" % n)
