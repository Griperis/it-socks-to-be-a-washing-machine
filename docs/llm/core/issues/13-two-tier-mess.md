---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[09-hand-details]]"]
notes: []
terms: []
---

# The two-tier Mess

Milestone M0.5 (batch 2). The every-Sock station (core/12) put about 2,000 lying Socks in the zoo, each a full Looks
scene of about 20 nodes: the physics tick went from 3 ms to about 40 ms. The port always meant the Mess to be the old
game's two tiers rewritten clean (Q2168, `docs/migration/coop-structure-for-the-port.md` section 5); the designer
settled its shape (Q2301, Q2305-Q2311). Old code: `reference/it-socks/game/world/` (`sock_world.gd`,
`sock_bodies.gd`, `sock_colliders.gd`, `sock_drawing.gd`, `sock_draw_group.gd`, `sock_flights.gd`, `pair_wakes.gd`),
`docs/adr/0008-two-tier-socks.md`; tuning `data/tuning/mess.json`, `release.json`, `upgrades.json` (throw).

## Behaviour list
From the designer's answers; every approved line of core/02, 03, 04, 08 and 10 still holds.

**Two tiers** (Q2305, Q2309, Q2310)
- M01 A lying Sock costs nothing per tick: a static collider (two boxes, leg and foot; a Pair a sphere) made in the
  physics server, and one instance in a MultiMesh; no node per Sock. The crosshair hits it and falling Socks land on it.
- M02 Lying Socks are drawn in MultiMeshes grouped by an 8 m floor grid (placeholder), with Godot's automatic LOD and
  visibility ranges; each instance tinted by its Design as today.
- M03 Only where it matters is a Sock a full Looks scene: the aimed Sock (its outline), held Socks, and the flying Socks
  that get cloth (core/09's `flying_cap`). A Sock goes between the two without a visible pop.
- M04 With the every-Sock station in the zoo, the physics tick stays near the zoo's old cost (before core/12, about
  3 ms headless); measured before and after and reported.

**Moving** (Q2306, Q2308, Q2311)
- M05 A moving Sock is a physics body counted against the moving budget: 512, 32 of it reserved for Throws; extra
  wakes wait in a queue and start nearest the players first; at most a set number start and stop per tick; under
  pressure the slowest Socks farthest from the players rest first (all numbers the old game's, placeholders until a
  stress test).
- M06 A moving Sock comes to rest once it has stopped moving (under the old rest speed and spin) for a short time; there
  is no limit on a flight's total time (Q2308).
- M07 When a Sock or Pair is picked, the lying Socks just above it (found by a physics query at that moment, no stored
  support links, Q2307) wake and fall, up to 40, Socks and Pairs alike.
- M08 When a body at 1.5 m/s or more hits a lying Sock, then that Sock and up to 8 touching it wake.
- M09 When a Door swings or a drawer slides, then the lying Socks in its way wake and are pushed; Socks inside a drawer
  ride out with it.
- M10 Thrown and dropped bodies bounce (restitution 0.35) and slide (friction 0.6); a woken Sock is damped 0.6 linear,
  3.0 angular; a dropped Sock 0.05 / 0.8. The Throw's spin stays the same each time and a thrown Pair keeps its drag
  (Q2311, kept).

**Invariants**
- The records, the Part, the Commands and the snapshot do not change shape; a Guest and a late joiner see the same
  Mess (M0.6 tests it).
- Every Design still has its records; pairing, shelving and the every-Sock station play as before.

## Design
To be drafted by the agent here first (the classes and who owns what, the physics-server bodies, the MultiMesh groups,
how a Sock moves between the tiers and how the Looks scene is borrowed for the aimed or held Sock, the budget), then
built. Code shape Q2251-Q2253; Godot's own nodes and servers wherever they do the job. Ask in the report about any
choice of play.

## Acceptance
- One test per behaviour line; the real-path case: the player picks a Sock from under another at the handling station
  and the one on top falls; a throw into the every-Sock rows wakes the Socks it hits.
- The physics tick and frame time before and after, with the every-Sock station in the zoo, in the report.

## Answers
- The shape, the budget, support by query, the wake and push rules, the collider, the drawing, the physics numbers:
  Q2305-Q2311 (2026-11-20).

## Open follow-ups

## Built log
- Model: Opus (lead): a core rewrite of the Mess's bodies and drawing, physics and performance.
