---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[163-radio-carried-and-thrown]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 3", "suggested model: opus"]
terms: [Sock vacuum, Hands, Teammate, Door]
suites: [vacuum, carry, coop_carry, handling, hand_details, room_doors, profiler, player, save, zoo]
---

# The Sock vacuum: the nozzle, the hose and the container

The house's one Sock vacuum, first as a thing to handle: a left click takes its nozzle off the hook into the whole
Hands (Socks, Pairs or the book held fall round the player's feet; a carried thing refuses it), the hose drapes over
furniture and wraps round door frames, at its length the walk stops and only the hose shakes, a right tap hangs or
drops the nozzle; the container is carried by the shared whole-Hands rule. Build `docs/architecture/devices.md` "The
whole-Hands rule", "`Vacuum`" (take and put the nozzle, `left`, `loaded`), "The hose", draft 150-F:

- `sock_vacuum.tscn` with the container's `Carriable` (title "Sock vacuum", `handable` off), the `Vacuum` Part (all
  its State fields; the Tank empty for now), graybox Looks and contract;
- `Hands.TAKERS` in `hands.gd` (Parts answering `takes_hands_of(by)`, counted as held by every "full" check; mind
  `Hands.carries()` now returning a Part, the doc's gotcha);
- the hose: a skinned tube whose bones are `PhysicalBone3D`s under a `PhysicalBoneSimulator3D` (Jolt), pinned at the
  container's cuff and the nozzle's, its mask the house, the furniture and the moving leaves (never the Elevator's
  car's layer); `HoseTuning` (length 5 m, bones, radius, damping, `tug_seconds` 0.25, `hose_budget_ms` 0.3); its `tug`
  clip on the walker's machine only; the walk away stopped at the length on the walker's own machine (a seam in
  `player.gd`'s movement); the Host's check reads its own rope plus `host_slack` 1 m. **Spike first:** the rope pinned
  at both ends through a door frame at the budget; if `PhysicalBone3D` cannot do it, a chain of `RigidBody3D` capsules
  with `ConeTwistJoint3D`s, the rest unchanged;
- `hold_slot_vacuum.tres`, `hold_slot_nozzle.tres` with the new `HoldSlot.follows_aim` (a Teammate's along their aim);
- the hints and words; `vacuum_nozzle_hang`, `vacuum_nozzle_drop`, `vacuum_lift`, `vacuum_set_down` played (the
  SoundEvents are core/154's); taking the nozzle plays the Hands' pick rustle (Q2698);
- the vacuums station filled (shell from core/154 at x = 236): the real Sock vacuum, a small room with a room Door, a
  table and a drawer, a `SockGenerator`, its own `Upgrades` and `Bank`, a board of the Upgrades whose stat a `Vacuum`
  reads and the tunings' numbers, switches for each vacuum Upgrade's level and "Refill Socks".

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V4, V9, V12, V13 (the Doors; the car's half is core/175's), V14, V15, V16, V17 (both orders of shared
carrying, Q2698), V20, V21, V22, V31; the words "Hold: Vacuum", "Drop the nozzle", "Hang the nozzle", "Take the nozzle
%s", "Pick up   %s", "Hands full", "The hose won't reach".

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`VacuumTuning` (`sock_vacuum_tuning.tres`: the doc's numbers, `# placeholder:` the old), `HoseTuning` and the hold slots
in the inspector; the hose's `tug` a clip; Looks graybox (a canister, a hook, a nozzle, a boned tube), then assets/24.

## Acceptance
- Real path: in the vacuums station the player left-clicks the hung nozzle (two Socks in the Hands fall round their
  feet), walks through the Door with it, and the hose lies through the door frame; walking 5 m along the hose the walk
  stops and `tug` plays; a right tap within 0.6 m of the hook hangs it ("Hang the nozzle"); one past the hose's length
  reads "The hose won't reach".
- The Door shut on the hose pushes it; a dropped nozzle lies where dropped.
- Co-op: one carries the container while the other holds the nozzle, both orders; whichever walks away is stopped;
  neither drags the other; a leaver's or a knocked-down player's nozzle goes back on its hook.
- The profiler budget holds with a held hose; an idle hose costs nothing.
- Saved and joined (a Guest's held nozzle saved hung).
- Placeholders: `VacuumTuning`, `HoseTuning`, the hold slots.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- As the old: the nozzle take plays the pick rustle; both orders of shared carrying; a dropped nozzle lies where
  dropped; only the hose shakes at its length (Q2698, 2026-11-26).

## Open follow-ups
