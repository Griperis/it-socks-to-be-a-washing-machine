---
type: ticket
status: needs-info
kind: build
area: core
feature: frame
priority: now
created: 2026-11-23
done:
blocked_by: [research: docs/research/steam-cloud-saves.md]
notes: ["M4's first piece; design core/57, Q2553-Q2562; list docs/migration/m4-lists/01-main-menu-and-saves.md"]
terms: [Host, Guest, Mess, Part, Hands]
---

# The main menu and saves (M4)

Build `docs/architecture/saves.md` as decided (its "Decided" section, Q2553-Q2562) and the behaviour list
`docs/migration/m4-lists/01-main-menu-and-saves.md` (fold the answers into its header and lines first; one test per
line, named after it).

## Scope (Q2562)
Title, Options (volume incl. the Voice bus slider of Q2549 if cheap, mouse speed, FPS cap, graphics presets,
fullscreen), Licence, the loading screen (house/09 makes a placeholder one: reuse and restyle it), the cursor, menu
sounds, the ESC menu, and saves. Screens are scenes on the one Theme (Q2163); reuse the godot-game-dev templates
(settings, saving, pause menu, scene changer) as the design names. Not in scope: the Lobby, the World list, the studio
intro, key remapping, the encyclopedia key.

## Must-haves
- The save is the join snapshot written to a file (Parts), per World; Worlds as Q2554; autosave Q2555; the failed write
  Q2556; the version and migration chain with sample saves in the suite (Q2557); the id list test (Q2558); the load
  resets (Q2559); things in the air laid where they would land (Q2560); the menu flow Q2561.
- First fix the port gap core/57 found: alone, Hands keys the player by peer number, not player id.
- The kit save template's follow-up (a broken file may replace a good backup): fix in the game's copy and note it for
  the lead to propose upstream.

## Acceptance
- Real path: launch, the title, Solo, the house loads behind the loading screen, pick and pair a Sock, quit to the
  title, Solo again: the Mess, Hands, Cabinets and Coins are as left (with Q2559's resets).
- A Host's co-op World saves and a Guest joining after a reload sees it.
- A sample save of the first version loads after a migration step is added (a case with a made-up v2).
- A failed write shows the HUD line once and keeps the old file.
- Stills for the designer: the title, Options, the ESC menu and the loading screen (`builds/review-menus/`); the look is a
  first still (the screens' style is reviewed before the merge).
