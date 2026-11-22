---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: next
created: 2026-11-22
done:
blocked_by: ["[[39-pushed-out-of-a-shut-leaf]]"]
notes: []
terms: [Throw, Sock, Mess]
---

# A Throw shoves the Socks it hits

Today a thrown Sock's hit is judged on its flight's first contact, so the lying Socks it hits wake one step after
the bounce and drop where they lie. The old game woke them just before contact, so the thrown Sock pushed them
(core/08 T11 follow-up). The designer wants the old shove.

## Acceptance
- A thrown Sock or Pair about to hit lying Socks wakes them before the contact (a look-ahead along its motion, as the
  old game did; find the old rule in `reference/it-socks/`), so the contact moves them.
- The real-path case: in the handling or heap station the player throws a Sock into lying Socks with the Throw input;
  the hit Socks move away from the thrown one in the hit's direction (not straight down).
- A resting Pair is still never moved by a hit (Q2330).
- `tools/mess_bench.sh --only=burst_16,sweep` (two runs, timeout 900): no worse tick beyond noise; numbers in the
  Built log.

## Answers
- A Throw wakes the lying Socks it is about to hit just before contact, as the old game (Q2431, 2026-11-22).

## Open follow-ups
- [blocking] `burst_16` costs more. A Throw now pushes the Socks it meets and keeps going, so it wakes more of the
  heap: moving peak 124 against 52, wakes 37/s against 15/s. Physics tick p95 is 1.79/1.87 ms against 1.00/1.05 ms
  on `main` (worst 2.17/2.22 against 1.14/1.30), still far under the 8 ms budget. That breaks "no worse tick beyond
  noise". Is that cost all right, or should a Throw wake fewer (for example only its first look-ahead hit, as one
  hit per Throw)?
- [later] The push is small on screen with today's numbers. The hit Socks get 0.48 m/s (Heap) to 0.95 m/s (table
  Sock) along the hit, where before they got none, but they end only 0.3 to 9 mm along it. The Throw's arc comes
  down steeply on flat Socks, so most of the push goes down and into spin, and the woken friction (0.9) stops the
  slide. Same rule and same numbers as the old game (Q1215: Jolt alone, no extra force). Does the designer want a
  bigger scatter (that would be a look-and-feel number)?

## Built log

### 2026-11-22
- Changed: a thrown Sock or Pair (not dropped, poured or woken) at `wake_speed` or more looks ahead every tick: the
  lying Socks in a `hit_reach` (0.12 m) sphere `hit_lead_ticks` (2) ticks along its motion wake, with up to
  `wake_count` touching them, before the contact (the old `SockFlights._impact_wakes`). The contact rule stays for
  everything else. Resting Pairs are still never woken (Q2330). Two new HandsTuning numbers (old values, placeholders).
  Before the change, in the handling station, the hit Socks woke after the bounce with no push (0.000 m/s along the
  hit). After: 0.48 m/s (Heap) and 0.95 m/s (table Sock).
- Files: game/mess/mess_moving.gd, game/hands/hands_tuning.gd, tests/throw_test.gd (t11_shove),
  docs/architecture/mess.md
- Bench (`--only=burst_16,sweep`, two runs each, tick median/p95/worst ms): branch burst_16 0.490/1.790/2.166 and
  0.505/1.866/2.218 (moving peak 124); main 0.452/1.000/1.141 and 0.511/1.050/1.298 (moving peak 52). Branch sweep
  0.755/1.327/2.504 and 0.538/1.215/2.225; main 0.784/1.350/3.002 and 0.713/1.204/2.457 (noise). The burst cost is
  the one open follow-up.
- Verified: see the commit's `suite:` line
