---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: audio
priority: now
created: 2026-11-26
done:
blocked_by: ["[[165-tv-and-test-card]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 6", "suggested model: sonnet"]
terms: [TV, Channel, Design]
suites: [menus, zoo]
---

# The TV's three shows

The TV's other three channels, as the old with their texts and timings (Q2704): the Sock puppet show, Sock shopping
and the Weather. Build `docs/architecture/tv-and-radio.md` "The four shows", draft 150-D:

- `puppets.tscn` (24 s, `tv_puppets`): the orange (`#e8945a`, top hat) and teal (`#6fb3a8`, bobble hat) sock creatures
  on a little stage, talking in turns in a bubble, both laughing at the end; the old eleven lines and their times;
- `shop.tscn` (16 s, `tv_shop`): a real Design on a turntable (the catalogue's Designs in a fixed order, the loop's
  number picking, so every machine shows the same), its name, a "%d.99" price by rarity (`ShopTuning`) pulsing, the
  pink (`#d9568f`) announcer's three lines, the jingle (0.0-2.6 s) and the ding (14.4 s), the ticker "SOCK SHOPPING *
  ONE SOCK, ALL YOURS * MATE NOT INCLUDED * CALL NOW";
- `news.tscn` (24 s, `tv_news`): the presenter in a bow tie at a desk beside the weather map (the house's four levels
  side by side, `weather_room.tscn` blocks placed by hand), each room's forecast in turn with its sign lit and moving,
  the sting (0.0-2.0 s); the five old forecasts as `Forecast` files;
- the voices, the old synthesised gibberish, copied as recordings; the `TvBubble` Theme variation; the three channel
  files in dial order before the Test card.

Behaviour lines (`13-tv-and-radio.md`): R10, R11, R12; the shows' names and texts (the old `tv.json`).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Each show is a scene of nodes on the Theme with one `show` clip as long as its loop (its lines keyed on the bubble's
text, Q2697, Q2658); forecasts and channels are files; the shop's Designs come from the catalogue (a new Design shows
with no change). The recordings are copied as they are (changing a line's timing needs a new recording).

## Acceptance
- Real path: in the TV and Radio station the player presses E on the TV once: the Sock puppet show plays, and at 0.5 s
  into its loop the bubble reads "Blorp! Snibble?"; E again: Sock shopping shows a catalogue Design's name and a
  "%d.99" price, the ticker moving; again: the Weather, the bathroom's sign lit with "SOCK SHOWERS IN THE BATHROOM" in
  its turn.
- Two machines show the same Design in the same loop (co-op).
- Every copied recording has its credit (`menus` l02).
- Placeholders: `ShopTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The four shows with their texts and timings (Q2704, 2026-11-26).

## Open follow-ups
