---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
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

## Open follow-ups

## Built log
- Model: Sonnet (lead): a station built from data, like the every-Sock station.
