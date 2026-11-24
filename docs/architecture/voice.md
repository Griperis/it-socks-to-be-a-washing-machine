# Voice (build plan)

**Status: build plan for batch A (designed in core/73; W1-W10 answered Q2633-Q2642, and Q2640 changed the line data;
filed by core/74 as core/84 and core/85, the icon assets/15).** It turns core/56's proposal into what is built.
Decided: Q2545-Q2552 (V1-V8), Q2608 (authoring, its Resource per line replaced by Q2640), Q2609 (speakers), Q2633-Q2640.
The findings: `docs/migration/voice-findings.md`; the washer's behaviour list:
`docs/migration/m4-lists/05-washer-and-voices.md`; the washer as an entity: `docs/architecture/washer.md`.

## What it owns

Every spoken line: how it is written (one JSON file per speaker, Q2640), built (the bake command), picked (one picker),
triggered (the trigger list), played (one autoload, one channel per speaker, the priority rule), heard (the Voice bus,
muffling, earshot), subtitled (one scene on the Theme) and shown in the zoo (the Voice station, built from the lines at
load). It does not own a speaker's body or face (each speaker's Looks plays the line's acting Animation), the cutscene
frame (camera, freeze, fade, skip, respawn: `docs/architecture/run-ends.md` "The Cutscene frame"), nor when a game
moment happens (the feature that owns the moment fires the trigger).

## Decided

V1 the Host decides every speaker's line (Q2545). V2 a baked Animation per take, played by the speaker's Looks
AnimationPlayer with the audio (Q2546). V3 several takes, one at random (Q2547). V4 cutscene > washer > Old Tree, the
higher cuts the lower, lower ones dropped except story beats that wait (Q2548). V5 a Voice bus with its slider, the
music ducks only in cutscenes (Q2549). V6 the old subtitle look on the Theme, one row per speaker, the speaker's icon,
no name (Q2550). V7 the text from transcribing the recording, corrected by hand (Q2551; now in the speaker's JSON).
V8 a subtitle shows within earshot, through a shut Door too (Q2552). Q2608: drop the recording into the speaker's
folder; the trigger is picked from a list; a Voice station plays every line. Q2609: the speakers are the washer, the
Old Tree and cutscenes 1-6, no plot NPC. Batch A's answers:

- **Lines are one JSON file per speaker** (each line's id, trigger, text, recording files), checked and built by the
  bake command; no Resource per line (Q2640).
- **One picker for every speaker:** a fitting line, never the last one, each fitting line once before any repeats
  (Q2637).
- **No level adjustment** by the game or the bake: the recordings are fixed at the source (Q2638). Every take plays at
  its speaker's `voice_db`, 0 dB (the old +6 dB for comments is not carried over; the lead's reading, on the review
  sheet).
- **The bake is a command** that agents and the designer run; no editor entry, no automatic bake (Q2639).
- **cutscene_3** plays the washer's recording alone in batch A; the Old Tree's line joins it in batch B as a second line
  of the same trigger in its own speaker's JSON, no code (Q2633, confirming Q2609).
- **cutscene_5** plays whole at the fourth Fix; **cutscene_6** whole at the Final wash (Q2634, Q2629). The voiceovers
  will change: swapping a recording is replacing its wav and running the bake (below).
- **The Laundry day's comments** are a customisable set; by default Stage 4's (Q2635: `StagePlan.laundry_day_comment_set`).
- **The washer is silent** until the First wash breaks it (Q2636).
- **The washer's subtitle icon** is a flat drawn icon in the UI icons' style, its own look ticket, assets/15 (Q2641);
  until it lands, a plain disc in the Theme's colours.

## Folder layout

| Path | What | Who writes it |
|---|---|---|
| `assets/voice/<speaker>/<file>.wav` | the recordings, 16-bit PCM wav | the designer drops them |
| `game/voice/lines/<speaker>.json` | **the speaker's lines** (below): the one file a designer edits | the bake adds a new recording's entry; the designer edits it |
| `game/voice/speakers/<speaker>.tres` | one `VoiceSpeaker` per speaker: `washer.tres` (batch A), `old_tree.tres` (batch B) | made once per speaker, edited in the inspector |
| `game/voice/speakers/<speaker>_acting.tres` | the speaker's `VoiceActing`: how the bake turns loudness and moods into its rig's tracks | made once per speaker |
| `game/voice/triggers/<trigger>.tres` | one `VoiceTrigger` per game moment that may speak (the trigger list) | see "Triggers" |
| `game/voice/baked/<speaker>.tres` | the speaker's `VoiceBank`: every line's takes with their timing, the bake's alone | the bake |
| `game/voice/baked/<speaker>/<file>.anim.tres` | one acting Animation per take (mouth, brows, lean, wiggle, glow), the bake's alone | the bake |
| `game/voice/voice_lines.csv` | the string table of every subtitle (`keys,en`, key `VO_<LINE>_<n>`), written by the bake from the JSON texts; registered under Project Settings, Localization (one `project.godot` change, core/84) | the bake |
| `game/voice/*.gd` | the code: `voice_speaker.gd`, `voice_acting.gd`, `voice_trigger.gd`, `voice_bank.gd`, `voice_line.gd`, `voice_take.gd`, `voice_segment.gd`, `voice_book.gd`, `voice_picker.gd`, `voices.gd` (autoload), `voice_source.gd`, `subtitles.tscn` | agents |
| `tools/voice_bake.gd`, `tools/voice_bake.sh` | the bake command (Godot, headless) | agents |
| `tools/voice_transcribe.py` | the transcription step (faster-whisper `small.en`, offline once its model is downloaded, as the old `voiceover.py`) | agents |
| `game/zoo/stations/voice.tscn` | the Voice station | agents |

`assets/voice/` holds only recordings; Godot imports them (their `.import` committed, compressed as QOA for the game).
The lines live under `game/voice/` because they are game data a designer edits (Q2167: game apart from assets).

## A speaker's JSON (Q2640)

`game/voice/lines/washer.json`, one object per line, in the order the station lists them:

```json
{
  "speaker": "washer",
  "lines": [
    {
      "id": "stage_1_voice_A",
      "triggers": ["washer_stare"],
      "sets": [1],
      "text": ["I don't wanna talk to you!"],
      "recordings": ["stage_1_voice_A.wav"],
      "moods": [[0.0, "angry"]],
      "order": 0,
      "waits": false,
      "placeholder": false,
      "note": ""
    }
  ]
}
```

- `id`: the line's name (the first recording's file stem by default); the CSV keys are `VO_<ID>_<n>`.
- `triggers`: trigger ids, each the stem of a file in `game/voice/triggers/`; empty = it never plays in a game (the
  station still plays it, marked "no trigger"). An unknown id is a bake error that names the known ones.
- `sets`: the comment sets it may play in (the old stage_1..stage_5 files made a field); empty = any. A set is a number
  the run gives (`Stage.comment_set`, `StagePlan.laundry_day_comment_set`, `stages.md`).
- `text`: the subtitle, one string per segment, in order. Every take of the line has that many segments.
- `recordings`: the wav files in the speaker's folder, one per take (Q2547); a second take is a second file.
- `moods`: `[seconds, mood]` keys (a mood of the speaker's `VoiceActing.moods`); seeded with the speaker's default mood.
- `order`: its place within a cutscene trigger; `waits`: a story beat that waits instead of being dropped (V4; the Old
  Tree's, batch B); `placeholder`, `note`: for the designer.

## Key types

All typed, one class per file (Q2251-Q2253). The designer edits the JSON, the speakers, the acting profiles and the
triggers; the rest the bake writes.

- **`VoiceSpeaker`** (Resource): `id`; `icon: Texture2D` (the subtitle's, V6); `priority: int` (cutscene 30, washer 20,
  Old Tree 10, V4); `positional: bool`; `unit_size`, `max_distance` (m); `earshot`, `level_band` (m, the subtitle's reach,
  V8); `voice_db` (0, Q2638); `cooldown` (s, between two lines of this speaker given by a trigger); `default_mood`;
  `acting: VoiceActing`; `tail` (s after the last word); `linger` (s a segment stays past its end). Washer values are the
  old ones (`docs/architecture/washer.md` "Numbers"), each marked `# placeholder:` as in the old tuning.
- **`VoiceActing`** (Resource): what the bake writes for this speaker's rig: the mouth bone and its open angle, the
  loudness window (20 ms), smoothing (0.6), gate (8 %), keys a second (30); the moods with each one's lean and brow pose;
  the brow acting's flick sizes; the mood blend (0.4 s); the property tracks (`wiggle`, `glow_colour`, `glow_energy`) and
  each mood's glow. The washer's carries the old `voiceover.py` and `brows.py` numbers. The Old Tree's (batch B) has its
  rustle instead of brows; the bake's code is the same, the profile differs.
- **`VoiceTrigger`** (Resource): `id: StringName`; `speaker: VoiceSpeaker`; `kind` (COMMENT: a line picked by the
  speaker's director with cooldown and chance; CUTSCENE: every line with this trigger, of every speaker, in `order`,
  played as a cutscene); `chance: float` (1 but the stare's 0.5); `ignores_cooldown: bool`; `note` (what fires it: the
  seam, for the designer).
- **`VoiceBank`** (Resource, the bake's): `speaker`, `lines: Array[VoiceLine]`.
- **`VoiceLine`** (Resource inside the bank, the bake's copy of a JSON entry): `id`, `triggers: Array[VoiceTrigger]`,
  `sets`, `keys: PackedStringArray`, `takes: Array[VoiceTake]`, `order`, `waits`, `placeholder`.
- **`VoiceTake`**: `stream: AudioStream`; `source_md5` (the bake re-bakes a take whose wav changed); `duration`;
  `segments: Array[VoiceSegment]`; `acting: Animation` (the external acting file). No gain field (Q2638).
- **`VoiceSegment`**: `start`, `end` (s), `key: StringName`. Every take of a line has the same keys in the same order;
  their times are the take's own.
- **`VoiceBook`** (RefCounted, built at load): every `VoiceBank` under `game/voice/baked/`, grouped by speaker and
  trigger. A bank older than its JSON (the bake not run), a missing trigger file, or a key missing from the CSV is a load
  error a test catches.
- **`VoicePicker`** (RefCounted, rules only): the lines of (speaker, trigger, set); fit first (a line with the trigger;
  when none fits, any line of the speaker's set: the old washer fallback, so a "hit" plays any line); never the last
  line; each fitting line once before any repeats (Q2637); seeded RNG for tests. The take is picked here too, so the
  Host's answer carries both.
- **`Voices`** (autoload, looks only, as `Sounds`): `say(line, take, source: VoiceSource, as_cutscene := false)`;
  `play_cutscene(trigger, takes)`; `stop(speaker)`; `talking(speaker) -> bool`; `cutscene_playing() -> bool`; signals
  `started(line, take)`, `segment_changed(line, index)`, `finished(line, skipped)`. It owns one channel per speaker and
  one for cutscenes, the priority rule, the 3D and flat players, the bus choice, the music duck and the Subtitles.
- **`VoiceSource`** (Node3D script, on a speaker's Looks): where the voice sounds from and the speaker's face:
  `act(take)` plays the take's acting Animation on the Looks' AnimationPlayer from its start, `rest()` goes back to the
  basic pose. The washer's Looks has one (`washer.md`); a cutscene line plays its acting on the speaker's source while
  the sound is flat.
- **`Subtitles`** (`game/voice/subtitles.tscn`, a Control on the one Theme, under the HUD's layer, on top in cutscenes):
  one row per speaker talking now (an icon and a Label), bottom centre, the old look made Theme styles (`SubtitleLabel`:
  cream, black outline 10 at 0.85, 30 px at 1080p; 160 px side margins); text through `tr(key)`. Rows stack in priority
  order, the highest at the bottom.

## The bake: adding or swapping a line (Q2608, Q2639, Q2640)

1. **Drop** `my_line.wav` into `assets/voice/washer/` (the folder names the speaker; a new folder needs its
   `speakers/<folder>.tres` and an empty `lines/<folder>.json`, which the bake makes from copies of the washer's and
   reports).
2. **Run** `tools/voice_bake.sh` (the designer and agents alike; no editor entry, Q2639). For the speaker's JSON and
   every wav in its folder:
   - a wav named in no line gets a new line in the JSON: `id` its stem, `recordings` [it], `triggers` empty, `text` from
     `tools/voice_transcribe.py` (the segments' times and English text; without whisper installed one segment over the
     voiced span with the text `TODO`, said in the output);
   - a wav whose take is new or whose `source_md5` changed is timed again: whisper's segments matched to the line's
     `text` by order (a count that differs is reported and the station marks the line), or, with `--retranscribe`, its
     `text` replaced;
   - the take's acting Animation is written from the loudness, the segment texts (`?` and `!`), the line's moods and the
     speaker's `VoiceActing` (the old `voiceover.py` door curve and `brows.py` acting, ported into GDScript);
   - the JSON is checked (unknown triggers, a recording that is missing, a mood the speaker lacks) and the bake stops on
     an error, naming the line;
   - `game/voice/baked/<speaker>.tres` and the acting files are written through `ResourceSaver` (with their `uid=`, in
     the editor's own format, Q2268); the CSV is written from every JSON's `text`. The JSON is written back only to add a
     new line or, with `--retranscribe`, new text, keeping the designer's order and fields.
3. **Edit the line** in the JSON: its `triggers`, `sets`, `text` (the correction of the transcription), `moods`; run the
   bake again.
4. **See it** in the Voice station at the next load (Q2337): its pillar, its subtitle, its acting on the stand-in face.

Swapping a recording (the cutscenes will be re-voiced, Q2634): replace the wav under the same name, run the bake; id,
text, triggers and moods stay; timing and acting are remade. A second take: drop `my_line_b.wav` and add it to the
line's `recordings` (or let the bake add it as its own line and merge by hand). Removing a line: delete its wav and its
JSON entry, run the bake. A line id appears in no save, so renaming is editing the JSON's `id`.

The bake's tests (core/84): a fixture wav (a generated tone pattern under `tests/fixtures/voice/`) dropped into a test
speaker folder bakes to a new JSON entry and a bank line whose take has the right duration, a door track that opens on
the loud parts and is shut at the end; a hand edit of the entry's triggers and text survives a second bake; an unknown
trigger stops the bake.

## Triggers: the list, and how one is added

A trigger is a file in `game/voice/triggers/`, so "the list" is the folder; a line names triggers by id in its JSON, and
the bake checks them. The game fires a trigger by its file: the code that owns the moment holds it as a typed export (or
`preload` in a rules class), so a missing file is a parse or load error, not silence.

- **A new line for an existing moment:** no trigger work: name the trigger in the line's JSON.
- **A new moment a feature already announces** (a Stage starting, a Part fitted, a cutscene of a new Stage): make the
  trigger file (copy one, set `speaker` and `kind`) and set it where the moment's data names its voice. Batch A's
  data-driven seam: `Stage.fix_cutscene` (core/92), so a new Stage with a new cutscene is a new trigger file, a recording,
  its JSON entry and the Stage's field; no code.
- **A moment nothing announces yet** (say, "a player falls down the stairs"): a trigger file plus one line of code in
  the feature that owns the moment (the speaker Part's `talk` Command). That code change belongs to that feature's ticket.

Batch A's triggers (the washer's; the Old Tree's come with batch B):

| Trigger | Kind | Fired by | Seam owner |
|---|---|---|---|
| `washer_stare` | comment, chance 0.5 | the washer's stare sensing, on each machine for its own player (4 s, 8 m, 12 degrees) | core/86 |
| `washer_progress` | comment | the Host on a Pair shelved (the Mess's Pair answer, exists) or a Cabinet filled | core/86 (core/76's Cabinet filled) |
| `washer_hit` | comment | the Host on a thrown thing's landing within 1.4 m (the Throw's landing answer, exists) | core/86 |
| `washer_idle` | comment | the Host after 60 s with no Pair shelved, while a comment could play | core/86 |
| `cutscene_first_wash` | cutscene | core/94's First wash, when the machine breaks (cutscene_1) | core/94 |
| `cutscene_fix_1` .. `cutscene_fix_4` | cutscene | core/92's Fix of each floor's Part (cutscene_2 .. _5, whole), named by the Stage Resource | core/92 |
| `cutscene_final_wash` | cutscene | core/96's Final wash, after its wash (cutscene_6, whole) | core/96 |

The comment set is each line's `sets`, read against the run's current set: `Stage.comment_set` of the current Stage, or
`StagePlan.laundry_day_comment_set` (4 by default, Q2635) in the Laundry day. stage_5's lines wait for the Drum (D);
they are in the JSON with set 5, which batch A never reaches.

## Playing

- **Positional** speakers (the washer's comments) play on an `AudioStreamPlayer3D` that follows the `VoiceSource`, with
  the speaker's unit size, max distance and `voice_db`, on the **Voice** bus, or on **MuffledVoice** (a new bus, -9 dB,
  900 Hz low-pass, sending into Voice, as the other Muffled buses) when `Sounds.is_muffled(where)` says a shut Door lies
  between; re-checked as the other world sounds are.
- **Cutscene** lines play flat on the Voice bus, heard and subtitled by everyone; their acting still plays on the
  speaker's `VoiceSource`.
- **Heard and subtitled:** a positional line's subtitle row shows while the local camera is within the speaker's earshot
  and level band (12 m and 2 m for the washer), checked every frame, through a shut Door too (Q2552); `display/subtitles`
  off hides every row.
- **Priority (V4):** a line asked on a channel of lower priority than one playing is dropped (or waits up to its speaker's
  hold time when `waits`); a higher one cuts the lower (its `finished(skipped = true)` fires, the lower speaker rests).
  The same speaker: the new line replaces the old.
- **The music duck (V5):** while the cutscene channel plays, the Music bus fades to 0.25 of its level over 0.5 s and back
  after (an `AudioEffectAmplify` on Music driven by `Voices`, as the old `MusicDuck`; the numbers on `VoiceTuning`
  `game/voice/voice_tuning.tres`, placeholders).
- **Tail:** a cutscene line counts as finished 0.9 s after its last word; a comment 0.27 s after (the old 0.3 of the tail).
- **Segments:** the showing segment is the one begun and not ended, lingering 0.25 s; `segment_changed` fires when the
  index moves (the cutscene camera cuts on it).

## Cutscenes

A cutscene, for the voice system, is a trigger of kind CUTSCENE: every line with that trigger, of every speaker, plays in
`order`, one after the other, on the cutscene channel; a line of another speaker plays its acting on that speaker's
source (cutscene_3: the washer's line now, the Old Tree's joins in batch B with a higher `order`, Q2633).
`Voices.play_cutscene(trigger, takes)` plays them and emits `segment_changed` and `finished`; the Host's answer that
starts the cutscene carries the take index of each line so every machine plays the same takes. The frame around it is
`run-ends.md` "The Cutscene frame" (core/88).

## Co-op (scene parts, `docs/migration/coop-structure-for-the-port.md`)

- **The Host decides what is said (V1).** A comment is a Command to the speaker's Part (`Washer`): `talk {trigger}`; its
  `decide()` runs the cooldown, the cutscene block, the chance and the picker and answers `{line, take}` or nothing (a
  silent no, no Refusal shown). On `Parts.applied` every machine calls `Voices.say`. A Guest's stare sends the Command; the
  Host's own triggers run the same `decide()` locally.
- A cutscene's lines and takes ride the answer of the sequence's Command that starts it (core/92's Fix, core/94's and
  core/96's washes); every machine plays the same.
- **Each machine decides who hears it:** distance, floor, muffling and the subtitle are local (looks only).
- **Not saved:** a line playing, the cooldown and the picker's memory (as the old: a load starts quiet). A late joiner
  hears the next line; a comment playing as they join is not replayed.

## The Voice station (`game/zoo/stations/voice.tscn`, Q2608, Q2337)

Built from the VoiceBook at load: no line is listed by hand.
- A stand-in speaker per `VoiceSpeaker`: a graybox face with the washer's Looks contract (the real washer once core/86
  lands), 4 m apart, a shut Door with a pillar behind it to hear the muffle and see the subtitle stay.
- One pillar per line, in rows per speaker and trigger; using a pillar (E, through the player's own use wiring) asks the
  speaker's Part to say that line (a station-only Command `say_line {line}` the Part grants in the zoo alone), so the line
  plays through the real path: Part, `Voices`, the Looks' acting, the subtitle. A label over each pillar: the line id, its
  triggers and sets, its takes, and the marks "no trigger", "placeholder", "keys differ", "text TODO".
- One pillar per CUTSCENE trigger plays the whole cutscene flat (no frame: the station has no cutscene camera) with a
  radio stand-in playing music to hear the duck.
- One pillar per COMMENT trigger fires the trigger as the game does (cooldown and chance included), to see the picker.

## Tests

- core/84: the bake (above); the 21 washer lines load with no VoiceBook error; every key has CSV text.
- core/85, real path: in the Voice station, the player walks to a washer line's pillar and presses E; within the line's
  lead the Subtitles row shows the line's first segment text (through `tr`) with the washer's icon, and
  `Voices.talking(washer)`; the stand-in's AnimationPlayer plays the take's acting. Rules: the picker (fit, fallback,
  never the last, each once before repeats, seeded takes); the priority rule (a higher cuts, a lower is dropped, a
  `waits` line waits); earshot and level band; the CSV key check. Co-op: a Guest's `talk` is decided on the Host; both
  machines play the same line and take.

## Localisation, later

Every subtitle is a key in `voice_lines.csv` from the first line; the bake writes the English column from the JSON. A
translator's column would be kept by the bake (it rewrites only `en`). Dubbed audio, if ever: Localization Remaps swap a
take's stream per locale and a remapped line carries its segment times. Not built until a language is asked for. The
subtitle's size follows the Theme.

## Gotchas

- The bake owns the banks, the acting files, each take's timing and the CSV's English column; hand edits go in the JSON.
- A take's segments must match the line's `text` count; the station marks a line whose takes differ.
- The bake runs headless (`tools/voice_bake.sh`); the designer runs the same command.
- `Voices` decides nothing: a line reaches it only from a Part's answer (or the station's zoo-only Command).
- The old clips are quiet (peaks near -5.9 dBFS, P109); with no game gain (Q2638) they play quieter than the old comments
  until the recordings are fixed at the source.
