---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: soon
created: 2026-11-25
done:
blocked_by: [core/103]
notes: ["suggested model: opus (netcode test debugging)", "from core/103's [later] follow-up"]
terms: [Guest, Host]
---

# coop_knockdown still races when the Guest's pose arrives late

core/103 forced the Guest's pose 0.4 s late (a temporary hack in `Avatar._copy_follow`): with it,
`coop_knockdown:real_path` and its two drag cases still fail, although core/101 made `_aim` wait for the Host's copy
of the Guest's place. core/101 forced a different late path (the position send), so its wait does not cover this one.
Not yet seen flaky in a normal run, but the race is real.

## Acceptance
- Reproduced with core/103's forced 0.4 s pose lag; the cause named per failing case.
- Each case waits on the real condition the Host judges by (not more frames); passes with the forced lag, and the
  suite passes 10 runs in a row in suite order under load with no FLAKY line.
- No game code or look/feel number changed unless the game is wrong (then a [blocking] follow-up).

## Open follow-ups

## Built log
