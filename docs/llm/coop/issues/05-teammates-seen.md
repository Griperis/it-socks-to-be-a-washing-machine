---
type: ticket
status: needs-info
kind: build
area: core
feature: coop
priority: next
created: 2026-11-22
done:
blocked_by: ["[[03-host-join-roster]]", "[[04-avatar-model]]"]
notes: ["M0.6 batch 2 (Q2436); look and feel: one round on how it moves before it is handed out (designer-grilling rule 10)"]
terms: [Teammate, Avatar, HoldPoint]
---

# Teammates seen and heard

Everything a player sees and hears of another player: the body following every frame with light easing,
head look, crouch, waddle and squash, pupils, the held item at the HoldPoint, the Teammate's colour and
name tag, the Teammate's sounds and footsteps at their body.

## Behaviour list
`docs/migration/m06-lists/02-teammates-seen.md` (approved, Q2460), with: easing 12/s, crouch 6/s (Q2450);
a snap over 1 m (Q2451); steps and land as the local player's clips in 3D, full up close, 3 m to 20 m, a
step every 1.4 m (Q2452); pick, pair, drop, shelve, throw as loud as the local player's, 3D at 1.2 m over
their feet (Q2453); no held turn or zoom shown (Q2454); pupils follow the nearest player (Q2455); a
Teammate's Throw leaves the hand at once (Q2439).

## Design
To be written by the lead before hand-out (the pose properties on the Avatar's synchronizer every frame,
the follow, the motion-derived Looks animation, the worn held view, the 3D teammate sounds).

## Acceptance
- (written with the design)

## Answers
- Q2439, Q2450-Q2455, Q2460 (2026-11-22).
- Look and feel (rule 10): every old motion with the old numbers (Q2461); name tag "Player" in their colour at the cuff top (Q2462); a far or hidden Teammate unmarked (Q2463); held things as old (Q2464). Additions nobody asked for (wind-up cue, release squash, blink, wave) are not built (list question 8: report only).

## Open follow-ups
- [blocking] The lead writes the Design and Acceptance once coop/03 and coop/04 are merged.

## Built log
