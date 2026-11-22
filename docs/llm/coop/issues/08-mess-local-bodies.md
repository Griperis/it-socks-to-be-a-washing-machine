---
type: ticket
status: done
kind: build
area: core
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 3, the Mess half (Q2472); plan: docs/migration/coop-mess-sync.md"]
terms: [Host, Guest, Mess, Flight]
---

# The Mess in co-op: moving Socks on every machine, as the old game

A Guest sees Socks fall, tumble, pour and get swept by Doors and drawers as the Host does, at the same
moment, and every Sock ends where the Host's ended. Cheap on the wire: only decided changes and rests
travel; motion is simulated on each machine (Q2222).

## Behaviour list
`docs/migration/m06-lists/03-mess-throw-coop.md` sections A (join), B (moving Socks and the settle
stream) and C (Doors and drawers), approved by Q2472; a Sock mid-flight at a join flies on from where it
is (A05, Q2472). The m06-backlog Co-op items this closes: woken flights spawned with no synchronizer,
Doors sweeping on the Host only, the co-op cost of whole arrays, the heap sign's Moving count on a Guest,
`MessMoving._launch` setting the pose after `add_child`.

## Design (`docs/migration/coop-mess-sync.md`)
- **Local bodies:** when a record turns FLYING by a wake, fall, pour or sweep (the Host's answer, already
  compact after coop/07), each machine starts its own body from the record's pose and launch values, for
  looks; no spawner and no synchronizer for these. On a Guest the body is looks only: it never wakes,
  rests, writes or sweeps anything shared, and lives on a layer that touches the static world and the
  Guest's own local bodies only. The budget and wait queue apply on each machine alike.
- **Snap:** the rest batch (coop/07) puts each Sock LYING at the Host's pose on every machine, ending its
  local body at once; a local body the Host never moved goes back where it lay. No MultiMesh is physics-
  interpolated (Q2407), so a snap never smears.
- **Throws stay on the spawner** (coop/09 gives them the stamped stream); woken Socks no longer use it.
- **Doors and drawers:** every machine sweeps its own lying bodies with the same rule (looks only on a
  Guest; the Host's decides).
- **Join:** the Mess's snapshot in a compact packed form, compressed; FLYING records carry their linear
  and angular velocity so a joiner starts their bodies from where they are.
- **Counts:** the heap sign's Moving count reads this machine's own bodies.

## Acceptance
- Real path: two zoos (Host, Guest); on the Host, the heap station's pour of 200 Socks: the Guest shows
  bodies falling within a frame of the Host's answer (not only after they rest), and once all rest the
  Guest's records and poses equal the Host's.
- A Throw into a heap on the Host: the Guest shows the woken Socks tumbling, then snapped to the Host's rest.
- A drawer opening on the Host over lying Socks: the Guest sweeps and shows them moving.
- A late joiner mid-pour: its bodies start from where the Host's are and end equal.
- A Guest's local body never changes a shared record (a case that checks no shared write happens on a
  Guest during a pour).
- Measured at 0 ms and 50 ms one way, written in the Built log: reliable bytes a second during a
  2,000-Sock pour, the join's size for 2,000 Socks, the Guest's frame time against the Host's. Budgets in
  `coop-mess-sync.md` (placeholders until measured).

## Answers
- Q2222, Q2407, Q2428, Q2472 (2026-11-22).

## Open follow-ups
- [later] A Guest that leaves mid-pour becomes a Host of one with its looks bodies still on `LAYER_LOOKS`
  (they rest by the Host's rules, but do not touch its new bodies until then). Technical; no case yet.
- [later] The join after a 2,000 pour at rest (4,039 Socks) is 110 KB, over the plan's 100 KB if that budget is
  read per record: a poured Sock's exact pose is 48 bytes of floats that do not compress. Smaller needs the Host
  to keep rested poses quantized (a choice for the lead and the designer: it moves every rest by under a mm).
- [later] "The Guest's frame time" is measured as the Mess's scripts a tick on each machine with the same bodies;
  both machines' physics worlds step in one process in the test, so a two-process measure of whole frames
  (net_shot or two exports) is left.

## Built log
- 2026-11-22 lead: model opus (netcode and physics, CLAUDE.md "Models").
- 2026-11-22 agent (coop/08): Changed: every machine starts its own body for a Sock the Host's answer makes
  FLYING by a wake, fall, pour, sweep or drop (`MessMoving.start`, under the Mess's own `Bodies` holder, no
  spawner); a Guest's is looks only on `Mess.LAYER_LOOKS`, never asks anything, and the Host's rest batch snaps
  it. Only a Throw's body is under `flights` (the spawner; a Guest's copy still frozen until coop/09). A Guest's
  moving Doors and drawers sweep its own lying Socks (`tick_looks`, `Mess.lift`); one the Host never woke goes
  back where it lay once still (`Mess.lie_again`, B06). The pose is set before `add_child` (backlog). The heap
  sign's Moving count reads this machine's bodies. `Part.whole_state()` (new; `Parts.snapshot()` uses it): the
  Mess's packed and zstd-compressed, exact, with each flying body's place and motion (half floats), read back
  by `Mess.unpacked()`; `Session.layout_of` reads `Parts.ids()`.
  Files: game/mess/mess.gd, game/mess/mess_moving.gd, game/parts/part.gd, game/parts/parts.gd,
  game/parts/session.gd, game/debug/mess_watch.gd, tests/coop_mess_test.gd (new), tests/throw_test.gd,
  tests/pairing_test.gd, docs/architecture/mess.md, docs/migration/coop-mess-sync.md.
  Measured (`MESS`, `RESPILL` lines; before = main 6c469d60):
  - Reliable bytes during a 2,000-Sock pour: 983 KB in 16.2 s, 60.8 KB/s, worst second 91 KB (0 ms); 991 KB,
    59.4 KB/s, worst second 90 KB (50 ms). coop/07 had 58 to 60 KB/s, worst 87 to 91 KB. From a late welcome on:
    50 to 56 KB/s, worst second 81 to 85 KB (before: 55 KB/s, worst 80 KB).
  - Join: the zoo's 2,039 Socks 19.7 KB (before 132 KB; the Mess alone about 4 KB, the rest is other Parts);
    mid-pour 3,059 Socks with 474 flying 90 KB at 0 ms, 96 KB at 50 ms (before 256 KB, the spawner's copies
    included); a 500 pour mid-way 46 KB; after the 2,000 pour at rest (4,039 Socks) 110 KB.
  - A late joiner's bodies start at the Host's place (farthest 0.000 m from the Host's path).
  - The Mess's scripts a tick during a 2,000 pour: Host mean 1.36 ms (95th 2.50), Guest 0.48 ms (95th 0.76) at
    0 ms; Host 1.25 (2.33), Guest 0.45 (0.77) at 50 ms; the Guest holds as many bodies as the Host (200 of 200 in
    the real-path pour).
  Verified: `PASS 15735 checks, 380 cases` (run.sh --touched); coop_mess and coop_respill with --stress PASS; coop_flight --stress PASS.
- Merged: 703c1971 (2026-11-22, branch coop/08-mess-local-bodies)
