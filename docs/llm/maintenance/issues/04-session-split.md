---
type: ticket
status: ready-for-agent
kind: build
area: maintenance
feature: net
priority: now
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: opus (big refactor of the one RPC node)", "from core/68's [later]; before batch A (designer, 2026-11-24)"]
terms: [Session, Part, Host, Guest]
---

# Split session.gd before batch A

`game/parts/session.gd` is 842+ lines (core/68's [later]). Batch A (core/76-98) adds the run's state and new
verbs through Session; 30 tickets editing one big file will clash. Split it now, with no change of behaviour.

## Design
Session stays the one RPC node (the co-op shape, CLAUDE.md): every `@rpc` function stays on Session, and the
`PROTOCOL` constant stays there. What moves out is the work behind them, into plain helper classes beside it (one
class per file, named alike, no inner classes; Q2251-Q2253), grouped by concern (e.g. the gate and joining, the
snapshot, Command routing and guards, the per-verb handlers), so a new verb in batch A touches its own helper and one
thin RPC line. Read `docs/architecture/coop.md` first and update it with the new layout; `docs/architecture.md`'s
code map too.

## Acceptance
- No behaviour change: no wire message changes (PROTOCOL stays), every co-op suite passes unchanged (the full suite
  through `agent_finish.sh`), no test edited except a path that moved.
- `session.gd` under about 300 lines; no helper over about 300; each helper's one job in its first comment line.
- `docs/architecture/coop.md` says where a new verb goes (a short "Adding a verb" section) so batch A's agents follow it.

## Open follow-ups

## Built log
