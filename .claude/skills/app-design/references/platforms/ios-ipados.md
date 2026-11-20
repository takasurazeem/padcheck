# iOS and iPadOS (and iPhone Duo)

If the `ipad-duo-design` skill is installed, it is the house style for these platforms: postures (compact, Duo bar column, regular, Duo book, Duo laptop), dark glass over content for immersive screens, one accent, concentric radii, and the three-device verification routine. Load it and let it win where it's specific. This file covers the platform conventions underneath it.

Kit: **Apple iOS and iPadOS UI Kit** (current year). Every system element comes from it as an instance.

## Layout
- Design for size classes, not device names: compact width (iPhone portrait), regular width (iPad, iPhone landscape on large phones, Duo open). iPad windows resize freely (Stage Manager, multiple windows), so layouts must flex, not snap to fixed widths.
- Respect safe areas, the Dynamic Island, the home indicator and the keyboard. Content may extend edge to edge under bars; controls stay inside safe areas.
- Margins ~16–20 pt on iPhone; readable content width on iPad (don't stretch text lines across 1,000+ pt).
- iPhone frame 393×852 (Pro), 440×956 (Pro Max); iPad 11-inch 834×1194, 13-inch 1032×1376.

## Navigation
- iPhone: a **tab bar** for 3–5 top-level sections (in iOS 26+ it floats as Liquid Glass and can minimize on scroll; a separate search tab is a common pattern); `NavigationStack` with large titles that collapse; swipe from the leading edge to go back.
- iPad: the tab bar can turn into a **sidebar**; use `NavigationSplitView` for list → detail with two or three columns; inspectors on the trailing side for properties; pointer and keyboard support; drag and drop between apps; multiple windows (scenes) when documents are independent.
- Sheets: medium and large detents on iPhone; on iPad, sheets present as centered forms or popovers. Primary actions stay reachable at every detent.
- Menus and context menus (long-press) for secondary actions; swipe actions on list rows for frequent ones; undo via shake or toolbar where appropriate.
- Search: a search field in the navigation bar or a dedicated search tab, with suggestions and recent searches.

## Liquid Glass (iOS/iPadOS 26+)
- System bars, tab bars, toolbars, sheets and many controls adopt Liquid Glass automatically when built with standard components; that's one more reason to use the kit's components and the system controls.
- Glass is for the **navigation and control layer floating over content**, not for content itself. Don't stack glass on glass; group nearby glass elements so they blend and morph together (`GlassEffectContainer`).
- Tinted (prominent) glass only for the primary action.
- Every glass surface needs a solid fallback for Reduce Transparency and for earlier OS versions; test with Increase Contrast.
- App icons use Apple's layered icon format (Icon Composer) with light, dark, tinted and clear variants.

## Type, color, symbols
- SF Pro through the text styles (Large Title 34 → Caption 2 11, Body 17) with **Dynamic Type** up to the accessibility sizes; custom fonts register with `UIFontMetrics` / relative sizing so they scale.
- System semantic colors for text, backgrounds, fills and separators; one app **tint/accent** for interactive elements. Support dark mode and Increase Contrast.
- SF Symbols with weights matched to adjacent text; use hierarchical/palette rendering deliberately; variable symbols for levels.

## Controls and input
- Targets 44×44 pt minimum. Standard controls: buttons (bordered, prominent, glass styles), toggles, steppers, segmented controls, pickers, date pickers, sliders, menus, text fields with the right keyboard type and content type (for autofill and passkeys).
- Gestures are conventions: swipe back, pull to refresh, swipe actions, long-press for context menus, pinch to zoom. Every gesture has a visible alternative.
- Haptics through the system feedback types (selection, success, warning, impact) at meaningful moments, not on every tap.

## System integration (design these too, if in scope)
Widgets (small/medium/large, Lock Screen, StandBy; light/dark/tinted), Live Activities and Dynamic Island, App Intents / Shortcuts / Siri and Spotlight, Control Center controls, notifications (actions, grouping, rich content), share sheet, permissions priming screens, Sign in with Apple, App Store screenshots.

## Checklist
- [ ] Every system bar, sheet, alert, keyboard and control is a kit instance
- [ ] iPhone, iPad and (if in scope) Duo postures designed (`ipad-duo-design`)
- [ ] Safe areas and Dynamic Island respected; large titles behave
- [ ] Dynamic Type at XL and AX sizes; Dark; Increase Contrast; Reduce Transparency fallback; Reduce Motion
- [ ] 44 pt targets; swipe-back never blocked; gestures have alternatives
- [ ] iPad: split view, inspector, pointer hover, keyboard shortcuts (hold ⌘ shows them), resizable window
