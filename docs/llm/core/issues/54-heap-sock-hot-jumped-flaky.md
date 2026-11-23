---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-23
done:
blocked_by: []
notes: ["flaky ledger tests/flaky/ledger.md lines 48-60 (2026-11-22 21:19 to 2026-11-23 12:01); core/49's and core/50's [later] notes"]
terms: [Mess, Sock]
---

# A heap Sock now and then comes out "hot", "jumped" or "jittering" (mess_settle FLAKY)

The flaky ledger has 12 `mess_settle` entries in 15 hours, across branches that do not touch the Mess: `real_path`,
`real_path_1`, `real_path_3` (most), `real_path_4` and `small_heap`, failing "no Sock jumped", "no Sock hot" or
"no Sock jitter" (1 Sock each), passing on rerun. core/49 saw the same once ("one Sock hot and jumped: pressed 116 mm
under the floor, then lifted by the rest rule while still moving", its Open follow-ups); core/50 found Jolt's position
solve pushing a Sock through the 0.2 m floor and put it back 1 cm higher, noting floors 0.4 m thick never showed it.
A flaky test is a defect to rework (kit/docs/TESTING.md "Flaky cases"), never a budget to raise or a case to switch off.

## Acceptance
- Reproduced first: a loop that runs `mess_settle` (by case, in order and reversed) until it fails, with the failing
  Sock's id and its track (position, speed, contacts) written to a log; the cause written up in the Built log.
- Fixed in the Mess (or the physics setup), not by loosening a check: 50 runs of the whole `mess_settle` suite with no
  FLAKY and no FAIL, counted in the Built log.
- If the fix is the floors' thickness or a Jolt setting, it is the lead's call: stop with a [blocking] follow-up naming
  the options and their cost.
- coop/07's and coop/08's co-op cases and budgets still pass.
