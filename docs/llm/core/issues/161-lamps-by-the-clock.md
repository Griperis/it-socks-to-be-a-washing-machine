---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[160-day-cycle]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 6", "suggested model: sonnet"]
terms: [the house, Stage]
suites: [day, floor_lock, stages, house, first_wash, final_wash]
---

# The lamps follow the clock; their click; the wall clock

At 19:30 every lamp in the house comes on, on every floor, a locked floor's too (the clock wins at night, Q2706), with
a click; at 7:00 they go off with a click but the basement's; the wall clock on the living room's wall shows the hour
(Q2709). Build `docs/architecture/day-and-exterior.md` "The lamps by the clock", "The wall clock", draft 149-H:

- Q2706 in `HouseLights._switch()`: at night every lamp is on whatever `dark_levels` says; by day as built (the day
  level's lamps, the reveals, a locked floor dark); `lamp_factor` (from the keys, 1.0 by day to 1.5 at night)
  multiplying every lamp's base energy;
- `DayLight.lamps_switched` playing `lamp_on` / `lamp_off` flat (the SoundEvents are core/154's); a load or a join
  switches silently;
- the wall clock (`game/house/wall_clock/wall_clock.tscn`, `WallClock`, a view with no state reading the level's
  `Day`): graybox Looks with `hour_hand` and `minute_hand` turning about z (once in 12 hours, once an hour, the old
  `_show_time`), hung on the living room's wall where the old hung it (the old layout's `clock`, moved with its wall by
  house-kit-plan), no collider; one in the Day station too.

Dropped by Q2709, not built: the shades' glow, the night-blue panes, the grade and vignette by the hour, the outside's
night glow. The clock's ticking (`amb_clock`) is M1.1's ambience, batch D.

Behaviour lines (`day-and-exterior.md` "The lamps by the clock"): all 5.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The hours in `DayTuning`; the lamp factor in the keys; the clock a Looks scene (assets/23 swaps in the ported model by
its two hand nodes). The hands follow the hour in code, as the old: a clip cannot follow a clock running at the World's
rate.

## Acceptance
- Real path: a New Game from the title, the game's clock run to 19:31, to the first floor's ceiling light visible and
  lit at its base energy x the factor while the floor is still locked, and `lamp_on` heard once.
- At 19:29 the locked first floor's lamps are off; at 7:01 only the basement's are on, with `lamp_off`; by day a
  floor's reveal still fades in, holds and fades out; a load at 22:00 shows every lamp on with no switch sound.
- At 15:45 the clock's hour hand points between 3 and 4 and its minute hand at 9.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The lamps on and off by the clock, 19:30 and 7:00 (Q2693, 2026-11-26).
- The day's lamps follow the clock on every floor, locked or not (Q2706, 2026-11-26).
- Of the old day's six small details, the lamps' click and the wall clock's hands are kept; the other four dropped
  (Q2709, 2026-11-26).

## Open follow-ups
