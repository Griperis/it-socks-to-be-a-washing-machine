---
type: ticket
status: needs-triage
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-23
blocked_by: []
notes: ["found by house/09 (2026-11-23)"]
terms: [Mess, Sock, Heap, Hands]
---

# Picking the top Sock of a Heap in the kitchen never reaches the Hands

## What happens
house/09 changed the laying, and the kitchen real-path case then aimed at the top Sock of a Heap. The pick
never reached the Hands. house/09 switched the case to a Sock lying on the floor and did not look into why.
In play this may be a Sock on a Heap that cannot be picked up.

## Reproduce
On main after house/09's merge, point the kitchen real-path case (house suite) back at the top Sock of a Heap
and run it alone.

## Acceptance
- Reproduced first; the cause is written up in the Built log (the aim ray, the Heap's bodies, the pick filter?).
- Fixed: a Heap's top Sock can be picked through the real input path; a case covers it.
- The kitchen real-path case may go back to the Heap pick if that is the truer path.
