---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[13-two-tier-mess]]"]
notes: []
terms: []
---

# The heap station

A zoo station with a real physics heap of Socks to play with (designer, 2026-11-20; Q2334-Q2336). It puts the two-tier Mess
(core/13) under load the designer can see and touch. The old game's live spill: ADR-0008 "The Mess is spilled live"
(`reference/it-socks/docs/adr/0008-two-tier-socks.md`), `reference/it-socks/game/world/sock_pour.gd`.

## Behaviour list
- H01 A spout above the station's pad pours Socks in waves; each Sock falls as a moving body under the moving budget
  and rests into the two-tier Mess as it settles (Q2335).
- H02 A click on the station's "More" button (an interactable, used like a drawer) pours one more batch of about 500
  Socks (a tuning number, Q2334): both Socks of each Design it picks, so they can be paired; Designs may repeat in the
  zoo (Q2290).
- H03 A "Respill" button clears the station's Socks and pours a fresh batch (Q2336).
- H04 A live counter sign shows how many Socks are moving, waiting for the budget and resting, and the physics time a
  tick (Q2336).
- H05 Low walls round the pad keep the heap together; a slope and a table stand in it for Socks to slide off and pile
  against (Q2336).
- H06 The poured Socks are real Mess Socks: picked, paired, thrown and shelved like any other; picking from the heap
  wakes the Socks above (M07).
- H07 New Socks during play go through the Mess's own Host path (a Host-only Command that adds records), so a Guest and
  a late joiner would see the same heap (M0.6 tests it); nothing is written to a save (the zoo is never saved).

## Design
To be drafted by the agent here first (adding and removing Mess records during play; the spout and the waves; the
buttons as Openable-like interactables or Parts; the counter), then built. Keep edits to `game/mess/` small: another
agent works in `mess.gd` (core/14) and one in `mess_drawing.gd` (core/21).

## Acceptance
- One test per line; the real-path case: the player clicks "More", Socks pour and come to rest, the player picks one
  from under another and the one on top falls.
- The physics tick while pouring and at rest, with 500 and with 2,000 poured Socks, in the report.
- A still and a short strip of a pour in `builds/review-core-20/`; the ticket goes ready-for-human.

## Answers
- Q2290, Q2334-Q2336 (2026-11-20).

## Open follow-ups

## Built log
- Model: Opus (lead): physics and the Mess under load.
