---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[09-hand-details]]"]
notes: []
terms: []
---

# Batch 1 fixes: the Throw leaves from the hand, the pairing ring around the ball, readable signs

Found by the designer playing batch 1 (2026-11-20), reproduced by the lead.

## Faults
- F1 **The Throw starts at the eyes.** The designer: "the sock should be thrown from the hand position". Reproduced in
  `builds/review-core-09/cloth-strip.png`: f225 the Sock hangs low right in the hand; f234, just after the release, it
  is big in the middle of the view (the flying body starts at the eyes and is drawn there). The old game: the body
  flies from the eyes but the drawn Sock starts in the hand and joins its body over `catch_up` 0.1 s
  (`reference/it-socks/game/hands/thrown_item.gd:180-250`, `data/tuning/release.json`). Fix: what the player sees
  leaves from where the Sock hung in the hand and joins the flight; check the drop too.
- F2 **The pairing moment's ring scales around the wrong point.** The designer: "the pair mechanic has wrong scaled up
  effect (it should scale around the sock only)". Reproduced in `builds/review-core-19/before-pair-ring.png`
  (f120-f124): the ring grows into a circle around the middle of the screen, not around the new ball. Fix: the ring and
  the burst scale and sit around the ball (the pairing moment's own place), as the old `paired_moment.gd` did; check
  the pop's scale too.
- F3 **The station signs cover the view up close.** Since they wrap at 3 m (core/04 merge), the handling sign is a tall
  block of text that fills the view near the station (same strip). Fix: keep the words, make each sign readable without
  covering the view (smaller text, higher, or placed at the pad's back edge); the zoo-design skill says a `Name`
  Label3D says what to try.

## Acceptance
- One case per fault on the real path (the throw from the handling station: the first frames of the drawn Sock are near
  the hand; the ring's centre stays on the ball; the sign does not cover the view's centre from the station's pad).
- Before and after strips in `builds/review-core-19/` for F1 and F2, a still for F3; the ticket goes ready-for-human.

## Answers

## Open follow-ups

## Built log
- Model: Opus (lead): debugging looks across the held view, the flight and the pairing moment.
