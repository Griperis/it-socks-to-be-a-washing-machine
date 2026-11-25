---
type: ticket
status: done
kind: build
area: core
feature: voice
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Voice line]
---

# Voice lines: the speaker's JSON and the bake

The voice system's data and its one tool. Build `docs/architecture/voice.md` "Folder layout", "A speaker's JSON", "Key types" (the
Resources and `VoiceBook` with its load checks; `Voices` and the picker are core/85) and "The bake": `tools/voice_bake.sh`
and `.gd` (headless; no editor entry, Q2639), `tools/voice_transcribe.py`, the acting Animations ported from the old
`voiceover.py` and `brows.py`, the CSV written from the JSON and registered under Localization (the one
`project.godot` change). The 21 washer recordings copied from `reference/it-socks/audio/voiceover/` to
`assets/voice/washer/`, `game/voice/lines/washer.json` written with the old corrected texts (Q1382, Q1473), triggers,
sets (stage_1..5) and moods, then baked; `washer.tres` and `washer_acting.tres` with the old numbers; batch A's trigger
files; no level adjustment anywhere (Q2638).

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "Its comments": the 15 lines' texts, lengths, triggers and moods; "Its cutscenes": the six
lines and their moods; "How it talks": what the acting Animation carries.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The designer drops a wav in `assets/voice/<speaker>/`, runs `tools/voice_bake.sh`, edits the line's entry in
`game/voice/lines/<speaker>.json`, runs it again (`docs/architecture/voice.md`); speakers, acting profiles and triggers are Resources
edited in the inspector.

## Acceptance
- Real path (the designer's): a fixture wav dropped into a test speaker folder and `tools/voice_bake.sh` run headless gives a new JSON entry and a bank line the VoiceBook lists at the next load; its take's acting opens the mouth on the loud parts and is shut at the end; a hand edit of the entry's triggers and text survives a second bake; an unknown trigger stops the bake naming the line.
- The 21 washer lines load with no VoiceBook error; every key has CSV text; no take carries a gain.
- No game behaviour changes (nothing plays yet).
- Placeholders: the speaker's and acting profile's numbers (the old ones).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Lines are one JSON per speaker, checked and built by the bake; replaces Q2608's Resource per line (Q2640, 2026-11-24).
- The bake is a command; no editor entry or automatic bake (Q2639, 2026-11-24).
- No level adjustment by the game or the bake (Q2638, 2026-11-24).
- cutscene_5 and cutscene_6 whole (Q2634, Q2629, 2026-11-24); cutscene_3 the washer's alone (Q2633, 2026-11-24).

## Open follow-ups

## Built log
- 2026-11-25. Changed: the voice data and its bake. The Resources `VoiceSpeaker`, `VoiceActing`, `VoiceMood` (one mood's
  pose, brow acting and glow), `VoiceTrigger`, `VoiceBank` (with `lines_md5`), `VoiceLine` (with `marks`), `VoiceTake`
  (no gain), `VoiceSegment`, and `VoiceBook` with its load checks (bank older than its JSON, missing trigger file, key
  without CSV text). The bake: `tools/voice_bake.sh` (import, bake, import; project.godot put back) and
  `tools/voice_bake.gd` (headless script entry), `VoiceBaker` (JSON check and completion, timing, banks, CSV; stops on
  an error before writing, naming the line), `VoiceLipsync` (the old voiceover.py door curve and brows.py acting,
  wiggle, angry share and mood glow ported), `VoiceFiles` (the JSON in the designer's order, CSV rows, the editor's uid
  format a headless save lacks); `tools/voice_transcribe.py` (faster-whisper small.en; without it new lines get TODO).
  The 21 washer recordings in `assets/voice/washer/`, `game/voice/lines/washer.json` (the old corrected texts, triggers,
  sets 1-5, moods, and the old segment times as `timing`), `washer.tres`, `washer_acting.tres` (old numbers), the ten
  batch A trigger files, baked to `game/voice/baked/`; `voice_lines.csv` registered under Localization (the one
  project.godot change); a credits entry for the recordings. Settled by the old game (batch-a-review.md): the untagged
  comments get all four comment triggers; the optional per-recording `timing`; the credits entry.
  Files: see the commit. Verified: `kit/tools/run.sh --touched` (the commit's verdict lines); `tests/voice_bake_test.gd`.
- Merged: ff8944fc (2026-11-25, branch core/84-voice-data-and-bake)
