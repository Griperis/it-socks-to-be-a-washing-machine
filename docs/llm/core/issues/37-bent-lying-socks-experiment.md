---
type: ticket
status: ready-for-human
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
- [later] Added by the agent, the designer's call: a Sock that rests bent sinks from flat into its bend over
  `MessTuning.drape_time` (0.25 s; its lying boxes are bent at once). Without it the flat flight snaps bent in one
  frame. 0 gives the ticket's literal "starts bent exactly as decided". Keep the sink, or snap?
- [later] E3 hand-off from a cloth Looks: not built as a read of the chain. At every rest the cloth is already flat:
  it blends flat below `flat_speed` over `blend_time` (0.3 s, the same as `rest_time`) and within `ground_room` of
  the ground (D04, P07). So there is no bend to hand over, and the bend found by the rays applies (eased in, above).
- [later] E6: a woken bent Sock eases flat over the cloth's `blend_time` when its flight is given a cloth Looks (the
  `flying_cap` nearest the camera, given the tick it starts). As an instance it is drawn flat at once.
- [later] How many bend: about 45% of a heap poured on a flat floor rests bent (226 of 500 in `settle_500`), because
  Socks lie over each other's edges. Should only the house's edges bend a Sock (the rays would then see only
  `LAYER_HOUSE`), or other Socks' edges too, as now?
- [later] Hinges come from the bones, so on the `ankle` shape the leg past its ankle hinge is only 2 cm (the Heel
  bone's head sits near its cuff), and its "ankle bend" folds just the cuff rim.
- [later] A bent Sock's three boxes are the crew box model split at its own shape's hinges, like the flat boxes that
  fit the crew for every shape. So a `chunky` Sock's drawn ends reach past its boxes, as they do when it lies flat.
  Fitting them to each shape's own mesh caused overlaps in the heap: the flight's boxes are crew-sized.
- [later] Two hinges can only drape where the edge falls within about a quarter of an end's length of a hinge. Ends
  bend less than cloth would elsewhere, and the box check halves a bend that would cut into the edge.
- [later] The zoo's Lose button (`game/zoo/handling/lose_button.gd`, outside this ticket) still puts a Sock down
  with no bend.
- [later] `tools/shot_hooks.gd` is 705 lines (grep_rules notes over 600): `bend_row` and `bend_drop` added here.
- [later] Kit: the new scripts' `.uid` were made with `ResourceUID.create_id()` in the test mirror (none was left
  in the check mirror).

## Built log
- Model: Opus: a cross-cutting Mess change with a shader and physics; hard to get pop-free.

### 2026-11-21
- Changed: the pose record is 14 floats, the last two the heel's and ankle's bend (E1). A rest finds them with
  three rays down along each end and then one box query per end (up to four if each try overlaps), turning the end
  down to the surface under it. The turn stops at the limit or at straight down, and halves when the turned end
  would overlap anything (E2, `SockBend`). Nothing is added per tick; a rest costs about 80 us. The sock shader
  bends vertices, normals and tangents about each shape's two hinges (from the Heel and Foot bones), with the
  angles packed in the instance colour's alpha, so the buffer does not grow (E4). A lent Looks is bent by its
  bones and matches the shader (stills). The lying body is three boxes turned with the ends (E5). A woken Sock
  flies flat (E6). The heap station has three steps under the spout and its table moved under the pour's edge.
  The benchmark has `drape_500`, and the `main` vs branch table is in `builds/review-core-37/report.md` (E7).
  Numbers are in `MessTuning` "Bend" (E8).
- Bench, branch vs `main` (one run each, a loaded machine, noisy): idle ticks unchanged (10,000 lying: 0.008 vs
  0.011 ms median). Pouring ticks within noise (`pour_500` 4.41 vs 4.43 ms median, p95 7.7 vs 6.5). Per rest 80-90
  us (`bend_us`). Per frame: scripts' frame 0.20 vs 0.12 ms in `settle_500`, from rows rewritten while draping; the
  shader's GPU cost was not measured headless. Faults: the same 7 scenarios fail on both, on flips (Q2413), sunk
  and the tick budget. `drape_500`: 267 of 500 rest bent. Branch: jumped 1, sunk 2. `main`: lost 1, sunk 2.
- Files: `game/mess/sock_bend.gd` (new), `mess.gd`, `mess_bodies.gd`, `mess_drawing.gd`, `mess_moving.gd`,
  `mess_tuning.gd`; `game/sock/sock_pattern.gdshader`, `sock_cloth.gd` (carry with places);
  `game/debug/mess_bench*`, `mess_watch.gd`; `game/zoo/stations/heap.tscn`; `tools/shot_hooks.gd`;
  `tests/mess_bend_test.gd` (new); `docs/architecture/mess.md`.
- Verified: `kit/tools/run.sh --touched`: PASS 16708 checks, 366 cases; rules PASS; asset_lint PASS. Stills
  `builds/review-core-37/bend-*.png` (the shader's and the bones' bend differ by 798 pixels over 16 levels in a
  1280x720 frame).

### 2026-11-22 (lead): parked
- Parked by the designer (Q2426): not merged; the branch and `builds/review-core-37/` stay. The shader bend may come back for the held Sock (the lead's note, not planned).
