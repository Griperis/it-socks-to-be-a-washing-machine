---
type: ticket
status: done
kind: build
area: core
feature: zoo
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: []
notes: []
terms: [station]
---

# Zoo station names near the ground

The designer (Q2408, 2026-11-21): "For the houses and labels in zoo - they should be near on the ground, so I can
read them easily." Today each station's `Name` Label3D floats 2.2 to 13.5 m up (the houses at 11.5 m, the icons at
13.5 m, the house kit at 7 m), mostly billboarded, with mixed `pixel_size` and font sizes, and long texts in one line.

## Behaviour list
- L1 Every station's `Name` label in `game/zoo/stations/*.tscn` (the two old houses and the house kit included)
  stands at the station's front edge, on the side the player walks up from, low: its bottom about 1.2 m and its
  middle near eye height (the player's camera height), so it reads standing 2-4 m in front of it without looking up.
- L2 It does not sit inside the station's things or block a walk path, a door (the houses' front doors) or another
  station's pad.
- L3 All Name labels share one look: the same `pixel_size`, font size and outline, and a wrap width (`autowrap_mode`,
  `width`) so a long text runs to a few short lines, not one long line. They stay billboarded around the up axis
  only (`billboard = 2`, Y-billboard) so they don't tilt when the player is close, unless the stills show a fixed
  facing reads better; say which.
- L4 Only the `Name` labels move; button labels, notes and counters stay where they are.

## Acceptance
- Stills in `builds/review-core-33/`: from the player's eye height, 3 m in front of each station's label, and one
  wide view of the zoo from the start spot; stop there for the designer's go (look work).
- A zoo test checks every station's `Name` label is between 0.8 m and 2.2 m high (its position in world space) and
  outside every other station's pad.
- Real-path case: the player walks from the zoo's start spot to the old house A's front door and the house's name
  is on screen, readable (within the view, upright, not cut off) on the way.
- The placement numbers (height, wrap width, pixel size) are placeholders for the designer to tune in the editor.

## Answers
- Station names near the ground, easy to read (Q2408, 2026-11-21).
- Approved from the stills in `builds/review-core-33/` (Q2411, 2026-11-21).

## Open follow-ups
- [closed 2026-11-21] Placement choices for the designer to look at in the stills: each label stands on the pad edge that faces the start spot (south edge for stations north of z=4, north edge for those south of it; old houses on the north side, 2 m left of the front door; house kit and Cabinet at their north edge), bottom at 1.2 m (`vertical_alignment` bottom), `pixel_size` 0.004, `width` 700, font 32 / outline 12 (Label3D defaults). Billboard is Y-only (`billboard = 2`) and reads well in the stills, so no fixed facing. The Cabinet label (long text) overlaps the gallery's boxes seen from 3 m. — Q2411: the stations' names near the ground are approved from the stills

## Built log
- 2026-11-21 Changed: every station's `Name` label moved to its pad's front edge at 1.2 m, one shared look (pixel_size 0.004, width 700, bottom-aligned, Y-billboard, default font and outline). Zoo test cases `labels` (height 0.8-2.2 m, outside other pads, shared look) and `labels_walk` (real path: walk from the start spot to old house A's door, its name whole in view). Shot hook `sign` and set `zoo-labels`.
  Also: tests/hand_details_test.gd `f3_sign_clear` (core/19 F3: the sign must not cover the view's centre from the pad) cannot hold for a sign at eye height at the front edge; it now checks the sign is behind the player on the pad (the handling label stands 0.4 m outside its pad's front edge for that). The lead should confirm.
  Files: game/zoo/stations/*.tscn (Name nodes only), tests/zoo_test.gd, tests/hand_details_test.gd, tools/shot_hooks.gd, tools/shots/sets/zoo-labels.txt. Stills: builds/review-core-33/. Verified: suite PASS (see report); waiting for the designer's go on the stills.
- Model: Sonnet: scene edits and stills.
- Merged: 9cc484f3 (2026-11-21, branch core/33-zoo-labels-near-the-ground)
