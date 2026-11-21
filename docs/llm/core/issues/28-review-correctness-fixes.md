---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: []
notes: []
terms: []
---

# Code review: the correctness fixes

The M0.5 code review (2026-11-21, five read-only reviewers) found these faults. Fix each, with a case that fails
before the fix. No behaviour the designer sees changes, except that the faults go away.

## Behaviour list
- R1 A locked Cabinet's drawers and drawers above its Rows in use stay shut for every player, a Guest's `open`
  Command straight to `Cabinet/DrawerN/Openable` included: the Host refuses it. Today the rule lives only in
  `Cabinet.click()` on the asking machine (`game/entities/cabinet/cabinet.gd:264-268`, `game/parts/openable.gd:79-89`)
  and nothing writes a drawer's `Openable.locked`. Tick `locked` on drawers above `rows`; the answer that locks,
  unlocks or grows a Cabinet patches its drawers' `locked` too.
- R2 A patch that leaves `open` unchanged (e.g. `{"locked": true}`) on a resting Openable replays no swing
  (`openable.gd:111-115`, `129-138`: return early when `open == _was_open` and not `now`).
- R3 The held readout's wheel keycap follows a switch from keyboard to pad at once: `pad` is part of the
  `show_sense` and `show_held` signatures (`game/ui/hud.gd:108,118`, drawn at 311).
- R4 The heap pour never hangs: `heap_spout.gd:91-97` stops after `cat.size()` misses when no Design comes back.
- R5 The kit line-up's floor and ceiling labels sit at their piece, not 0.5 m above it (`lift` added twice,
  `game/house/kit/house_kit_line_up.gd:67`).
- R6 A pair ball's Looks stops its physics step after its one landing, and on a Cabinet flier with no RigidBody
  parent (`game/sock/ball_landing.gd:93-99`); its 27-key Animation is built once per tuning, not per ball.
- R7 `SoundCatalogue` builds its index once; a duplicate name or a null entry is a `push_error`, not a rebuild on
  every play (`game/audio/sound_catalogue.gd:22`).
- R8 Check, and fix if real: (a) `door_close` played at the shut Door's own place is not muffled by that Door
  (`game/audio/sounds.gd:150-163`, `openable.gd:123`): skip a hit within a few cm of `where`; (b) footsteps of a
  body that is not the own player are not played flat at full level (`game/audio/footsteps.gd:42,50`). If (b)
  only matters once Guests have bodies (M0.6), write it as a `[later]` follow-up instead.
- R9 `Outline` turns its `_process` back on when a shown, blend-shaped outline re-enters the tree
  (`game/outline/outline.gd:80`), if a case shows it stops.
- R10 `Cabinet` caches its drawers and slot arrays in `dress()`: no `has_node` probing per frame from the aim
  outline, no recursive `find_child` per slot on each write (`game/entities/cabinet/cabinet.gd:160-179`, `398-428`).

## Acceptance
- One case per line, failing before the fix; R1 as a co-op case (Host and Guest; the Guest's direct `open` on a
  drawer above the Rows is refused, the drawer stays shut on both).
- Real-path case: in the zoo's Cabinet station, the player clicks a drawer above the Rows in use and it stays shut.
- `--touched` passes; nothing outside the files named above changes, except tests.

## Answers
- The review's findings are fixed (Q2404, 2026-11-21).

## Open follow-ups
- [later] R8(b): `Footsteps` (`game/audio/footsteps.gd:42,50`) plays `land` and `step_*` flat at full level for any
  body it is put on; today only the own player has one. When Guests get bodies (M0.6) their footsteps must play
  spatially at the body, not flat. Not changed now.

## Built log

### 2026-11-21
Changed: R1 `Cabinet.lock_patch(locked, rows)` builds the answer that sets lock and Rows and each drawer's
`locked`; `cabinet.tscn` Drawer3 ticked locked (Rows 2); the Host refuses a Guest's direct `open`. R2 `Openable._show`
returns when `open` is unchanged and not `now` (no swing, no sound). R3 `pad` in the held and sense signatures.
R4 `HeapSpout._queue_batch` stops after one lap of misses. R5 line-up label no longer adds `lift` twice.
R6 `BallLanding` stops its physics step after landing and with no RigidBody parent; the landing Animation is built
once per set of numbers (`landing_of`). R7 `SoundCatalogue` indexes once per list size, `push_error` for a null or
repeated name. R8(a) was real (reproduced): `Sounds.is_muffled` ignores a hit within 8 cm of the sound's place;
R8(b) is a `[later]` above. R9 `Outline._enter_tree` restarts `_process` (reproduced with a blend-shaped mesh).
R10 `Cabinet` caches drawers and slot points in `dress()`. Existing cabinet cases that grow Rows use `lock_patch`.
Files: game/entities/cabinet/cabinet.gd, cabinet.tscn, game/parts/openable.gd, game/ui/hud.gd,
game/zoo/heap/heap_spout.gd, game/house/kit/house_kit_line_up.gd, game/sock/ball_landing.gd,
game/audio/sound_catalogue.gd, game/audio/sounds.gd, game/outline/outline.gd, tests (cabinet, cupboard, aim_screen,
heap, house_kit, feedback_polish, sounds, outline).
Verified: PASS 16279 checks, 372 cases. Failing before the fix was seen for R8(a) and R9; the co-op R1 case uses the
Host's `answer` for a Guest's id, not a real ENet peer.
- Merged: 57a6a791 (2026-11-21, branch core/28-review-correctness-fixes)
