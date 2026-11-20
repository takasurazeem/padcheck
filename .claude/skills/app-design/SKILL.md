---
name: app-design
description: Design an app completely before building it, for mobile (iOS, iPadOS, Android), web and desktop (macOS, Windows, Linux) apps that coding agents will then implement. Runs a design-first process from product brief through information architecture, user flows, visual direction, a token-based design system, every screen in every state and form factor, a clickable prototype and critique, to a handoff contract that agents build from. Use this whenever the user wants to design, plan, mock up, wireframe, prototype or redesign an app, screen, flow, onboarding, dashboard, settings, design system or theme, says "design it before we build", "what should this look like", "make a design doc/spec", starts a new app or feature with UI, wants to port an app to another platform or form factor, or asks for a DESIGN.md, tokens, or a UI review, even if they never say the word "design".
---

# App design: design it completely, then build it

The owner builds mobile, web and desktop apps with coding agents and wants every app **designed before any feature code is written**. A coding agent given a vague brief invents a generic UI, and every screen it invents differently. Given a finished design (decided product, structure, tokens, components, every screen in every state, and a handoff contract), it builds the intended app and builds it consistently.

So the deliverable of this skill is not code. It is a `design/` folder in the project that a later coding session can implement without inventing anything. Prototype code (HTML/CSS screens, or design files) is part of the design, not the product.

## The outputs

```
design/
├── PRODUCT.md        # who, problem, jobs, success, platforms, scope, anti-goals   (phase 1)
├── STRUCTURE.md      # IA, navigation model per platform, flows, screen inventory (phase 2)
├── DIRECTION.md      # chosen visual direction + the rejected options and why     (phase 3)
├── KITS.md           # which official UI kits / component libraries are used, and where (phase 4)
├── DESIGN.md         # the design system: principles, tokens, type, color, motion,
│                     # components with all states, platform adaptations          (phase 4)
├── tokens/tokens.json  # single source of truth (W3C DTCG format), with modes      (phase 4)
├── tokens/build/     # generated: tokens.css, Tokens.swift, Tokens.kt, Tokens.xaml
├── screens/          # every screen x state x form factor (HTML prototype and/or
│                     # .fig/.pen design files) + screenshots                     (phase 5)
├── prototype/        # clickable flow: index.html linking the screens            (phase 6)
├── REVIEW.md         # critique scores, issues found and fixed, open questions   (phase 6)
└── HANDOFF.md        # the build contract for coding agents                       (phase 7)
```

Templates for every file live in `assets/templates/`. Copy and fill them; do not reinvent their structure. A project may already have some of these (or impeccable's `PRODUCT.md`/`DESIGN.md`, or a `design-system/` folder): read them first and extend rather than replace.

## The one rule that is not negotiable: reuse real components, never redraw them

The owner's rule: **native and library components are copied from their official source, not drawn from scratch.**

- **Native apps**: build screens from instances of the official UI kits' components: Apple's iOS/iPadOS, macOS (and watchOS/visionOS) UI kits from Apple Design Resources, Google's **Material 3 Design Kit** for Android, Microsoft's **Fluent 2 / Windows UI kit** for Windows, and the GNOME (libadwaita) or KDE (Breeze) kits for Linux. Navigation bars, tab bars, toolbars, sidebars, lists, buttons, toggles, sheets, alerts, menus, keyboards, status bars and Liquid Glass materials come from the kit as instances with their variants and the kit's variables, then get their properties set (labels, icons, state). Only product-specific components that no kit has get designed, and those are built from kit primitives and the system's tokens.
- **Web apps**: if the project has a design system or component library (shadcn/ui, Radix, MUI, Material Web, Fluent UI, Chakra, Mantine, Ant Design, a company library, Storybook), screens use *its* components with its variants and tokens. Never recreate a button, input, dialog, menu, table or date picker that the library already ships. When the project has none, choose one in phase 4 (with the owner), and from then on the same rule applies.
- **Why**: a redrawn native control is always slightly wrong (metrics, materials, states, accessibility), the coding agent then rebuilds the wrong thing, and every redraw drifts. A kit instance maps one-to-one to a real control (`TabView`, `NavigationBar`, `NavigationView`, `<Button variant>`), which makes the handoff exact.
- **How**: locate the kits before phase 4 (ask the owner where their `.fig` kits are, or download from Apple Design Resources, the Material 3 Figma Community kit, Fluent 2 kits). In a design tool, insert kit components as instances (OpenPencil: open the kit and use its library/instance tools; Figma: the kit as a library). For web, render the real library components in the prototype. Details: `references/tools.md` → "Official kits and libraries".
- **Recording it**: `DESIGN.md`'s component inventory names, for each component, its source (`Apple iOS 27 kit › Tab Bar`, `Material 3 kit › Navigation bar`, `shadcn/ui › Dialog`, or `custom`), and every `custom` entry carries a one-line justification. The critique fails any screen that redraws a component its kit or library provides.

## Before starting

1. **Find the project and what exists.** Read `CLAUDE.md`/`AGENTS.md`, README, any existing `design/`, `PRODUCT.md`, `DESIGN.md`, mocks, screenshots, brand assets, and the code if there is any (detect stacks: `*.xcodeproj`/`Package.swift` → SwiftUI, `build.gradle(.kts)` + Compose → Android, `pubspec.yaml` → Flutter, `package.json` with react-native/expo, next/vite/svelte, electron/tauri → web or desktop shell, `.csproj` with WinUI/WPF → Windows). An existing app is evidence: keep what works, and treat the rest as an anti-reference for a redesign.
2. **Pick up house styles.** If a platform the app targets has a house-style skill installed, that skill's decisions win over this skill's defaults for that platform. For Apple platforms the owner has `ipad-duo-design` (posture-based layouts for iPhone, iPad and iPhone Duo; dark glass; one accent; concentric radii; three-device verification). Load it whenever iOS or iPadOS is in scope, and design iPhone, iPad and Duo together from the start.
3. **Decide the scale of the job** and say it in one line: a full app (all 7 phases), a feature inside an existing design system (phases 1–2 light, skip 3–4, then 5–7), a redesign (all phases, phase 3 replaces the world), or a design system only (phases 1, 3, 4). Don't run a full interview for a settings toggle.
4. **Choose the design medium** by platform, following the reuse rule above (details and setup in `references/tools.md`):
   - **Native apps (iOS, iPadOS, Android, macOS, Windows, Linux)**: a design file built from the official UI kits, through a design tool's MCP: OpenPencil (a local desktop app the owner can watch while you design; opens Material's and other `.fig` kits with their components, variants, variables and Liquid Glass, and Apple's iOS 27 kit only with the patched build until upstream fixes land, see `references/tools.md` §2; install the kits' fonts first), Figma's MCP server, or Penpot. Check which MCP tools exist in the session before planning around one. When no design tool is available, use **native previews** (SwiftUI `#Preview`, Compose `@Preview`, WinUI XAML) kept under `design/previews/`: they use the real system controls by construction, so they satisfy the rule too.
   - **Web apps**: **HTML prototype screens built with the project's component library** (or the one chosen in phase 4), rendered in a browser and screenshotted at exact sizes. Use `assets/prototype/` as the shell. If the web app has a Figma/OpenPencil library, a design file is equally fine.
   - Plain hand-drawn HTML is acceptable only for phase 2–3 wireframes and direction specimens, never for final native screens.

## The process

Work through the phases in order. Each phase ends at a **checkpoint**: show the result (render it; a picture beats a paragraph) and get the owner's confirmation or one round of corrections before the next phase. A wrong decision found in phase 2 costs minutes; found in phase 7 it costs the whole design. When no human can answer (an automated run), write assumptions explicitly into the file and continue.

### Phase 1: Product brief → `PRODUCT.md`

Interview before designing; read `references/discovery.md`. Ask two or three questions per round, each one that would change the result, and state your likely reading so the owner can just confirm. Usually one or two rounds. Cover: the specific person and the situation they're in when they open the app, the job they're hiring it for, what success looks like (for them and as a measurable outcome), what makes this product unlike its neighbors, the real content and data with min/typical/max ranges, platforms and form factors, offline/sync/accounts/permissions, localization and right-to-left, accessibility commitments, and what is explicitly out of scope.

### Phase 2: Structure → `STRUCTURE.md`

Read `references/structure.md`. Design what exists and how people move through it before how it looks:
- **Objects and actions**: the nouns the app manages and the verbs on them. This becomes the IA.
- **Screen inventory**: every screen, sheet, dialog, popover, window and notification, with its purpose and entry points.
- **Navigation model per platform**: tab bar or sidebar on iOS/iPadOS, navigation bar/rail/drawer by window size on Android, menu bar + sidebar + toolbar on macOS, NavigationView on Windows, header bar on GNOME, app shell on web. The same IA maps to different chrome per platform.
- **Key flows** as numbered steps with decision points, written as flow diagrams (Mermaid) plus prose: first run, the core loop, create/edit/delete with undo, search, settings, sign-in, error recovery, offline.
- **The state matrix**: for every screen, which of these apply and what each looks like: empty (first use / no results / cleared), loading (first load / refresh / pagination), partial, error (network / permission / validation / server), success, offline, overflow (very long text, huge counts, many items), and permission-denied.

Checkpoint with a rendered flow diagram and the screen list.

### Phase 3: Visual direction → `DIRECTION.md`

Read `references/visual-direction.md`. Generic output comes from defaults; this phase exists to catch them.
1. **Name the surface mode** of each main area. *Operate* (tools, dashboards, editors, settings): precision, density, scanability and convention win. *Persuade* (onboarding, paywall, marketing pages): commitment and one memorable moment. *Read* (content, docs): comprehension and comfort. *Experience* (media, games, canvases): the content leads and chrome recedes.
2. **Explore the domain** before proposing anything: at least 5 concepts and metaphors from the product's world, 5 colors that exist naturally in it, one **signature** element that could only belong to this product, and the 3 **defaults** you would produce for any similar app (so you can avoid them deliberately).
3. **Propose 2–3 distinct directions** as rendered specimens, not prose: palette swatches, the type scale in the real typeface, one key screen at low-to-mid fidelity, the signature element. Set the three dials for each: variance (conventional ↔ expressive), motion (still ↔ choreographed), density (airy ↔ dense).
4. **Self-check each direction against the brief**: remove the product name; could someone still tell what it's for? If a direction is what you'd produce for any similar prompt, revise it and say what changed.
5. Owner picks (or blends). Record the choice, the rejected options and why. The rejected list protects the decision from drift later.

The brief wins: if the owner pins colors, fonts, an era or a reference app, follow it exactly. Platform-native apps earn their personality inside the platform's conventions (accent, icons, type details, motion, copy), not by fighting them.

### Phase 4: Design system → `DESIGN.md` + `tokens/tokens.json`

Read `references/design-system.md`. Build the system before any high-fidelity screen, because screens composed from a system stay consistent and screens drawn freehand don't.
- **Tokens in three tiers**: primitives (raw palette, type families, a 4- or 8-pt spacing scale, radii, durations) → semantic (`color.surface.default`, `color.text.secondary`, `color.action.primary`, `space.inset.card`, `radius.control`) → component (`button.primary.background`). Screens and code only ever use semantic or component tokens. Name semantic tokens after the product's world where it helps (an ink-and-paper app can say `ink` and `paper`).
- **Modes**: light, dark and increased-contrast at minimum; brand or density modes if the product needs them. Every color token has a value in every mode.
- **Run `scripts/contrast_check.py design/tokens/tokens.json`**: every text/background and control/background pair must pass WCAG (4.5:1 text, 3:1 large text and UI parts) in every mode. Fix failures before moving on; never ship a design that only passes in light mode.
- **Run `scripts/build_tokens.py design/tokens/tokens.json --out design/tokens/build`** to generate `tokens.css`, `Tokens.swift`, `Tokens.kt` and `Tokens.xaml`, so prototypes and later the app code read the same values.
- **Type**: a ratio-based scale (≈1.2 dense, ≈1.25 most apps, ≈1.333 expressive), mapped to each platform's text styles so Dynamic Type, Android font scale and browser zoom work. Hierarchy comes from weight and color before size.
- **Components**: an inventory of every component the screens need. Start from the official kits and the component library (the reuse rule): for each component record its **source** (kit or library component, or `custom` with a reason), the native control or library component it maps to on each platform, its variants and sizes, **every state** (default, hover, pressed, focused, selected, disabled, loading, error), accessible name and role, and keyboard behavior. Theme kit components through the kit's own variables (accent, tint, color scheme) mapped to your tokens; don't detach or repaint them.
- **Motion**: durations, easing curves and springs, what animates and what never does, reduced-motion behavior.
- **Iconography and imagery**: one icon library with one stroke weight (SF Symbols on Apple, Material Symbols on Android, Fluent icons on Windows, a chosen set on web), plus illustration and photo rules.

Checkpoint with a rendered specimen page: `assets/prototype/specimen.html` shows tokens, type, color in every mode, and components in every state.

### Phase 5: Screens → `design/screens/`

Read `references/craft.md` before drawing any screen, then the platform file for each target (`references/platforms/ios-ipados.md`, `android.md`, `macos.md`, `windows.md`, `linux.md`, `web.md`; read `cross-platform.md` when one codebase targets several).
- Compose screens **only from kit instances, library components and the design system**. Native chrome (status bar, navigation/tab/tool bars, sidebars, sheets, keyboards, alerts, menus) is always the kit's instance at the kit's metrics. A new need becomes a new token or component, added to `DESIGN.md`, never a one-off value or a redrawn control in a screen.
- Use **real content** at realistic lengths and counts from PRODUCT.md's ranges, not lorem ipsum, and include the longest realistic name, the biggest number, and a translated string about 40% longer than English.
- Design **every state** from the state matrix and **every form factor** in scope: phone portrait (393×852 pt), phone landscape, tablet (iPad 11-inch 834×1194), foldables and Duo postures, desktop window at its minimum size and a large size, web at 390 / 768 / 1024 / 1440. Light and dark. Larger text sizes.
- **One focal point per screen**: the thing the person came to do wins through size, weight, contrast or space.
- Write the copy now: it is design content. Buttons name their action ("Save changes"), the same action keeps its name through the flow, and errors say what happened and how to fix it.
- **Look at every screen rendered** at its real size: screenshot the HTML at the device size, or export it from the design tool. Fix what one look reveals before taking the next. Never declare a screen done from its source alone.

### Phase 6: Prototype and critique → `prototype/` + `REVIEW.md`

Read `references/critique.md`.
- Link the screens into a clickable prototype of the key flows (`assets/prototype/index.html` shows a device frame, flow navigation, a state switcher and a light/dark toggle).
- Walk each key flow as the person from PRODUCT.md, start to finish, including the error and empty paths.
- Score the design with the rubric (heuristics, hierarchy, consistency, platform fit, accessibility, copy, states coverage, craft) and run the checklists. Fix what you can, record what's left as open questions, and write it all to `REVIEW.md`.
- If a subagent tool is available, have a fresh agent that hasn't seen your reasoning critique the screenshots against PRODUCT.md. It catches what you can no longer see.

### Phase 7: Handoff → `HANDOFF.md`

Read `references/handoff.md`. This is the contract the coding agents implement. It contains:
- **What to build, in order**: tokens and theme first, then base components, then screens grouped by flow, each a buildable slice.
- **Per screen**: the file(s) that define it, the components and tokens it uses, every state and how it is triggered, behavior and gestures, accessibility (labels, order, traits), and **acceptance criteria** a reviewer can check against screenshots.
- **The mapping** from design components to code components or native controls for the target stack.
- **Rules for the builder**: use tokens and components only; don't invent screens, states, copy or values; when the design is silent, stop and ask (or record the gap) rather than improvise.
- **Verification**: how to compare the built app with the design (screenshots at the same sizes; for Apple apps, the three-device routine from `ipad-duo-design`).

Finally, add a short pointer to `CLAUDE.md`/`AGENTS.md` (create the section if needed): "UI is specified in `design/`. Read `design/HANDOFF.md` before building any screen; tokens come from `design/tokens/`." This is what makes later coding sessions follow the design.

## Working habits

- **Render, don't describe.** Directions, components and screens are shown as images or live HTML. If an inline visual tool exists (such as `show_widget`), use it for quick specimens; the source of truth still goes into `design/`.
- **Decide, then explain why.** Every token, layout and component choice should trace to PRODUCT.md (the person, the job, the situation) or to a platform convention. "Clean and modern" is not a reason.
- **Spend boldness in one place.** One memorable element (the signature); keep everything around it quiet and disciplined.
- **Use the platform.** Native navigation, controls, text styles, materials, gestures and keyboard conventions are features users already know. Diverge only with a stated reason.
- **Accessibility is part of the design, not a later audit.** Contrast, target sizes, text scaling, focus order, screen reader labels and reduced motion are decided in phases 4–5. See `references/accessibility.md`.
- **Keep the design files current.** When the owner changes their mind, update the source files (tokens, DESIGN.md, the screen) and regenerate, so `design/` never drifts from what was agreed.
- **Say what you verified.** State which screens, sizes, modes and states you actually rendered and looked at, and what you didn't.

## Reference map

| Read | When |
|---|---|
| `references/discovery.md` | Phase 1: interview questions, PRODUCT.md guidance |
| `references/structure.md` | Phase 2: IA, navigation per platform, flows, state matrix |
| `references/visual-direction.md` | Phase 3: modes, domain exploration, AI-default tells, dials |
| `references/design-system.md` | Phase 4: tokens and modes, color, type, spacing, elevation, motion, components |
| `references/craft.md` | Before drawing any screen: the quality floor, polish, motion, copy |
| `references/platforms/*.md` | Phase 5, per target platform |
| `references/accessibility.md` | Phases 4–6 |
| `references/critique.md` | Phase 6: rubric and checklists |
| `references/handoff.md` | Phase 7 |
| `references/tools.md` | Choosing and driving the medium: HTML prototypes, OpenPencil, Figma, Penpot, screenshots |
| `SOURCES.md` | Where these practices come from |
