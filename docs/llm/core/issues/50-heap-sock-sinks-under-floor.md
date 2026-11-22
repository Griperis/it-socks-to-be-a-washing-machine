---
type: ticket
status: done
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-22
blocked_by: []
notes: ["found by core/49 (2026-11-22); a FLAKY case is a defect to rework (kit/docs/TESTING.md)"]
terms: [Mess, Sock]
---

# A Sock in the heap sinks 116 mm under the floor, then is lifted while still moving

## What happens
In about 1 of 30 heap pours (`mess_settle:real_path_2` run in reverse order, once also with a 5 mm slop),
one Sock is pressed 116 mm under the floor by the heap. The rest rule then lifts it back up while it is
still moving, and the watch reports it as "hot" and "jumped". The case passed on its rerun, so it shows
as FLAKY. In play, a Sock would vanish into the floor and pop back up.

## Reproduce
On main (d2b9087 or later), run `mess_settle` reversed, repeating `real_path_2` until it fails. The
pour's places are seeded, so log the Sock's id and tick once it is seen.

## Acceptance
- The cause is found and written in the Built log: what lets a lying or falling Sock get 116 mm through
  the static floor (the floor's thickness, a Sock pushed out of a body, the wait queue, a body started
  inside the floor?), and why the rest rule lifts a moving Sock.
- Fixed in the Mess, not hidden in the test: no Sock is ever under the floor, and the rest rule never moves
  a Sock that is still moving. `real_path` at 0 to 4 extra records, in order and reversed, run repeatedly
  with no FLAKY line.
- core/49's counts and coop/07's and coop/08's co-op cases and budgets still pass.

## Answers

## Open follow-ups
- [later] The cause is Jolt's, and two project-wide Jolt settings each stopped it in a replay of one
  falling Sock: `physics/jolt_physics_3d/simulation/speculative_contact_distance` 0 (default 0.02) and
  `physics/jolt_physics_3d/collisions/collision_margin_fraction` 0.5 (default 0.08). A floor 0.4 m thick
  or more also stopped it. The Mess's guard is enough; whether also to change a setting (it changes how
  every body in the game touches) or to build floors at least 0.4 m thick is the designer's call.
- [later] With speculative contacts at 0, a heap showed other jumps, on the heap station's table and
  slope (0.1 m sideways, 0.02 m to 0.13 m): not looked into, as that setting is not used.

## Built log
- 2026-11-22
  - Changed: the cause is found. Reproduced on main 4ab5ab4: `mess_settle` reversed fails every run (in one
    process, `--jobs=1`, every real path; shared over processes, one or two of them). Jolt's position solve,
    not a Sock's motion, moves a Sock touching the zoo's 0.2 m floor 0.17 m to 0.24 m down in one step
    (Sock 2047 of `real_path_3`: 0.21 m and 25 degrees in one step at 0.08 m/s). Its leg or foot is then past
    the floor's middle, the floor's bottom face is nearest, and Jolt holds the Sock there (lowest point at
    the floor's bottom, -0.2 m). The rest rule then lifts it onto the floor: "jumped"; a pressure rest
    (`_relieve`, speed under 0.3 m/s, any turn, or one stopped by a hit that tick) is how it was also "hot".
    Not the wait queue, not a body made inside the floor, not a Sock pushed out of another. Replays of the
    captured bodies alone: the push needs Jolt's speculative contacts (gone at a distance of 0), a 1 mm floor
    margin made it happen to one lone falling Sock, a 0.4 m or 2 m floor and a larger margin fraction never
    (Open follow-ups). The fix, in the Mess (`MessMoving._pushed_in`): each tick a flight that moved farther
    than its speed and turn explain by more than `push_slack`, with the middle of its leg or foot inside the
    house, goes back to its place before the step, `push_lift` (10 mm) higher, its fall and turn stopped (at
    the very same place Jolt pushes it in again, every step). A pressure rest never moves a Sock (one the rule
    would lift flies on) and takes none that moved at the pressure speed the step before. `MessWatch` counts
    `under` (a moving Sock's leg or foot middle more than 50 mm under the floor), a fault of the suite and
    the benchmark. New cases: `real_path_thin_floor` (the real path with the floor's margin at 1 mm: without
    the fix 6 under and 4 jumped every pour) and `pushed_in`.
  - Files: `game/mess/mess_moving.gd`, `game/mess/mess_tuning.gd`, `game/debug/mess_watch.gd`,
    `game/debug/mess_checks.gd`, `game/debug/mess_bench.gd`, `game/debug/mess_bench_report.gd`,
    `tests/mess_settle_test.gd`, `docs/architecture/mess.md`.
  - Verified: `--touched` (45 suites, coop/07's and coop/08's included): `PASS 16227 checks, 409 cases`;
    `mess_settle` six times, in order and reversed, and twice reversed in one process: `PASS 199 checks, 20
    cases` each, no FLAKY; `PASS rules: 9 rules, no new hit`. core/49's counts at rest: sunk 0 to 7 (deepest
    20 mm), none under, none jumped.
