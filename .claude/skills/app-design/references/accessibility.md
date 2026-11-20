# Accessibility, designed in

Baseline for every app: **WCAG 2.2 level AA** plus each platform's accessibility features. These are design decisions made in phases 4–5, not a final audit; a builder cannot add good accessibility to a design that didn't plan it.

## What the design must specify

**Perceivable**
- Contrast: text 4.5:1 (large text 3:1); UI components, icons that carry meaning, and focus indicators 3:1. In **every** mode (light, dark, increased contrast). Checked with `scripts/contrast_check.py`.
- Never color alone: status, errors, selection, chart series and links also differ by icon, text, shape or underline.
- Text scales: iOS Dynamic Type up to the accessibility sizes (AX5), Android font scale to 200%, Windows text scaling to 225%, web zoom to 200% and text-spacing overrides. Layouts reflow (stack horizontally arranged items, let panels scroll); nothing clips or overlaps. Design at least one screen per flow at the largest size.
- Images and icons that carry meaning have text alternatives; decorative ones are marked decorative.
- Captions or transcripts for video and audio content.

**Operable**
- Targets: 44×44 pt (Apple), 48×48 dp (Android), 40×40 epx (Windows), 24×24 CSS px minimum on web (WCAG 2.5.8), 44 preferred for touch. Spacing so targets don't overlap.
- Keyboard: every action reachable on desktop and web without a pointer; logical focus order that matches the visual order; visible focus everywhere; no keyboard traps; Escape closes overlays; shortcuts listed in menus (macOS, Windows) or a help sheet (web). iPad with a hardware keyboard too.
- Gestures have alternatives: anything done by swipe, pinch, long-press or drag is also possible with a button or menu (WCAG 2.5.1, 2.5.7).
- No time limits without a way to extend; no auto-advancing content without pause.
- Motion: respect reduced-motion settings; nothing flashes more than three times a second.

**Understandable**
- Visible labels on inputs; errors identified in text, next to the field, with how to fix them; don't clear what the person typed.
- Consistent navigation and naming across screens.
- Plain language; abbreviations explained.
- Don't ask for the same information twice in a flow (WCAG 3.3.7); support password managers and passkeys (3.3.8: no cognitive tests to sign in).

**Robust: screen readers**
- For every screen: the reading order, each element's accessible name, role/trait, value and hint, which elements group together (a list row reads as one item), headings for navigation, and live announcements for changes (a toast, a completed upload).
- Platform screen readers: VoiceOver (Apple), TalkBack (Android), Narrator (Windows), Orca (Linux), NVDA/JAWS/VoiceOver on the web. Custom components must expose the same semantics native ones do, which is one more reason to use native and library components.

## Platform settings to design for

- Apple: Dynamic Type, Bold Text, Increase Contrast, Reduce Transparency (every glass/material needs a solid fallback), Reduce Motion, Differentiate Without Color, Smart Invert, Button Shapes, VoiceOver rotor, Voice Control labels, Switch Control.
- Android: font and display size, high-contrast text, color correction, remove animations, TalkBack, Switch Access.
- Windows: text scaling, contrast themes (High Contrast must use system colors), animation settings, Narrator.
- Web: `prefers-reduced-motion`, `prefers-contrast`, `prefers-color-scheme`, `forced-colors`, zoom.

## Right-to-left and localization

If Arabic, Urdu, Hebrew or Persian is in scope: mirror the layout (navigation, back chevrons, progress direction, swipe directions), keep media controls and clocks unmirrored, use fonts that support the script with appropriate line height, and design one screen per flow in RTL.

## In the review

Each screen in `REVIEW.md` lists: contrast results per mode, largest text size checked, focus order, screen reader notes, and reduced-motion behavior. For a deep web audit, the owner's `accessibility` skill covers WCAG testing in code.
