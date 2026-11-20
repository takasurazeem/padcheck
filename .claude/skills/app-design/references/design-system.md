# Phase 4: The design system

Contents: 1 Tokens and the file format · 2 Color · 3 Typography · 4 Spacing and layout · 5 Shape and elevation · 6 Motion · 7 Iconography and imagery · 8 Components · 9 Writing DESIGN.md

Screens composed from a system stay consistent; screens drawn freehand drift. And because the coding agents build from the same tokens and component list, the system is what makes the built app match the design.

## 1. Tokens

### Three tiers

1. **Primitives**: the raw palette (`color.primitive.blue.500`), type families, the spacing scale, radii, durations. Never used directly by screens.
2. **Semantic**: intent, used by screens and code: `color.surface.default`, `color.surface.raised`, `color.text.primary`, `color.text.secondary`, `color.text.tertiary`, `color.text.disabled`, `color.border.subtle`, `color.action.primary`, `color.action.primary.on`, `color.status.danger`, `space.inset.card`, `radius.control`, `motion.duration.fast`.
3. **Component** (only when a component needs independent tuning): `button.primary.background`, `input.background`, `input.border.focus`.

Name tokens so that someone reading only the token file could guess the product. Semantic names may come from the domain (`color.ink`, `color.paper`), as long as their role stays obvious.

### File format (what the scripts read)

`design/tokens/tokens.json` uses the W3C Design Tokens (DTCG) format: groups are nested objects; a token has `$value` and `$type`; `{group.token}` references another token. Modes live in this skill's extension: each token's default `$value` is the **light** mode; other modes override it.

```json
{
  "color": {
    "primitive": {
      "ink":   { "900": { "$type": "color", "$value": "#141518" }, "50": { "$type": "color", "$value": "#F2F2F4" } },
      "blue":  { "500": { "$type": "color", "$value": "#2F6BFF" }, "400": { "$type": "color", "$value": "#5B8CFF" } }
    },
    "text": {
      "primary": { "$type": "color", "$value": "{color.primitive.ink.900}",
        "$extensions": { "app-design": { "modes": { "dark": "{color.primitive.ink.50}", "high-contrast": "#000000" } } } }
    }
  },
  "space":  { "2": { "$type": "dimension", "$value": "8px" } },
  "radius": { "control": { "$type": "dimension", "$value": "10px" } },
  "font":   { "family": { "body": { "$type": "fontFamily", "$value": ["Inter", "system-ui", "sans-serif"] } } },
  "motion": { "duration": { "fast": { "$type": "duration", "$value": "150ms" } },
              "easing": { "out": { "$type": "cubicBezier", "$value": [0.23, 1, 0.32, 1] } } },
  "$extensions": { "app-design": {
    "modes": ["light", "dark", "high-contrast", "dark-high-contrast"],
    "contrast": [
      { "fg": "color.text.primary", "bg": "color.surface.default", "min": 4.5 },
      { "fg": "color.action.primary.on", "bg": "color.action.primary", "min": 4.5 },
      { "fg": "color.border.control", "bg": "color.surface.default", "min": 3 }
    ]
  } }
}
```

Units: write dimensions in `px` in the file. Builders convert: CSS keeps px (or rem), Swift uses points (1 px = 1 pt), Compose uses dp, XAML uses effective pixels. `assets/templates/tokens.json` is a complete starter.

### Scripts

- `python3 scripts/contrast_check.py design/tokens/tokens.json` checks every pair in `contrast` in every mode, and exits non-zero on failure. Add a pair for every text/surface and control/surface combination the screens use.
- `python3 scripts/build_tokens.py design/tokens/tokens.json --out design/tokens/build` writes `tokens.css` (`:root`, `[data-theme="dark"]`, `prefers-color-scheme`, `prefers-contrast`), `Tokens.swift` (SwiftUI, light/dark via a dynamic `UIColor`/`NSColor`), `Tokens.kt` (Compose light/dark color objects and dimensions) and `Tokens.xaml` (WinUI `ThemeDictionaries` for Light/Dark/HighContrast). Re-run after every token change.

When the project uses a component library with its own theme format (shadcn CSS variables, MUI theme, Tailwind config, Material's `ColorScheme`, an asset catalog), map semantic tokens onto it rather than creating a parallel system, and record the mapping in DESIGN.md.

## 2. Color

- **Start from roles, not swatches**: background/surface levels, text levels (four: primary, secondary, tertiary, disabled), borders (subtle, default, strong/control), the one primary action color and its "on" color, focus ring, selection, and status (success, warning, danger, info) each with a background tint and an "on" color.
- **Use the platform's system colors where the kit does.** On Apple, text and backgrounds map to the semantic system colors (`label`, `secondaryLabel`, `systemBackground`, `secondarySystemBackground`, `separator`) and only the accent (tint) is yours; this keeps dark mode, increased contrast and vibrancy correct for free. On Android, generate a Material 3 color scheme from the seed color (and support dynamic color from the wallpaper where appropriate). On Windows, use the theme resources and the system accent. Brand colors layer on top.
- **Restraint**: roughly 60% neutral surfaces, 30% secondary tone, 10% accent. One accent used with intent beats several used for decoration. Color communicates (action, status, identity); gray builds structure.
- **Dark mode is designed, not inverted**: surfaces step up in lightness as they rise (a few percent per level), shadows weaken so borders carry more, saturated colors desaturate slightly, and pure black is reserved for OLED-first media apps.
- **Never rely on color alone** for meaning: pair it with an icon, label or shape.
- **Contrast**: text 4.5:1 (3:1 at ≥ 24 px regular or ≥ 18.66 px bold), UI components and focus indicators 3:1 against what they touch. Secondary text on colored surfaces is tinted from that surface's hue, not plain gray.
- Prefer perceptual color spaces (OKLCH) when building ramps, so equal steps look equal.

## 3. Typography

- **Platform text styles first.** iOS/iPadOS/macOS: SF Pro via the system text styles (Large Title 34, Title 1 28, Title 2 22, Title 3 20, Headline 17 semibold, Body 17, Callout 16, Subheadline 15, Footnote 13, Caption 1 12, Caption 2 11 on iOS; macOS body is 13). Android: the Material 3 type scale (Display/Headline/Title/Body/Label × L/M/S; Body Large 16/24). Windows: Segoe UI Variable ramp (Caption 12, Body 14, Subtitle 20, Title 28, Title Large 40, Display 68). Web: your own scale. A brand typeface can replace or join the system face, but must still scale with Dynamic Type, Android font scale, and browser zoom.
- **Custom scales are ratio-based**: ~1.2 dense, ~1.25 most product UI, ~1.333 expressive, from a 14–17 base. Sizes that differ by 1px are not a hierarchy.
- **Weight and color before size**: one size can hold three tiers (600 primary, 500 secondary, 400 tertiary).
- Body line length 45–75 characters; body line height ~1.4–1.6, tighter for large display text. Tighten tracking slightly as size grows.
- **Tabular numerals** for anything that changes or aligns (prices, timers, tables).
- Plan for **localization**: German and Finnish run 30–40% longer; CJK needs different line height; right-to-left mirrors layout.

## 4. Spacing and layout

- One base unit (4 or 8) and a scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Apple works in points on an 8-pt rhythm with 16–20 pt margins; Material uses a 4/8 dp grid with 16 dp margins on compact; Fluent uses a 4-epx grid.
- Name spacing by role where useful (`space.inset.card`, `space.gap.list`, `space.section`).
- Density is a decision: tight 8–12 inside tools, generous 16–24 around reading content; the same numbers repeat everywhere.
- **Layout grids per form factor**: columns, margins and gutters for phone, tablet, desktop window sizes and web breakpoints (390, 768, 1024, 1440). Respect safe areas, the Duo fold and system bars.
- Group with space before lines: tight within a group, generous between groups, more space above a heading than below it.

## 5. Shape and elevation

- **Radius scale**, by size of element: small (controls), medium (cards), large (sheets, panels), full (capsules). On Apple, nested shapes are **concentric**: inner radius = outer radius − padding. Material 3's shape scale: none 0, extra-small 4, small 8, medium 12, large 16, extra-large 28, full. Windows 11: 4 for controls, 8 for overlays and windows.
- **Elevation**: pick one strategy and commit: tonal surface steps, subtle layered shadows, borders, or platform materials (Liquid Glass on Apple 26+, Mica/Acrylic on Windows 11, Material's tonal elevation). Don't mix strategies.
- **Materials** (glass, blur, translucency) are platform features with meaning (chrome floating over content), not decoration. Always define the solid fallback for Reduce Transparency and older OS versions.

## 6. Motion

- Motion explains change: where something came from and went, what's connected, what responded. If it doesn't explain, cut it.
- Frequency decides: actions done hundreds of times a day get little or no animation; occasional transitions get standard motion; rare moments (first success, milestone) may get a crafted moment.
- Durations: press feedback 100–160 ms, small UI (tooltips, toggles, menus) 150–250 ms, larger transitions (sheets, pages) 250–400 ms. Exits a bit faster than entrances.
- Easing: ease-out for entering and responding (`cubic-bezier(0.23, 1, 0.32, 1)`), ease-in-out for things moving on screen; avoid linear and ease-in for UI. On Apple and modern Android, prefer **springs** (interruptible, velocity-aware): iOS `.smooth`/`.snappy`/`.bouncy`; Material 3 Expressive motion springs.
- Gestures track the finger 1:1 and hand off velocity to the animation; animations are interruptible.
- **Reduced motion**: replace movement with cross-fades, remove parallax and autoplay. Pair important motion with haptics on mobile where the platform does.

## 7. Iconography and imagery

- One icon system: SF Symbols (Apple, with weights matched to text and rendering modes), Material Symbols (Android: outlined/rounded/sharp, fill and weight axes), Fluent System Icons (Windows), and one consistent set on web (Lucide, Phosphor, Material Symbols, or the component library's). One stroke weight and grid. Never emoji as icons.
- Icons that mean something have text labels or accessible names; icon-only buttons need tooltips on desktop.
- App icon: follow each platform's template (Apple's layered icons with Icon Composer for Liquid Glass; Android adaptive and themed icons; Windows tile assets; web favicon set and manifest icons).
- Imagery and illustration rules: subject, style, crop, corner treatment, and what happens when an image is missing.

## 8. Components

Build the inventory from the screens (phase 2) and the kits:
1. **Kit and library components first** (the reuse rule in SKILL.md). List each with its source and the code it maps to.
2. **Product-specific components** (the habit row, the price chart, the editor timeline): designed here, composed from kit primitives and tokens, each with a stated reason for existing.

For every component document:
- Source (kit/library path or `custom` + reason) and platform mapping (SwiftUI view, Compose composable, WinUI control, library component).
- Anatomy (named parts), variants, sizes.
- **States**: default, hover (pointer platforms), pressed, focused (keyboard), selected/checked, disabled, loading, error, read-only, plus drag/drop where relevant.
- Content rules: min/max text, truncation, icons, counts.
- Accessibility: role, accessible name, value, hint, keyboard interaction, focus order, minimum target (44×44 pt Apple, 48×48 dp Android, 40×40 epx Windows, 24×24 CSS px minimum on web with 44 preferred for touch).
- Behavior: what it does, animation, haptics.

## 9. Writing DESIGN.md

Use `assets/templates/DESIGN.md`. It is the document both the owner and the coding agents read, so keep it navigable: principles first (3–5 lines that explain the design's character, from the direction), then tokens (a summary table; the JSON is the source of truth), type, color roles with mode values, spacing, shape, elevation, motion, icons, the component inventory, and per-platform adaptations. Checkpoint with `assets/prototype/specimen.html` rendered against the generated `tokens.css`.
