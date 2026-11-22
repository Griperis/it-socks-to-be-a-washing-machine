---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: ["[[02-handling-socks]]"]
notes: []
terms: []
---

# The Throw

Milestone M0.5. Split from core/02 (Q2250). Holding the right button charges a Throw (a ring round the
crosshair); release throws the active item along the aim. Built on core/02's `Hands`, `Mess` and `Flight` body:
a `throw(dir, charge)` Command to `Hands`, the Host spawns the `Flight` with the Throw's speed. Co-op (the
Guest's ghost and blend, Q2221; watching a Throw, Q2226; hitting a teammate) is M0.6.

## Behaviour list
Approved with core/02's list (Q2243, 2026-11-20); the lines moved here unchanged.

**Throw**
- T01 When you hold the right button past 0.25 s with something in the Hands, then a ring fills round the crosshair
  (full in 1.2 s) and releasing throws the active item along the aim with a gravity arc; no cancel.
- T02 When a charge is released under 15%, then it is a short lob (3.5 m/s forward, 2 m/s up), not a drop.
- T03 When thrown with more charge, then it flies faster: 3 m/s at the tap to 5 m/s at full charge. The free Throw
  is weak (Long Arm and Quick Charge: M4).
- T04 When you press Q, then nothing happens.
- T07 When a loose Sock is thrown at a Cabinet, then it bounces off and lies loose again, never shelved. (With
  core/04's Cabinet.)
- T08 When a Sock is thrown, then it never ends inside a wall or furniture and always ends up lying loose.
- T11 When a Throw faster than 1.5 m/s hits lying Socks, then it wakes the Sock hit and at most 8 touching it; a
  slow drop wakes none.
- T13 When a thrown Sock comes to rest, then it lies where its body stopped; a flight that never settles is put
  down after 6 s.
- T14 When a thrown Sock leaves the playable space or goes above the ceiling, then it comes down at once and lies
  at a set return spot (in the old game, in front of the washer; in the zoo, the station's).

## Design
Built on what core/02 merged: `Hands.decide()` already grants a `drop` by changing two Parts (the Sock's record
becomes FLYING in `Mess`, its id leaves the Hands), and `Mess` already launches a Host-owned `Flight` RigidBody3D
and writes the Sock lying again with a Host-only `rest` when the body sleeps or after the 6 s limit. The Throw is
the same path with a speed. Old code: `game/hands/thrower.gd` (170 lines), parts of `flights.gd`,
`sock_flights.gd`, `game/ui/power_ring.gd`.

**On the player (looks and input only)**: the right button already times a tap for the drop. Held past `hold`
(0.25 s) with something in the Hands, `charge` runs 0 to 1 over `charge_time` (1.2 s) and the ring shows it;
release sends `throw(dir, charge)`. No cancel. A menu opening mid-charge drops the charge without a throw (the old
knockdown rule, kept for the freeze).

**The Command** `throw(dir, charge)` to `Hands`, in `accepts()` (dir a unit Vector3, charge 0..1, a rate limit):
- refused "nothing" with empty Hands; "wrong" for a bad dir or charge;
- granted: like a drop, the Sock leaves the Hands and becomes FLYING, with the launch in the answer: `from` (just in
  front of the eyes, 0.35 m ahead and 0.08 m low, pulled back so it never starts inside a wall, the old
  `_start_point`), `vel` (dir times `lerp(min_speed, max_speed, charge)`; below `tap_charge` the lob: `lob_speed`
  plus `lob_lift` up), `spin` (the old fixed (2, 1, 3) rad/s). The Host decides from and vel; a Guest's dir is
  only a direction (M0.6 reads it from the Guest's eyes).
- `Mess` launches the `Flight` at once, no flick (a drop keeps its 0.1 s flick), with the thrown damping (linear
  0.05, angular 0.8).

**T11, the wake**: the `Flight` reports its first contacts on the Host. When it hits a lying Sock faster than
`wake_speed` (1.5 m/s), `Mess` turns that Sock and at most `wake_count` (8) lying Socks touching it into FLYING
bodies (a Host-only `wake` change), and they rest again the normal way. A drop is slower than that, so it wakes
none.

**T14, out of bounds**: `Mess` gets an `@export var bounds: AABB` and `@export var return_spot: Marker3D`, set per
level in the editor (the zoo: its floor's box up to 6 m; the house later: the house and under its roof). A flying
body outside `bounds` is put down at once lying at `return_spot` (Host-only `rest` there).

**The ring**: a `Control` drawn round the crosshair, its look from the old `power_ring.gd` unless the designer says
otherwise (radius 26 px, 5 px line, a faint white track, filling from cream to orange). See the questions.

**Numbers** (`HandsTuning`, each `# placeholder:`): hold 0.25 s, charge_time 1.2 s, tap_charge 0.15, lob_speed
3.5 m/s, lob_lift 2 m/s, min_speed 3, max_speed 5 m/s, spin (2, 1, 3), thrown damping 0.05 / 0.8, wake_speed
1.5 m/s, wake_count 8.

**Tests** (`tests/handling_test.gd` is over 600 lines: the Throw goes in its own `tests/throw_test.gd`): one case per
line T01-T04, T07 (with a stand-in Cabinet body until core/04: a StaticBody on the house layer), T08, T11, T13,
T14; the I.1 count after each Throw. Real path: the handling station, real input, hold, release, the Sock lands
farther than a drop would.

**Co-op, M0.6** (not built here, nothing blocks it): the Guest's ghost and 0.2 s blend (Q2221), the Flight's
synchronizer with the stamp (coop-structure section 4, option A), a teammate catching (T09), the knockdown (T10).

## Acceptance
- The Throw goes through a `throw` Command answered by the Host of one; the flying Sock is the Host's body.
- Tests follow the behaviour lines above, one case each.
- A still of the ring mid-charge in `builds/review-core-08/` (Q2260).
- One real-path case: in `game/zoo/stations/handling.tscn`, with real input, pick a Sock, hold the right button,
  release, and the Sock lands farther than a drop would.

## Answers
- The design is approved as written (Q2259, 2026-11-20).
- The ring keeps the old look (26 px radius, 5 px line, faint white track, cream to orange, clockwise); a still of
  it mid-charge goes in `builds/review-core-08/` before merging (Q2260, 2026-11-20).
- The zoo's return spot is a marker on the handling station's pad (Q2261, 2026-11-20).
- Merge it; core/02's "a long press does not drop" check is removed, a long press throws (Q2267, 2026-11-20).

## Open follow-ups
- [moved 2026-11-22] T11: the wake is judged on the Flight's first contact, so the hit Socks are woken one step after the
  bounce and fall where they lie; the old game woke them just before contact so the thrown item pushed them. Is a
  push wanted? — Q2431: wake before contact, as the old game (core/46).
- [later] The ring's faint white track hardly shows on a light wall (`builds/review-core-08/throw-ring-close-up.png`).
  Keep the old look, or add an outline?
- [moved 2026-11-21] M0.6: a Guest's Throw leaves from `EYES_FALLBACK` (1.5 m) above where it stands, and only the local
  player's body lets its own thrown Sock through (`Mess._spare_thrower`). Both need the Guest's eyes and avatar. — to docs/migration/m06-backlog.md

## Built log
- 2026-11-20 (lead): handed to a ticket agent on Opus: a Host-owned physics body with contacts and the wake (the
  Models value: opus for hard netcode and physics debugging).

### 2026-11-20
- Changed: holding the right button past the tap with something in the Hands charges a Throw: a ring round the
  crosshair fills over 1.2 s, and a menu drops the charge. Releasing sends `throw(dir, charge)` to the Hands. The
  Host decides from and vel (the lob under 15%) and the spin, and the Mess launches the Host's Flight at once with
  the thrown drag (`throws` record). A Flight hitting a lying Sock faster than 1.5 m/s wakes it and up to 8
  touching it (Host-only `wake`). A Flight outside `bounds` comes down at `return_spot` (on the handling pad),
  and so does one that would rest inside a wall. The hold is HandsTuning's existing `tap`. The H07 long-press
  check moved here.
- Files: game/hands/hands.gd, hands_tuning.gd, physics_queries.gd, game/mess/mess.gd, game/player/player.gd,
  power_ring.gd, player.tscn, game/sock/flight.tscn, game/zoo/stations/handling.tscn, tests/throw_test.gd,
  tests/handling_test.gd, tools/shot_hooks.gd, tools/shots/sets/throw-ring.txt
- Verified: `run.sh --touched` PASS 366 checks, 74 cases; grep_rules PASS; stills
  builds/review-core-08/throw-ring-mid-charge.png, throw-ring-close-up.png
- Merged: 53cd387a (2026-11-20, branch core/08-throw)
