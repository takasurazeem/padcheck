# Phase 3: Visual direction

The goal is a direction that comes from *this* product, its person, job and world, rather than from the patterns every model has seen thousands of times. The test: if another agent given a similar prompt would produce substantially the same design, it isn't a direction yet.

For native apps, the direction lives **inside** the platform: the kit's components stay as they are (the reuse rule), and personality comes from accent and tint, icon choice, imagery, illustration, the signature element, motion and haptics, copy, and the custom components the product needs. For web apps and immersive screens (editors, players, games), the direction can go further.

## 1. Surface modes

Name the mode of each main area; the mode sets how much expression is appropriate.

| Mode | The person succeeds when they… | Examples | Ambition shows as |
|---|---|---|---|
| **Operate** | complete a task | dashboards, editors, admin, settings, tools, lists | precision, density, consistency, speed; convention wins |
| **Persuade** | decide and act | onboarding, paywall, landing pages, empty-state invitations | commitment and one memorable moment |
| **Read** | understand something | articles, docs, help, changelogs | comfortable measure and rhythm, clear structure |
| **Experience** | are inside the work | media, games, canvases, photo/video tools | the content leads; chrome recedes |

A product usually mixes modes: a fitness app's workout logger is Operate, its onboarding Persuade, its stats Read.

## 2. Explore the domain first

Produce all four before proposing anything:
- **Domain**: at least 5 concepts, metaphors and words from the product's world (not features). A bread-baking app: proofing, crumb, scoring, flour dust, the bench scraper.
- **Color world**: at least 5 colors that exist naturally in that world. Walk into the physical version of the space: what materials, what light?
- **Signature**: one visual, structural or interaction element that could only belong to this product. If you can't name one, keep exploring.
- **Defaults**: the 3 obvious choices you'd make for any app of this type, visual and structural. You can only avoid defaults you have named.

## 3. Defaults that read as AI-generated

These are legitimate when the brief asks for them, but when an axis is free, choosing one means you weren't deciding.

- Warm cream background (~#F4F1EA) with a high-contrast serif and a terracotta accent; or near-black with one acid-green or vermilion accent.
- Purple-to-blue gradients, gradient text, glowing blobs, glassmorphism used as decoration rather than as a platform material.
- Everything in identical rounded cards with the same soft grey shadow; cards inside cards; one radius on everything regardless of hierarchy.
- The hero-metric block: big number, small label, three supporting stats, a sparkline.
- A tracked-out ALL-CAPS eyebrow label over every heading; "A · B · C" meta strings; "→" appended to every button; section numbers 01/02/03 on content that isn't a sequence.
- Emoji or Unicode glyphs instead of a real icon set; monospace used as a "technical" costume.
- Fade-and-slide-up on every element; hover lift on every card.
- Light or dark chosen by category ("finance = dark") instead of by the use scene (who, where, under what light).

## 4. Propose 2–3 directions, rendered

Each direction is a one-page specimen, not a paragraph:
- Palette as swatches, 4–6 named colors, with names from the domain where it helps.
- The type scale in the real typeface (or the platform system font plus the accent choices).
- One key screen at low-to-mid fidelity, built on the kit for native platforms.
- The signature element, shown.
- The three dials:

| Dial | Low (1–3) | Mid (4–7) | High (8–10) |
|---|---|---|---|
| Variance | conventional, centered, platform-pure | balanced | expressive, asymmetric, custom |
| Motion | still; feedback only | standard transitions and a few moments | choreographed, physics-rich |
| Density | airy (generous spacing, larger type) | standard | dense (tight spacing, compact type, more per screen) |

Make the directions genuinely different (not three shades of the same idea): for example, one platform-pure, one warmer and more editorial, one bolder around the signature.

## 5. Check before showing

For each direction: remove the product name; could someone still tell what it's for? Run the defaults list. If a direction is what you'd produce for any similar prompt, revise it and note what you changed. Check the direction against the brief's situation: a phone app used in bright sunlight needs high contrast; a night-time app may want a dark default.

## 6. Record the decision

`DIRECTION.md` (template in `assets/templates/`) records the chosen direction, the dials, the signature, the defaults avoided, and the **rejected directions with the reason**. That record keeps later sessions from drifting back to a default.

## Notes per kind of app

- **Platform-native utility** (settings-heavy, system-like): low variance. The kit, the system font, one accent and excellent spacing and copy. The signature can be small: a custom glyph, a satisfying haptic, a well-made widget.
- **Consumer app with brand**: mid variance; brand color, illustration and motion on top of native components; a custom display face only for large titles if the platform allows (iOS large titles, Android display styles).
- **Pro tool / dashboard**: density high, variance low-to-mid; hierarchy through weight and color, tabular numbers, keyboard everywhere.
- **Media / creative / immersive**: the content is the screen; chrome is translucent or dark and recedes (see `ipad-duo-design` for the owner's dark-glass language on Apple).
- **Web marketing pages around the app**: Persuade mode; this skill's craft rules apply, but a dedicated landing-page skill (for example taste-skill or impeccable) goes deeper.
