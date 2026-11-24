---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus (physics debugging)", "ledger: tests/flaky/ledger.md, mess_settle:real_path_thin_floor (3 lines, 2026-11-25)", "reopens core/70's finding"]
terms: [Sock, Mess]
---

# A Sock is drawn under the floor when the machine is loaded

core/70 found no drawn frame with a Sock under the floor (0 of 306) and added a drawn-frame watch to
`mess_settle:real_path_thin_floor`. In the full suite (several runs at once) that watch fails and then passes alone:
12 to 35 frames draw a flying Sock 1.1-1.3 cm under the floor (ledger, 2026-11-25 00:12, 00:16, 00:45; e.g. "frame 74:
a body drawn at y -0.013"). Under load more than one physics step can run per drawn frame, or frames are drawn between
steps (physics interpolation), so the push and the put-back no longer share a step before the draw. A player on a
slow frame may see it. A flaky case is a defect to rework (kit/docs/TESTING.md "Flaky cases").

## Acceptance
- Reproduced first under load (the suite order, or the case with a forced slow frame / several steps per frame).
- The cause named (steps per frame, interpolation, or when the Mess's put-back runs) and fixed so no drawn frame shows
  a Sock under the floor, with no look or feel number changed (else a [blocking] follow-up).
- The watch passes in the full suite 10 runs in a row; no FLAKY line.

## Open follow-ups

## Built log
