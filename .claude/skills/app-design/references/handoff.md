# Phase 7: Handoff to coding agents

`HANDOFF.md` is a contract. A coding agent with no memory of the design sessions should be able to build the app from it and the `design/` folder without inventing anything, and a reviewer should be able to check the result against it.

## Principles

- **Point, don't duplicate.** Reference the token file, DESIGN.md sections and screen files rather than restating values that could drift.
- **Buildable slices.** Order work so each slice compiles and can be reviewed on its own.
- **Acceptance criteria are checkable**: "matches `screens/today-light-iphone.png` at 393×852 within the kit's metrics" and "empty state shows when there are no habits", not "looks good".
- **Silence means ask.** Anything the design doesn't specify is a gap to raise, not a license to improvise.

## Contents (template in `assets/templates/HANDOFF.md`)

1. **Read first**: PRODUCT.md (one line why), DESIGN.md, tokens, the platform list and minimum OS versions.
2. **Stack mapping**: for each design component, the code it maps to (SwiftUI `TabView`, Compose `NavigationBar`, WinUI `NavigationView`, shadcn `Dialog`, or the custom component to create), and where custom components should live in the codebase.
3. **Token pipeline**: how `design/tokens/build/*` gets into the app (asset catalog or `Tokens.swift`, Compose theme, `tokens.css` import, XAML merged dictionary), and the rule that UI code uses tokens only.
4. **Build order**: (1) theme and tokens, (2) base and custom components with all states (render them in a gallery/preview screen), (3) navigation shell per platform, (4) screens flow by flow, (5) states, edge cases and accessibility pass, (6) motion and haptics polish.
5. **Per screen**: name and purpose · design files (per form factor, mode) · components and tokens used · layout notes per form factor/posture · every state with its trigger · interactions, gestures, keyboard shortcuts · accessibility (reading order, labels, traits, announcements) · copy (exact strings, or the strings file) · acceptance criteria.
6. **Rules for the builder**:
   - Use kit/native controls and the component library exactly as the design maps them; never hand-draw a control the platform or library provides.
   - Use tokens; no literal colors, sizes or durations in UI code.
   - Don't add screens, states, copy, animations or settings that aren't in the design. If something is missing, stop and ask, or list it under "Design gaps".
   - Keep `design/` and the app in sync: a deliberate change to the UI updates the design files in the same change.
7. **Verification**: screenshot the built app at the same sizes and modes as the design and compare side by side; list every difference. Apple apps follow the three-device routine (iPhone, iPad, iPhone Duo) in `ipad-duo-design`. Web apps: Playwright or a browser at 390/768/1024/1440. Android: phone, foldable/tablet emulators. Desktop: minimum and large window sizes.
8. **Design gaps and open questions**: copied from REVIEW.md, with owners.

## Make future sessions find it

Add to the project's `CLAUDE.md` / `AGENTS.md`:

```markdown
## UI design
The app's UI is fully specified in `design/`. Before building or changing any screen,
read `design/HANDOFF.md`. Use tokens from `design/tokens/` and the component mapping in
`design/DESIGN.md`; never invent UI the design doesn't specify. Report design gaps instead.
```
