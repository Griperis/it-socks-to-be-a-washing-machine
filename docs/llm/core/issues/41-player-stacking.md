---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: next
created: 2026-11-21
done:
blocked_by: []
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M3", "triaged to M3, soon (Q2533, 2026-11-23); to shape with its behaviour list"]
terms: []
---

# Player stacking

Port of the old game's stacking on a teammate's back (catalogue B07, `game/player/rig_stack.gd`; leftovers P27).

## Acceptance
- Step 1 (2026-11-23): the behaviour list `docs/migration/m3-lists/01-player-stacking.md` (the `migration-port` skill, step 1:
  every line, motion, glide, pop and sound with its old file:line; what was weak) and its open choices as
  `[blocking]` Open follow-ups. Then the designer approves the list and the ticket is shaped for its build.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).

## Open follow-ups
- [blocking] The rider's crouch (list 01, line 22). Old: a rider stays crouched on a back even where the ceiling lets them stand. Options: (a) keep (recommended: stacks fit under 2.6-2.7 m ceilings, no new rule); (b) the rider stands where there is room; (c) a deeper crouch (a new avatar shape).
- [blocking] A rider's jump (line 22). Old: none (a crouched player cannot jump), so a rider walks off and cannot climb to a third. Options: (a) keep (recommended); (b) a rider may jump off, or climb onto a third back with the same rule.
- [blocking] The carrier's jump and a knockdown (lines 31-32). Old: the carrier may jump with a rider (they ride along), a knockdown drops the rider. Options: (a) keep (recommended); (b) forbid the carrier's jump while carrying.
- [blocking] Carry pace and stack size (lines 6, 28). Old: pace 0.5 for every carrier, at most 3 players. Options: (a) keep both numbers (recommended; typed Resource placeholders); (b) a slower pace for a taller stack; (c) two players at most.
- [blocking] Climb and ride look and sound (lines 18, 44). Old: only the jump and land sounds; no tuck, push-off, riding pose or cue (spec follow-up 0, never built). Options: (a) keep (recommended; a later look ticket may add); (b) add a tuck and a push-off sound now; (c) add a riding pose for the rider's avatar.
- [blocking] The rider's waddle while carried (line 43). Old: the avatar waddles on other machines. Options: (a) keep (recommended: as old); (b) hold the waddle still while riding.
- [blocking] The disc's edge (line 23). Old: a 0.6 m disc with no rim; riders walk off by accident. Options: (a) keep (recommended); (b) a wider disc for the rider's feet; (c) a soft edge that slows the rider.
- [blocking] Solo high spots, P27 (line 53). Old: none (Q664: alone the Sock is placed reachable). Options: (a) leave to M6 as the catalogue says (recommended); (b) add a jump Upgrade now.
- [blocking] How a stack is decided across machines (co-op section). Old: nothing is decided state; each machine runs its own body and the pose carries the riding id and offset. Options: (a) keep, as a pose property of the avatar's synchronizer (recommended: same feel, no new Command); (b) a Host-decided Stack Part (fixes the climb-onto-a-moving-Teammate lag, costs a trip and a refusal path).

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/01-player-stacking.md` (54 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). The soft push (Q263, lines 45-50) is in the list too. Nine open choices. No game code.
- Files: `docs/migration/m3-lists/01-player-stacking.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.
