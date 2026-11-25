---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: soon
created: 2026-11-25
done:
blocked_by: [core/101]
notes: ["suggested model: sonnet", "from core/101's [later] follow-up"]
terms: [Guest, Host]
---

# Co-op tests that click a fixed time after moving the Guest

core/101 found `coop_knockdown:real_path` clicking 15 frames after moving the Guest, while the Host judges reach by
the Guest's position as last heard (sent on a wall-clock interval, may be late). On a busy machine the Host refuses
the pick as too far. `coop_hands`, `coop_carry` and `coop_pings` move the Guest the same way and may share the race.

## Acceptance
- Each of the three suites checked: where a click follows a Guest move, it waits until the Host has the player at
  the spot (core/101's `_aim` wait), not a fixed number of frames.
- Shown by forcing the Guest's position 0.4 s late (as core/101 did): each case passes with the wait, and a case that
  had the race fails without it.
- No game code or look/feel number changed unless the game is wrong (then a [blocking] follow-up).

## Open follow-ups

## Built log
