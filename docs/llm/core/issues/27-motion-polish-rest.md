---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: ["[[16-feedback-and-motion-polish]]"]
notes: []
terms: []
---

# The rest of the motion polish

M0.5 batch 5, split from core/16 on the designer's word (Q2398, 2026-11-21: "Rest can come as a separate ticket").
The behaviour lines are core/16's (approved there with Q2366-Q2370); read `16-feedback-and-motion-polish.md` for the
old code and numbers of each.

## Behaviour list
- P03 The held Size box follows the held Sock's cloth sway, as the old readout did (fitting core/15's held readout).
- P08 A thrown Sock leaves with the bend it had in the hand (core/23 left the flying Looks straight; Q2315).
- P10 A shelved Pair lands in its slot with P04's squash, hop and roll (Q2316).
- P11 A Pair thrown at a drawer front flies on to its slot (Q2316).
- P14 Two fusing Socks curl along their cloth bones, curl 1.3, in the fold (Q2281).
- P15 The Door swings 0.6 s eased in and out; the cupboard 0.35 s eased out (Q2368).
- F1 First: fix the FLAKY `sound_wiring:w10_gap` (a defect, `kit/docs/TESTING.md` "Flaky cases"): find the race and
  rework the case or the code; it must pass 20 runs in a row, also reversed.

## Acceptance
- One case per line; the real-path cases through the zoo's stations.
- A review sheet of P03, P08, P10, P11, P14 and P15 in `builds/review-core-27/`, stopped at it for the designer's go.

## Answers
- Split from core/16 (Q2398, 2026-11-21).

## Open follow-ups

## Built log
- Model: Opus (lead): cloth, flights and the pairing moment's animation.
