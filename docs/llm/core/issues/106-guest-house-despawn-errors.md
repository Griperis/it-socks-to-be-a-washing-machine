---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: later
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus (netcode)", "from core/97's [later] follow-up; after batch A"]
terms: [Guest, Host]
---

# Engine errors when a Guest's house goes before the Host's

core/97 (Back to the Lobby) sees two engine errors, `on_despawn_receive` and `recv_nodes`, when a Guest's house is freed
while the Host's still stands. Its co-op case declares exactly two with `_expect_error`, so the count is fragile and
the errors are real.

## Acceptance
- Reproduced in `tests/back_to_lobby_test.gd`'s co-op case; the cause named (spawner or synchronizer order on leave).
- Fixed so no engine error prints; the case's `_expect_error` lines removed.

## Open follow-ups

## Built log
