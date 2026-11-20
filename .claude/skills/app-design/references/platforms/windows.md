# Windows (Fluent 2, Windows 11)

Kit: **Microsoft Windows UI kit / Fluent 2 design kit** (WinUI 3 controls, materials, Segoe UI Variable, Fluent System Icons). Controls come from it as instances.

## Window and structure
- Custom **title bar** integrated with the app (back button, app title, search or tabs where useful), keeping caption buttons and a draggable region. Snap layouts must work: design for half, third and quarter screen widths, and the minimum window size.
- **NavigationView** for top-level navigation: left pane (expanded, compact icon rail, minimal hamburger) adapting to window width, or top navigation for 5 or fewer destinations.
- **TabView** for documents or browser-like apps; **CommandBar** for page commands; **InfoBar** for persistent status; **TeachingTip** for contextual onboarding.
- Content dialogs for blocking decisions only; flyouts and menus for the rest.

## Materials and visual
- **Mica** for the window background (picks up the desktop wallpaper tint), **Acrylic** for transient surfaces (menus, flyouts), solid fallbacks when transparency is off or on battery saver.
- Corner radius 4 epx for controls, 8 for overlays and windows. 4-epx grid; layered surfaces with subtle strokes rather than heavy shadows.
- **Segoe UI Variable** type ramp: Caption 12, Body 14, Body Strong 14, Subtitle 20, Title 28, Title Large 40, Display 68. Sentence case for labels and buttons.
- The system **accent color** drives interactive elements unless brand requires otherwise; support Light, Dark and **contrast themes** (high contrast uses system colors only; test with Aquatic and Desert themes).
- Fluent System Icons (regular and filled), one style per context.

## Input
- Mouse, keyboard, touch and pen. Touch targets 40×40 epx minimum (larger for primary touch apps); hover and pressed states from the controls.
- Full keyboard support: Tab order, arrow-key navigation in groups, **access keys** (Alt shows key tips), keyboard accelerators listed in menus and tooltips.
- Right-click context menus; drag and drop.
- Text scaling up to 225% must reflow.

## System integration
Start menu tiles and jump lists, toast notifications with actions, widgets board, share, Windows Hello sign-in, app icon assets at all scales, Store listing.

## Checklist
- [ ] Controls are Fluent/WinUI kit instances; Mica/Acrylic with fallbacks
- [ ] Title bar, NavigationView modes at narrow/medium/wide; snap widths; minimum size
- [ ] Light, Dark and contrast themes
- [ ] Keyboard: tab order, access keys, accelerators; 40 epx targets; text scaling 225%
