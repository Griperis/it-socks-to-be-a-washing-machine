---
type: ticket
status: needs-info
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

## Open follow-ups
- [blocking] Socks pressed into each other under the heap. With the pour fixed (Built log), a second, rarer way
  is left: two Socks that start apart are pressed about 20 mm into each other by the heap's weight while still
  falling, and rest so. Jolt lets bodies overlap by its `penetration_slop`, 20 mm by default, a Sock being 26 mm
  thick; the suite's "inside" line (a Sock's middle 6 mm or less from another's) sits right at that limit. It is
  the same cause as the sunk Socks (Q2412 "leave it"; Q2423 left the slop as is). Measured on the five
  `mess_settle:real_path` cases (0 to 4 extra Sock records), two runs each: at 20 mm, 3 of 10 had 1 or 2 Socks
  inside another (some FLAKY: the heap differs with the run order); with the slop at 5 mm (a trial, not kept),
  0 of 10 inside and 0 sunk (before: 1 to 3 sunk, up to 21 mm), with one "jumped" in one run. Which: (a) lower
  `physics/jolt_physics_3d/simulation/penetration_slop` to 5 mm in `project.godot` (every body of the game
  settles tighter; core/31's trial: same tick cost, the heap settles faster); (b) a rest rule moves a Sock that
  rests inside another out of it (a snap of up to 2 cm); (c) accept it: then "inside" is counted and not held at
  none, like sunk and flips. Until answered, `mess_settle:real_path` and its count cases can fail or be FLAKY
  with "no Sock inside".
- [later] The Knockdown station keeps 2 Socks: neither coop/10's ticket nor its old list
  (`docs/migration/m06-lists/04-knockdown.md`: the old game had no knockdown station) says 3.

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
