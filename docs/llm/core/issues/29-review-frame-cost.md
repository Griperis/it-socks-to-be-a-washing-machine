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

# Code review: per-frame cost outside the Mess

The M0.5 code review found work repeated every frame in the player, the hands and the held view. Cut it without
changing what the player sees or how anything feels. (The Mess's own per-frame findings are core/31's.)

## Behaviour list
- F1 While something is held, `AimFinder.find` runs once per physics tick, not twice: `drop_spot` takes the tick's
  `found`; the tick keeps its spot and refusal, and a drop click uses them instead of computing a third time
  (`game/player/player.gd:281-286`, `374-375`, `382-404`).
- F2 Probe shapes are reused, not made per query (`game/hands/physics_queries.gd:13`, `game/hands/hands.gd:403`).
- F3 The held Sock's sway looks up its `SockCloth` and nearest bone once, when its Looks is made, not with a
  recursive `find_children` every frame (`game/hands/held_view.gd:430,470`, called from `game/ui/hud.gd:384`; leave `hud.gd` as it is, core/28 edits it);
  `_watch_bend` (413-419) builds a pose array only for the Socks that use it (the active one, a let-go bend).
- F4 HeldView's nine per-Sock dictionaries are cleared by one `_forget(sock)` used by both paths
  (`held_view.gd:49-64`, `89-93`, `296-302`); the pairing path no longer leaves `_spin` behind for the ball.
- F5 `PairMoment.fold` caches its two `SockCloth` lookups (`game/sock/pair_moment.gd:62-67`).
- F6 `UiIcons` caches a missing icon too (`game/ui/ui_icons.gd:47`).

## Acceptance
- A timing case per change where one is cheap (count queries or allocations per tick before and after, not wall
  time), and every existing case still passes.
- Real-path case: in the zoo, the player picks up a Sock, aims at the floor and drops it; it lands where the aim
  showed (the drop path through the new shared spot).
- Report the before/after numbers (queries per held tick, `find_children` calls per frame).

## Answers
- The review's findings are fixed (Q2404, 2026-11-21).

## Open follow-ups

## Built log

- 2026-11-21
  - Changed: F1 one `AimFinder.find` per held tick (`drop_spot(found)`, the tick keeps `_tick_spot` and
    `_tick_refusal`, a drop click uses them); F2 probe spheres reused; F3 `SockCloth` found once per held Sock,
    nearest bone once, bends noted only for Socks that have been active; F4 `_forget(sock)` for both paths (the
    ball pairing path now clears `_spin`); F5 `PairMoment` caches its cloths; F6 `UiIcons` caches a miss.
    Before/after per held tick: aim lookups 2 -> 1 (a drop click: 3 -> 0 more), drop-spot queries 1 -> 1 (click: +1 -> 0),
    `find_children` per frame 1 -> 0, sphere shapes made per tick 1 -> 0.
  - Files: game/player/player.gd, game/hands/{hands,held_view,physics_queries}.gd, game/sock/pair_moment.gd,
    game/ui/ui_icons.gd, tests/handling_test.gd.
  - Added counters for the timing case (`Player.aim_finds`, `PhysicsQueries.ball_queries`, `HeldView.cloth_searches`,
    `HeldView.bends_noted`, `PairMoment.cloth_searches`).
  - Verified: PASS 16116 checks, 339 cases (--touched); PASS rules.
- Merged: 5ae33583 (2026-11-21, branch core/29-review-frame-cost)
