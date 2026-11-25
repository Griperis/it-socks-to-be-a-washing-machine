---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: opus (flaky test debugging)", "ledger: tests/flaky/ledger.md, coop_knockdown:real_path (2026-11-25)", "batch A side ticket"]
terms: []
---

# A knocked-down co-op case misses its hold under load

`coop_knockdown:real_path` failed once during batch A while 4-5 agents and a merge ran at once, and passed on rerun. The ledger line:
"Sock 1 to be held (within 180 frames)". A flaky case is a defect to rework, never to tolerate or switch off (kit/docs/TESTING.md "Flaky cases").

## Acceptance
- Reproduced first (the suite order, a part/shard, or a forced slow frame), and the cause named.
- Fixed at the cause: the test waits on the real condition, not more frames, unless the game itself is wrong (then
  fix the game). No look or feel number changed (else a [blocking] follow-up).
- The case passes 10 runs in a row in its suite order under load; no FLAKY line.

## Open follow-ups
- [later] Lead: `tests/coop_hands_test.gd`, `coop_carry_test.gd` and `coop_pings_test.gd` place a Guest the same way
  (a teleport, then a fixed `LAG_MS * 3` frames) and may click before the Host has the pose; not looked at here
  (outside this ticket). `coop_hand_off_test.gd` already waits on `LevelNet.where()`.
- [later] Kit: the first `agent_finish.sh` run hung 25 min after its shards ended (12:20), its run.py asleep holding
  `game-tests-shared/perf.lock`, no slot, no child process, load 0.5; killed and rerun.

## Built log
- 2026-11-25 (agent): Cause: the Guest is teleported beside SockB and clicks a fixed 15 frames later; the Host
  judges reach by the pose it last heard (`LevelNet.where()`), sent unreliably at wall-clock intervals. Logged
  at the click in the 50 ms round, the Host still had the Guest at its spawn (0.6, 0, 4.0), `far`, every time;
  the pick only won because the Command trailed the pose by the lag. A pose that leaves late (busy machine)
  makes the Host refuse the pick, and nobody clicks again. Reproduced with the Guest's pose sent 0.4 s late:
  the ledger's "Sock 1 to be held (within 180 frames)". The game is right (a real player walks up).
  Changed: `_aim` waits until the Host has the player where it stands before the click. No number changed.
  Files: `tests/coop_knockdown_test.gd`. Verified: forced-late-pose repro PASS 608 checks; `--only=coop_knockdown`
  10 runs in a row, 3 at once beside batch A, reruns off: PASS 170 checks, 8 cases each; `--touched`: PASS 396 checks, 20 cases; `grep_rules.py`: PASS.
- Merged: c3d0af91 (2026-11-25, branch core/101-coop-knockdown-real-path-flaky)
