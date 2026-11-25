---
type: ticket
status: done
kind: build
area: core
feature: ui
priority: now
created: 2026-11-24
done:
blocked_by: [core/83]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Pair, Coins, Final wash]
---

# The Final screen

The ending's screen, built and shown in its station first: build `docs/architecture/run-ends.md` "The Final screen": `final_screen.tscn` and
`final_column.tscn` on the Theme (a column per player in the game at the end, Q2630), the Sock stage, the pop
schedule, the rare pause and sparkle, the count-up, the "+N bonus" step, the totals from `final_totals.tres`
(`play_time`, `coins_earned`, `stages`), the finale, the empty pieces and unlock strips for batch B, any key skips to
the totals, Continue waiting (core/97 makes it work), the sounds as SoundEvents. The screen's look goes on the review
sheet (stills of 1, 2 and 4 players and a long name, in `<main checkout>/builds/review-final-screen/`) instead of
stopping (Q2603).

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The Final screen" (the lines not marked B).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`FinalScreenTuning` (the old `final_screen.json`), `FinalTotal` Resources in `final_totals.tres` (batch B adds a
total by adding a Resource), `final_pop`, `final_tick`, `final_rare`, `final_sting` in the sound catalogue with the old
placeholder recordings. The Final screen station (`game/zoo/stations/final_screen.tscn`) opens it on a made-up
`RunRecord` from the catalogue at load.

## Acceptance
- Real path: in the Final screen station the player presses E on the 2-player pillar and presses a key: both columns' scores show their final Coins and the totals show.
- A player who left before the end has no column; their Pairs count in the totals.
- No "who did what" titles.
- Placeholders: `FinalScreenTuning`, the four sounds.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A column only for the players in the game at the end (Q2630, 2026-11-24).
- No "who did what" titles in batch A (Q2632, 2026-11-24).

## Open follow-ups

## Built log

### 2026-11-25
- Changed: the Final screen (`final_screen.tscn`, `final_column.tscn` on the Theme): a column per player in the game at the end, Sock stage per column (one MultiMesh per Collection), the slow-then-fast pop schedule with the rare pause and sparkle, the score count-up and "+N bonus", totals from `final_totals.tres` (`play_time`, `coins_earned`, `stages`), finale bursts and sting, any key skips to the totals, Esc swallowed, player held and mouse freed, empty pieces and unlock strips (hidden), Continue waiting (`continue_pressed`). `FinalSummary.make/of` builds the data from RunRecord, RunTallies, Stages and play time (core/96 calls `of`). Station `final_screen.tscn` at zoo x 116 with pillars for 1, 2, 4 players, a leaver and a long name, built from the catalogue. Sounds `final_pop`, `final_tick`, `final_rare`, `final_sting` with two copied old clips (`coins`, `match`) and their credits. Seven rows added to "Settled by the old game". Stills in `builds/review-final-screen/` (1, 2, 4 players, long name, popping, leaver); shot set `final-screen`. The signal is `taken_down`, not `closed`, so the menus suite does not count it as a dialogue needing an Esc key.
- Files: `game/ui/final_screen/*`, `game/zoo/final_screen/*`, `game/zoo/stations/final_screen.tscn`, `game/zoo/zoo.tscn`, `game/audio/sound_catalogue.tres`, `assets/audio/{coins__starninjas_coin1,match__a}.ogg`, `assets/audio/SOURCES.md`, `game/ui/licence/credits.tres`, `tools/shot_hooks.gd`, `tools/shots/sets/final-screen.txt`, `tests/final_screen_test.gd`, `docs/migration/batch-a-review.md`.
- Verified: PASS 21987 checks, 654 cases (`--touched`, 74 suites since the zoo scene changed).
