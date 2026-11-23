---
type: ticket
status: needs-triage
kind: build
area: core
feature: mess
priority: later
created: 2026-11-23
done:
blocked_by: [core/52-sock-generator]
notes: ["Q2525"]
terms: [Mess, Sock, Pair]
---

# A Pair's mates placed by a better distance than a straight line

core/52 places a Pair's two Socks 0.4 m to 6 m apart in a straight line (Q2525), so mates can land either side of a
wall. The old game walked the distance through the house's rooms (`reference/it-socks/game/world/sock_layout.gd`
mate distance, Q409). Improve it: walked distance (a navigation mesh or a room graph) or another rule the designer
picks. To shape with the designer when core/52 is merged.
