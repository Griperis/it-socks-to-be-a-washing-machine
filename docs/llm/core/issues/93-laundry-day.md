---
type: ticket
status: done
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/82, core/86, core/90, core/91]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Laundry day, Laundry bin, Final wash]
---

# The Laundry day

After the last Fix the bins load the machine: build `docs/architecture/run-ends.md` "The Laundry bins": the draw, and "The Laundry day":
the bins placed in `house.tscn` under `LaundryBins` at the seven old spots (the one by the washer `always`), the draw
at a New Game from the World's seed (`bins_per_world`, clamped), the `LaundryDay` Part (`load` and its refusals in
order, `loaded`, the pile through `WasherLooks.pile`, the ending's wait counted down by the Host and saved), the use of
the washer with a carried bin ("[LMB] Load the washing machine" after the last Fix), `socks_pour` at the porthole,
`LaundryDay` as the bar's `laundry_bins` provider, and the washer's Laundry day comment set (Q2635). The Final wash
itself is core/96 (here the wait ends in a stub the station shows).

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The Laundry bins": the spots and the draw; "The Laundry day" (all); "Words and sounds".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

A bin spot is an instance placed in `house.tscn` (a new spot is a new instance, no code); `LaundryTuning`
placeholders. The Laundry station gets "Last Fix done" and "Final wash" (all but one loaded) pillars and a
`loaded/total` label.

## Acceptance
- `LaundryDay` provides `laundry_bins` and the `bar_changed` signal for the Stage bar's fold into "Wash clothes n/m" (core/82).
- The bins are placed, their `used` and `full` written and `tip()` called through core/90's `LaundryBin` API.
- Real path: in the house with the last Fix set by the zoo knob, the player carries a bin to the washing machine and clicks: the bar reads "Wash clothes 1/3", the bin is empty in the Hands, a second click is refused "That bin is empty".
- Before the last Fix a bin is refused "Fix the washing machine first"; during the wait "The washing machine is busy".
- Every machine draws the same bins from the seed; saved and in the join snapshot (loaded bins, pile, the wait).
- Reachable in the main scene. Placeholders: `LaundryTuning`, the seven spots (judged by eye in the review).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The bins stand full from the New Game, refused until the last Fix (Q2624, 2026-11-24).
- Loading stays as the old: no Socks seen going in (Q2627, 2026-11-24).
- The Laundry day's comment set, Stage 4's by default (Q2635, 2026-11-24).

## Open follow-ups
- [later] core/82's Stage bar drops a number change that lands while its fold's pop-in is still playing (`refresh()` returns
  while `folding()`; the fold redraws only what was current when it landed): a bin loaded within about 0.2 s of the
  fold would not show until the next change. The real-path case waits for the fold to end.
- [later] The Laundry station keeps core/89's stand-in washer box (the spray test aims along its marker): the real
  washer there would let the load be clicked in the station too.
- [later] Sock laying sees the bins' shapes, which the draw switches off for the unused spots: the layout depends on
  whether the draw ran first (it does in a New Game, before the Stages lay). `house:h09_same_seed_sliced` therefore
  frees `LaundryDay` in both its houses. Only the Host lays, so no machine can disagree.
- [later] The seven spots' places are the old layout's moved by the house's frame, not yet judged by eye (placeholders).


## Built log

### 2026-11-25
- Changed: `LaundryDay` (Part, `game/laundry/`, instanced in `house.tscn` as `LaundryDay/Day` beside the seven bins under
  `LaundryBins`, the one by the washer `always`): the draw from the World's seed at a New Game (clamped), `load` and its
  refusals in order (words in `LaundryDay.SAYS`), `loaded_bins`, the pile through `WasherLooks.pile`, `socks_pour` at the
  porthole, the bin's `tip()`, the ending's wait counted by the Host and saved (live value in `whole_state()`), the stub
  `final_started`, and `laundry_bins` as the Stage bar's provider with `bar_changed`. `Washer.use` asks the load (left click
  only), the crosshair reads "Load the washing machine" after the last Fix, `Player` says the three refusals. `socks_pour`
  joined the sound catalogue (asset, SOURCES, credits). The Laundry station has the Last Fix done and Final wash pillars and a
  loaded/total label. Seven rows in batch-a-review.md. The state field is `loaded_bins`: `loaded` is Part's load reset.
  Two house cases made robust (a Pair "open" no longer needs clear air above; the same-seed case draws nothing).
- Files: game/laundry/laundry_day.gd, laundry_day.tscn, game/house/house.tscn, game/entities/washer/washer.gd,
  game/player/player.gd, game/ui/prompts.gd, game/zoo/laundry/laundry_pillar.gd, laundry_label.gd,
  game/zoo/stations/laundry.tscn, game/audio/sound_catalogue.tres, assets/audio/socks_pour__pyrano_whoosh_pour.ogg(+.import),
  game/ui/licence/credits.tres, tests/laundry_day_test.gd, tests/house_test.gd, tests/saves/*, docs.
- Verified: `kit/tools/run.sh --touched` PASS (laundry_day 5 cases, 57 checks; house 26 cases); grep_rules PASS.
  Not covered: a co-op Guest case (the Parts path is generic; the wait and snapshot are checked on the Host).
