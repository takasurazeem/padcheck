# Web apps

**Reuse rule for the web**: if the project has a design system or component library (shadcn/ui, Radix, MUI, Material Web, Fluent UI, Chakra, Mantine, Ant Design, a company library or Storybook), screens use its components, variants and theme. Never recreate a component it ships. If the project has none, choose one in phase 4 with the owner: shadcn/ui (owned code, Radix accessibility, Tailwind) for custom-branded apps; MUI or Material Web for Material-styled apps; Fluent UI for Microsoft-ecosystem tools; then follow it.

## Layout and responsiveness
- Design at 390 (phone), 768 (tablet portrait), 1024 (tablet landscape / small laptop), 1440 (desktop), and check 320 and very wide (1920+) for breakage. Mobile layouts are designed, not just stacked.
- An **app shell**: top bar and/or sidebar navigation that collapses to a drawer or bottom bar on small screens; content max-widths for reading; dense data views can go full width.
- No horizontal page scroll; reserve space for images and async content (no layout shift); sticky elements don't cover content or focus.

## Navigation and state
- The **URL is part of the design**: every meaningful view and filter state is addressable, shareable and restorable; the back button behaves; deep links work after sign-in.
- Breadcrumbs for deep hierarchies; a command palette (⌘K / Ctrl+K) for power users of tools.
- Optimistic updates with undo for quick actions; clear saving/saved status for editors; unsaved-changes warnings.

## Interaction
- Every interactive element is a real button, link or input (the library's components handle this); links navigate, buttons act.
- Hover states on pointer devices but nothing that **requires** hover (touch users can't hover).
- Visible focus on every interactive element (styled, not removed); logical tab order; Escape closes overlays and returns focus; dialogs trap focus.
- Forms: visible labels; correct input types and `autocomplete` values; inline validation after the field is left, not on every keystroke; errors next to the field and summarized on submit; don't clear input on error; support paste and password managers.
- Touch targets 24×24 CSS px minimum (WCAG 2.2), 44 preferred on touch layouts.

## Visual and theming
- Tokens as CSS custom properties (`design/tokens/build/tokens.css`) mapped onto the library's theme variables.
- Light and dark via `prefers-color-scheme` plus a manual toggle that persists; `prefers-contrast` and `forced-colors` respected.
- Theme browser surfaces: focus ring, selection, scrollbars, caret, autofill.
- Typography with a real scale, `text-wrap: balance` for headings, `tabular-nums` for data; web fonts with `font-display: swap` and metric-matched fallbacks.
- Motion respects `prefers-reduced-motion`; animate transform and opacity.

## Content and performance (design-relevant)
- Skeletons that match final layout; images with defined aspect ratios and modern formats; a loading budget per screen.
- Localization: text expansion, `dir="rtl"`, locale-aware dates, numbers and currency.
- Empty, error (including 404 and 500 pages), offline and permission states designed.
- PWA (if in scope): manifest icons, install prompt, offline screens.

## Checklist
- [ ] Screens use the project's component library; no lookalike rebuilds
- [ ] 390/768/1024/1440 designed; no horizontal scroll; no layout shift
- [ ] URLs for views and filters; back button and deep links
- [ ] Keyboard, focus visible, forms accessible; 24 px+ targets
- [ ] Light/dark, contrast, forced colors, reduced motion
