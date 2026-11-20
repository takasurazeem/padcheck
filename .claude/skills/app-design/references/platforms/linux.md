# Linux desktop (GNOME and KDE)

Pick the target desktop with the owner; a native-feeling Linux app follows one toolkit's conventions. Cross-platform shells (Electron, Tauri, Flutter) should still respect the conventions below for window chrome and keyboard.

## GNOME (GTK 4 + libadwaita)
Kit: GNOME's Adwaita design resources (from the GNOME design team).
- **Header bar** instead of a title bar and menu bar: window title or a view switcher in the center, primary actions at the start, a primary ("hamburger") menu at the end with Preferences, Keyboard Shortcuts, About.
- **Adaptive layouts** from phone width (360 px) to desktop: breakpoints with libadwaita's `AdwBreakpoint`, `AdwNavigationSplitView` (sidebar + content collapsing to a stack), `AdwOverlaySplitView`, view switcher in the header bar that moves to a bottom bar when narrow.
- Boxed lists and preference rows for settings (`AdwPreferencesDialog`), toasts for undoable feedback, banners for persistent states, dialogs that adapt to bottom sheets when narrow.
- Adwaita stylesheet colors with accent color support (GNOME 47+), light/dark following the system style, high contrast. Adwaita Sans/Cantarell type; symbolic icons from the icon theme.
- Keyboard: standard shortcuts (Ctrl+Q, Ctrl+W, Ctrl+, preferences, Ctrl+? shortcuts window), full keyboard navigation.

## KDE Plasma (Qt + Kirigami)
Kit: KDE's Breeze/Kirigami design resources.
- Kirigami's **global drawer** and **context drawer**, column-based page navigation (pages slide in columns on wide screens), convergent design from phone to desktop.
- Traditional menu bar and toolbar are acceptable for desktop-centric apps (KDE apps often allow hiding the menu bar with a hamburger fallback).
- Breeze colors and icons, the system accent and color scheme; Noto Sans by default.

## Both
- Respect the system's light/dark preference and accent; scaling factors (fractional scaling); reduced animations setting.
- Flatpak packaging with a proper app icon set and metadata (AppStream screenshots).

## Checklist
- [ ] Target desktop chosen; components from that kit
- [ ] Narrow (360) to wide layouts designed (libadwaita breakpoints / Kirigami columns)
- [ ] Header bar or menu conventions; standard shortcuts; preferences and about
- [ ] Light/dark/high contrast and system accent
