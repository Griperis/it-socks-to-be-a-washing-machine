---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[170-vacuum-spit-and-pour]]", "[[128-wardrobe-pieces-and-dressed-avatar]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 7", "suggested model: opus"]
terms: [Backpack vacuum, Tank, Spit, Hands, Wardrobe, Teammate]
suites: [vacuum, carry, coop_carry, wardrobe, wardrobe_looks, coop_wardrobe, knockdown, avatar, save, zoo]
---

# The Backpack vacuum

Two Backpack vacuums: carried in the whole Hands, or worn on the back with the nozzle out (E puts it on and takes it
off); worn, it sucks into its own Tank of 16 and spits, with no Filter and no Pour; a knocked-down or leaving wearer
drops it beside them with its load. Build `docs/architecture/devices.md` "The shape" (the Backpack), "`Vacuum`" (its
`wearable` mode, `wear` / `unwear`), draft 150-J:

- `backpack_vacuum.tscn` (`Carriable` title "Backpack vacuum", `handable` on, `hold_slot_backpack.tres`; the same
  `Vacuum` Part in `wearable` mode, `backpack_tuning.tres`: capacity 16, the same reach, cone, rate and spit, no pour);
- `wear` / `unwear` (the Carriable's holder moves to `nozzle_by` and back; "Put it on" / "Take it off");
- the worn views: the wearer's nozzle with its dial gauge, a Teammate's tank on the back with its hose to the nozzle,
  the `worn` / `lying` clips;
- `WardrobePiece.on_back` set on the four backpack pieces (`backpack`, `balloon_backpack`, `bubble_tea_backpack`,
  `fruit_basket_backpack`) and the Dresser hiding them while its player wears a Backpack vacuum;
- two Backpacks in the vacuums station; "Backpack: full".

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V32-V39; the words "Backpack: full", "Put it on", "Take it off".

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`backpack_tuning.tres` in the inspector; Looks graybox, then assets/25; the worn and lying poses are clips (Q2697); the
piece flag in the inspector.

## Acceptance
- Real path: in the vacuums station the player left-clicks a lying Backpack with empty Hands, presses E (it is worn,
  "Take it off [E]"), holds the left button at loose Socks and they fly in to 16 ("Backpack: full"); a right hold
  spits them; E takes it off into the Hands, a right click puts it down.
- Co-op: another player's pick of a carried one is refused; a Teammate sees it on the wearer's back and the wearer's
  Wardrobe backpack hidden; knocked down, the wearer drops it beside them with its load.
- Saved and joined (a Guest's worn one saved lying where they stood with its load).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The vacuums as the old (Q2698, 2026-11-26).

## Open follow-ups
