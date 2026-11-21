---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: ["[[28-review-correctness-fixes]]", "[[29-review-frame-cost]]", "[[31-mess-benchmark-and-settling]]", "[[34-zoo-only-into-the-zoo]]"]
notes: []
terms: []
---

# Code review: the tidy-up

The M0.5 code review's duplication, unused code and rule tensions, which the designer chose to fix (Q2404). Nothing
the player sees, hears or feels changes; the designer gains numbers in the inspector and zoo labels in the editor.
Runs after core/28, 29, 31 and 34 because it touches their files (paths as core/34 left them).

## Behaviour list
- T1 Felt numbers move from code constants into their tuning Resources, with the same values:
  - hands: `THROW_CLEAR`, `DROP_TRIES`, `DROP_CLOSEST`, `EYES_FALLBACK`, `THROW_RATE`, the damps `0.6` and `3.0`
    (`game/hands/hands.gd:30-45, 295, 311`) into `HandsTuning`;
  - Mess: `CCD_ON`/`CCD_OFF`, `TOUCH_MARGIN`, `0.7` (`mess.gd:373`), `0.1` s (`mess_moving.gd:125`), `15.0`
    (`:168`), `MIN_THICK` into `MessTuning`, and `tuning` required (one assert) instead of the fallback literals
    (`mess_moving.gd:221, 320-321, 381-382`; `mess.gd:547, 711`);
  - `avatar.gd:12` `GLIDE`, `power_ring.gd:7-12`, `picture.gd:9-15`, the icon station's hard numbers
    (`icons_station.gd:64,84`);
  - the HUD's font sizes, refusal red and separation read from `theme.tres` (`game/ui/hud.gd:12-29,324`).
- T2 The zoo's label, button and swatch trees become small scenes, instanced and filled: `zoo_label.tscn`,
  `sound_button.tscn`, `icon_cell.tscn`, `swatch.tscn` (`sounds_station.gd:86-129`, `icons_station.gd:77-100`,
  `material_board.gd:103-136`, `every_sock_station.gd:91-100`, `sock_looks_station.gd:89-98`,
  `furniture_line_up.gd:86-96`, `cabinet_gallery.gd:67-75`, `house_kit_line_up.gd:62-68`). Stations keep
  building from data at load (Q2337). Stills of every changed station, before and after, must match.
- T3 Duplication removed:
  - `_keep_uid` once, shared by `game/house/kit/house_kit_build.gd:1026-1045` and `tools/old_house_build.gd:643-661`
    (with a null check on `FileAccess.open`);
  - `collections()` once in `DesignCatalogue` (`cabinet_gallery.gd:28`, `every_sock_station.gd:29`,
    `sock_looks_station.gd:33-38`) and the row-count expression once;
  - `arc.gd:71-123` one integrator step for `height_at`, `reach_at`, `path`; `arc.gd:39-43` returns
    `Vector3.ZERO` as documented when it does not converge;
  - `hands.gd` one `_player_of(by)` for `tuning_of`, `eyes_of`, `_body_of` (95-101, 373-391), and the drop/throw
    tails of `decide` (224-230, 239-245); the dead `mess != null` guards (291-311, 364-366);
  - `physics_queries.gd` one `_space(node)`; `overlaps` deleted if unused;
  - `cabinet.gd:238-296` `held_pairs` computed once in `shelve_refusal`;
  - Mess: `lying_patch`'s repeat of the rest branch, `dropped_patch`/`thrown_patch`, `drawn_flight_of`'s loop,
    the size scale written three times, the literal `"Flight"`, `_cut_off`'s repeat of `_show`;
  - `SockDress` and `SockLook` made one-way (or one class); `sock_look_table.gd` takes a Collection id, no probe
    `SockDesign`s; `GROUND_MASK` and `LAYER_HOUSE` use `Mess`'s constants.
- T4 Unused code removed: `MessMoving.is_waiting`, `MessBodies.body_of`, `MessDrawing.flying_count`, the unused
  `_now` parameter; `Cabinet.flights_into`, `shelved`, `FAR`; `cabinet.gd:144` `tuning_of` asserts instead of
  making a silent default; `SockDress.dress`/`tint`, `OutlineStyle.rebuild`, `UiIcons.upgrade`, the unheard
  `Footsteps` signals; `heap_counter.gd` `worst_ms`/`reset_timing`; the line-up's unused clear loop;
  `_hexa`, `_room_root`, the twice-written `pick` lambda in `house_kit_build.gd`; `zoo_net.gd:77-79`'s dead `Log`
  branch. Check tests and tools for callers first; kit template files (`carriable.gd`, `profiler.gd`, `settings.gd`,
  `session.gd`) are not touched.
- T5 (done in core/34 instead) `Prompts.target()` asks the Part for its title (`prompt_title()` on `Part`) instead of switching on classes
  (`game/ui/prompts.gd:35-40`); `Prompt` is a `RefCounted`.
- T6 Small naming fixes the review listed (`house_kit_build.gd:2` says `.tres`, `_offset` at the top, the stale
  path in `tools/furniture_from_old.py:14`, `lose_button.gd` verb as a StringName).

## Acceptance
- Every existing case passes unchanged (a test changes only where it named a removed function, and the report
  lists each).
- Stills of every zoo station before and after, in `builds/review-core-30/`, show no difference.
- Real-path case: the zoo's walk through the Sounds station (click a sound button, the sound plays) on the new
  button scene.
- The report gives game code lines before and after per area (the complexity report).

## Answers
- The review's findings are fixed, felt numbers into Resources and zoo labels as scenes included (Q2404, 2026-11-21).

## Open follow-ups
- [later] T3 `Arc.aimed()`: returning `Vector3.ZERO` whenever it does not converge made a charge-0 lob land 0.38 m
  from the crosshair (`flight_start:t03_lands` failed). The behaviour is kept (the nearest aim found); the comment
  now says what it does. Changing it is a change the player sees, so it is the designer's.
- [later] T3 `LAYER_HOUSE` in `tools/house_kit_build.gd` and `tools/furniture_build.gd` stays `1`: a `--script` run
  has no autoloads, and naming `Mess` (whose scripts name `Sounds`) stops the tool compiling (tried). Found on the
  way: `tools/furniture_build.gd` already does not compile in a `--script` run (it preloads `openable.gd`, which
  names `Sounds`); a tool fault for the lead.
- [later] T4 `Cabinet.shelved()` and `Cabinet.flights_into()` are kept: the cabinet, drawer-details and zoo suites
  call them (about 20 places). `Cabinet.FAR` is gone (the refusal is `Hands.FAR`, the same "far").
- [later] T6 `tools/furniture_from_old.py:14` was already right after core/34 (its line 5 was the stale one).

## Built log

### 2026-11-21
- Changed: nothing the player sees. Felt numbers moved into HandsTuning, MessTuning, the theme (`Hud` colours and
  spacing; text sizes read from the variations) and exports (Avatar glide, PowerRing, Picture, IconsStation); the
  Mess and the Cabinet assert their tuning. Zoo stations instance `zoo_label.tscn`, `sound_button.tscn`,
  `icon_cell.tscn`, `swatch.tscn`. Duplication removed (`Hands._player_of`, `_let_go`, `thrown_patch(.., drop)`,
  `Mess._take_down`, `_pose_into`, `SockDress.scale_of`, `Arc._stepped`, `PhysicsQueries._space`,
  `DesignCatalogue.collections()`/`rows_of`, `keep_uid` shared by the house builders); unused code removed. Tests
  changed where they named a changed function: `sock_looks_test` (4 lines), `every_sock_test` (2 lines).
- Files: game/hands, game/mess, game/sock, game/ui/hud.gd, game/look/theme.tres, game/zoo/*, tools/house_kit_build.gd,
  tools/old_house_build.gd, tests/sounds_test.gd (new case core30_button_scene), tools/shots/sets/review-tidy.txt
- Verified: `PASS 16722 checks, 363 cases` (--touched); `builds/review-core-30/` (33 shots, before at c8ac0f5):
  28 identical to the pixel, 5 differ only in the heap counter's live "Tick ms" digits.
