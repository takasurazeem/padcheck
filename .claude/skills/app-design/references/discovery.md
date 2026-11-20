# Phase 1: Discovery and the product brief

The brief decides everything downstream: which screens exist, what leads on each, how dense the UI is, which platform conventions matter, even whether the palette is light or dark. Most generic designs come from skipping this and designing for "users".

## How to interview

- Use the structured question tool if the session has one; otherwise ask in prose and stop to wait.
- **Two or three questions per round**, chosen because their answers would change the design. One round is normal; a second only when answers expose a real gap. Never send a questionnaire.
- **Lead with your reading.** "I'm assuming this is mainly used one-handed on the go, by people tracking their own habits, not coaches. Right?" Owners correct a wrong guess faster than they answer an open question.
- Don't ask what the code, existing docs or earlier conversation already answer. Don't ask for colors or fonts here; that is phase 3.
- A detailed prompt may need only a confirmation of your summary. A one-line idea needs at least one round.

## What to find out (pick what matters most for this app)

**The person and the moment**
- Who exactly opens this? Role, expertise, age range, how often, and what they were doing just before.
- Where and how: on a phone while walking, at a desk with a keyboard, on a TV across the room, in bright sun, at night, gloved, rushed, bored?
- What is their state of mind: anxious (money, health), focused (work), relaxed (media), curious?

**The job and the outcome**
- What job is the person hiring the app for, in one verb phrase? ("log a workout in under 10 seconds", "find the failing deploy", "approve this invoice")
- What does success look like for them, and what number would show the product works? (time to first value, task completion, retention, errors)
- What would make them stop using it?

**What's unique**
- What's true about this product that a competitor or template couldn't claim? This becomes the signature in phase 3.
- Which apps does the owner admire or want to be measured against, and which ones should this definitely not look like?

**Content and data**
- The real objects: what are they called, what fields do they have, and what are the min / typical / max counts and lengths? (a name of 2 vs 60 characters, 0 vs 10,000 items, amounts with 2 vs 9 digits)
- Media: photos, video, audio, maps, charts? Who provides them?
- Real sample content the design can use. Ask for it; designs built on lorem ipsum break on contact with real data.

**Platforms and form factors**
- Which platforms at launch and later? Phone, tablet, foldable/Duo, desktop window sizes, web breakpoints, watch, TV, car?
- One codebase across platforms (Flutter, React Native, Compose Multiplatform, Electron/Tauri, web) or native per platform? This decides how native each platform must feel (`platforms/cross-platform.md`).
- Minimum OS versions (for example, Liquid Glass needs iOS 26+; plan the fallback).

**Behavior and constraints**
- Accounts and sign-in, offline use and sync, notifications, permissions (camera, location, photos, contacts), payments or subscriptions.
- Localization: which languages, and is right-to-left (Arabic, Urdu, Hebrew) in scope? Number, date and currency formats.
- Accessibility commitments beyond the baseline (WCAG 2.2 AA is the baseline always).
- Brand assets that exist: logo, colors, fonts, voice guide. Existing design system or component library?
- Hard technical limits: frameworks, performance budgets, data sources.

**Scope**
- What is in version 1, and what is explicitly out? Anti-goals ("not a social network", "no gamification").

## Writing PRODUCT.md

Use `assets/templates/PRODUCT.md`. Keep it short enough to reread before every phase: one page is ideal. Write facts and decisions, not the conversation. Mark anything you assumed with **(assumed)** so the owner can correct it later. If the project already has a PRODUCT.md (for example from impeccable), extend it rather than starting over.

Checkpoint: show the filled PRODUCT.md summary and ask for corrections before phase 2.
