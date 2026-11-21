---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: ["experiment: built on its branch, never merged until the designer says (Q2419)"]
terms: []
---

# Experiment: lying Socks with two bends

The designer asked what it would take for the Mess's Socks to bend at their joints (2 bends would do) and chose the
cheap way to try (Q2418, 2026-11-21): a lying Sock gets two bend angles, at the heel and the ankle, decided once as
it comes to rest so it drapes over what is under it (a step, a furniture edge, another Sock); the sock shader bends
the instance's vertices around those two hinges (no skeleton in a MultiMesh), and its lying boxes follow the bends.
Flights stay one rigid body as today. **An experiment: it stays on its branch; the designer tests it from a review
build of the zoo (Q2419). No strip.**

## Behaviour list
- E1 Each Sock's pose record carries two bend angles (heel, ankle; radians, signed, within placeholder limits), so the
  record grows from `POSE` 12 to 14 floats, through every patch, the snapshot and `put_down`. Pairs (balls) carry
  zeros and never bend.
- E2 At a rest (`MessMoving._rest` / `Mess.put_down`), the bends are found from what is under the Sock: a few short
  rays down from the heel, the ankle and the toe points of its resting pose (along its length), and each segment
  turned to lie on the surface under it, within the limits. On flat floor the bends are 0 (it lies as today). A rest
  costs at most a handful of rays; nothing is added per tick.
- E3 The bend matches what was drawn just before: a flight drawn with a cloth Looks hands its bones' bend to the rest
  where that fits the two hinges (read the Looks' chain at the rest), else the found bend; and the instance starts
  bent exactly as the rest decided, with no pop (core/31's settle teleport must not come back: check frame by frame
  with core/31's watch, `jumped` stays 0).
- E4 The sock shader (`game/sock/sock_pattern.gdshader` or the instance material's) bends an instance's vertices
  around two hinge lines across the Sock at the heel and the ankle (positions per shape, from the model's bones: the
  `Leg`→`Toe` chain), with smooth weights over a short band so the cloth does not crease; the bend angles reach it in
  the instance data (find room: the custom data and colour are in use by the look data, `MessDrawing.look_data()`;
  pack where it costs no extra buffer, or widen the buffer and say what it costs). Normals bend too (lighting
  right). The LOD meshes bend the same.
- E5 The lying boxes follow the bends: the leg and foot boxes (`MessBodies.parts_at`) placed per segment (a third box
  if the two bends need it), so a bent Sock is picked, hit and woken where it is drawn.
- E6 A woken bent Sock flies straight as today (its flight is one body); the bend eases out over the cloth's
  `blend_time` on a cloth Looks, or snaps on an instance (note which in the report).
- E7 Bench: core/31's benchmark gains `drape_500` (a heap poured onto steps and a furniture edge) and the existing
  scenarios run on this branch beside `main`; the report says what the bends cost per tick, per rest and per frame.
- E8 Numbers (bend limits, ray reach, hinge band) in `MessTuning`, placeholders for the designer.

## Acceptance
- Suite cases for E1-E5 (a Sock resting across a step's edge comes out bent and its boxes sit where it is drawn; on a
  flat floor the bends are 0; a pick, a hit and a door sweep find a bent Sock) and the real-path case: in the zoo's
  heap station the player pours onto the steps, the Socks drape, and the player picks one by its bent toe.
- The zoo has somewhere to see it: steps and a furniture edge in or beside the heap station (or the movement
  station's ledge), with the heap's pour able to land on them.
- `--touched` passes; the bench report with the `main` vs branch table in `builds/review-core-37/`.
- Status `ready-for-human` when built: the lead exports the review build (the agent does not export) and the designer
  plays it. Not merged until the designer says.

## Answers
- Two bends decided at rest, drawn by the shader (Q2418, 2026-11-21).
- Not merged; a review build of the zoo, no strip (Q2419, 2026-11-21).

## Open follow-ups

## Built log
- Model: Opus: a cross-cutting Mess change with a shader and physics; hard to get pop-free.
