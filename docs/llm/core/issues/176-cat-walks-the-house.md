---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[154-batch-c-groundwork]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 4", "suggested model: opus"]
terms: [Cat, Door, Stage, Session]
suites: [cat, save, stages, floor_lock, room_doors, furniture, zoo]
---

# The Cat walks the house: the entity, its map, roaming, resting and the watchdog

The house's black Cat as one entity and one Part: it sits on the living room's couch until the ground floor opens
(Q2703), then roams the open floors on Godot's navigation, never through a shut or locked Door, rests, sits, naps at
nap spots, meows now and then and turns its head toward a player; a watchdog puts it back where it can walk. Build
`docs/architecture/cat.md` "The shape", "`Cat`'s state", "Navigation and the gait", "Places", "Couch, roaming and
resting", "The watchdog", "How it is authored", draft 151-A:

- `cat.tscn` (root, the `Cat` Part with every State field of the doc, so `tests/saves/shape.json` changes once here;
  `Aim`, `Gait` (a pure function of the path and the time since its answer), `Nav`, graybox Looks with its contract and
  every clip (`scratch` a placeholder copy of `swat`), `Hearts`, `Mouth`, `Carry`, `CatLooks` with the coat);
- `CatTuning` and its `.tres` (every field of the doc), `CatCoat` and the five coats `01_black` .. `05_calico` with the
  old colours;
- the verbs `rest_over`, `walk`, `meow`, `put` and the Host's timers; the group contracts `cat_nap` and `cat_places`
  (the calls, no member yet);
- one `NavigationRegion3D` per floor baked on the Host at load from the static colliders (agent radius 0.12, height
  0.3, climb 0.05, cell 0.05), Heaps over 0.12 m and open leaves as projected obstructions, re-baked off the main
  thread when they changed (under 2 ms of main thread); the Door scenes' `NavigationLink3D` (enabled while open) and
  doorway obstacle; a Door shut across a walk makes the Host plan again;
- `CatStart` and the low-window nap markers in the Cat slot `game/house/systems/cat.tscn` (core/154, Q2720), the nap markers in `sofa.tscn`, `double_bed.tscn`,
  `bunk_bed.tscn`, `old_cot.tscn`, the Cat placed in the Cat slot (not `house.tscn`);
- the Cat station filled (shell from core/154 at x = 278): two graybox rooms joined by a real Door and a short stair to
  a landing, a sofa, a bed, a low-window marker, the real litterbox and washer, a `SockGenerator` area, the Cat with
  the station's own `cat_tuning_zoo.tres` (short timers, `fetch_chance` 1, `litter_every` 30 s, swats every 10-20 s), a
  board of the coats, the nap spots found, the Cat's SoundEvents and the tuning.

The Cat's SoundEvents are core/154's (`cat_meow` is played here).

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): W1 (graybox look; the model is assets/29), W2, W3; R1, R2 (the sofa, beds and window spots; the car's
spot is core/180's), R3, R4, R5, R6, R7; WD1. Keep the old seed-8 soak failure's seed in the soak (DC B4).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`CatTuning` and the coats are typed Resources in the inspector (`# placeholder:` the old `cat.json`, but `fetch_chance`
0.6 and `fetch_cooldown` 45 s, set by Q1946); a nap spot is a `Marker3D` in the group `cat_nap` placed in a furniture
scene; a coat is a dropped `.tres` in `game/entities/cat/coats/` (listed with `ResourceLoader.list_directory()`); the
motion is clips in Looks, the cross-fade the AnimationTree's, the head turn `LookAtModifier3D`s (Q2697); the station is
built from the coats folder, the markers and the catalogue (Q2337).

## Acceptance
- Real path: in the Cat station, with the Cat's walk planned through the Door to the far room (the zoo tuning's seed),
  the player's left click shuts the Door; the Host plans again and the Cat the player sees never crosses the doorway
  while it is shut, and walks through it once the player opens it again.
- In the house from a New Game (stages on) the Cat sits on the living room's couch while the ground floor is locked;
  when the ground floor opens (the real `open_floor`) it walks off within a rest's length.
- A 10-minute seeded soak of the house at a raised time scale (seed 8 among the seeds) finds no watchdog `put` but by
  `park_seconds`, and the Cat on a map spot every second, never on a locked floor, through a shut Door or in the shaft.
- It naps at nap spots with `curl`; a meow every 12 to 30 s while awake; its head turns toward a player in front
  within 2.5 m.
- A Guest sees the same walk (within 0.05 m of the Host's at the same walk time); a late Guest sees it mid-walk; save
  mid-walk and load: the walk resumes; a Cat placed inside furniture is `put` back at once.
- The async bake costs the main thread under 2 ms.
- Placeholders: `CatTuning`, the coats' colours.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Cat as the old: the couch until the ground floor opens (Q2703, 2026-11-26).
- The Cat's model and clips are ported by the port rules, with the old colours (Q2705, 2026-11-26).

## Open follow-ups
