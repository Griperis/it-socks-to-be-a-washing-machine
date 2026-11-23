---
type: ticket
status: done
kind: build
area: core
feature: coop
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["M0.6 batch 5 (Q2534); docs/migration/milestones.md"]
terms: [Host, Guest, Mess, Throw, Hands]
---

# M0.6 close-out: lag tests, guard tests, the co-op cost, code map and review guide

The last batch of M0.6 (Q2534), as `docs/migration/milestones.md` batch 5 says, plus the leftovers found in batches 3-4.

## Acceptance
- **Lag:** the co-op real-path cases (join, avatars, Mess, Hands, Throw, knockdown) run at 0 and 50 ms one way, as one
  case each over both values; all pass.
- **Guards:** a Guest's bad-shaped Command, a flood over the rate, and a forged avatar or knockdown write are each
  refused by the Host, a case each.
- **Cost:** measured in two processes with a Guest at 2,000 Socks: bytes a second each way, the Host's frame time, the
  Guest's frame time; written in the Built log and `docs/architecture/` (the co-op file).
- **Leftovers:** a leaver's looks-only bodies removed on every machine; the leaver's drop sound; the knockdown lines
  built but not proven by a case (coop/10's Open follow-ups: F70-F71 wall gap, E53, E62/F72, H97, H101, D37 in co-op)
  get a case each where they can be made headless, else a line saying why not; the ragdoll spike's tests removed if
  superseded; the closed M0.6 lines in `docs/migration/m06-backlog.md` marked done with their ticket.
- **Docs:** the code map (`docs/architecture.md` and the co-op subsystem file) and a review guide for the designer's
  code review of M0.6 (`docs/migration/review-guide-m06.md`: what to read, in what order, what to look for).
- **The designer's run:** a short list of what to try in one co-op zoo run of every station, in the Built log, for the
  lead to hand over.

## Open follow-ups
- [later] E62/F72 (the Host's bones and the knocked camera drawn between physics ticks, interpolated) have no
  case: headless runs draw no frame between two ticks, so there is nothing to compare; the designer sees it in
  the two-window run (item 7 below).
- [later] `tests/coop_knockdown_test.gd` is 610 lines, `coop_hands_test.gd` 743, `coop_mess_test.gd` 648 (grep_rules
  notes over 600): each copies the same two-zoo helpers; one shared `tests/support/` helper for a Host and a Guest
  would shorten all co-op suites. Not done here (each suite is another ticket's).
- [later] The cost's frame times are headless (no drawing) on the agents' Linux machine; the Host kept 36 frames a
  second during the 2,000-Sock pour (23 ms mean, its Mess's physics). The designer's PC in two windows is the
  reference; `tools/coop_cost.sh` was never run on Windows.
- [later] Kit: none found.

## Built log

### 2026-11-23
- Changed: the co-op real paths run at 0 and 50 ms one way as one case each (join, avatars' walk, the pour, a
  Guest's pick and Throw, the Throw ghost, the knockdown); new `coop_guard` suite: a Guest's malformed Commands
  to the Hands (shape 3, args 4, verb 1, no part 1), a flood of picks over the rate (10 answered, 20 dropped),
  a forged write (an avatar pose outside the area dropped on the Host's copy; a knock Command and a forged
  `_event` RPC refused). A leaver's looks-only bodies: reproduced (`coop_mess:leave_mid_pour` never settled in
  90 s: the frozen Throw copy and the looks bodies stayed); now `Session.close()` on a Guest calls
  `Parts.went_alone()` (new, empty on `Part`), and `Mess.went_alone()` turns each looks-only body and frozen
  Throw copy into its own body where it is (`MessMoving.take_over`, `FlightRow.last_motion`), for a leaver
  and for every Guest whose Host quits: all lie 160-175 frames later. Knockdown lines proven: D37, H97, H101
  in co-op (`drag_ends`), E53 (`inside`), F70-F71 (`wall_gap`); E62/F72 cannot be made headless (follow-up).
  The leaver's drop sound was already at its last place (coop/05, `teammates:cues`). The ragdoll spike's suite
  and scene removed (superseded by `ragdoll.tscn` and `coop_knockdown`); `avatar:spike_rig` now checks the
  real ragdoll's bones (`ragdoll_rig`). Free ports (the lead's item): `Session.free_port` (static, set by
  `tests/hooks.gd`) makes every Host in a test listen on a port the system picks; `coop_join:free_port`
  hosts two at once with the game's port held. Cost tool `tools/coop_cost.sh` (two headless processes).
  Code map `docs/architecture/coop.md` (new) and its row; review guide `docs/migration/review-guide-m06.md`;
  closed M0.6 lines marked in `docs/migration/m06-backlog.md`.
- Cost (two processes, Guest at 2,000 poured Socks, 4,151 in the zoo): pour 15.7 s: Host sends 72.2 KB/s,
  Guest sends 4.6 KB/s; Host frame 23.4 ms mean / 38.3 95th / 38.6 worst (36 frames/s), Guest 27.1 / 36.2 /
  68.8 ms (60 frames/s). At rest: 3.7 KB/s each way; Host 4.5 / 8.1 / 9.9 ms, Guest 7.2 / 17.1 / 17.1 ms.
  Headless, process plus physics time a frame.
- The designer's run (one co-op zoo run of every station; `-- --zoo --host` in one window, `-- --zoo
  --join=127.0.0.1 --profile=b` in another):
  1. Join: the Guest reads "Joined Player's zoo" and stands beside the Host in the second colour.
  2. Avatar station and walking: watch the other window's creature walk, crouch, look, waddle; hear its steps.
  3. Handling: the Guest picks, drops and throws; pick sounds at the click, the Throw leaves the hand at once.
  4. Heap: the Host clicks More; the Guest sees every Sock fall and settle; both grab one Sock (the Host wins).
  5. Cabinet: the Guest pairs and shelves into a drawer; the Host sees it paid.
  6. Openables and Furniture: one opens a door or drawer over lying Socks; the other sees them swept.
  7. Knockdown: a full-charge Throw at the other player; it falls, drops its Sock, sees the vignette, gets up;
     drag it by the feet, struggle free with Space; watch the fall look smooth (E62/F72).
  8. Leave mid-pour: the Guest closes its window during a pour; the Host sees its Socks drop where it stood,
     "Player left"; the Guest rejoins where it left.
  9. Every other station once as the Guest (Outline, Sock looks, Every sock, Sounds, Screen, Materials, House
     kit, Sock generator, Icons, Movement): nothing should differ from playing alone.
- Files: game/parts/session.gd, part.gd, parts.gd, game/mess/mess.gd, mess_moving.gd, game/sock/flight_row.gd,
  tests/coop_guard_test.gd (new), coop_join_test.gd, teammates_test.gd, coop_mess_test.gd, coop_hands_test.gd,
  coop_knockdown_test.gd, avatar_test.gd, hooks.gd, tests/ragdoll_spike_test.gd and tests/support/ragdoll_spike/
  (removed), tools/coop_cost.{gd,tscn,sh}, docs/architecture/coop.md (new), docs/architecture.md,
  docs/migration/review-guide-m06.md (new), docs/migration/m06-backlog.md
- Verified: suite: PASS 17940 checks, 495 cases (--touched, 55 suites); grep_rules PASS; tools/coop_cost.sh PASS. The full --touched verdict at commit is in the commit's `suite:` line.
- Merged: 26a3ccf7 (2026-11-23, branch coop/12-m06-close-out)
