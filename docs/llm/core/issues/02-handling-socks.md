---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: ["[[01-zoo-movement]]"]
notes: []
terms: []
---

# Handling Socks: pick, hold, drop, Throw

Milestone M0.5. A station with loose Socks: the Hands, picking a Sock the crosshair reaches, carry capacity, dropping, the Throw. Socks at this station are few and real entities; the Mess as one bulk system comes in M3 (Q2168), but the Sock's look and its state fields are the real ones.

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
<Written from the reference in step 1; approved by the designer.>

## Design
<Step 2.>

## Acceptance
- Every change to the Hands goes through a Command answered by the Host of one (Q2212).
- A Sock's look comes from a Looks scene (graybox now); held, flying and resting are states, not code animation where an AnimationPlayer can do it (Q2213).
- Tests follow the approved behaviour list.

## Answers

## Open follow-ups

## Built log
