---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-22
blocked_by: []
notes: ["found by coop/10 (2026-11-22)"]
terms: [Mess, Sock]
---

# The heap's pour leaves two Socks resting inside each other when the zoo holds 1 or 3 extra Socks

## What happens
coop/10 added Sock records to its Knockdown station. With 1 or 3 extra Sock records anywhere in the zoo,
`mess_settle:real_path` fails with "no Sock inside (2)": after the heap station's pour, two Socks rest
inside each other. With 0 or 2 extra it passes, and coop/10 ships with 2 to dodge it. The fault is in the
Mess's settle, not in coop/10. It will hit whatever adds Socks next, and in play it is a Sock clipping
into another.

## Reproduce
On main after coop/10's merge, set the Knockdown station's Socks to 3 (or add one Sock record anywhere in
the zoo) and run `mess_settle` with `--only real_path`.

## Acceptance
- The cause is found and written up in the Built log: which step lets two resting Socks overlap, and why
  the count of earlier records changes it (the order of ids, the wait queue, a shared seed?).
- Fixed in the Mess, not in the station: `mess_settle:real_path` passes with 0 to 4 extra Sock records,
  run as a case over those counts.
- The Knockdown station goes back to 3 Socks if the old list says 3 (coop/10's note).
- coop/07's and coop/08's co-op cases and budgets still pass.

## Answers

## Open follow-ups

## Built log
