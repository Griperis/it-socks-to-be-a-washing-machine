---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/96]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [World, Host, Guest]
---

# Back to the Lobby after the end

Continue on the Final screen takes everyone back: build `docs/architecture/run-ends.md` "Continue" and the finished World: any player's
press asks the Host; the Host saves and loads `lobby.tscn` for everyone through the game link behind the loading
screen (the Session and Roster kept); the finished World stays chosen as a record, its row and card saying "Finished"
with its play time; it cannot be continued; Start (Solo: New Game) with it chosen asks "Start a new game? The finished
World is replaced." and makes a New Game in its slot.

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The Final screen": the Continue lines; "What the Lobby offers after an ending".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The words are placeholders in the Lobby's own scenes; nothing new to author.

## Acceptance
- Real path: a Guest presses Continue on the Final screen; both machines are in the Lobby with the same Roster, the World's row says "Finished" with its play time, and the Host's Start asks before replacing it.
- Solo: Continue, then New Game asks and makes a New Game in the finished World's slot.
- A finished World never loads into the house.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A finished World stays in the Lobby as a record; Start or New Game asks and replaces it (Q2631, 2026-11-24).

## Open follow-ups

## Built log
