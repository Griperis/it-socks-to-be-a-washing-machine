---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: ["[[13-two-tier-mess]]"]
notes: []
terms: []
---

# The heap station

A zoo station with a real physics heap of Socks to play with (designer, 2026-11-20; Q2334-Q2336). It puts the two-tier Mess
(core/13) under load the designer can see and touch. The old game's live spill: ADR-0008 "The Mess is spilled live"
(`reference/it-socks/docs/adr/0008-two-tier-socks.md`), `reference/it-socks/game/world/sock_pour.gd`.

## Behaviour list
- H01 A spout above the station's pad pours Socks in waves; each Sock falls as a moving body under the moving budget
  and rests into the two-tier Mess as it settles (Q2335).
- H02 A click on the station's "More" button (an interactable, used like a drawer) pours one more batch of about 500
  Socks (a tuning number, Q2334): both Socks of each Design it picks, so they can be paired; Designs may repeat in the
  zoo (Q2290).
- H03 A "Respill" button clears the station's Socks and pours a fresh batch (Q2336).
- H04 A live counter sign shows how many Socks are moving, waiting for the budget and resting, and the physics time a
  tick (Q2336).
- H05 Low walls round the pad keep the heap together; a slope and a table stand in it for Socks to slide off and pile
  against (Q2336).
- H06 The poured Socks are real Mess Socks: picked, paired, thrown and shelved like any other; picking from the heap
  wakes the Socks above (M07).
- H07 New Socks during play go through the Mess's own Host path (a Host-only Command that adds records), so a Guest and
  a late joiner would see the same heap (M0.6 tests it); nothing is written to a save (the zoo is never saved).

## Design
To be drafted by the agent here first (adding and removing Mess records during play; the spout and the waves; the
buttons as Openable-like interactables or Parts; the counter), then built. Keep edits to `game/mess/` small: another
agent works in `mess.gd` (core/14) and one in `mess_drawing.gd` (core/21).

Drafted (agent, 2026-11-20):
- Records during play: two Host-only Commands of the Mess. `add` appends FLYING records (designs, poses) with a launch
  in `throws` by `Mess.NOBODY`, so they start at once as released bodies (no flick). `take_out` makes loose LYING or
  FLYING records (a Pair only when both are named) the new state GONE: never drawn, aimed or simulated, ids unchanged
  so held and shelved Socks keep theirs; trailing GONE records are cut off. `_show` now handles a changed record
  count incrementally (added records shown, cut-off ones dropped) instead of rebuilding every body; `now` still
  rebuilds. PROTOCOL 7 -> 8.
- The spout (`HeapSpout`, a Part on `Spout`): Guest verbs `more` and `respill` (no args); its answer counts them
  (`asked`, `respills`) and notes `first`, the heap's first record. The Host alone pours: each tick one wave of at most
  `per_tick` Socks while the budget's general share has room, each at a free place of the column under the spout
  (shape query), random turn, small sideways push, as one `add` (the old SockPour). Batches walk the catalogue a
  Design at a time, both Socks each, and wrap. A respill asks `take_out` for every record from `first` on.
- Buttons: `HeapButton`, a Part on each StaticBody3D (clicked like a drawer: pick on a non-Sock uses it), asking the
  spout its verb. Counter: `HeapCounter` (Label3D, looks only), tick timed from its first `_physics_process` to its
  next `_process`. Numbers: `game/zoo/heap/heap_tuning.tres`. Station off the grid at (13, 0, -7), turned to face the
  spawn (Q2347): 6x6 pad, 0.3 m walls, a 25 degree slope, a table.

## Acceptance
- One test per line; the real-path case: the player clicks "More", Socks pour and come to rest, the player picks one
  from under another and the one on top falls.
- The physics tick while pouring and at rest, with 500 and with 2,000 poured Socks, in the report.
- A still and a short strip of a pour in `builds/review-core-20/`; the ticket goes ready-for-human.

## Answers
- Q2290, Q2334-Q2336 (2026-11-20).
- Q2347 (2026-11-20): the designer's go; the heap station moves clear of every pad (the house kit's included) and of
  sounds:s07's walk, then merges with no new still.
- Q2348 (2026-11-20): nothing pours at start; the first batch waits for a click on More.

## Open follow-ups
- [later] The old zoo spawner's other pour modes are not built: a heap where the crosshair aims, rain over every room,
  a count set by hand, clear all; also SockPour.stop() resting every falling Sock at POUR_MAX and the `poured` signal
  with the "Last pour" line. The designer has not chosen yet.
- [later] Co-op cost: every `add` and `rest` answer carries the Mess's whole arrays (about 4,000 records with 2,000
  poured): M0.6 should measure it with a Guest.
- [later] The sign's Moving count is the Host's flights; a Guest shows 0 moving.
- [later] `count_of()` counts GONE records too (a Design of a respilled heap may count more than two).
- [later] `game/mess/mess.gd` is 683 lines (grep_rules: over 600): split it when next touched (core/14 also edits it).

## Built log
- Model: Opus (lead): physics and the Mess under load.
- 2026-11-20 (agent, core/20-heap-station)
  - Changed: the heap station (spout, More and Respill buttons, counter sign, walls, slope, table); the Mess's
    Host-only `add` and `take_out`, the GONE state, incremental showing of a changed record count; PROTOCOL 8; the
    `heap_more` shot action and the `heap-pour` shot set.
  - Files: game/zoo/stations/heap.tscn, game/zoo/heap/ (heap_spout, heap_button, heap_counter, heap_tuning + .tres,
    .uid), game/mess/mess.gd, game/parts/session.gd, tests/heap_test.gd, tools/shot_hooks.gd,
    tools/shots/sets/heap-pour.txt.
  - Ticks (zoo with every station, headless, `heap:ticks`, counter's timing): 500 poured: pouring median 3.0 ms, worst
    8.3 ms, at rest median 0.62 ms, worst 1.2 ms (321 frames to rest). 2,000 poured: pouring median 5.1 ms, worst
    14.9 ms, at rest median 0.61 ms, worst 9.0 ms (828 frames to rest); 4,031 records, 4,031 lying bodies.
  - Review: builds/review-core-20/heap-pour-f480.png (still at rest), heap-pour-strip.png (the pour, frames 66-480).
  - Verified: see the commit's suite line (`kit/tools/run.sh --touched`).
- 2026-11-20 (agent, core/20-heap-station, Q2347): main merged in (core/14, house/01, core/22; mess.gd auto-merged,
  PROTOCOL stays 8 as main kept 7). The station moved to (13, 0, -7), turned to face the spawn, clear of every pad
  and of sounds:s07's walk; the suite takes the mouse as the player's (core/14 R01) before clicking.
  - Files: game/zoo/stations/heap.tscn, tests/heap_test.gd, this ticket.
  - Verified: suite: PASS 7279 checks, 218 cases (`--touched`, 18 suites).
