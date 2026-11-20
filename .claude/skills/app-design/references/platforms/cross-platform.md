# One codebase, several platforms

When the app ships from one codebase (Flutter, React Native/Expo, Compose Multiplatform, Kotlin Multiplatform with native UI, .NET MAUI, Electron, Tauri, a responsive web app or PWA), decide **how native each platform should feel** before designing screens, and record it in DESIGN.md.

## Three strategies

| Strategy | What it means | Fits | Cost |
|---|---|---|---|
| **Fully native per platform** | Shared logic, separate UI per platform using each platform's controls | Apple-first or Android-first consumer apps where feel matters | more design and build work |
| **Adaptive** | One design, platform-specific **chrome and conventions**: navigation (tab bar vs navigation bar), back behavior, sheets, switches, date pickers, typography (SF vs Roboto), icons, haptics | most cross-platform apps | moderate |
| **Brand-uniform** | One custom look everywhere, platform conventions only for system-level behavior | games, creative tools, strongly branded media apps | lowest, but feels foreign if overdone |

Default to **adaptive**. Even brand-uniform apps keep platform behavior for back navigation, text input, scrolling physics, keyboard shortcuts, accessibility, and system dialogs.

## How to design it

- Design the **shared core** once: IA, flows, content, tokens (semantic layer), custom product components.
- Design **platform chrome** per platform from that platform's kit (the reuse rule still applies): iOS screens from the Apple kit, Android from Material 3, desktop from the macOS/Windows/GNOME kits, web from the component library.
- Keep a **platform matrix** in DESIGN.md: for each component and pattern, what it becomes on each platform.

| Pattern | iOS | Android | macOS | Windows | Web |
|---|---|---|---|---|---|
| Top-level nav | Tab bar / sidebar | Nav bar / rail / drawer | Sidebar + menu bar | NavigationView | Sidebar / top bar |
| Secondary actions | Context menu, sheet | Menu, bottom sheet | Context menu, menu bar | Context menu, CommandBar | Dropdown menu |
| Toggle | Switch | Switch (M3) | Checkbox or switch | ToggleSwitch | Library switch |
| Date input | Date picker (wheels/calendar) | M3 date picker | Date picker | CalendarDatePicker | Library date picker |
| Confirmation | Alert / action sheet | Dialog | Alert sheet | ContentDialog | Dialog |
| Feedback | Haptic + inline | Snackbar | Inline | InfoBar / toast | Toast |

## Framework notes

- **Flutter**: Material 3 widgets by default; use Cupertino widgets or adaptive constructors (`Switch.adaptive`, platform-aware navigation) for iOS; check the app on both before calling it done.
- **React Native / Expo**: native navigation (`@react-navigation/native-stack`, native tabs), platform-specific components where they differ; respect safe areas and platform fonts.
- **Compose Multiplatform**: Material 3 on Android and desktop; for iOS decide between Compose UI with iOS-adapted components or SwiftUI screens on shared logic.
- **Electron / Tauri desktop**: native menus on macOS (a real menu bar), title bar conventions per OS (traffic lights on macOS, caption buttons on Windows), OS keyboard shortcuts (⌘ vs Ctrl), system light/dark and accent, installer and app icon per platform.
- **Web/PWA used on mobile**: safe-area insets, no hover dependency, native-feeling scroll and inputs, installable icon and splash.

## Review

Check each platform's screens with that platform's checklist (`platforms/*.md`) as well as the shared rubric.
