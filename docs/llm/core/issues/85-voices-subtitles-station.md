---
type: ticket
status: done
kind: build
area: core
feature: voice
priority: now
created: 2026-11-24
done:
blocked_by: [core/84]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Voice line]
---

# Voices, Subtitles and the Voice station

Lines heard and read: build `docs/architecture/voice.md` "Playing", "Cutscenes" (`play_cutscene`), the co-op rules, and the Voice
station: `Voices` (channels, priority and `waits`, the Voice and new MuffledVoice buses, earshot and level band,
`display/subtitles`, the cutscene duck, the signals), `VoicePicker` (Q2637), `VoiceSource`, `subtitles.tscn` on the
Theme with the speaker's icon (a plain disc until assets/15), the station built from the VoiceBook with a zoo-only
stand-in source and its station-only `say_line`.

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "The voice system as the player meets it" (all); "Its comments": the hearing, linger and
replace lines; "Its cutscenes": the duck and tail lines.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The station lists every line from the baked banks at load (Q2337): a new line in the JSON, baked, is a new pillar
with no other change. `VoiceTuning` (the duck's 0.25 and 0.5 s), placeholders.

## Acceptance
- Real path: in the Voice station the player presses E at a washer line's pillar; the Subtitles row shows the line's first segment text with the washer's icon and the stand-in's AnimationPlayer plays the take's acting; behind the shut Door the row still shows and the voice is on MuffledVoice.
- The picker: a fitting line, never the last, each once before repeats, the fallback for a trigger no line has.
- A higher speaker cuts a lower; a lower is dropped; a `waits` line waits.
- Co-op: a Guest's `talk` is decided on the Host; both machines play the same line and take.
- Placeholders: `VoiceTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- One picker for every speaker (Q2637, 2026-11-24).
- The subtitle icon is its own look ticket (Q2641, 2026-11-24).

## Open follow-ups

## Built log

### 2026-11-25
- Changed: `Voices` autoload (channels, priority and `waits`, earshot and level band, `display/subtitles`, the cutscene duck, signals, `play_cutscene`), `VoicePicker`, `VoiceSource`, `VoiceChannel`, `VoiceTuning` (placeholders), `Subtitles` and `SubtitleRow` on the Theme (`SubtitleLabel`, `SubtitleIcon` disc), the MuffledVoice bus, the Voice station (pillars built from the VoiceBook, a stand-in speaker Part with `talk`, `say_line`, `cutscene`, a second speaker behind a shut Door, a radio) placed at (78, 0, 2). Five rows under "Settled by the old game".
- Files: `game/voice/{voices,voice_channel,voice_picker,voice_source,voice_tuning,subtitles,subtitle_row}.*`, `game/zoo/voice/*`, `game/zoo/stations/voice.tscn`, `tests/voice_test.gd`, `default_bus_layout.tres`, `game/look/theme.tres`, `project.godot` (autoload), `tests/hooks.gd`.
- Verified: `--touched` ran every suite (an autoload changed); only 3 failures, in the new suite, fixed after (picker fallback no longer takes cutscene lines; a wrong earshot edge in the test).
