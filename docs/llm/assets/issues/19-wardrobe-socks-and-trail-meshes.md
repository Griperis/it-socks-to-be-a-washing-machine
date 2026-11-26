---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 3", "suggested model: opus"]
terms: [Socks piece, Trail, Wardrobe]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Wardrobe's Socks pieces and the Trails' meshes

The 17 Socks pieces and the meshes of the 17 Trails imported from the old `assets/avatar/wardrobe/*.glb` by the asset
port rules into `assets/wardrobe/`:
- each Socks piece a Looks scene `game/wardrobe/looks/<id>.tscn` with `sock_l` and `sock_r` (they sit on `FootL` and
  `FootR` at identity), its rare touch as a `touch` clip where it has one;
- each Trail's meshes as mesh resources the Trail's particle nodes draw (`docs/architecture/wardrobe.md` "Trails:
  particle scenes authored in the editor", Q2680), named as core/144's stand-ins so the swap is a mesh reference.
The Lost Socks' pieces are imported too (held back, not deleted, Q2683). On the designer's yes the piece files and the
Trail scenes are pointed at them and the graybox socks go.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The pieces" (the Socks pieces) and
"Trails" (each Trail's meshes, Q872).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
Inherited scenes and mesh resources of the imported glbs; the shared materials where the port's rules swap them (Q2177).

## Acceptance
- Look work: a line-up (every Socks piece on the Avatar's feet beside the old shots; every Trail's meshes laid out
  beside the old) in `builds/review-assets-19/`; `ready-for-human`.
- No real-path case (a look ticket, Q2421).

## Answers
- The Trails are remade as particle scenes authored in the editor (Q2680, 2026-11-25).
- Yes to the line-up: the Socks pieces and the Trails' meshes as built (Q2708, 2026-11-26).

## Open follow-ups
- [later] On the designer's yes: point the 17 Socks piece files at `game/wardrobe/looks/<id>.tscn`, and the
  Trail scenes' draw passes at `assets/wardrobe/meshes/<id>_a.res`, `_b` ... (core/144 names its stand-ins
  alike), then delete the graybox socks.
- [later] The old game has no shot of a Trail on its own (its line-up hides the Trail behind the creature):
  the Trail close-ups are compared with the old line-up only; the meshes are the old glbs' unchanged.
