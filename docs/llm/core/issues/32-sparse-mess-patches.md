---
type: ticket
status: wontfix
kind: build
area: core
feature: core
priority: next
created: 2026-11-21
done:
blocked_by: ["[[31-mess-benchmark-and-settling]]"]
notes: ["done by coop/07 (changed records only), closed 2026-11-23"]
terms: []
---

# Sparse Mess patches (M0.6)

The M0.5 code review: every Mess patch carries the whole `states` and `poses` arrays (`game/mess/mess.gd:318-353,
447, 469`), and `game/parts/session.gd:224` sends the whole event to each Guest by reliable RPC. At 2,000 Socks one
rest is about 98 KB on the wire, up to about 0.8 MB per tick per Guest with `stop_cap` 8; on the Host each Command
makes about four O(N) copies. Make patches carry only the Socks that changed (`{"set": {sock: [state, pose]}}`,
applied by a `Mess.write` override), with core/31's bench showing the cost before and after. Touches the Part
contract and `Session.PROTOCOL`: shaped with M0.6's co-op work.

## Acceptance
- To be shaped with M0.6.

## Answers
- Sparse patches come with M0.6 (Q2404, 2026-11-21).

## Open follow-ups

## Built log
