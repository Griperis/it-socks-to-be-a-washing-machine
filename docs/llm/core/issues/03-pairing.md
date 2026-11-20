---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: ["[[02-handling-socks]]"]
notes: []
terms: []
---

# Pairing: two mates become a Pair

Milestone M0.5. A station where two matching Socks become a Pair, by the old game's rules (hand-off, in the Hands, what is refused and what it says).

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
From `docs/migration/behaviour-core-loop.md` rows P01-P12, H04, H12 and the survey's Pairs questions (part 6,
answered by approving this list: today's behaviour is kept). Ids are the survey's. Numbers are today's values,
placeholders until the designer sets them. Built on core/02's `Mess` and `Hands` (and core/08's Throw for P07's
thrown Pair).

**Forming a Pair**
- P01 When you pick a Sock and hold its loose mate (same Design), then the two fuse at once into one Pair in your
  Hands, which becomes the active item and takes one place.
- P02 When your Hands are otherwise full and you pick the mate of a held Sock, then it still fuses (the Pair uses
  the mate's place). This is H04's exception: "Hands full" is never shown for a mate.
- P03 When a Sock is not the mate (another Design), then it never fuses; a held Pair never takes a third Sock.
- A held Pair is never split back into two Socks (survey question 2, kept).

**How it looks**
- P05 When a Pair forms, then the picked Sock flies to the held one, they line up, fold and roll into a sock ball
  that pops with a sparkle burst in the Collection's colour and a ring (0.5 s), once per pairing; picking up a
  whole Pair plays none; dropping a Pair mid-moment ends it. (Sounds: the first audio ticket.)
- P06 When a Pair is held, then it is drawn as one sock ball (the old `ball_*.glb` models, tinted as the Sock).

**A Pair on the floor**
- P07 When you drop (or, with core/08, throw) a Pair, then it lies as a sock ball where it lands, pickable again
  once settled; a Sock dropped on it rests on top or beside it, never inside.
- H12 When you aim at a Pair lying on the floor and click, then it goes back into your Hands as a Pair if there is
  a free place, else it stays ("Hands full").
- P08 When what a floor Pair rests on is taken away (the Sock under it picked), then the Pair falls like a drop and
  lands; a Pair beside it stays (survey question 3, kept).

**Invariants**
- P09 / I.1 When a Pair or Sock is picked, then it is nowhere else; two Socks become one Pair and never more or
  fewer: the count per Design stays two.
- I.4 Pairs form only in one player's Hands, only from two Socks of one Design.
- Floor Pairs are records in the same `Mess` (one id space, one snapshot), not nodes (co-op structure, section 2).

**Not in this ticket**
- Co-op, M0.6: halves held by two players never pair (P04); Hand-off and catch completing a Pair (survey question
  1, kept: only a completing Sock or a Pair goes); a teammate sees a small burst, not the full moment (survey
  question 4, kept); a leaver's Pair lies where they stood (P10).
- Shelving and its Coins (P11): core/04.
- Dirty Socks never fuse (P12): the laundry feature, M5.

## Design
<Step 2.>

## Acceptance
- Pairing is decided by the Host's answer; a refusal says why.
- Tests follow the approved behaviour list, the refusals included.

## Answers
- The behaviour list is approved as written (Q2254, 2026-11-20).
- The pairing moment stays as the old game has it (fly, line up, fold, roll, sparkle in the Collection's colour,
  ring, 0.5 s), built as an AnimationPlayer in the Looks with a GPU particle burst; a strip of its frames is shown
  before merging (Q2255, 2026-11-20).

## Open follow-ups

## Built log
