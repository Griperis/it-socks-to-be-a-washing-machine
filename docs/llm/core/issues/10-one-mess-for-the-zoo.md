---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[04-one-cabinet]]"]
notes: []
terms: []
---

# One Mess and one Hands for the zoo

Milestone M0.5. core/04 gave the Cabinet station its own `Socks` (Mess, Hands, Coins) beside the handling
station's, and the player uses the Hands of whichever station it stands in (`game/player/player.gd:111-134`). So a
Pair made at the handling station is gone from the Hands when the player walks to the Cabinet. The designer wants one
Mess and one Hands for the whole zoo (Q2284), as the house will have one per level (M2).

## Behaviour list
From Q2284; no line of an approved list changes.
- Z01 When you hold Socks or Pairs at one station and walk to another, then they are still in your Hands: a Pair made
  at the handling station is shelved at the Cabinet by a click or a Throw.
- Z02 The zoo has one Mess, one Hands and one Coins; every station's Socks are records of that one Mess, lying where
  the station places them.
- Z03 A station still runs alone (the wiring check, `zoo:alone`, each station's own real-path case): instanced
  without the zoo, it plays as it does today.
- Z04 A Sock thrown out of bounds comes back to a return spot (core/08) in the zoo's Mess as before.

## Design
To be drafted by the agent in this section first (the ownership of `Socks` between `zoo.tscn` and the stations; how
a station's SockSpots join the zoo's Mess and how a station alone gets its own; what `player.gd`'s per-station Hands
search becomes; Part ids and `PROTOCOL`), then built. Prefer the least code: what the scene-parts template and
`Parts.part_of()` already give. Code shape Q2251-Q2253. Ask in the report about any choice of play.

## Acceptance
- One test per behaviour line; the real-path case: in the zoo scene, the player pairs two Socks at the handling
  station, walks to the Cabinet station and shelves the Pair by a click.
- The touched suites pass (handling, throw, pairing, cabinet, zoo, player).

## Answers
- One Mess and one Hands for the zoo (Q2284, 2026-11-20).

## Open follow-ups

## Built log
- Model: Opus (lead): it moves ownership of the Mess and Hands across scenes, Part ids and every station's suite.
