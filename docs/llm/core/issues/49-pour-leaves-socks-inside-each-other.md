---
type: ticket
status: done
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-22
blocked_by: []
notes: ["found by coop/10 (2026-11-22)"]
terms: [Mess, Sock]
---

# The heap's pour leaves two Socks resting inside each other when the zoo holds 1 or 3 extra Socks

## What happens
coop/10 added Sock records to its Knockdown station. With 1 or 3 extra Sock records anywhere in the zoo,
`mess_settle:real_path` fails with "no Sock inside (2)": after the heap station's pour, two Socks rest
inside each other. With 0 or 2 extra it passes, and coop/10 ships with 2 to dodge it. The fault is in the
Mess's settle, not in coop/10. It will hit whatever adds Socks next, and in play it is a Sock clipping
into another.

## Reproduce
On main after coop/10's merge, set the Knockdown station's Socks to 3 (or add one Sock record anywhere in
the zoo) and run `mess_settle` with `--only real_path`.

## Acceptance
- The cause is found and written up in the Built log: which step lets two resting Socks overlap, and why
  the count of earlier records changes it (the order of ids, the wait queue, a shared seed?).
- Fixed in the Mess, not in the station: `mess_settle:real_path` passes with 0 to 4 extra Sock records,
  run as a case over those counts.
- The Knockdown station goes back to 3 Socks if the old list says 3 (coop/10's note).
- coop/07's and coop/08's co-op cases and budgets still pass.

## Answers
- Q2499 (designer, via the lead, 2026-11-22): (c). Socks pressed up to 20 mm into each other under a heap (Jolt's
  default slop) are accepted and only counted; `penetration_slop` stays as it is and no rest rule is added. The
  test tells the two cases apart: a Sock made inside another by the spout never happens (a fault); a Sock resting
  pressed into another is allowed and counted.

## Open follow-ups
- [answered, Q2499: (c), accept and count] Socks pressed into each other under the heap. With the pour fixed, a
  second, rarer way was left: two Socks that start apart are pressed about 20 mm into each other by the heap's
  weight while still falling, and rest so (Jolt's `penetration_slop`, 20 mm by default; a Sock is 26 mm thick).
  Trial at 5 mm (not kept): 0 of 10 runs with one inside, none sunk.
- [later] The Knockdown station keeps 2 Socks: neither coop/10's ticket nor its old list
  (`docs/migration/m06-lists/04-knockdown.md`: the old game had no knockdown station) says 3.
- [later] A rarer fault of the heap, not an overlap: in 1 of about 30 heap pours run today (`real_path_2` in
  reverse order, at the default slop; once also in the 5 mm trial) one Sock is "hot" and "jumped": pressed 116
  mm under the floor, then lifted by the rest rule while still moving. The pour's places differ with this fix,
  so which run meets it differs too; it was not looked into here (FLAKY on its rerun).

## Built log
- 2026-11-22
  - Changed: the cause is found. The heap's spout picks a wave's places (up to `per_tick`, 40, a tick) one
    after another, each tried with a physics query, and asks for them as one `add`; the query sees only bodies
    already made, never the earlier picks of the same wave, so two Socks of one wave could be made inside each
    other. They then fall touching each other from their first tick (4 contacts each at 2 m up) and rest stuck
    together: Jolt keeps a contact made deep and never parts the two thin boxes. Reproduced with 3 extra
    records: Socks 2082 and 2093, picks 0 and 11 of the tick-7 wave, 7.7 cm apart, rest inside each other. The
    count of earlier records does not change the pour (the spout's seeded dice give the same places; that same
    pair is made inside each other with 2 extra records too): it changes the ids, so Jolt's order and the heap's
    tumble, and with it whether the stuck pair is pulled apart on landing (with 0 or 2 it was, by luck). The fix:
    the spout also tries each place against its wave's earlier picks (`MessBodies.boxes_meet`, a box-box
    separating-axis test in the Mess's code; `HeapSpout._meets`). A second, rarer way is left and needs the
    designer: Socks pressed into each other within Jolt's 20 mm slop (Open follow-ups). Cases: `real_path_1`
    to `real_path_4` (the real path with 1 to 4 more Sock records in the zoo) and `wave_places`.
  - Files: `game/mess/mess_bodies.gd`, `game/zoo/heap/heap_spout.gd`, `tests/mess_settle_test.gd`,
    `docs/architecture/mess.md`.
  - Verified: `FAIL 1 of 16184 checks, 406 cases` (agent_finish refused: `mess_settle:real_path_3: no Sock inside
    (1)`, the slop's way, Open follow-ups); `PASS rules: 9 rules, no new hit`. An earlier `--touched` (45 suites):
    every case passed but `coop_join:join` (its ENet host not made, a port taken; alone `PASS 192 checks, 6 cases`)
    and `mess_settle:real_path_2` FLAKY ("no Sock inside"). The code (the four files above) waits uncommitted in
    the branch's worktree until the [blocking] question is answered; this commit holds the ticket alone.
- 2026-11-22 (Q2499)
  - Changed: the test tells the two cases apart. `MessWatch` counts `made_inside`: a new Sock (a record that never
    lay) whose leg or foot overlaps a moving Sock's deeper than `MessChecks.made_inside` (3 mm) on the tick it is
    first seen, by the sharp boxes' depth (`MessBodies.overlap_depth`). It is a fault in the suite and the
    benchmark. The survey measures how deep each lying Sock overlaps its neighbours: from `pressed` (6 mm) it is
    pressed, deeper than `inside` (22 mm) it is inside. Both are only counted in the suite (Q2499); the
    benchmark keeps inside as a fault. Without the spout's fix every real-path count fails with about 110 Socks made
    inside; with it none. The counts, `real_path` at 0 to 4 extra records, two runs (in order, reversed): pressed
    198/208, 240/194, 184/173 (one run of the two), 198/176, 207/202 of about 500 Socks, the deepest 20.0 to 21.7 mm;
    inside 0 to 6 a run (deepest 29.0 mm: the sharp boxes at a slanted edge, which Jolt's rounded box edges meet
    less deep; Jolt's own `collide_shape` points gave no usable depth). New cases: `made_inside`; `survey` also
    counts a pair pressed 12 mm as pressed, not inside. Knockdown stays at 2 Socks.
  - Files: `game/debug/mess_watch.gd`, `game/debug/mess_checks.gd`, `game/debug/mess_bench.gd`,
    `game/debug/mess_bench_report.gd`, `game/mess/mess_bodies.gd`, `game/zoo/heap/heap_spout.gd`,
    `tests/mess_settle_test.gd`, `docs/architecture/mess.md`.
  - Verified: see the commit's `suite:` line. `mess_settle` alone: `PASS 172 checks, 18 cases` in order; reversed,
    the same with one FLAKY (`real_path_2`: hot 1, jumped 1, Open follow-ups).
- Merged: 897167c1 (2026-11-22, branch core/49-pour-leaves-socks-inside-each-other)
