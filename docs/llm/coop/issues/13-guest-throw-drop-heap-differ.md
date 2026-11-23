---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["the designer's M0.6 co-op zoo run, 2026-11-23; Q2573"]
terms: [Host, Guest, Throw, Mess, Sock, Hands]
---

# On a Guest: the own Throw has no arc, a put-down Sock sinks under the floor, heaps stack differently

From the designer's two-window co-op run on main (2026-11-23), after coop/09, coop/11 and coop/12:
1. **The Guest's own Throw looks wrong:** it has no arc; the Sock "just sways down". The Host's Throw is right.
   The designer asks for prediction on the Guest with the Host authoritative (Q2573): the Guest flies its own Throw with
   full physics (the same Jolt body, shape, mass, material and launch numbers as the Host's), and is corrected
   smoothly to the Host's stamped stream when the two part (a threshold and an ease, typed Resource numbers), ending
   on the Host's rest record. Teammates' Throws stay on the stream, played 0.1 s behind (Q2439).
2. **On the Guest, a Sock put down goes below the ground.** (Compare core/50: Jolt pushed a Sock through the 0.2 m floor
   on the Host; the Guest's looks-only bodies and the drop ghost may lack that fix, or the snap puts it at a wrong
   height.)
3. **On the Guest, Socks stack much differently than on the Host.** The Guest's looks-only bodies (Q2222) should end
   where the Host's rest batch says (snapped at rest); the designer sees different heaps.

## Reproduce first
Two processes (Host and Guest, `-- --zoo --host` / `--join`), at 0 and 50 ms, driven by input, logging per Sock the
Host's and the Guest's poses over time: a Guest Throw, a Guest drop at the handling station, a heap pour. Measure
before you diagnose: the Guest's flight path against the Host's (height over time), the Guest's resting heights against
the floor, and every Sock's final pose on both machines. Write each cause in the Built log (coop/11 found three
causes for an earlier version of item 1: read it).

## Acceptance
- Item 1: the Guest's own Throw follows the Host's arc: its path within a small error of the Host body's (a number in
  the Built log) at 0 and 50 ms, with the hand-over to the Host's rest record invisible (no pop over a set distance).
- Item 2: no Sock on the Guest ever rests under a floor (a case over drops and a pour).
- Item 3: after a pour settles, every Sock on the Guest lies where the Host's does (within 1 mm and 1 degree), a case.
- Real path: two zoos at 50 ms, the Guest throws, drops and the Host pours; all three hold.
- coop/07-coop/12's cases and the cost budgets still pass.

## Answers
- Q2573 (2026-11-23).

## Open follow-ups
- [later] Item 3, for the designer before the merge (the small-details rule): at rest the two heaps are equal (every
  record and every drawn instance, 0 and 50 ms, 200 and 300 Socks), so what was seen is most likely the heap while it
  settles: the Guest's own looks-only bodies (Q2222) come to rest a median 11 cm and 55 degrees from where the Host's
  rest, 95th percentile 30 cm, worst 60 cm, and each is snapped there at its rest (280 of 300 by more than 5 cm or
  20 degrees). A many-body pile is chaotic: the Guest starts each wave a few ticks later and lies the Host's rests a
  tick or more late, so its pile parts from the Host's. Options, each a choice of look or cost: (A) keep (Q2222, Q2472);
  (B) ease each snap over a short time instead of a jump; (C) stream the Host's poses of moving Socks (about 5.6 KB/s
  a body, coop/01), which coop-mess-sync.md ruled out.
- [later] Seen by a Teammate, a Throw or drop now leaves the thrower's own first-person hand and is drawn from their
  avatar's hand easing onto it in `hand_over_time` (0.2 s). The Host's own Throws seen on a Guest used to pop from
  the avatar's hand to the eye-line at release; they ease the same way now. Worth the designer's eye in a two-window run.
- [later] The `part_distance` (0.03 m) and `part_turn` (20 degrees) thresholds of Q2573 are placeholders in
  `ghost_tuning.tres`; the ease is the existing `predict_blend` (0.2 s).

## Built log
- 2026-11-23 agent (coop/13): Reproduced in two headless processes (new `tools/coop_probe.sh`: Host and Guest on
  127.0.0.1, 0 and 50 ms, the Guest throws and drops by input at the handling station, the Host pours 200/300 at the
  heap; `tools/coop_probe.py` compares the logs). Measured before the fix (main 4552ca1):
  1. Throw: the Guest's ghost body flew the Host's flight within 0.0001 m, but the Host lets a Guest's Throw go from
     the Guest avatar's worn hand (coop/05), 0.60 m below the Guest's first-person hand, so the ghost was drawn from
     the first-person hand easing 0.6 m down onto it in 0.2 s (Q2481): drawn height 1.42, 1.20, 0.81, 0.50 m at 0,
     0.07, 0.13, 0.2 s against the Host body's 0.82, 0.75, 0.65, 0.50 m. Cause: the two machines let the same Throw
     go from different hands; the ease made it "sway down" with no arc. (The Host's own Throws leave its first-person
     hand, so they looked right.)
  2. Drop: drawn down to -0.26 m (0 ms) and -0.39 m (50 ms) under the floor. Cause: the same two hands. The ghost
     left the first-person hand, the Host's body (and the Guest's local copy of it, the ghost's reference) the worn
     hand 0.6 m lower; the ghost's offset towards that reference carried the drawing under the floor while its own
     body was still 0.36 m up. The ghost's body also had no core/50 guard against Jolt pushing it into the floor.
  3. Heaps: not reproduced at rest: every record equal, every drawn instance equal (0 and 50 ms). During the pour
     the Guest's own bodies rest a median 0.11 m / 55 degrees from the Host's rest and are snapped (Open follow-ups).
- Changed: every Throw and drop leaves the thrower's own first-person hand on every machine (`Hands.start_of` uses
  the new `own_hand_of`, from the thrower's eyes and aim), so a Guest's ghost flies the Host's very flight (Q2573).
  The ghost flies on its own body (full physics, the Host's numbers) and is drawn on it until it parts from the
  Host's body by more than `GhostTuning.part_distance` or `part_turn` at the same moment of the flight; from then it
  eases to the Host's (`predict_blend`) and onto the Host's rest as before. The first-person lead of Q2481 is gone
  (nothing to ease). Teammates still see a Throw or drop leave the avatar's hand (Q2439): the Mess draws a let-go Sock
  of a player on another machine from `Hands.worn_start_of` (their avatar's HoldPoint) easing onto its body over
  `hand_over_time` (`Mess._leads`, MultiMesh row or Looks). The ghost body undoes a push into the floor as flights do
  (`MessMoving.undo_push`, core/50's rule made static). `Mess.drawn_lying_of` (tests compare drawn heaps).
- After (probe, 0 and 50 ms): the Guest's drawn Throw within 0.0016 m of the Host's body at the same moment, from
  its first frame to the rest (0.002 m in the bounces); drop lowest drawn -0.0025 m (the Host's own rest pose); no
  moving body under the floor; the Host draws the Guest's Throw from the avatar's hand (0.82 m) onto its body in
  0.2 s. Tolerance in the case: 0.02 m before the first touch; no frame's step over the Host body's own.
- Files: `game/hands/hands.gd`, `game/hands/guest_ghosts.gd`, `game/hands/throw_ghost.gd`,
  `game/hands/ghost_tuning.gd`, `game/hands/held_view.gd`, `game/mess/mess.gd`, `game/mess/mess_moving.gd`,
  `game/mess/mess_drawing.gd`, `game/parts/avatar/avatar_looks.gd`, `tests/coop_hands_test.gd` (new case
  `throw_drop_pour_real_path`, `guest_throw_ghost_on_host_flight` now judges the drawing from its first frame),
  `tests/teammates_test.gd` (`throw_hand`), `tools/coop_probe.{sh,gd,tscn,py}`, `docs/architecture/{mess,coop}.md`.
- Verified: coop_hands PASS 209 checks, 8 cases; teammates PASS 71 checks, 9 cases; grep_rules PASS;
  `run.sh --touched` by agent_finish below.
