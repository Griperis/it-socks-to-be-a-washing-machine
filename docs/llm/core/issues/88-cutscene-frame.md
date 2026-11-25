---
type: ticket
status: done
kind: build
area: core
feature: cutscene
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/86]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Host, Guest]
---

# The Cutscene frame

One frame for every batch A cutscene (core/72's draft 4 and core/73's draft 5 merged): build `docs/architecture/run-ends.md` "The
Cutscene frame": the `Cutscenes` Part (Host starts and ends, a Host-only `skip`, in the join snapshot), the
`CutsceneScript` Resource (beats, voice trigger, lead, respawn, hold black, no-voice length) and the `CutscenePlayer`
(menus closed, input off, HUD hidden, Socks, Pairs, items, Laundry bins and avatars not drawn, the washer's wide and
close shots and the cut rule, the shared fade, `Voices.play_cutscene`, the Host's "[Space] Skip", the respawn at the
washer's `Spawns` with every knockdown ended, a Guest holding black until the Host's end, a late joiner after it).

Behaviour lines: `docs/migration/m4-lists/05-washer-and-voices.md` "Its cutscenes" (the frame's lines: shared camera, hiding, fades, lead and tail, the cuts,
no-voice lengths, skip, respawn); `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "The First wash": the camera, fade, duck, skip, respawn and late-join lines.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

A cutscene is a `CutsceneScript` `.tres` (beats as data, its voice trigger picked in the inspector); the shots are
the washer's markers. The washer station gets one pillar per CUTSCENE trigger found at load (Q2337), playing it on
the frame.

## Acceptance
- Hiding for a cutscene calls `LaundryBin.set_drawn()` on group `laundry_bins` (core/90's hook).
- Real path: in the washer station the player presses E on "Play cutscene_fix_1"; the camera is the washer's wide shot, the subtitle shows cutscene_2's first segment, at its second segment the camera is the close shot; the Host presses Space and the player stands at a spawn with input back and the HUD shown.
- Co-op (0 and 50 ms): the Guest sees the same cutscene, cannot skip, and respawns at the Host's end; a late joiner during it spawns after it at the laundry.
- Without a voice line it holds the wide shot for its no-voice length.
- Placeholders: the fade and the no-voice lengths.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- cutscene_3 plays the washer's line alone in batch A (Q2633, 2026-11-24).

## Open follow-ups
- For the lead before the merge (old details of the named lines this frame cannot build yet): "every knockdown wash
  ended" at the respawn waits for the knockdown wash (not built; the end answer is where it belongs, `Cutscenes._ended`);
  the First wash's 1 cm bob on the wide shot and its beats (`calm_wash`, `break`, `door_open`, `door_close`, `spray`) are
  washer Looks methods core/94 adds, which the frame already calls by name.

## Built log
- 2026-11-25. Changed: the Cutscene frame in `game/cutscene/` (`Cutscenes` Part in the level runtime with Host-only
  `skip`/`end`, `CutsceneScript`, `CutscenePlayer` scene, `CutsceneTuning`); `Player.set_cutscene`/`respawn_at`;
  `Mess.set_drawn`; the washer's zoo-only `zoo_cutscene` and `Washer.of_level`, no mood written while a cutscene plays;
  the washer station's "Play <trigger>" pillars from the CUTSCENE triggers; input action `skip_cutscene` (Space, Start);
  the WasherLooks `set_cutscene` call slots in when core/87 lands (has_method). Files: game/cutscene/*, game/player/player.gd,
  game/mess/mess.gd, game/entities/washer/washer.gd, game/level/level_runtime.gd/.tscn, game/zoo/washer/washer_station.gd,
  game/zoo/stations/washer.tscn, project.godot, tests/cutscene_test.gd, tests/coop_cutscene_test.gd,
  tests/fixtures/cutscene_silent.tres, docs/architecture/run-ends.md, docs/migration/batch-a-review.md.
  Verified: see the commit's `suite:` line (run.sh --touched PASS).
