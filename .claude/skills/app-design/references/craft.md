# Craft: the quality floor for every screen

Read this before drawing screens. Build to this floor without announcing it; the direction decides everything above it.

## Hierarchy and composition

- **One focal point per screen.** Name the one thing the person came to do; it wins through size, weight, contrast, position or the space around it. When everything competes, nothing leads.
- **Squint test**: blur your eyes at the screenshot. You should still see what's above what and where groups divide, and nothing should jump out by accident.
- **Space before lines**: separate groups with spacing and tonal shifts before reaching for borders and dividers. Tight inside groups, generous between them.
- **Proportions speak**: a 280 px sidebar beside wide content says "navigation serves content"; equal widths say "these are peers". Choose on purpose.
- **Alignment**: one edge per column; optical corrections where geometric alignment looks wrong (icons beside text, play triangles).
- **Don't put everything in cards.** Cards are for distinct, actionable, movable things. A list is often better than a grid of cards; cards inside cards are almost always wrong.

## Detail

- **Concentric radii** for nested rounded shapes (inner = outer − padding).
- **Tabular numbers** for changing or aligned figures.
- **Text wrapping**: balanced headings, no orphans in short paragraphs, no truncated primary content (truncate secondary text with a way to see the rest).
- **Hit targets** meet the platform minimum even when the visible control is smaller; no overlapping targets.
- **States everywhere**: every interactive element has its states designed; every data view has empty, loading and error.
- **Real content** at real lengths; test the longest name, the largest number, the translated string.
- On the web, theme the parts you didn't draw: focus rings, text selection, scrollbars, caret, link underlines, form autofill.

## Native fidelity (reuse rule)

- System chrome (status bar, home indicator, navigation/tab/tool bars, sidebars, keyboards, sheets, alerts, menus, context menus, pickers) is the kit's instance at the kit's size, never redrawn.
- Safe areas, the Dynamic Island, camera cutouts, the Duo fold and gesture areas are respected.
- Use the platform's text styles, symbols, materials and haptics before custom ones.

## Motion

- One authored moment per flow at most, not effects on everything.
- Response to input is immediate (< 100 ms visual feedback); press states on every tappable thing.
- Interruptible, velocity-aware springs for gesture-driven motion; fades for reduced motion.

## Copy

Words are design content.
- Write from the person's side: they manage *notifications*, not *webhook config*.
- Buttons name their action ("Save changes", "Delete 3 photos"), and the same action keeps one name through the flow (button "Publish" → toast "Published").
- Errors say what happened and how to recover, without apologizing or blaming; never "Something went wrong" alone.
- Empty states invite the next action.
- Sentence case (follow the platform: Apple uses title case for some buttons and menu items on macOS; Windows uses sentence case), plain verbs, no filler, no exclamation marks in routine UI.
- Labels are visible on form fields; placeholders are examples, not labels.

## Refuse unless the brief asks for it

Gradient text; decorative glass and blur; a colored bar down one side of a card; hard offset "neobrutalist" shadows; sparkline and progress-ring filler standing in for content; emoji as icons; ALL-CAPS eyebrow labels over headings; modals for tasks that don't need interruption; identical fade-up entrance on every element.

## Look at the result

Render each screen at its real size (device-size screenshots for HTML, exports from the design tool) and check: hierarchy, alignment, spacing rhythm, contrast in every mode, text at large sizes, every state. Batch your checks: fix everything one look reveals before taking the next look.
