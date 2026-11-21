---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: zoo
priority: now
created: 2026-11-21
done:
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

## Open follow-ups

## Built log
- Model: Sonnet: scene edits and stills.
