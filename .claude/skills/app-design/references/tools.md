# Tools: kits, design files, prototypes and verification

Contents: 1 Official kits and libraries · 2 OpenPencil through MCP · 3 Figma, Penpot and others · 4 HTML prototypes · 5 Native previews · 6 Rendering and screenshots

## 1. Official kits and libraries (the reuse rule)

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

## 2. OpenPencil through MCP

OpenPencil (github.com/open-pencil/open-pencil, MIT) opens `.fig` files natively, so it can use Apple's and Material's kits directly, and exposes ~115 MCP tools to agents. Tested with the iOS and iPadOS 27 kit and Google's Material 3 kit: pages, component sets, instances, variables with modes (Light/Dark, contrast, Dynamic Type, Liquid Glass Bright) and **Figma Glass effects (refraction, depth, dispersion, light, frost) render faithfully**.

Useful tools: `open_document`, `create_document`, `list_pages` / `switch_page`, `find_nodes` / `query_nodes`, `get_node`, `list_libraries` / `list_components` / `insert_library_component`, `create_instance`, `combine_as_variants`, `expose_instance_swap`, `create_slot`, `render` (design JSX → real layers; supports `defineVars`/`defineMode` for variables with modes and `glass()` for Liquid Glass), `set_layout`, `batch_update`, variables tools (`create_collection`, `create_variable`, `set_variable_mode`, `bind_variable`), `export_image` / `export_svg` / `export_pdf`, `lint` (includes contrast checks), `analyze_colors` / `analyze_typography` / `analyze_spacing`, `export_design_tokens`, comments and statuses ("Ready for dev").

Known limits (as of v0.17 beta, Nov 2026):
- **Files over 64 MiB can't be opened through MCP or URL** (open-pencil/open-pencil#2260). Apple's iOS kit is ~160 MB. Until fixed, open large kits from the desktop app's File → Open (not affected as far as known), or work from a smaller file that contains the components needed.
- **Files with Figma paint-type variables fail to open** (open-pencil/open-pencil#2261); the iOS 27 kit has five (Alert button fills). Until fixed, the kit won't open unmodified.
- `set_effects` handles shadows and blur only; add Liquid Glass through `render` with `glass({...})`, or by instancing kit components that already carry glass.
- In design JSX, `weight="semibold"` silently falls back to Regular; use numeric weights (600) or `bold`.
- Running from source: the dev MCP bridge needs `OPENPENCIL_DEV_TOKEN` and `OPENPENCIL_DEV_ORIGIN` set to the editor's origin; the desktop app needs none of this.
- Fonts: SF Pro must be installed locally (Apple Developer fonts) or it is substituted.

If the session has no OpenPencil tools but the app is installed, the owner can connect it (`openpencil-mcp` stdio server, or the desktop app's agent integration for Claude Code).

## 3. Figma, Penpot and others

- **Figma** (with Figma's MCP server or Dev Mode MCP): the best support for the official kits as libraries. Use it if the owner has it; the same reuse rule applies (library instances, variables for tokens).
- **Penpot** (open source, MPL-2.0): solid components, tokens and flex/grid layout, self-hostable; can't open `.fig` files, so kits must be Penpot versions.
- **Doop** (AGPL, HTML-based frames, strong agent MCP, light/dark token themes): good for web app screens where the design *is* HTML; not suited to native kit fidelity.
- Whatever the tool, the design must end up readable by coding agents: exported PNGs per screen/state/mode in `design/screens/`, plus the tool file.

## 4. HTML prototypes (web apps; wireframes and specimens for any platform)

- Start from `assets/prototype/`: `index.html` (device frames, flow navigation, state switcher, light/dark toggle), `specimen.html` (tokens, type and components overview), and `screen-template.html`.
- Import `design/tokens/build/tokens.css` so screens use the same tokens as the app.
- For web apps, render the **real component library** in the prototype: link the library's CSS and markup conventions, or build the screens as a small Vite app using the library's components (keep it in `design/prototype-app/`, outside the product code). Don't hand-roll lookalikes of library components.
- One HTML file per screen, with states selectable via `data-state` (`?state=empty`), so each state can be screenshotted.
- Native platforms: HTML is only for phase 2–3 wireframes and direction specimens. Final native screens come from kits (sections 1–3) or native previews (section 5).

## 5. Native previews (when no design tool is available, or to judge native feel)

- SwiftUI `#Preview` screens in a small design-only target or package under `design/previews/`, using real system controls with mock data; render with Xcode previews or a simulator build and screenshot (see `ipad-duo-design` for the three-device routine).
- Compose `@Preview` with `device = Devices.PIXEL_7`, `FOLDABLE`, `TABLET`, light/dark and font scale variants; screenshot via Paparazzi/Roborazzi or the IDE.
- WinUI: a design-only page in a sample app; screenshot at the target window sizes.
- Previews are prototypes: they live in `design/`, not the app target, and the handoff maps them to the real implementation.

## 6. Rendering and screenshots

- Web/HTML: the built-in browser pane (resize to exact sizes) or Playwright (`page.setViewportSize`, `page.screenshot`) at 390×844, 768×1024, 1024×768, 1440×900; light and dark via `prefers-color-scheme` emulation; reduced motion via emulation.
- Device sizes for screens: iPhone 393×852 (and Pro Max 440×956), iPad 11-inch 834×1194 and 13-inch 1032×1376, iPhone Duo closed/open postures, Android compact 412×915, medium/foldable 600–839 wide, expanded ≥ 840, Mac window minimum and a 1440×900 window, Windows 1366×768 and 1920×1080.
- Name exports predictably: `design/screens/<screen>-<state>-<mode>-<device>.png` (for example `today-empty-dark-iphone.png`), so the handoff and reviews can reference them.
