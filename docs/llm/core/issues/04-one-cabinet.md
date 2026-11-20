---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: ["[[03-pairing]]"]
notes: []
terms: []
---

# One Cabinet: Doors, Drawers, shelving a Pair

Milestone M0.5. A station with one Cabinet: its Doors and Drawers open (an AnimationPlayer in Looks, as the kit's example cupboard does), a Pair is shelved by a click and by a Throw. This closes the core: movement, handling Socks, pairing, one Cabinet (Q2208).

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
<Written from the reference in step 1; approved by the designer.>

## Design
<Step 2.>

## Acceptance
- The Cabinet is an entity: behaviour plus a Looks scene with a `looks_contract.json`; `kit/tools/asset_lint.py` passes.
- Shelving by click and by Throw both work and are tested; what is refused is tested.
- The designer plays the four stations in one run of the zoo.

## Answers

## Open follow-ups

## Built log
