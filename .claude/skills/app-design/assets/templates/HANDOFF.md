# <App name>: Build handoff

**This is the contract for building the UI.** Build exactly what `design/` specifies. Where the design is silent, don't improvise: stop and ask, or add the gap to "Design gaps" below.

## Read first
- `design/PRODUCT.md`: who it's for and the job (2 minutes)
- `design/DESIGN.md`: tokens, components, platform mapping
- `design/STRUCTURE.md`: navigation and the state matrix
- Platforms and minimum OS: <…>

## Rules for the builder
1. Use native controls and the component library exactly as `DESIGN.md` maps them. Never hand-draw a control the platform or library provides.
2. Use tokens only (`design/tokens/build/`); no literal colors, sizes, radii or durations in UI code.
3. Don't add screens, states, copy, animations or settings that aren't in the design.
4. Keep `design/` in sync: a deliberate UI change updates the design files in the same change.

## Token pipeline
- Apple: copy `design/tokens/build/Tokens.swift` into <target/path>; tint = `Tokens.Colors.actionPrimary`
- Android: `Tokens.kt` → <module/path>; wire into `MaterialTheme` color scheme
- Web: import `tokens.css`; map to <library> theme in <file>
- Windows: merge `Tokens.xaml` into `App.xaml`
- Regenerate: `python3 <skill>/scripts/build_tokens.py design/tokens/tokens.json --out design/tokens/build`

## Build order
1. Theme and tokens
2. Custom components with all states, in a gallery/preview screen
3. Navigation shell per platform
4. Screens, flow by flow: <list>
5. States, edge cases, accessibility pass
6. Motion and haptics polish

## Screens

### <Screen name>
- **Purpose**: <…>
- **Design files**: `design/screens/<screen>-<state>-<mode>-<device>.png` (all states and form factors listed in `design/screens/INDEX.md`)
- **Components**: <kit/library components + custom ones>; **tokens**: <notable>
- **Layout per form factor / posture**: <…>
- **States and triggers**: empty → <when>; loading → <…>; error → <…>; offline → <…>
- **Interactions**: <taps, gestures, keyboard shortcuts, haptics>
- **Accessibility**: reading order <…>; labels <…>; traits <…>; announcements <…>
- **Copy**: <exact strings or strings-file keys>
- **Acceptance criteria**:
  - [ ] Matches the design screenshots at <sizes> in light and dark
  - [ ] Every state above reachable and matching its design
  - [ ] Largest text size reflows without clipping
  - [ ] Screen reader reads <…> in this order
  - [ ] <behavioral criteria>

## Verification
Screenshot the built app at the design's sizes and modes; compare side by side and list differences. Apple: iPhone, iPad, iPhone Duo routine (`ipad-duo-design`). Android: compact phone, foldable, tablet. Web: 390/768/1024/1440. Desktop: minimum and large window.

## Design gaps
| Gap | Where found | Decision |
|---|---|---|
