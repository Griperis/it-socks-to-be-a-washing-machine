---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-22
done:
blocked_by: []
notes: ["reported by the designer 2026-11-22 in a two-window test; pulls forward m06-backlog 'Mess patches carry the whole arrays' (coop/01 condition 3)"]
terms: [Host, Guest, Mess]
---

# A Guest disconnects or crashes on a bigger sync or a respill

The designer, in two windows (Host and Guest on one PC, `-- --host`, `-- --join=127.0.0.1 --profile=b`):
"player disconnects and crashes, when trying to sync more and respill". Which machine crashed and the
logs are not known yet (they may arrive in `builds/crash-logs/`).

Suspect, not a diagnosis: every Mess answer carries the whole `states`/`poses` arrays (about 100 KB at
2,038 Socks, `docs/research/coop-flight-sync.md` condition 3); a respill makes thousands of answers on the
reliable channel, which backs up until ENet times out. Reproduce first; the cause may be another.

## Acceptance
- A headless Host and Guest case that reproduces the fault through the zoo's own wiring (the heap
  station's respill, and a large pour), failing before the fix: which machine fails, how (disconnect,
  timeout, engine error, crash) and why, written in the Built log.
- The cause fixed. If it is the whole-array answers: a Mess answer carries only the records it changed
  (and the join snapshot stays whole); the Guest's Mess applies them to the same result as the Host's.
- After the fix: a respill and a 2,000-Sock pour with a Guest joined keep the Guest connected, its Mess
  equal to the Host's once all rest, at 0 ms and 50 ms one way; bytes per second on the reliable channel
  measured before and after.
- No change to how Socks look on the Guest while in flight (batch 3 does that).

## Answers

## Open follow-ups

## Built log
- 2026-11-22 lead: model opus (netcode debugging, CLAUDE.md "Models").
