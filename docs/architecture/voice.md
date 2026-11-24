# Voice (build plan)

**Status: build plan for batch A (core/73, Q2606, Q2614), waiting on the designer's answers W1-W10 (core/73's Open
follow-ups).** It turns core/56's proposal into what is built. Decided: Q2545-Q2552 (V1-V8), Q2608 (authoring), Q2609
(speakers). The findings: `docs/migration/voice-findings.md`; the washer's behaviour list:
`docs/migration/m4-lists/05-washer-and-voices.md`; the washer as an entity: `docs/architecture/washer.md`, which also
holds the batch's ticket drafts. Where the text follows a W recommendation it says so; another answer changes only
that paragraph.

## What it owns

Every spoken line: how it is stored (a Resource per line, made by the bake), picked (one picker), triggered (a list of
triggers picked in the inspector), played (one autoload, one channel per speaker, the priority rule), heard (the Voice
bus, muffling, earshot), subtitled (one scene on the Theme) and shown in the zoo (the Voice station, built from the
lines at load). It does not own a speaker's body or face (each speaker's Looks plays the line's acting Animation), the
cutscene frame (camera, freeze, fade, skip, respawn: the sequence that plays the cutscene, see "Cutscenes"), nor when a
game moment happens (the feature that owns the moment fires the trigger).

## Decided

V1 the Host decides every speaker's line (Q2545). V2 a baked Animation per take, played by the speaker's Looks
AnimationPlayer with the audio (Q2546). V3 several takes, one at random (Q2547). V4 cutscene > washer > Old Tree, the
higher cuts the lower, lower ones dropped except story beats that wait (Q2548). V5 a Voice bus with its slider, the
music ducks only in cutscenes (Q2549). V6 the old subtitle look on the Theme, one row per speaker, the speaker's icon,
no name (Q2550). V7 the text from transcribing the recording, corrected in the string table (Q2551). V8 a subtitle
shows within earshot, through a shut Door too (Q2552). Q2608: drop the recording into the speaker's folder; a tool
makes the line Resource, subtitle key and animation; the trigger is picked from a list in the inspector; a Voice
station plays every line. Q2609: the speakers are the washer, the Old Tree and cutscenes 1-6, no plot NPC.

## Folder layout

| Path | What | Who writes it |
|---|---|---|
| `assets/voice/<speaker>/<line>.wav` | the recordings, 16-bit PCM wav; `<line>_b.wav`, `_c.wav` are more takes of `<line>` | the designer drops them |
| `game/voice/` | the code: `voice_line.gd`, `voice_take.gd`, `voice_segment.gd`, `voice_mood_key.gd`, `voice_speaker.gd`, `voice_acting.gd`, `voice_trigger.gd`, `voice_book.gd`, `voice_picker.gd`, `voices.gd` (autoload), `voice_source.gd`, `subtitles.tscn` | agents |
| `game/voice/speakers/<speaker>.tres` | one `VoiceSpeaker` per speaker folder: `washer.tres` (batch A), `old_tree.tres` (batch B) | made once per speaker, edited in the inspector |
| `game/voice/speakers/<speaker>_acting.tres` | the speaker's `VoiceActing`: how the bake turns loudness and moods into its rig's tracks | made once per speaker |
| `game/voice/triggers/<trigger>.tres` | one `VoiceTrigger` per game moment that may speak (the trigger list) | see "Triggers" |
| `game/voice/lines/<speaker>/<line>.tres` | one `VoiceLine` per line: the bake makes it, the designer edits its triggers, Stages, moods, order and note in the inspector | the bake, then the designer |
| `game/voice/lines/<speaker>/acting/<line>[_b].tres` | one Animation per take (mouth, brows, lean, wiggle, glow), the bake's alone | the bake |
| `game/voice/voice_lines.csv` | the string table of every subtitle: `keys,en`, key `VO_<LINE>_<n>`; registered under Project Settings, Localization (one `project.godot` change, in the first ticket) | the bake adds rows; the designer corrects the text |
| `tools/voice_bake.gd`, `tools/voice_bake.sh` | the bake (Godot, headless or in the editor) | agents |
| `tools/voice_transcribe.py` | the transcription step (faster-whisper `small.en`, offline once its model is downloaded, as the old `voiceover.py`) | agents |
| `game/zoo/stations/voice.tscn` | the Voice station | agents |

`assets/voice/` holds only recordings; Godot imports them (their `.import` committed, compressed as QOA for the game). The
lines live under `game/voice/` because they are game data a designer edits (Q2167: game apart from assets).

## Key types

All typed, edited in the inspector, one class per file (Q2251-Q2253).

- **`VoiceLine`** (Resource): `id: StringName` (the file stem, `stage_1_voice_A`); `speaker: VoiceSpeaker`;
  `takes: Array[VoiceTake]` (one plays, at random, Q2547); `triggers: Array[VoiceTrigger]` (picked in the inspector; empty
  = it never plays in a game, the station still plays it and marks it "no trigger"); `stages: PackedInt32Array` (the Stage
  numbers it may play in, empty = any: the old comment sets made a field); `moods: Array[VoiceMoodKey]` (hand-set, kept by
  the bake; seeded with the speaker's default mood); `order: int` (its place within a cutscene, see "Cutscenes");
  `waits: bool` (a story beat that waits instead of being dropped, V4; the Old Tree's, batch B); `end_at: float` (seconds,
  0 = the whole take: cuts every take there, W2); `placeholder: bool`; `note: String`.
- **`VoiceTake`** (Resource, inside the line's `.tres`): `stream: AudioStream`; `source_md5: String` (the bake re-bakes a
  take whose wav changed); `duration: float`; `gain_db: float` (the bake's loudness match, W6); `segments:
  Array[VoiceSegment]`; `acting: Animation` (the external acting file).
- **`VoiceSegment`** (Resource): `start`, `end` (s), `key: StringName` (the CSV key). Every take of a line has the same keys
  in the same order; their times are the take's own.
- **`VoiceMoodKey`** (Resource): `at: float` (s), `mood: StringName` (one of the speaker's `VoiceActing.moods`).
- **`VoiceSpeaker`** (Resource): `id`; `icon: Texture2D` (the subtitle's, V6); `priority: int` (cutscene 30, washer 20,
  Old Tree 10, V4); `positional: bool`; `unit_size`, `max_distance` (m); `earshot`, `level_band` (m, the subtitle's reach,
  V8); `voice_db`; `cooldown` (s, between two lines of this speaker given by a trigger); `default_mood`; `acting:
  VoiceActing`; `tail` (s after the last word); `linger` (s a segment stays past its end). Washer values are the old ones
  (`docs/architecture/washer.md` "Numbers"), each marked `# placeholder:` as in the old tuning.
- **`VoiceActing`** (Resource): what the bake writes for this speaker's rig: the mouth bone and its open angle, the
  loudness window (20 ms), smoothing (0.6), gate (8 %), keys a second (30); the moods with each one's lean and brow pose;
  the brow acting's flick sizes; the mood blend (0.4 s); the property tracks (`wiggle`, `glow_colour`, `glow_energy`) and
  each mood's glow. The washer's carries the old `voiceover.py` and `brows.py` numbers. The Old Tree's (batch B) has its
  rustle instead of brows; the bake's code is the same, the profile differs.
- **`VoiceTrigger`** (Resource): `id: StringName`; `speaker: VoiceSpeaker`; `kind` (COMMENT: a line picked by the
  speaker's director with cooldown and chance; CUTSCENE: every line with this trigger, in `order`, played as a cutscene);
  `chance: float` (1 but the stare's 0.5); `ignores_cooldown: bool`; `note` (what fires it: the seam, for the designer).
- **`VoiceBook`** (RefCounted, built at load): every `VoiceLine` under `game/voice/lines/`, grouped by speaker and trigger.
  A line whose speaker or trigger file is missing, a take whose segments differ in keys from the first take's, or a key
  missing from the CSV is a load error a test catches.
- **`VoicePicker`** (RefCounted, rules only): the lines of (speaker, trigger, Stage); fit first (a line with the trigger;
  when none fits, any line of the speaker's Stage set: the old washer fallback); never the last line; each fitting line
  once before any repeats (W5: one rule for every speaker); seeded RNG for tests. The take is picked here too, so the
  Host's answer carries both.
- **`Voices`** (autoload, looks only, as `Sounds`): `say(line, take, source: VoiceSource, as_cutscene := false)`;
  `stop(speaker)`; `talking(speaker) -> bool`; `cutscene_playing() -> bool`; signals `started(line, take)`,
  `segment_changed(line, index)`, `finished(line, skipped)`. It owns one channel per speaker and one for cutscenes, the
  priority rule, the 3D and flat players, the bus choice, the music duck and the Subtitles.
- **`VoiceSource`** (Node3D script, on a speaker's Looks): where the voice sounds from (its own position) and the
  speaker's face: `act(take)` plays the take's acting Animation on the Looks' AnimationPlayer from its start, `rest()`
  goes back to the basic pose. The washer's Looks has one (`docs/architecture/washer.md`); a cutscene line plays its
  acting on the speaker's source while the sound is flat.
- **`Subtitles`** (`game/voice/subtitles.tscn`, a Control on the one Theme, under the HUD's layer, on top in cutscenes):
  one row per speaker talking now (an icon and a Label), bottom centre, the old look made Theme styles (`SubtitleLabel`:
  cream, black outline 10 at 0.85, 30 px at 1080p; 160 px side margins); text through `tr(key)`. Rows stack in priority
  order, the highest at the bottom.

## The bake: adding or swapping a line (Q2608 made concrete)

1. **Drop** `my_line.wav` into `assets/voice/washer/` (the folder names the speaker; a new folder needs its
   `speakers/<folder>.tres`, which the bake makes from a copy of the washer's and reports).
2. **Bake**: press "Bake voices" in the editor (an `EditorScript` run from the Script editor's File menu, or a small dock;
   W7) or run `tools/voice_bake.sh`. It does, for every wav whose take is new or whose `source_md5` changed:
   - reads the PCM, measures its loudness and writes `gain_db` (W6);
   - runs `tools/voice_transcribe.py` on it when the line has no CSV rows yet (new line) or with `--retranscribe`: the
     segments' times and English text; without whisper installed it writes one segment over the voiced span and the text
     `TODO`, and says so;
   - times an extra take or a re-recording against the line's existing keys (whisper's segments matched by order; a
     count that differs is reported and the station marks the line);
   - writes the take's acting Animation from the loudness, the segments' text (`?` and `!`), the line's moods and the
     speaker's `VoiceActing` (the old `voiceover.py` door curve and `brows.py` acting, ported into GDScript);
   - writes or updates `game/voice/lines/<speaker>/<line>.tres` through `ResourceSaver` (so the file has its `uid=`, in
     the editor's own format, Q2268), keeping every hand-set field (triggers, Stages, moods, order, waits, end_at,
     placeholder, note);
   - adds the CSV rows `VO_<LINE>_<n>,<text>` for a new line; never touches an existing row's text.
3. **Pick the trigger** in the line's inspector (the `triggers` array's picker lists every `VoiceTrigger` file), and the
   Stages it may play in; correct the subtitle text in `voice_lines.csv`.
4. **See it** in the Voice station at the next load (Q2337): its pillar, its subtitle, its acting on the stand-in face.

Swapping a recording: replace the wav, bake; id, text, triggers and moods stay; timing and acting are remade. A second
take: drop `my_line_b.wav`, bake. Removing a line: delete its wav, its `.tres` and acting; the bake lists orphaned CSV
rows and `.tres` files without a wav (it deletes nothing). Renaming: `tools/voice_bake.sh --rename old new` moves the
wav, the `.tres`, the acting and the CSV keys together (a line id appears in no save, so nothing else breaks).

The bake's tests (in the bake ticket): a fixture wav (a generated tone pattern, committed under `tests/fixtures/voice/`)
bakes to a line whose take has the right duration, a door track that opens on the loud parts and is shut at the end, and
whose hand-set fields survive a second bake.

## Triggers: the list, and how one is added

A trigger is a file in `game/voice/triggers/`, so "the list in the inspector" is the folder. The game fires a trigger
by its file: the code that owns the moment holds it as a typed export (or `preload` in a rules class), so a missing
file is a parse or load error, not silence.

- **A new line for an existing moment:** no trigger work: pick the trigger in the line's inspector.
- **A new moment a feature already announces** (a Stage starting, a Part fitted, a cutscene of a new Stage): make the
  trigger file (copy one, set `speaker` and `kind`) and set it where the moment's data names its voice. Batch A's
  data-driven seams: core/71's Stage Resource names its Fix cutscene trigger, so a new Stage with a new cutscene is a
  new trigger file, a recording and the Stage's field; no code.
- **A moment nothing announces yet** (say, "a player falls down the stairs"): a trigger file plus one line of code in
  the feature that owns the moment, `washer.talk(trigger)` (or the speaker's own Part's Command). That code change is
  the only one, and it belongs to that feature's ticket.

Batch A's triggers (the washer's; the Old Tree's come with batch B):

| Trigger | Kind | Fired by | Seam owner |
|---|---|---|---|
| `washer_stare` | comment, chance 0.5 | the washer's stare sensing, on each machine for its own player (4 s, 8 m, 12 degrees) | core/73 |
| `washer_progress` | comment | the Host on a Pair shelved (the Mess's Pair answer, exists) or a Cabinet filled | core/71 (Cabinet filled) |
| `washer_hit` | comment | the Host on a thrown thing's landing within 1.4 m (the Throw's landing answer, exists) | core/73 |
| `washer_idle` | comment | the Host after 60 s with no Pair shelved, while a comment could play | core/73 |
| `cutscene_first_wash` | cutscene | core/72's First wash, when the machine breaks (cutscene_1) | core/72 |
| `cutscene_fix_1` .. `cutscene_fix_4` | cutscene | core/71's Fix of each floor's Part (cutscene_2 .. _5), named by the Stage Resource | core/71 |
| `cutscene_final_wash` | cutscene | core/72's Final wash, after its wash (cutscene_6) | core/72 |

The comment set (stage_1 .. stage_4) is each line's `stages` field, read against core/71's current Stage number (a
read of its run Part). The Laundry day's set (after the fourth Fix) is W3; stage_5's lines wait for the Drum (D).

## Playing

- **Positional** speakers (the washer's comments) play on an `AudioStreamPlayer3D` that follows the `VoiceSource`, with
  the speaker's unit size, max distance and `voice_db + gain_db`, on the **Voice** bus, or on **MuffledVoice** (a new
  bus, -9 dB, 900 Hz low-pass, sending into Voice, as the other Muffled buses) when `Sounds.is_muffled(where)` says a shut
  Door lies between; re-checked as the other world sounds are.
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

A cutscene, for the voice system, is a trigger of kind CUTSCENE: every line with that trigger plays in `order`, one after
the other, on the cutscene channel; a line of another speaker in the same trigger plays on that speaker's source (Q2609:
the washer and the Old Tree in one cutscene is two lines, two `order`s; W1). `Voices.play_cutscene(trigger, takes)`
plays them and emits `segment_changed` and `finished`; the Host's answer that starts the cutscene carries the take
index of each line so every machine plays the same takes.

The cutscene frame (camera, freeze, hiding Socks and bodies, fades, the Host's skip, the respawn) is not the voice
system's: it is the sequence that plays the cutscene. Every batch A cutscene is the washer's, played inside core/71's
Fix or core/72's First and Final wash, so the frame is one shared piece; `docs/architecture/washer.md` "The cutscene
frame" names what the washer gives it (its two shots, its line's segments) and proposes who builds it.

## Co-op (scene parts, `docs/migration/coop-structure-for-the-port.md`)

- **The Host decides what is said (V1).** A comment is a Command to the speaker's Part (`Washer`): `talk {trigger}`; its
  `decide()` runs the cooldown, the cutscene block, the chance and the picker and answers `{line, take}` or nothing (a
  silent no, no Refusal shown). On `Parts.applied` every machine calls `Voices.say`. A Guest's stare sends the Command; the
  Host's own triggers run the same `decide()` locally.
- A cutscene's lines and takes ride the answer of the sequence's Command that starts it (core/71's Fix, core/72's
  washes); every machine plays the same.
- **Each machine decides who hears it:** distance, floor, muffling and the subtitle are local (looks only).
- **Not saved:** a line playing, the cooldown and the picker's memory (as the old: a load starts quiet). A late joiner
  hears the next line; a comment playing as they join is not replayed.

## The Voice station (`game/zoo/stations/voice.tscn`, Q2608, Q2337)

Built from the VoiceBook at load: no line is listed by hand.
- A stand-in speaker per `VoiceSpeaker`: the washer's graybox Looks (its real Looks once the asset ticket lands, the
  same scene the house uses), 4 m apart, a shut Door with a pillar behind it to hear the muffle and see the subtitle stay.
- One pillar per line, in rows per speaker and trigger; using a pillar (E, through the player's own use wiring) asks the
  speaker's Part to say that line (a station-only Command `say_line {line}` the Part grants in the zoo alone), so the line
  plays through the real path: Part, `Voices`, the Looks' acting, the subtitle. A label over each pillar: the line id, its
  triggers and Stages, its takes, and the marks "no trigger", "placeholder", "keys differ", "text TODO".
- One pillar per CUTSCENE trigger plays the whole cutscene flat (no frame: the station has no cutscene camera) with a
  radio stand-in playing music to hear the duck.
- One pillar per COMMENT trigger fires the trigger as the game does (cooldown and chance included), to see the picker.

## Tests (the first ticket's)

- Real path: in the Voice station, the player walks to a washer line's pillar and presses E; within the line's lead the
  Subtitles row shows the line's first segment text (through `tr`) with the washer's icon, and `Voices.talking(washer)`;
  the washer Looks' AnimationPlayer plays the take's acting.
- Rules: the picker (fit, fallback, never the last, each once before repeats, seeded takes); the priority rule (a higher
  cuts, a lower is dropped, a `waits` line waits); earshot and level band; the CSV key check; the VoiceBook load errors.
- Co-op: a Guest's `talk` is decided on the Host; both machines play the same line and take.

## Localisation, later

Every subtitle is a key in `voice_lines.csv` from the first line. A translator adds a column. Dubbed audio, if ever:
Localization Remaps swap a take's stream per locale and a remapped line carries its segment times. Not built until a
language is asked for. The subtitle's size follows the Theme.

## Gotchas

- The bake owns the acting files and each take's timing and gain; hand edits go in the line's own fields and the CSV.
- A take's segments must match the first take's keys; the station marks a line whose takes differ.
- The bake runs headless in the agent's runs and inside the editor for the designer; both are the same `tools/voice_bake.gd`.
- `Voices` decides nothing: a line reaches it only from a Part's answer (or the station's zoo-only Command).
