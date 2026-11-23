---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: soon
created: 2026-11-23
done:
blocked_by: [house/04-shell-details]
notes: ["Q2515"]
terms: []
---

# The old house's lamp rules

house/04 lights every lamp at noon. The old house switched all but the basement's lamps off by day and lit each
floor only with its own lights (light layers). Port both (Q2515), by examination of the old code (grep the old
house's lights and layers in `reference/it-socks/game/house/`).

## Acceptance
- A behaviour list of the old lamp rules, every detail (Q2277), in the ticket before building; open choices to the lead.
- Built as the old: by day only the basement lamps lit; a lamp lights only its own floor.
- A look change, so no test (Q2421): a strip of each floor, old | house/04 | this ticket (`builds/review-house-06/`).
