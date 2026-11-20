# <App name>: Design system

Source of truth for values: `design/tokens/tokens.json` (build: `design/tokens/build/`). Kits used: `design/KITS.md`.

## Principles
1. <from the direction, e.g. "The checklist is the app: everything else recedes.">
2. <…>
3. <…>

## Color roles
| Token | Light | Dark | Increased contrast | Use |
|---|---|---|---|---|
| `color.surface.default` | | | | screen background |
| `color.text.primary` | | | | body and titles |
| `color.action.primary` | | | | the one primary action, selection |

Platform mapping: Apple → system semantic colors + tint `<accent>`; Android → M3 scheme from seed `<hex>` (+ dynamic color: <yes/no>); Windows → theme resources + accent; Web → `tokens.css` mapped to `<library>` theme variables.

Contrast: `scripts/contrast_check.py` passes in all modes (last run: <date>).

## Typography
| Role | Apple text style | Android M3 | Windows | Web | Notes |
|---|---|---|---|---|---|
| Screen title | Large Title 34 | Headline Large | Title 28 | 32/40 | |
| Body | Body 17 | Body Large 16 | Body 14 | 16/24 | |

Scaling: Dynamic Type to AX5, Android 200%, Windows 225%, web 200% zoom.

## Spacing, layout, shape, elevation
- Base unit <4/8>; scale <…>; margins per form factor <…>; grids <…>
- Radius scale <…> (concentric on Apple); elevation strategy <tonal / shadows / materials>
- Materials: <Liquid Glass on Apple 26+ (fallback …), Mica/Acrylic (fallback …)>

## Motion and haptics
- Durations <…>, easing/springs <…>; what never animates <…>; reduced motion <…>; haptics <…>

## Icons and imagery
- <SF Symbols / Material Symbols / Fluent / web set>, weight <…>; app icon <…>; imagery rules <…>

## Components
| Component | Source (kit/library or custom + reason) | iOS | Android | macOS | Windows | Web | States |
|---|---|---|---|---|---|---|---|
| Tab bar | Apple iOS kit › Tab Bar | `TabView` | — | — | — | — | default, selected, badge |
| Navigation bar | Material 3 kit › Navigation bar | — | `NavigationBar` | — | — | — | |
| Dialog | shadcn/ui › Dialog | — | — | — | — | `<Dialog>` | open, closing |
| Habit row | custom: no kit row shows streak + check-off in one target | `HabitRow` | `HabitRow` | | | | default, done, pressed, focused, disabled, editing |

### <Custom component name>
- **Why custom**: <…>
- **Anatomy**: <parts>
- **Variants / sizes**: <…>
- **States**: default · pressed · focused · selected · disabled · loading · error
- **Content rules**: <min/max text, truncation>
- **Accessibility**: role <…>, label <…>, value <…>, actions <…>, target ≥ <44 pt / 48 dp / 40 epx / 24 px>
- **Behavior and motion**: <…>
- **Files**: `design/screens/components/<name>-*.png`

## Platform adaptations
<What changes per platform (see platforms/cross-platform.md matrix), and anything platform-only.>
