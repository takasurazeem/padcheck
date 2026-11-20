# Phase 6: Prototype, critique and review

## The prototype

- Link the screens into the key flows from STRUCTURE.md. For HTML screens, use `assets/prototype/index.html` (device frames, flow navigation, a state switcher, light/dark toggle). In a design tool, wire prototype interactions between frames.
- Every flow is walkable end to end, including the empty, error and offline branches.

## Walk it as the person

For each key flow, play the person from PRODUCT.md in their situation (one-handed on a bus, at a desk under deadline). Note every moment of hesitation: where is the next step? what does this label mean? did that work? Count taps/clicks for the core loop.

## Score with the rubric (0–4 each)

| Criterion | 0 | 4 |
|---|---|---|
| **Job fit** | the screen doesn't serve the job in PRODUCT.md | the job is obvious and fast |
| **Hierarchy** | flat, competing elements | one clear focal point, clear order |
| **Navigation and flow** | dead ends, unclear back, surprise jumps | predictable, minimal steps, recoverable |
| **Consistency** | values and patterns vary per screen | tokens and components everywhere |
| **Reuse rule** | native/library components redrawn | kit and library instances throughout; custom components justified |
| **Platform fit** | fights platform conventions | feels native on each target |
| **States coverage** | only the happy path | every state in the matrix designed |
| **Accessibility** | contrast/targets/text scaling fail | passes AA in every mode, labels and order specified |
| **Copy** | vague, system-speak, inconsistent names | plain, specific, consistent, helpful errors |
| **Craft** | default look, misalignments, uneven spacing | deliberate, polished, the signature lands |

Any 0–1 is a blocker to fix now. Write the scores and the fixes into `REVIEW.md`.

## Heuristics to run (Nielsen, adapted)

Visibility of status · match with the person's words · control and freedom (undo, cancel, back) · consistency and standards (platform) · error prevention · recognition over recall · flexibility (shortcuts for experts) · minimalism · error recovery · help where needed.

## Checklists

**Every screen**
- [ ] Composed from kit/library instances and tokens only; no redrawn native control; no hard-coded values
- [ ] One focal point; squint test passes
- [ ] All states in the matrix designed (empty, loading, error, offline, overflow, permission)
- [ ] Real content including longest and largest cases; a translated string fits
- [ ] Light, dark and increased contrast pass contrast checks
- [ ] Largest text size reflows without clipping
- [ ] Targets meet platform minimums
- [ ] Focus order and screen reader labels specified
- [ ] Copy reviewed: actions named, errors helpful, consistent terms
- [ ] Rendered and looked at, at every form factor in scope

**Per platform** (details in `platforms/*.md`)
- [ ] iOS/iPadOS: safe areas, system bars from the kit, sheets and detents, swipe back, Liquid Glass with Reduce Transparency fallback, iPhone/iPad/Duo postures (`ipad-duo-design`)
- [ ] Android: window size classes, navigation component by size, predictive back, edge-to-edge with insets, dynamic color
- [ ] macOS: complete menu bar, toolbar, keyboard shortcuts, window resizing and minimum size, Settings window
- [ ] Windows: NavigationView, title bar, Mica/Acrylic, contrast themes, keyboard and access keys
- [ ] Linux: libadwaita/Kirigami patterns, adaptive widths, header bar
- [ ] Web: breakpoints, URLs and back button, keyboard, focus, reduced motion, no layout shift

## Fresh eyes

If a subagent tool is available, give a fresh agent only PRODUCT.md, the screenshots and this rubric, and ask for its scores and its three biggest problems. It hasn't absorbed your reasoning, so it sees what the person will see. Weigh its findings; don't adopt them blindly.

## REVIEW.md

Use `assets/templates/REVIEW.md`: scores per flow, what was fixed, what remains open with a recommendation, and exactly which screens, sizes, modes and states were rendered and checked.
