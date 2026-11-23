---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: coop
priority: now
created: 2026-11-23
done:
blocked_by: []
notes: ["M0.6 batch 5 (Q2534); docs/migration/milestones.md"]
terms: [Host, Guest, Mess, Throw, Hands]
---

# M0.6 close-out: lag tests, guard tests, the co-op cost, code map and review guide

The last batch of M0.6 (Q2534), as `docs/migration/milestones.md` batch 5 says, plus the leftovers found in batches 3-4.

## Acceptance
- **Lag:** the co-op real-path cases (join, avatars, Mess, Hands, Throw, knockdown) run at 0 and 50 ms one way, as one
  case each over both values; all pass.
- **Guards:** a Guest's bad-shaped Command, a flood over the rate, and a forged avatar or knockdown write are each
  refused by the Host, a case each.
- **Cost:** measured in two processes with a Guest at 2,000 Socks: bytes a second each way, the Host's frame time, the
  Guest's frame time; written in the Built log and `docs/architecture/` (the co-op file).
- **Leftovers:** a leaver's looks-only bodies removed on every machine; the leaver's drop sound; the knockdown lines
  built but not proven by a case (coop/10's Open follow-ups: F70-F71 wall gap, E53, E62/F72, H97, H101, D37 in co-op)
  get a case each where they can be made headless, else a line saying why not; the ragdoll spike's tests removed if
  superseded; the closed M0.6 lines in `docs/migration/m06-backlog.md` marked done with their ticket.
- **Docs:** the code map (`docs/architecture.md` and the co-op subsystem file) and a review guide for the designer's
  code review of M0.6 (`docs/migration/review-guide-m06.md`: what to read, in what order, what to look for).
- **The designer's run:** a short list of what to try in one co-op zoo run of every station, in the Built log, for the
  lead to hand over.
