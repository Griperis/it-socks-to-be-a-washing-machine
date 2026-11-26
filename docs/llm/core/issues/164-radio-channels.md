---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: audio
priority: now
created: 2026-11-26
done:
blocked_by: ["[[163-radio-carried-and-thrown]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 4", "suggested model: opus"]
terms: [Radio, Channel, Session]
suites: [sounds, sound_wiring, save, coop_join, voice, menus, zoo]
---

# The Radio's channels: the game's music

The Radio is the game's only music (R14): E turns its knob to the next of its six channels and back to Off, with the
click and a burst of static; everyone hears the same track roughly in step, in every room, louder and from its side
near it, muffled through a shut Door. Build `docs/architecture/tv-and-radio.md` "`ChannelKnob`", "The broadcast",
"The Radio, the game's music", draft 150-B:

- `ChannelKnob` (`game/devices/channels/channel_knob.gd`, a Part: `channel`, `on_air`; `turn`; `keeps_on_load`,
  `start_channel`), `ChannelKnobTuning` (`static_seconds` 0.6, `stagger` 37 s), `Channel` (one `.tres` per channel);
- the six Radio channels in `game/devices/radio/channels/`, the old tracks copied into `assets/radio/music/<channel>/`
  with their `credits.tres` lines (CC0 or public domain; CC-BY with credit for Metal and Rock);
- `RadioSound` (Music bus, attenuation off, near within 3 m up to 3 dB and panned, fully within 1 m; MuffledMusic with a
  shut Door between), `RadioTuning`;
- `Sounds.reach_of(where)` (CLEAR, MUFFLED, WALLED) beside `is_muffled()`;
- the dial clips (`on`, `off`, `dial` played as a section from the old mark to the new over the static's time);
- the carrier's E turns it whatever else is in reach (through core/163's `held_input`); the hint "Radio: Theme";
- the station's board (every channel of the folders, dial order, title, tracks and their licence lines), a room with a
  Door and a doorway, a stand-in cutscene button to hear the duck.

Behaviour lines (`13-tv-and-radio.md`): R3, R4 (the Radio's), R5, R6 (the dial), R14, R15, R16, R17, R18, R19 (the
Radio's), R21, R22; R2's channel; the words "%s: %s", "Off", the Radio's channel names.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Channels and tracks are files: a `Channel` `.tres` and a folder of `.ogg` (listed with
`ResourceLoader.list_directory()`), plus a credits line, show on the knob and the station with no code. The numbers are
typed Resources in the inspector (`# placeholder:` the old `devices.json`); the dial's motion is clips (Q2697).

## Acceptance
- Real path: in the TV and Radio station the player presses E on the Radio: `device_click`, 0.6 s of `radio_static`,
  then the next channel plays and the hint reads "Radio: Lo-fi".
- Walking into the next room through the doorway the music stays, louder and panned within 3 m of the Radio; with the
  Door shut it plays on MuffledMusic.
- Carrying it, E turns it while the TV is in reach.
- Co-op: a Guest's E turns it for everyone; a late joiner hears the same track near the same place, with no click.
- A load keeps the channel; a New Game starts on Theme; the duck button lowers the Music bus to 0.25 over 0.5 s.
- Every track has its credit (`menus` l02).
- Placeholders: `ChannelKnobTuning`, `RadioTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The old tracks; the hint names the current channel; a load keeps the Radio's channel; the Radio's near reaches open
  rooms (Q2704, 2026-11-26).

## Open follow-ups
