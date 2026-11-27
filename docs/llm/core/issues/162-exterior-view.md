---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[160-day-cycle]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 5", "suggested model: sonnet"]
terms: [the house]
suites: [house, day]
---

# The exterior seen through the windows

Looking out of a window the player sees the old outside (Q2694): the front garden, the street with a parked car and two
street lamps, the side lawns and fences, the back garden with the washing line and the apple tree, the houses around,
a ring of distant tree tops; a basement window looks into a light well; the garage's ramp runs down to its shut door.
Nobody walks out. Build `docs/architecture/day-and-exterior.md` "The exterior view", draft 149-I:

- `game/house/exterior/exterior.tscn`, a Looks-only scene (no script, no colliders, cast shadows off), its four sides
  `Exterior_North`, `_East`, `_South`, `_West` as MeshInstance3D (so the camera culls the sides it cannot see):
  graybox first (a lawn plane, the light wells at the port's basement windows 0.9 m out and 0.25 m wider each side,
  fence and house boxes, a street strip, the garage ramp at the port's garage door);
- instanced as `Exterior` in the exterior slot `game/house/systems/exterior.tscn` (core/154, Q2720; not `house.tscn`); a cut of it outside one window of the Day station.

The night glow of its windows and lamps is dropped (Q2709). The front and garage doors stay the shut bodies they are
(Q2514).

Behaviour lines (`day-and-exterior.md` "The exterior view"): all 5.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A Looks scene; assets/22 swaps the ported model in by replacing the graybox meshes under the same names.

## Acceptance
- Real path: the player walks to the living room's south window (movement input) and looks out; the camera's view ray
  through the window hits `Exterior_South`.
- Through a basement window the ray meets the light well; the exterior has no collider and casts no shadow; the front
  door still does not open.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The exterior is a view only; the front and garage doors stay shut (Q2694, 2026-11-26).
- The outside's night glow is dropped (Q2709, 2026-11-26).

## Open follow-ups
