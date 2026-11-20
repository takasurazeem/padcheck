# Android (Material 3)

Kit: **Material 3 Design Kit** (Figma Community, by Material Design). Components, color roles, type scale and shapes come from it as instances and variables. Material 3 Expressive (2025+) adds springier motion, more shape variety and emphasized components; use it where the direction calls for expression.

## Layout: window size classes
| Width class | Width | Navigation | Layout |
|---|---|---|---|
| Compact | < 600 dp (phones portrait) | Navigation bar (3–5 destinations) | single pane |
| Medium | 600–839 dp (foldables, small tablets) | Navigation rail | single or list-detail |
| Expanded | 840–1199 dp (tablets, foldables open) | Rail or navigation drawer | list-detail, supporting pane |
| Large / extra-large | ≥ 1200 dp | Permanent drawer or rail | multiple panes |

- Use canonical layouts: **list-detail**, **supporting pane**, **feed**. Foldables: avoid placing content across the hinge; support tabletop posture for media.
- **Edge-to-edge** is the default (Android 15+): draw behind system bars and handle insets; status and navigation bars are transparent.
- 4 dp grid; 16 dp margins on compact, 24 dp on medium+. Frames: 412×915 compact phone; test 600 and 840 widths.

## Navigation
- Navigation bar / rail / drawer chosen by width class, same destinations in each.
- Top app bars (center-aligned, small, medium, large) that collapse on scroll.
- System back and **predictive back** gesture: design what the back preview reveals; never trap back.
- Bottom sheets (standard and modal), dialogs, menus, snackbars for brief undoable feedback; FAB (or extended FAB) for the screen's primary creation action.
- Tabs for peer views within a screen; search bar and search view.

## Color, type, shape
- **Color roles** from a seed color (primary, on-primary, primary-container, secondary, tertiary, surface and surface-container levels, outline, error…). Support **dynamic color** (wallpaper-based) where brand allows, with a brand fallback scheme. Light and dark, plus contrast levels (standard, medium, high).
- **Type scale**: Display, Headline, Title, Body, Label at L/M/S (Body Large 16/24, Label Large 14/20). Roboto/Roboto Flex or Google Sans-style brand faces; scales with the user's font size (sp) to 200%.
- **Shape scale**: none 0, extra-small 4, small 8, medium 12, large 16, extra-large 28, full; Expressive adds more shapes for emphasis.
- Elevation is mostly **tonal** (surface container levels) with sparing shadows.

## Controls and input
- Targets 48×48 dp. Buttons: filled, tonal, outlined, elevated, text; icon buttons; segmented buttons; chips (assist, filter, input, suggestion); switches, checkboxes, radios; sliders; text fields (filled, outlined) with supporting and error text; date and time pickers.
- Ripple/state layers for pressed, hovered, focused and dragged states (from the kit).
- Material Symbols (outlined/rounded/sharp; fill, weight, grade, optical size axes); one style app-wide.
- Haptics through the system constants; keyboard and mouse support on large screens and ChromeOS.

## System integration
Widgets (resizable, Material You themed), notifications (channels, actions, conversation style), app shortcuts, themed (monochrome) adaptive icons, Quick Settings tiles, share targets, permissions rationale screens, Credential Manager / passkeys, Play Store screenshots.

## Checklist
- [ ] Every component is a Material 3 kit instance; color roles via the kit's variables
- [ ] Compact, medium and expanded layouts; foldable and tablet checked
- [ ] Edge-to-edge with insets; predictive back designed
- [ ] Light/dark, contrast levels, dynamic color and brand fallback
- [ ] 48 dp targets; font scale 200%; TalkBack labels and order
