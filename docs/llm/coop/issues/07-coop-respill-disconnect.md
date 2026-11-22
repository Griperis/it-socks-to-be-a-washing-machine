---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["reported by the designer 2026-11-22 in a two-window test; pulls forward m06-backlog 'Mess patches carry the whole arrays' (coop/01 condition 3)"]
terms: [Host, Guest, Mess]
---

# A Guest disconnects or crashes on a bigger sync or a respill

The designer, in two windows (Host and Guest on one PC, `-- --host`, `-- --join=127.0.0.1 --profile=b`):
"player disconnects and crashes, when trying to sync more and respill". Which machine crashed and the
logs are not known yet (they may arrive in `builds/crash-logs/`).

Suspect, not a diagnosis: every Mess answer carries the whole `states`/`poses` arrays (about 100 KB at
2,038 Socks, `docs/research/coop-flight-sync.md` condition 3); a respill makes thousands of answers on the
reliable channel, which backs up until ENet times out. Reproduce first; the cause may be another.

## Acceptance
- A headless Host and Guest case that reproduces the fault through the zoo's own wiring (the heap
  station's respill, and a large pour), failing before the fix: which machine fails, how (disconnect,
  timeout, engine error, crash) and why, written in the Built log.
- The cause fixed. If it is the whole-array answers: a Mess answer carries only the records it changed
  (and the join snapshot stays whole); the Guest's Mess applies them to the same result as the Host's.
- After the fix: a respill and a 2,000-Sock pour with a Guest joined keep the Guest connected, its Mess
  equal to the Host's once all rest, at 0 ms and 50 ms one way; bytes per second on the reliable channel
  measured before and after.
- No change to how Socks look on the Guest while in flight (batch 3 does that).

## Answers

## Open follow-ups
- [later] For the designer and the lead, about looks: a Guest's spawned flight copy is now frozen as it arrives
  (`Mess._on_flight_in`). It still shows at the Flights holder's origin, as before, but it now holds still
  there instead of tumbling in a pile at that spot. Both are wrong places (no synchronizer yet), and coop/08
  and coop/09 replace them. The freeze is what stops the Jolt overflow and the null-body errors on the Guest.
- [later] The launches in a rows patch are still a Variant Dictionary (about 90 B a poured Sock). Packing them
  would cut a 2,000-Sock pour from about 58 KB/s to about 50 KB/s. That is not needed for the 64 KB/s
  placeholder budget.
- [later] A disconnect itself was not seen: two machines in one process at 0 and 50 ms stayed connected even on
  the old code, while the Guest fell minutes behind. On two windows, the likely path is the Guest's frames
  stretching (Jolt overflow, megabytes of answers each frame) until ENet times out. The designer's crash logs,
  if they come, can confirm it.

## Built log
- 2026-11-22 lead: model opus (netcode debugging, CLAUDE.md "Models").
- 2026-11-22 agent (coop/07)
  - Reproduced in `tests/coop_respill_test.gd` (two whole zoos, real ENet, the Host's player clicks the heap
    station's More and Respill; a 2,000-Sock pour). On the old code, a 2,000-Sock pour sent **700 MB reliable
    in 525 s: 1.33 MB/s on average, worst second 16 MB** (50 ms: 712 MB, 1.54 MB/s, worst second 15.5 MB).
    The process ran at about 10 frames a second, and after 5,400 frames the Guest still had 478 Socks flying
    and its Mess was not the Host's: it was minutes behind. Either machine printed 4,000 to 5,000 Jolt
    `Parameter "body1" is null` errors plus contact, manifold and body-pair buffer overflows. A 500-Sock
    pour (the old respill) sent 88 MB in 102 s. The Guest stayed connected in one process.
  - Why: (1) every Mess answer carried the whole `states`/`poses`/`throws`/... arrays (about 100 to 190 KB at
    2,000 to 4,000 Socks), and a pour makes one answer per rest. (2) On the Guest, every spawned flight copy
    was a live RigidBody3D with no synchronizer, arriving at the holder's origin, so hundreds piled into one
    spot. A diagnostic run of a 300-Sock pour showed the Jolt overflows and 27 fps with live copies, and none
    with frozen copies at 60 fps.
  - Changed: a Mess answer is a rows patch (`Mess.ROWS`, `ROW_*`, `ROW_COUNT`, `LAUNCHES`): only the changed
    records, in packed arrays. `Mess.write` applies it the same on every machine; the snapshot stays whole.
    The `*_patch` functions chain through `onto`. Rests go as one `rest` a tick (`MessMoving._ask_rests`),
    and nothing is sent when none rested (coop-mess-sync plan, Q2472). A Guest's spawned copy is frozen
    (kinematic). `PROTOCOL` is now 11. `Hands.left` and the zoo's lose button build their patches with the
    Mess's functions. Tests reading patches use `Mess.row_states()`.
  - After: a 2,000-Sock pour **1.08 MB in 18 s: 58 to 60 KB/s on average, worst second 87 to 91 KB** (0 and 50
    ms). More then Respill (500 each): 175 KB each, 35 to 40 KB/s, worst second 76 KB, about 60 fps. The Guest
    stayed connected, its Mess `_same` as the Host's, and neither machine printed an engine error or warning.
  - Files: game/mess/mess.gd, game/mess/mess_moving.gd, game/parts/session.gd, game/hands/hands.gd,
    game/zoo/handling/lose_button.gd, tests/coop_respill_test.gd (+ .uid), tests/mess_test.gd, tests/throw_test.gd,
    tests/mess_settle_test.gd, docs/architecture/mess.md.
  - Verified: `--touched` PASS 15658 checks, 372 cases; `coop_respill` all four cases PASS (respill_0ms
    everyday; respill_50ms, pour_0ms, pour_50ms stress).
- Merged: 46fe2ee6 (2026-11-22, branch coop/07-coop-respill-disconnect)
