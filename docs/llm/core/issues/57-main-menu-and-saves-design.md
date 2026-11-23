---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: next
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["Q2540: M4 starts with the main menu and saves, the save format first"]
terms: [Host, Guest, Mess, Part]
---

# M4's first piece: the main menu and saves (design)

M4 starts with the main menu and saves; the save format is chosen first because everything else writes into it
(Q2540). A design ticket: findings and a proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks` (grep; never commit there): the old title, Options (volume, mouse speed, FPS
cap, graphics presets, fullscreen), Licence, loading screen and cursor (catalogue B60); Worlds and Groups (B62); saves
(B63: one World encoding for stream, join and save; autosave; the old file kept when a write fails). Write
`docs/migration/m4-lists/01-main-menu-and-saves.md` in the shape of the m06 lists: every line, every motion and sound
(Q2277), with its old file:line; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/saves.md` (proposal): how a save is made from the scene Parts (the co-op shape: Parts syncs and
saves each thing's state; the join snapshot and the save as one encoding), the file format and its version, autosave,
a failed write, save compatibility (from the first outside play-test, project values), Worlds; and the screens as
scenes on one Theme (Q2163) with the menu flow. The godot-game-dev skill has tested templates for settings, saving, a
pause menu and a scene changer: say which are reused. End with the choices for the designer, 2-3 options each with a
recommendation.

## Open follow-ups
- [blocking] M1-M10 in `docs/architecture/saves.md` "Choices for the designer": the save file's form; the Worlds
  rules (old Solo + 5 co-op with fixed Groups, or simpler); autosave cadence; telling the player a save failed; a
  World of another version before the play-test; when stable ids come; what a load resets; things in the air at a
  save; the menu flow until the Lobby; what the first build holds. Each has 2-3 options and a recommendation.
- [later] Wording placeholders carried from the old game or new: "Could not save the game" (new, M4), "Made by
  another version" (new, M5), "This World belongs to its Group: you are not in it", "Delete <name>? It cannot be
  brought back.", "All 5 co-op Worlds are used: delete one first".
- [later] Kit: the `save/` template moves the old file to `.bak` even when that file does not read, so a broken file
  can replace a good backup (the old game's rule, `saves.gd:259-272`); it also writes on the main thread. The
  proposal amends the game's copy; worth proposing upstream.

## Built log
### 2026-11-23
- Changed: Step 1 and Step 2 written (docs only). Findings: the old title and its pages, Options, Licence, cursor,
  loading screen, menu sounds, ESC menu, Worlds and Groups, the save file, autosave, failed writes and reads, load
  fix-ups, each with its file:line; what was weak (one class knowing every field, a failed write never shown, load
  fix-ups in one place, a hidden static save path, screens built in code). Proposal: a save is `Parts.snapshot()` in
  the kit's save template (amended), a WorldRecord, Worlds, an Autosave node, two Part hooks (`save_state`,
  `loaded`), absent players' Hands dropped through `Parts.left`, a shape fingerprint test for the version, screens as
  scenes on the one Theme with the kit templates named, the menu flow; choices M1-M10.
- Files: docs/migration/m4-lists/01-main-menu-and-saves.md, docs/architecture/saves.md
- Verified: docs only, no suite (agent_finish --no-test).

## Answers
- M1-M10 answered by Q2553-Q2562 (designer, 2026-11-23); `docs/architecture/saves.md` is the agreed design, its
  "Decided" section wins over the text where they differ. The build is core/58.
