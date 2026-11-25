---
type: ticket
status: ready-for-agent
kind: feature
area: core
feature: player
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25: a fallback that puts back anyone who drops out of the map"]
terms: [Host, Guest]
---

# Anyone who falls out of the map is put back

The designer: "add fallback so if anyone would drop outside of map (some weird large number) it ports them back."
Today nothing catches a player who falls through the floor or is flung far away.

## What it does
- Each machine watches its own player's body (it owns that body; the synchronizer carries the result to the others).
  When the body is out of the map, the player is put back standing at the washer's `Spawns`, by the Roster's order,
  the same place and call the cutscene end uses (`CutscenePlayer._respawn`, `player.respawn_at`, Q745). With no
  washer (the zoo, a bare level), they go to the level's own player spawn.
- "Out of the map": below the level's lowest floor by a margin, or farther than a limit from the level's centre on
  any axis, or a position that isn't finite (NaN or inf). The numbers are a tuning Resource; placeholder values are
  50 m below and 1000 m away, and the ticket says what it picked.
- A ragdoll or knocked-down player is ended first, the same way the cutscene's respawn ends it.
- Logged once per catch as a warning, with where the body was, so a hole in the floor can be found later.
- Not in this ticket: things (Socks, Parts, held objects) that fall out. The report says whether the old game caught
  those and how many ways a thing can leave the map today, as a [later] follow-up.

## Acceptance
- Real path: in the house, the player's body is put at y = -500 (and in a second case at a NaN position). Within a
  second the player stands at a washer spawn and can move.
- Co-op: a Guest who falls is put back on the Guest's machine, and the Host sees them at the spawn.
- A player standing anywhere in the house, on any floor, on top of furniture or mid-jump is never caught. A case
  walks the floors' extremes.
- The full suite passes, nothing flaky.

## Open follow-ups

## Built log
