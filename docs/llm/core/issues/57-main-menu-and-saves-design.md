---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: next
created: 2026-11-23
done:
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
