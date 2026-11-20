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

# Rules back to the old game

M0.5 batch 3. The differences of `docs/migration/audit-core-rules.md` that the designer sent back to the old game, one
by one (Q2297, Q2303, Q2304, Q2312). Kept as ours (not in this ticket): no 3 cm aim forgiveness, our zoom slow-down, a
drop lands square (no R turn), the same spin each Throw, a thrown Pair's drag; the pad differences wait (Q2302).

## Behaviour list
Each line names the approved line it changes, if any; the audit row gives the old file and number.
- R01 The click that captures the mouse does nothing else; while the mouse is free (after Esc), clicks, G, R and the
  wheel do nothing in the game (L03; a bug, Q2297).
- R02 With a lying Sock and a lying Pair both under the crosshair, the nearer one is aimed (the ball's surface against
  the Sock's), as the old `rig_aim.gd:30-40` (Q2303).
- R03 A woken or moving Sock can be aimed and picked mid-slide, as the old game (ADR-0008 Q783, `sock_picks.gd`
  `SOCK_LIVE`) (Q2303).
- R04 After two Socks fuse, the Pair moves to the end of the Hands and becomes the active item, as the old
  `hands.gd try_pick` (Q2304).
- R05 A drop onto a lying Sock or Pair is allowed anywhere on it, with no slope test, as the old `rig_drop.gd:88-100`
  (Q2304; changes core/02's slope rule for that case only).
- R06 A thrown Pair shelves only when it touches a drawer front, as the old `sock_flights.gd:_touch_stations`; landing
  on the Cabinet's top or sides does not shelve (Q2312).
- R07 Only a drawer takes a shelve by click (or E); the Cabinet's frame does not (Q2312).

## Acceptance
- One test per line, on the real path where the player's input matters (R01, R02, R03, R07); existing cases that
  asserted the old behaviour of ours are changed, each named in the report.

## Answers
- Q2297, Q2303, Q2304, Q2312 (2026-11-20).
- Q2339 (2026-11-20): R03 as the old game (Q783): any moving Sock can be aimed and picked, a dropped or thrown one in
  the air too; core/02's H10 ("cannot be aimed at or picked while it falls") changes to match.

## Open follow-ups
- [later] A woken Sock aimed mid-slide is not outlined (the outline is the lent Looks of a lying Sock).
- [later] The mouse wheel never captures the mouse (a wheel notch while free does nothing, R01); the old game is not
  known to differ.

## Built log
- 2026-11-20 core/14 (Sonnet). Changed: R01 `Player` acts only with the mouse captured, the capturing click's press is
  swallowed (`capture_mouse()` is new and public: tests and the pause menu use it); R02/R03 new `AimFinder`
  (`game/hands/aim_finder.gd`): the crosshair finds lying and woken Socks, a lying Sock against a Pair by distance;
  R04 a fused Pair goes last and active; R05 a lying Sock or Pair under the crosshair takes a drop anywhere (the Host
  checks a lying body within 5 cm instead of the slope); R06/R07 the Cabinet shelves a thrown Pair only on a drawer
  front in use, its frame's use does nothing. Cases changed: pairing p01 and p03 (the Pair's place in the Hands);
  every test that builds a player calls `capture_mouse()`. New: pairing r01, r02, r03, r05; cabinet r06, r07. No
  PROTOCOL change (nothing synced changed shape). Files: game/hands/{aim_finder,hands,physics_queries}.gd,
  game/mess/{mess,mess_moving}.gd, game/player/player.gd, game/entities/cabinet/cabinet.gd, tests/*.
  Q2339: any moving Sock is pickable (`Mess.is_moving`), H10's case and p07 changed, new case pairing r03_thrown. Verified: PASS 4999 checks (--touched).
- Model: Sonnet (lead): rule changes with known old code and tests.
- Merged: c747e6a6 (2026-11-20, branch core/14-rules-back-to-old)
