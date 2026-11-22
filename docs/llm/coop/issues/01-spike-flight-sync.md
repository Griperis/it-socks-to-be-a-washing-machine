---
type: ticket
status: done
kind: research
area: core
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 0 (Q2436): a spike; only its report merges"]
terms: [Host, Guest, Flight, Throw]
---

# Spike: thrown Socks carried to a Guest by Godot's synchronizer

Decides the Throw's co-op path before batch 3 (`docs/migration/coop-structure-for-the-port.md` section 4).
Option A: the Host owns the flight body (`game/mess/` flights, spawned by `FlightSpawner`); one
MultiplayerSynchronizer per body carries one stamped property `row = [pos, rot, vel, clock]`; a Guest
plays it 0.1 s behind. Untested so far: Jolt bodies under a synchronizer, and the order of the spawn
packet against the Host's reliable answer. Option C (keep a custom stamped stream) is the fallback.

## Acceptance
- A headless test with a Host and a Guest (the kit's two-peer harness, `kit/docs/TESTING.md`) throws one Sock
  and 16 Socks at once on the Host; the Guest's copies are spawned, move and come to rest where the Host's did.
- Measured at 0 ms and 50 ms one way: the largest jump of a Guest copy between frames, the lag behind the
  Host, whether the spawn ever arrives after the answer that names it, bytes per second per flying body.
- A report in `docs/research/coop-flight-sync.md`: what worked, the numbers, the recommendation (A or C) and
  the lines of game code each would need.
- No change to game behaviour on `main`: the test code may stay as a test if it passes and is not flaky,
  else only the report merges.

## Answers
- The Host owns the body; the thrower sees an instant ghost that blends over 0.2 s (Q2221).
- A Teammate's Throw leaves the hand at once with only the network's 0.1 s delay (Q2439).

## Open follow-ups
- [later] Technical, for the Throw ticket (batch 3) whichever option: hold ENet's packet throttle at full in
  `Session` (`throttle_configure(5000, 32, 0)` on each peer); left alone it drops 31 of 32 unreliable
  packets at 60 fps, avatars included (`docs/research/coop-flight-sync.md`, condition 1).
- [later] Technical, before co-op play with a full level: Mess patches carry the whole `states`/`poses`
  arrays (about 100 KB an answer with 2,038 Socks); they back up the reliable channel. Patches of changed
  records only (condition 3).

## Built log
- 2026-11-22 lead: model opus (hard netcode and physics, CLAUDE.md "Models").

### 2026-11-22
- Changed: nothing in the game. A spike: Host and Guest zoos in one process; thrown Socks spawned by
  `FlightSpawner` with one synchronizer per body carrying a stamped row, played 0.1 s behind. A works:
  no jump, lag 0.1 s + one-way, 0.4 mm at rest, spawn always before its answer, about 4.8 KB/s a body;
  needs the throttle held at full, the pose set before `add_child`, sparse Mess patches. Recommendation A.
- Files: `docs/research/coop-flight-sync.md`, `tests/coop_flight_test.gd`, `tests/support/flight_row.gd`,
  `tests/support/lag_peer.gd` (byte counters).
- Verified: `kit/tools/run.sh --touched`: PASS 296 checks, 28 cases; `--only=coop_flight` three times in a row
  PASS; the two stress cases PASS (numbers only).
- Merged: 12e922ad (2026-11-22, branch coop/01-spike-flight-sync)
