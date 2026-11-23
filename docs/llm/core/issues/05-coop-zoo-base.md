---
type: ticket
status: wontfix
kind: build
area: core
feature: core
priority: next
created: 2026-11-19
done:
blocked_by: ["[[04-one-cabinet]]"]
notes: ["superseded by coop/03-coop/08 (M0.6), closed 2026-11-23"]
terms: []
---

# The co-op zoo base: a Guest and a late joiner

Milestone M0.6. The M0.5 zoo played by a Host and Guests (`-- --host`, `-- --join=`): avatars every frame with light easing (Q2223), a Guest's pick as looks only (Q2220), a Guest's Throw as a ghost that blends onto the Host's flight (Q2221), Moving Socks simulated locally and snapped to the Host's rest (Q2222), a Teammate's Throw with the old look (Q2226), a long random player id in the profile (Q2224). Read `docs/migration/coop-structure-for-the-port.md` first.

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
<Written from the reference in step 1; approved by the designer.>

## Design
<Step 2.>

## Acceptance
- Every M0.5 behaviour has cases for the Host, a Guest, a race and a late joiner.
- A Guest's prediction never writes shared state (`since-the-research.md`, lesson 2), and a test pins it.
- Two windows on one machine play the zoo together.

## Answers

## Open follow-ups

## Built log
