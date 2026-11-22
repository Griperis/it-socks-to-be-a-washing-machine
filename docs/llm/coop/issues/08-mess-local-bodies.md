---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: coop
priority: now
created: 2026-11-22
done:
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

## Built log
- 2026-11-22 lead: model opus (netcode and physics, CLAUDE.md "Models").
