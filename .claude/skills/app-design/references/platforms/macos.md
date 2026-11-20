# macOS

Kit: **Apple macOS UI Kit**. Windows, toolbars, sidebars, controls, menus and sheets come from it.

A Mac app is a keyboard-and-pointer app with windows the person controls. A scaled-up iPad layout feels wrong here.

## Windows
- Design the main window at its **minimum size** and at a large size (for example 1440×900); content reflows, sidebars collapse, nothing clips. Remember window position and size.
- Document-based apps: one window per document, tabs, proxy icon, versions/autosave, the standard File menu commands.
- Full screen and Split View; the window toolbar can hide in full screen.
- The **Settings window** opens with ⌘, from the app menu; tabs across the top; changes apply immediately (no OK/Cancel).

## Structure
- **Sidebar** (source list) for top-level navigation and collections, with Liquid Glass (macOS 26+) floating over content; collapsible.
- **Toolbar** with the most used commands, customizable where useful; a search field on the trailing side; title and subtitle.
- Content area plus an optional trailing **inspector**.
- Split views with resizable dividers; tables/outline views with sortable, resizable columns for data.

## Menu bar (required)
- Every command lives in the menu bar, with standard menus (App, File, Edit, View, Window, Help) in standard order and standard item names and shortcuts (⌘N, ⌘O, ⌘S, ⌘Z/⇧⌘Z, ⌘C/⌘V, ⌘F, ⌘W, ⌘Q, ⌘,).
- Context menus mirror the relevant menu items; disabled items stay visible in menus.
- Menu bar extras (status items) only for genuinely global status or quick actions.

## Input
- Every action keyboard-accessible; full keyboard navigation and visible focus rings.
- Pointer: hover states, right-click/two-finger context menus, drag and drop (including from and to Finder and other apps), scroll and pinch gestures on the trackpad, cursor shapes where meaningful.
- Controls are smaller than on iOS (regular control size ~22 pt high, body text 13 pt); hit areas are still generous enough for a pointer.

## Visual
- SF Pro with the macOS text styles (Body 13); system colors and the user's accent color; vibrancy and materials from the kit (sidebar, menus, popovers); Liquid Glass on macOS 26+ with Reduce Transparency fallback.
- SF Symbols in toolbars and sidebars at matching weights.
- Alerts are rare and specific; sheets attach to their window; notifications for background events.

## Checklist
- [ ] Complete menu bar with standard menus and shortcuts
- [ ] Minimum and large window sizes designed; resizing reflows
- [ ] Sidebar, toolbar and inspector from the kit; Settings window with ⌘,
- [ ] Full keyboard access, focus rings, context menus, drag and drop
- [ ] Light/dark, accent color, Increase Contrast, Reduce Transparency
