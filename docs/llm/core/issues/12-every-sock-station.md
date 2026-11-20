---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[10-one-mess-for-the-zoo]]"]
notes: []
terms: []
---

# The every-Sock station

A zoo station that lays out every Sock of the game on the ground (Q2290), at the end of the zoo. With one Mess for the
zoo (core/10), Designs repeat across stations; this station shows the whole catalogue in one place.

## Behaviour list
From the designer's answers (Q2290, Q2294, Q2295).
- E01 The station lays out both Socks of every Design in `game/sock/designs.tres` (about 1,000 Designs, so about
  2,000 Socks) in rows by Collection, one row (or block of rows) per Collection with the Collection's name at its
  start, the Designs in id order, each Sock beside its mate.
- E02 In front of each Sock lies its info as text: the Design's id, name, Collection, Size and rarity (the first still
  shows the wording; the designer may change it).
- E03 The Socks are real Socks of the zoo's one Mess: you can pick, pair, throw and shelve them like any other.
- E04 The zoo is never saved and always starts fresh: nothing of this station (or any station) is written to a save,
  and each start lays every Sock back in its place.
- E05 It stands at the end of the zoo, off the grid, clear of the other stations' pads (the zoo test's check); the
  zoo's floor grows to hold it if it must.
- E06 A new Design added to `designs.tres` appears at the station with no other change (the layout is made from the
  catalogue, not placed by hand).

## Design
To be drafted by the agent here first, then built. Points to settle in the draft:
- Making about 2,000 SockSpots and labels from the catalogue: an `@tool` builder that writes them into the station
  scene, or the station placing them in `_enter_tree` before the Mess binds; either way the same order on every
  machine (Sock ids, co-op), and the station runs alone.
- Cost: about 2,000 lying Socks and 2,000 labels in one zoo. Measure the zoo's frame time and load time before and
  after (F3 overlay or the bench) and report them. A label may be one `Label3D` per Sock, or a cheaper way if the
  numbers say so.
- Where the zoo is saved today (if anywhere) and how E04 is held.

## Acceptance
- One test per behaviour line; the real-path case: the player walks to the station, picks a Sock and its mate and
  they pair.
- The zoo's frame time and load time before and after, in the report.
- A still of the station (an overview and a close-up of one row with its labels) in `builds/review-core-12/`, stopped
  for the designer's go.

## Answers
- Designs may repeat across stations; this station shows every Sock (Q2290, 2026-11-20).
- Rows by Collection, the name at the start, Design order, each Sock beside its mate (Q2294, 2026-11-20).
- Real Mess Socks; the zoo is never saved and always starts fresh; each Sock's info as text in front of it (Q2295,
  2026-11-20).

## Open follow-ups

## Built log
- Model: Sonnet (lead): layout and data from the catalogue, no new rules.
