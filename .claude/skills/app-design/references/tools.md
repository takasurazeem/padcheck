# Tools: kits, design files, prototypes and verification

Contents: 1 Official kits, libraries and fonts · 2 FigCraft (default design tool) · 3 OpenPencil (alternative) · 4 Figma, Penpot and others · 5 HTML prototypes · 6 Native previews · 7 Rendering and screenshots

## 1. Official kits, libraries and fonts (the reuse rule)

Locate these **before phase 4**. Ask the owner first; they may already have them (for example a downloaded `iOS and iPadOS (Community).fig`). Record the path and version of each kit used in `design/KITS.md` (a few lines). Don't commit 100+ MB kit files to the repo; reference them, or keep them in Git LFS if the owner wants them versioned.

| Platform | Kit | Where |
|---|---|---|
| iOS / iPadOS | Apple iOS and iPadOS UI Kit (current year), includes Liquid Glass materials, system bars, keyboards, controls, Duo examples | Apple Design Resources (developer.apple.com/design/resources), Figma Community "Apple Design Resources" |
| macOS | Apple macOS UI Kit | Apple Design Resources |
| watchOS, visionOS, tvOS | Apple kits per platform | Apple Design Resources |
| Android | Material 3 Design Kit (components, color/type/shape variables, M3 Expressive) | Figma Community, by Material Design (Google) |
| Windows | Windows UI kit / Fluent 2 design kit (WinUI 3 controls, Mica/Acrylic, Segoe UI Variable) | Figma Community, by Microsoft; Fluent 2 site |
| Linux GNOME | Adwaita / libadwaita design resources | GNOME design team (GitLab "Design" group, Penpot/Figma resources) |
| Linux KDE | Breeze / Kirigami resources | KDE design resources |
| Web | the project's library kit: shadcn/ui, MUI, Material Web, Fluent UI React, Ant Design, Chakra, Mantine, Radix, a company Storybook | each library's Figma kit and docs; the library's own code for HTML prototypes |

Rules:
- Insert components as **instances** of the kit's components, keep them linked, and set their properties (variant, label, icon, state). Don't detach and redraw.
- Theme through the kit's own variables/modes (Apple's accent and color scheme, Material's color scheme from a seed, Fluent's accent) mapped to the design tokens.
- Custom components are built from kit primitives (text styles, materials, shapes, icons) and listed as `custom` with a reason in DESIGN.md.
- Keep the kit's metrics: bar heights, insets, corner radii, type styles. If a design needs different metrics, that's a custom component, and it needs a reason.

**Fonts.** Install the kits' fonts before opening them; In FigCraft, `run_command text.fonts` lists what a file uses and what is missing; in OpenPencil, `get_font_status` reports `"faithful": true` when nothing is substituted.
- Apple: SF Pro, SF Compact, SF Mono, New York, SF Arabic from developer.apple.com/fonts (download the .dmg files and run the installers; licensed for designing Apple-platform UI).
- Everything open-licensed in one go:

  ```bash
  brew install --cask font-roboto font-roboto-flex font-roboto-mono font-roboto-serif \
    font-google-sans-flex font-google-sans-code font-material-symbols \
    font-inter font-geist font-geist-mono font-jetbrains-mono \
    font-noto-sans font-noto-sans-arabic font-noto-naskh-arabic font-cantarell
  ```
  (Material 3: Roboto family, Google Sans Flex/Code, Material Symbols; web/shadcn: Inter, Geist; GNOME: Cantarell, Adwaita Sans/Mono ship with OpenPencil; Arabic: Noto Naskh/Sans Arabic. Add the project's own brand and script fonts.)
- Windows: Segoe UI / Segoe UI Variable and Segoe Fluent Icons are licensed with Windows and can't be installed on a Mac. Windows mocks show a substitute; layout metrics still hold. Take final Windows screenshots on Windows.

## 2. FigCraft through MCP (default design tool)

FigCraft (github.com/storytold/figcraft, MIT or Apache-2.0) is a native, pure-Rust design app that opens `.fig` files (best effort), Penpot and Sketch files. **It opens Apple's 160 MB iOS and iPadOS 27 kit unpatched in about 3 seconds** with all 1,777 components, the kit's variable collections (Color Scheme, Colors, Color Contrast, Dynamic Type, Dimensions, Icons) and Liquid Glass. Every menu item and shortcut is one of 400+ commands, and the MCP server drives the **running app**, so the owner watches each layer appear; the agent shows up on the canvas as "Claude (agent)" and outlines what it just changed. Status: alpha, moving fast (several releases a week), so check the release notes when something behaves oddly.

**Setup (once per machine; no server to host):**

```bash
brew install --cask figcraft
# CLI (same version as the app) from the GitHub release, e.g. for 0.18.1:
gh release download v0.18.1 -R storytold/figcraft -p 'figcraft-cli-*-macos-universal.zip'
unzip figcraft-cli-*-macos-universal.zip && mkdir -p ~/.local/bin && cp figcraft-cli-*/figcraft-cli ~/.local/bin/
claude mcp add --scope user figcraft -- "$HOME/.local/bin/figcraft-cli" mcp --attach 47800 --timeout 300
```

The app must be started with its control channel: `open -a FigCraft --args --control 47800` (a one-click launcher: `osacompile` an AppleScript running that command into `~/Applications/FigCraft for Claude.app`). Without `--control`, the MCP tools report that they can't connect. `figcraft-cli mcp` without `--attach` runs a headless session instead (no window; good for CI renders). Linux: the AppImage bundles the CLI (`FigCraft.AppImage cli mcp …`). Update the CLI whenever Homebrew updates the app.

**Tools.** 19 MCP tools, of which the workhorses are: `list_commands` (discover commands; filter e.g. "instance", "variable", "layout"), `run_command` (one command), `batch` (many commands as **one undo step**; name a step `"as": "card"` and refer to its result later with `{"$ref": "card"}`, or `{"$ref": "dup", "field": "ids/0"}`), `get_node` (layer tree with `depth` and `fields`), `export` (PNG/SVG/PDF, returned as data), `screenshot`, `open_file` / `save_file`, `undo` / `redo`.

**Recipe: a screen from the official kit** (verified with the iOS 27 kit):
1. Open the kit `.fig` (or a copy of it) in the app; add a page for the design: `page.add {name}`, `page.select {id}`.
2. Find components: `component.list` (id, name, type, page). Useful iOS 27 sets: `Status Bar - iPhone`, `Toolbar - Top - iPhone` (variant `Style: Large Title`), `Header` (Lists; `Type: Prominent`), `Row` (Lists; `Height: Tall`), `Tab Bar - iPhone` (`Tabs: 2–5`), `Button - Liquid Glass - Text/Symbol`, `Toggle - Switch`, `Sheet - iPhone`, `Progress Bar - …`.
3. Read variant and property names first: `component.properties {ids:[setId]}`. Property names carry ids (`Title#519:116`) and **differ between variants** (the Tall Row uses other ids than Regular). Then `instance.create {component, parent, x, y}` and `instance.setProperties {ids, properties}`.
4. Fill in text and hide parts by overriding the instance's own layers (find them with `get_node {id, depth: 6}`): `node.set {ids:[textId], characters: "Today"}`, `node.set {ids:[layerId], visible: false}`. Kit glyphs are SF Symbols private-use characters (e.g. plus is U+10017C), so a symbol swap is a `characters` change.
5. Colour every custom layer with the kit's variables, not hex: `fill: {"$var": "Backgrounds – Grouped/Primary"}`, `"Labels/Primary"`, `"Labels/Secondary"`, `"Accents/Blue"` (collection **Color Scheme**). Lay out with auto layout keys on `node.create`/`node.set` (`layout`, `gap`, `padding`, `sizingH: "fill"`, `cornerRadius`).
6. Dark and other modes: duplicate the screen (`edit.duplicate {ids, dx}`) and set modes on the copy: `variable.setMode {ids:[copy], collection: "Color Scheme", mode: "Dark"}` (also `Colors`, `Icons`; `Color Contrast: Increased Contrast`; `Dynamic Type: AX5`).
7. Export each frame (`export {ids, format: "png", scale: 2}`) into `design/screens/`, and save the file into `design/` (`save_file`; `.figcraft`, or `.fig` export marked experimental).

Name frames `<Screen> / <state> / <mode> / <device>`, one page per phase, and build in visible steps so the owner can follow. Batches of 50+ commands run in well under a second.

Known issues (v0.18.1, Nov 2026):
- After switching a variant that changes an instance's size (e.g. `Tabs: 3 → 4`), absolutely positioned children with left-right constraints (the tab bar's glass `BG`) may keep their old width. Check the export and set the width by hand.
- The kit's "vibrant" labels use the plus-darker / plus-lighter blend modes; in dark mode some render too faint or vanish (large title, glass button symbols, inactive tab labels). For a title, override `blend: "normal"` with `fill: {"$var": "Labels/Primary"}`; note the rest in REVIEW.md.
- `.fig` import is best effort: `figcraft-cli info file.fig` lists anything not imported. Work on a copy of the kit, not the original.
- Windows fonts (Segoe) can't be installed on a Mac (see Fonts).

## 3. OpenPencil through MCP (alternative)

OpenPencil (github.com/open-pencil/open-pencil, MIT) opens `.fig` files natively, so it can use Apple's and Material's kits directly, and exposes ~130 MCP tools to agents. Tested with the iOS and iPadOS 27 kit and Google's Material 3 kit: pages, component sets, instances, variables with modes (Light/Dark, contrast, Dynamic Type, Liquid Glass Bright) and **Figma Glass effects (refraction, depth, dispersion, light, frost) render faithfully**.

Useful tools: `open_document`, `create_document`, `list_pages` / `switch_page`, `find_nodes` / `query_nodes`, `get_node`, `list_libraries` / `list_components` / `insert_library_component`, `create_instance`, `combine_as_variants`, `expose_instance_swap`, `create_slot`, `render` (design JSX → real layers; supports `defineVars`/`defineMode` for variables with modes and `glass()` for Liquid Glass), `set_layout`, `batch_update`, variables tools (`create_collection`, `create_variable`, `set_variable_mode`, `bind_variable`), `export_image` / `export_svg` / `export_pdf`, `lint` (includes contrast checks), `analyze_colors` / `analyze_typography` / `analyze_spacing`, `export_design_tokens`, comments and statuses ("Ready for dev").

**Setup (once per machine; no server to host).** OpenPencil is a local desktop app; the agent drives the app the owner is looking at, so they can watch every layer appear live and edit alongside (agent edits are separate undo steps and never undo the owner's).

```bash
brew install --cask openpencil          # or download from openpencil.dev
npm install -g @open-pencil/mcp
claude mcp add --scope user open-pencil -- "$(which openpencil-mcp)"
```

Use the absolute path from `which` if Node comes from nvm/fnm, since apps launched outside a shell may not have it on PATH. The stdio server finds the running app by itself; **the app must be open with a document loaded** (File → New is enough). New MCP servers load in the next Claude Code session. Alternative: the app's own chat panel can run Claude Code as its agent (Settings → Models → Run guided setup).

**Follow-along workflow.** Before phase 3, tell the owner to open OpenPencil, then design directly on its canvas: one page per phase (Directions, Design system, one page per platform for screens), frames named `<Screen> / <state> / <mode> / <device>`. Build in visible steps (structure, then components, then content) rather than one giant `render`, so the owner can follow and interrupt. Save the document into `design/` (`.fig`) and export PNGs into `design/screens/` for the docs and handoff.

Known limits (as of v0.16 stable / v0.17 beta, Nov 2026):
- **The official app can't open Apple's iOS and iPadOS 27 kit.** Files with Figma paint-type variables fail to import with "Unsupported document resource VARIABLE: unresolved collection, identity or type" (open-pencil/open-pencil#2261; the iOS 27 kit has five), and files over 64 MiB can't be opened through MCP or URL (open-pencil/open-pencil#2260; the kit is ~160 MB). Check the two issues first: once both are fixed, use the official app. Until then, either build the patched app below, or use native previews (section 6) for final Apple screens and OpenPencil for directions, flows, wireframes and the specimen.
- **Patched build (until the fixes ship).** `assets/openpencil/apple-kit.patch` (against open-pencil `main` at d55675d, v0.17.0-beta.6) skips unsupported variables with a warning instead of aborting, and raises the 64 MiB caps to 512 MiB. Needs Rust, Bun and Xcode command line tools; the build takes 2–3 minutes after dependencies:

  ```bash
  git clone https://github.com/open-pencil/open-pencil && cd open-pencil
  git apply <skill>/assets/openpencil/apple-kit.patch   # if it no longer applies, upstream has changed: re-check the issues
  bun install && bun run build:packages
  echo '{"bundle":{"createUpdaterArtifacts":false,"macOS":{"signingIdentity":"-"}}}' > /tmp/op-local.json
  bun tauri build --bundles app --config /tmp/op-local.json
  brew uninstall --cask openpencil 2>/dev/null
  ditto target/release/bundle/macos/OpenPencil.app /Applications/OpenPencil.app && xattr -cr /Applications/OpenPencil.app
  ditto /Applications/OpenPencil.app ~/OpenPencil-patched.app      # backup
  npm install -g @open-pencil/mcp@<same version as the app>       # e.g. 0.17.0-beta.6; a mismatched MCP won't connect
  ```

  Then quit the app, delete a stale `~/Library/Application Support/OpenPencil/mcp.json` and `mcp.sock` if their `pid` is gone, and reopen. Open the big kit with **File → Open** (the MCP package's own 64 MiB cap isn't patched). Don't accept in-app updates or run `brew install --cask openpencil` while you rely on the patch: both restore the unpatched app (restore with `ditto ~/OpenPencil-patched.app /Applications/OpenPencil.app`). The five Alert button fill variables are dropped; everything else imports, including glass.
- Material 3 and smaller kits open normally.
- `set_effects` handles shadows and blur only; add Liquid Glass through `render` with `glass({...})`, or by instancing kit components that already carry glass.
- In design JSX, `weight="semibold"` silently falls back to Regular; use numeric weights (600) or `bold`.
- Fonts must be installed locally or the kit substitutes them; see **Fonts** below.

Use OpenPencil when FigCraft isn't available or for its JSX `render` workflow. If the session has no OpenPencil tools, check `claude mcp list`; if `open-pencil` is missing, give the owner the setup above. If it's listed but tools fail, the app isn't open or has no document loaded.

## 4. Figma, Penpot and others

- **Figma** (with Figma's MCP server or Dev Mode MCP): the best support for the official kits as libraries. Use it if the owner has it; the same reuse rule applies (library instances, variables for tokens).
- **Penpot** (open source, MPL-2.0): solid components, tokens and flex/grid layout, self-hostable; can't open `.fig` files, so kits must be Penpot versions.
- **Doop** (AGPL, HTML-based frames, strong agent MCP, light/dark token themes): good for web app screens where the design *is* HTML; not suited to native kit fidelity.
- Whatever the tool, the design must end up readable by coding agents: exported PNGs per screen/state/mode in `design/screens/`, plus the tool file.

## 5. HTML prototypes (web apps; wireframes and specimens for any platform)

- Start from `assets/prototype/`: `index.html` (device frames, flow navigation, state switcher, light/dark toggle), `specimen.html` (tokens, type and components overview), and `screen-template.html`.
- Import `design/tokens/build/tokens.css` so screens use the same tokens as the app.
- For web apps, render the **real component library** in the prototype: link the library's CSS and markup conventions, or build the screens as a small Vite app using the library's components (keep it in `design/prototype-app/`, outside the product code). Don't hand-roll lookalikes of library components.
- One HTML file per screen, with states selectable via `data-state` (`?state=empty`), so each state can be screenshotted.
- Native platforms: HTML is only for phase 2–3 wireframes and direction specimens. Final native screens come from kits (sections 1–3) or native previews (section 6).

## 6. Native previews (when no design tool is available, or to judge native feel)

- SwiftUI `#Preview` screens in a small design-only target or package under `design/previews/`, using real system controls with mock data; render with Xcode previews or a simulator build and screenshot (see `ipad-duo-design` for the three-device routine).
- Compose `@Preview` with `device = Devices.PIXEL_7`, `FOLDABLE`, `TABLET`, light/dark and font scale variants; screenshot via Paparazzi/Roborazzi or the IDE.
- WinUI: a design-only page in a sample app; screenshot at the target window sizes.
- Previews are prototypes: they live in `design/`, not the app target, and the handoff maps them to the real implementation.

## 7. Rendering and screenshots

- Web/HTML: the built-in browser pane (resize to exact sizes) or Playwright (`page.setViewportSize`, `page.screenshot`) at 390×844, 768×1024, 1024×768, 1440×900; light and dark via `prefers-color-scheme` emulation; reduced motion via emulation.
- Device sizes for screens: iPhone 393×852 (and Pro Max 440×956), iPad 11-inch 834×1194 and 13-inch 1032×1376, iPhone Duo closed/open postures, Android compact 412×915, medium/foldable 600–839 wide, expanded ≥ 840, Mac window minimum and a 1440×900 window, Windows 1366×768 and 1920×1080.
- Name exports predictably: `design/screens/<screen>-<state>-<mode>-<device>.png` (for example `today-empty-dark-iphone.png`), so the handoff and reviews can reference them.
