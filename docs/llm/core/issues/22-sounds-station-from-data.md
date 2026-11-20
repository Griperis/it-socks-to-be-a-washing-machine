---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: ["[[17-sound-system]]"]
notes: []
terms: []
---

# The Sounds station, built from the catalogue

The Sounds station (core/17) is 135 nodes placed by hand: a new sound event gets no button. The designer wants every
data station built from its data (Q2337) and smaller boxes here.

## Behaviour list
- D01 The station builds one button per event of the sound catalogue when it enters the tree, in the catalogue's order,
  grouped by bus or group, each labelled with the event's name; a new event in the catalogue appears with no other
  change.
- D02 The buttons are small boxes (about 0.3 m, a layout tuning number, placeholder), in rows, so the whole catalogue
  fits on a compact pad.
- D03 A button plays its event flat or from its own spot in 3D as today; the ambience and footsteps parts of the station
  stay.
- D04 The station still runs alone and stays clear of the other stations' pads (the zoo check).

## Acceptance
- One test per line (a test adds an event to a copy of the catalogue and finds its button); a still in
  `builds/review-core-22/`; the ticket goes ready-for-human.

## Answers
- Q2337 (2026-11-20).
- Q2340 (2026-11-20): the still showed overlapping labels and the station sign over the buttons; fix both (column pitch 0.75 m, block moved forward to z 0.9) and merge without another still.

## Open follow-ups
- [later] The hand-made `BehindDoor` and `InTheOpen` buttons stay beside the Door (the muffling test's fixtures); looping events (amb_room) get no button, the station's Ambience node plays them. Say if either should change.
- [later] Layout numbers (0.3 m box, 9 per row, pitches, origin) are placeholders in `game/zoo/sounds_layout.tres`, for the designer's eye on the still.

## Built log
- Model: Sonnet (lead): a station built from data, like the every-Sock station.

### 2026-11-20
- Changed: `SoundsStation` builds a 0.3 m box button (body, SoundSpot, name) per non-loop event in the catalogue's order, grouped by bus, in rows of 9 on the front of the pad; the 19 hand-placed pillars are gone from sounds.tscn. S10 now walks to a front-row button, looks down with the mouse and presses use. New cases d01, d02, d04; shot action `sounds` and set `sounds-station`.
- Files: game/zoo/sounds_station.gd, sounds_layout.gd, sounds_layout.tres, stations/sounds.tscn, tests/sounds_test.gd, tools/shot_hooks.gd, tools/shots/sets/sounds-station.txt.
- Verified: PASS 5915 checks, 96 cases. Stills: builds/review-core-22/.
- Q2340 fix: column pitch 0.55 to 0.75 m, block origin to (-3.0, 0, 0.9), sounds_layout.tres given its uid. Verified: see commit.
- Merged: f0f6e333 (2026-11-20, branch core/22-sounds-station-from-data)
