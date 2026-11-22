---
type: ticket
status: ready-for-agent
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

## Built log
