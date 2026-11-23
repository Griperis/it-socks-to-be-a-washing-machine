---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: [house/05-mess-in-the-house]
notes: ["Q2542, Q2544; house/05's [later] notes"]
terms: [Mess, Sock]
---

# The house's Socks laid without a freeze; the attic trunk's inside

From house/05 (2026-11-23):
1. **Laying freezes the game ~1.7 s** in one frame when the house loads (measured headless). Lay a slice per frame
   within a frame budget behind a short loading screen reading "The washer bursts open..." (the old text,
   `reference/it-socks/game/core/main.gd:647`), with a progress bar as the old (0.1 once planned, then the share laid);
   the Socks still appear all at once when it lifts (Q2523, Q2542). The result is the same Mess for the same seed however
   many frames it takes. The loading screen is a scene on the game's Theme (a placeholder look; M4 restyles it).
2. **The attic trunk's inside sits 10 cm over its real floor,** so every try there fails and the attic gets no Socks
   inside furniture. Fix the trunk's `Inside` box (and any other piece found the same way: check every furniture
   piece's `Inside` against its mesh floor and list the ones fixed).

## Acceptance
- Real path: F5 shows the loading screen, no frame over the budget while laying (measured, in the Built log), then the
  house with its Socks; a Guest joining mid-lay waits and gets the full Mess.
- The same seed gives the same Socks laid in 1 frame and over many (a case).
- The attic has Socks inside its trunk; a still for the designer (`builds/review-house-09/`), with the loading screen.
- (The lead's review) every slice of laying stops before the budget by design; the timing case passes 10 runs of
  10 in a row. The stair trails' Socks stay lying on their treads through 120 ticks (a case).
- (Q2576) each attic trunk holds about 5 Socks, as the old game, through the trunk's own weight override (Q2520),
  the floor's total kept; the trunk stills retaken.

## Open follow-ups
- [later] The loading screen's old look (card, spinner, fade into play) is core/58's (Q2575); the placeholder stays.
- [later] The reveal (990 Socks join the Mess, get their bodies and drawings) is one frame of about 40 ms, behind
  the screen (the old game did the same: its deep review's B3); spreading it means splitting the Mess's _show.
- [later] The treads' layer (128, `SockTrail.LAYER_TREADS`) is also a standing player's Mate capsule's
  (`Ragdoll.MATE_LAYER`): the support rule tells them apart by the body's name; the trail's own tread ray does not,
  so a Teammate standing on a stair during a reseed could be taken for a tread. One of them could move layer.
- [later] The new furniture case checks each Inside's bottom only, not its shelves (`shelves_y`).
- [later] Stacking inside (Q2576) is for every piece's inside, as the old game's was: a crowded cupboard or drawer
  now holds Socks on Socks too; only the trunk's weight changed. The designer sees it in play.
- [later] The kitchen real path now picks a Sock lying on the floor itself: with the new layout it first chose the
  top Sock of a kitchen Heap (open to the eye), aimed at it, pressed pick, and that Sock never reached the Hands.
  Not looked into (a pick in a Heap takes its column, core rule?); worth a look.

## Built log
- 2026-11-23
  - Changed: Q2542. The level's starting Socks are laid by `StartingSocks` (every generator in order: seeds first,
    then every area's places, then each generator's Socks avoiding the ones before, then its records) through
    `SockLayingJob` (one generator's laying cut into `plan()`, `lay()`, `records()`, each to a deadline;
    `SockGenerator.lay()`/`records()` run it whole, so the preview and a regeneration are unchanged). A level
    runtime with `load_screen` (the house) lays a slice per frame behind `LoadingScreen` ("The washer bursts
    open...", the old bar rule, 14 ms slices: the old `loading.frame_ms`): the 3D is not drawn, the player is held
    at the spawn (its body kept in the space), a joining Guest waits (`Parts.unsettle`/`settled`, Session), the
    Socks join in a frame of their own and the screen goes 2 frames later; a Guest's snapshot drops its own laying.
    `SockLaying.restack` looks only at near rows and boxes (by hash cell): a floor's records went from about 300 ms
    to about 15 ms, the same heights, and restack too goes by slices. The house shot sets wait for the screen.
    Trunk: its `Inside` sat 3.5 cm under the top of the lining cushion its collision holds (the hull `Shape1` is
    the floor the rays meet; not 10 cm over the bottom board); its bottom raised to 0.16 m (box 0.84 x 0.20 x 0.44
    at y 0.26). Every piece's Inside is checked by a new furniture case: only the trunk was off; only it fixed.
  - Measured (headless, debug engine, `real_path_loading_screen`): the house laid in 70 frames, the longest slice of
    laying 18.3 ms (budget 14 ms; a slice ends at the first unit past it), the longest frame 18.5 ms, the reveal
    33.4 ms; before: 990 Socks in about 1.7-2 s in one frame.
  - Files: game/mess/starting_socks.gd, sock_laying_job.gd (new), mess.gd, sock_generator.gd, sock_laying.gd,
    sock_places.gd, generated_socks.gd; game/level/loading_screen.gd, .tscn, loading_tuning.gd, .tres (new),
    level_runtime.gd, .tscn; game/house/house.tscn; game/parts/parts.gd, session.gd; game/furniture/trunk.tscn;
    tests/house_test.gd, furniture_test.gd; tools/shot_hooks.gd (`house_trunk`); tools/shots/sets/house-09.txt and
    the house sets; docs/architecture.md, architecture/sock-generator.md, house.md, furniture.md.
  - Stills: builds/review-house-09/ (house-09-loading.png, house-09-trunk-a.png, house-09-trunk-b.png).
  - Verified: PASS 17901 checks, 465 cases (`kit/tools/run.sh --touched` before merging main; FLAKY mess_settle:real_path_2 and _3, core/54's); after merging main PASS 373 checks, 21 cases (house) and agent_finish's --touched; PASS rules
- 2026-11-23 (the lead's review, Q2576)
  - Changed: (1) Slices stop before the budget: `SliceClock` (game/mess/slice_clock.gd) is asked before every
    unit of work (a floor cell, a furniture node, an area's places, one try of a Sock, a trail, a restacked row,
    the Designs dealt, the records) and lets it start only when twice the longest unit of its kind so far, and at
    least 3 ms more than it, still fits; a Sock is now laid a try at a time (`SockLaying.lay_try()`, the same
    dice in the same order). (2) The stair trails stay on their treads: the trail's row kept a stale `ground` from
    the Sock before it, so the restack (core/55) brought it down under the stair, where the support rule found
    nothing and it fell; `_rest_on_tread` now sets its ground, and `MessBodies.supported()` counts a tread
    (a body named `Treads`, `SockTrail.TREADS`) as holding a Sock up. (3) Q2576: the trunk's root has
    `sock_weight` 4.0 (Q2520), and Socks inside a piece lie on the ones laid there before, as the old game's
    computed stacking did: flat, side by side, the trunk holds only 2 (its place box is 0.375 x 0.225 m on a
    0.82 x 0.42 m floor), so the weight alone moved none (1 and 1). The attic's total is unchanged (260).
  - Measured: `h09_slices_within_budget` (perf, a slice may not pass 14 ms): passed 10 runs of 10 in a row (`kit/tools/run.sh --only=house:h09_slices_within_budget`, each "ok": 3 of 3 of its timing runs, 30 in all); the longest slice of laying
    11.1 ms in `real_path_loading_screen` (114 frames), the reveal 31.4 ms (its own frame, behind the screen). Trunks: 6 and 5 Socks inside (`h05_mess`).
  - Files: game/mess/slice_clock.gd (new), sock_laying.gd, sock_laying_job.gd, sock_places.gd, starting_socks.gd,
    sock_generator.gd, mess_bodies.gd, sock_trail.gd; game/furniture/trunk.tscn; tests/house_test.gd (new case
    h09_trail_stays_on_treads; the timing case strict at 14 ms; the kitchen case picks a floor Sock);
    docs/architecture/sock-generator.md.
  - Stills: builds/review-house-09/house-09-trunk-a.png, house-09-trunk-b.png (retaken).
  - Verified: PASS rules; after merging main (d833a6f) the touched suites by agent_finish (its suite: line is in the report to the lead)
- Merged: b12fc1ca (2026-11-23, branch house/09-lay-without-freeze-and-trunk)
