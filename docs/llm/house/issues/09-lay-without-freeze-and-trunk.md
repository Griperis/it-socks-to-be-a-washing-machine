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

## Open follow-ups
- [later] The old loading screen's looks are not ported (a placeholder on the game's Theme; M4 restyles it): the
  old cream card, the tumbling sock spinner over the text, and the fade into play from the backdrop's colour
  after the screen goes (Q1262, Q1265). The bar follows the old rule exactly: empty while the places are found
  (about a third of the laying), then 0.1, then the share laid. For the designer to keep or drop.
- [later] The reveal (990 Socks join the Mess, get their bodies and drawings) is one frame of about 30 ms, behind
  the screen (the old game did the same: its deep review's B3); spreading it means splitting the Mess's _show.
- [later] The trunks hide 1 and 2 Socks (the old game 5 each): the hidden share (0.3) is spread by place weight
  over every inside and under-gap of the attic.
- [later] A trail Sock laid flat on a stair's tread lies under the walking ramp; the Mess's first tick finds nothing
  under it (it looks at the house layer, not the treads) and lets it fall onto the ramp, so in play the stair trails
  lean on the ramps as before (house/05's [later] "only the trail sees the treads"; found here comparing one frame
  with many).
- [later] The new furniture case checks each Inside's bottom only, not its shelves (`shelves_y`).

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
