# Voice (proposal)

**Status: proposal for the designer (core/56, Q2535). Nothing here is built.** The findings it rests on:
`docs/migration/voice-findings.md`. Choices for the designer are at the end (V1-V8); the design below follows the
recommended option of each, and names where another option would change it.

## What it owns

Every spoken line of the game: the washer's comments, its drum comments and its cutscene lines, the Old Tree's lines
and calls, and whatever speaker comes later (the plot's NPC, P32). It owns how a line is stored, picked, played,
heard and subtitled. It does not own the cutscene's camera, fade or skip (the cutscene feature, M5), nor the face
rigs (each speaker's Looks).

## Key types

All typed Resources edited in the inspector, beside the code in `game/voice/`.

- **`VoiceLine`** (Resource, one `.tres` per line):
  - `id: StringName` (the file's name, `washer_stare_03`), `speaker: VoiceSpeaker`;
  - `takes: Array[AudioStream]` (one plays; normally one, more when the designer keeps alternatives, V3);
  - `moments: Array[StringName]` (what it suits: `stare`, `idle`, `progress`, `cutscene_fix_2`, `tree_greet`;
    empty suits any moment of its speaker);
  - `when: Array[StringName]` (optional gates by game state, e.g. `stage_3`, `washer_broken`: the old "comment set"
    of the file name made explicit);
  - `priority: int` (default from the speaker; a cutscene line is highest);
  - `segments: Array[VoiceSegment]` (start, end, `key`: the string-table key of its subtitle text);
  - `acting: Animation` (the baked mouth, brows, moods and wiggle for the speaker's Looks, V2), may be null;
  - `placeholder: bool` and `note` (what it waits for: a recording, the designer's wording).
- **`VoiceSegment`** (Resource): `start`, `end`, `key`. The English text is the string table's, not the Resource's.
- **`VoiceSpeaker`** (Resource, one per speaker: `washer.tres`, `old_tree.tres`): display name key (for a subtitle
  label, V6), default priority, positional or flat, unit size, max distance, earshot, level band, voice dB, cooldown,
  the subtitle colour; numbers marked `# placeholder:` until set.
- **`VoiceBook`** (built at load, not hand-listed): every `VoiceLine` found under `game/voice/lines/` grouped by
  speaker and moment. It replaces the old `file_exists` probing and the tuning lists; an unknown moment asked by code
  or a line whose speaker is missing is an error a test catches, as with unknown sound names (core/17 S01).
- **`VoicePicker`** (RefCounted, rules only): the one picker every speaker uses: the lines fit for (speaker, moment,
  state gates), never the last one, each played once before any repeats (the tree's rule, now everyone's), seeded
  RNG for tests. Cooldowns and chances stay with the speaker's director (washer, drum, tree), which ask it.
- **`Voices`** (autoload, looks only): plays a chosen line: `say(line_id, from: Node3D)`. It holds one channel per
  speaker and the priority rule across speakers (V4), drives the subtitle, the Voice bus and ducking, and emits
  `started(line)` / `finished(line, skipped)` for cutscenes and directors.
- **`Subtitles`** (a scene on the one Theme, `game/ui/subtitles.tscn`): a bottom panel with one row per speaker
  talking now (so two speakers never overlap on one label), speaker name optional (V6), text through `tr(key)`.

## Authoring: adding or swapping a line

The aim of Q2296 carried over: drop a file, name it, done.

1. Drop `washer_stare_03.wav` (or `.ogg`) into `assets/voice/washer/`. The name is `<speaker>_<moment>_<nn>`;
   cutscene lines `washer_cutscene_<name>`.
2. Run `python3 tools/voice/bake.py` (the old `voiceover.py` and `brows.py`, ported): for each new or changed
   recording it writes `game/voice/lines/washer/washer_stare_03.tres` (speaker and moment from the name, the take,
   the acting Animation from the loudness and the mood keys) and adds the subtitle rows to the string table
   `game/voice/voice_lines.csv` (key `VO_WASHER_STARE_03_1`, English from the transcript, V7). A rerun keeps
   hand edits: the text in the CSV, the moments, gates, moods and priority in the `.tres`.
3. Open the `.tres` in the inspector to add a moment, a gate or a second take; correct the text in the CSV.
4. The zoo's Voice station shows it at the next load (Q2337).

Swapping a recording: replace the wav, rerun the bake; the line's id, text and moments stay. A placeholder voice
(the tree's synthesised one, `tools/voice/old_tree_voice.py`) writes into the same folder with `placeholder = true`;
a real recording of the same name replaces it.

Takes (V3): `washer_stare_03_b.wav` beside `_03.wav` becomes a second take of the same line; whether the game picks
one at random or the designer marks one is the choice.

## How it fits the sound system (core/17)

- Voices are not SoundEvents: a line has text, timing and acting a SoundEvent has not. But they share the mixer:
  a new **Voice bus** (V5) in `default_bus_layout.tres`, its volume a setting `audio/voice_volume` beside the others,
  and a **MuffledVoice** bus (-9 dB, 900 Hz, as the others) so a speaker behind a shut Door is muffled by the same
  `Sounds.is_muffled(where)` rule.
- Ducking (V5): Godot's own `AudioEffectCompressor` on the Music bus with `sidechain = "Voice"` ducks the music
  whenever anyone speaks, no code; the old cutscene-only duck is the other option.
- A speaker's other sounds (the washer's angry rumble under its voice) stay SoundEvents the speaker's Looks starts and
  stops on `Voices.started` / `finished`.

## Playing, heard only when audible, priority

- Positional speakers play from an `AudioStreamPlayer3D` in their Looks; cutscene lines play flat.
- **Heard and subtitled agree:** the subtitle shows while the local listener is within the speaker's earshot and level
  band (the old rule, Q1587), behind a shut Door too (V8 asks whether a muffled line should hide it). A speaker's sound
  reach (max distance) and its earshot sit side by side in its VoiceSpeaker, so the gap between them (old: 30 m sound,
  12 m subtitle) is visible and set on purpose.
- **Priority across speakers (V4):** cutscene > washer > Old Tree. A higher line cuts a lower one; a lower line asked
  while a higher one plays is dropped, except a line marked `waits` (the tree's story beats), which waits up to its
  hold time. Same speaker: the new line replaces the old one (the old behaviour).

## Co-op (scene parts, `docs/migration/coop-structure-for-the-port.md`)

- **The Host decides what is said.** A comment or a drum line is asked as a Command to the speaker's Part (the
  washer's Part); its `decide()` runs the director (cooldown, chance, picker) and the answer carries the line id. On
  `Parts.applied` every machine calls `Voices.say(id, washer)`. Same line everywhere, nothing decided on a Guest.
- **Each machine decides who hears it.** Distance, the floor, muffling and the subtitle are local (looks only).
- **Cutscenes:** the cutscene feature's Part starts it on the Host; every machine plays the same line; the skip
  follows the cutscene's own rule (the Host's, as the old rogue sequence).
- **The Old Tree (V1):** its moments are about one player (near, what they can afford, their tips). Either the Host
  decides them too, with the player's id in the Command (one model for every speaker), or each machine decides for
  its own player as the old game did. It is reworked later (Q2506); the voice system supports both.
- Nothing about voice is saved except what a director must keep (tips said, the tree's `met`), which lives on its Part.

## Localisation, later

- Every subtitle is a key in `game/voice/voice_lines.csv` from the first line (shipping-basics: text through `tr()`
  from the start). One language today; a translator adds a column.
- Dubbed audio, if ever: Godot's Localization Remaps swap a take per locale; segments are re-timed per locale by a
  remapped `VoiceLine`. Not built until a language is asked for.
- Subtitle text scale follows the Theme's text-scale setting when that exists.

## The zoo station (sketch)

`game/zoo/stations/voice.tscn`, built from the VoiceBook at load (Q2337):
- a stand-in washer box and a stand-in tree box (grey, with a hinged "mouth" lid that the acting Animation drives),
  4 m apart on the floor, and a shut Door with a pillar behind it;
- a row of pillars, one per speaker and moment; using one makes that speaker say a line of that moment through the
  real path (`Voices.say` via the Part's Command), with its subtitle;
- a "cutscene" pillar plays a cutscene line flat, with music on a radio stand-in to hear the duck;
- a label over each pillar: the moment and how many lines it has (placeholders marked).

The real-path case for the build ticket: the player uses a pillar; the line's subtitle shows on the Subtitles panel
and the Voice bus has a playing voice.

## Gotchas

- The bake owns the `.tres` acting and timing; hand edits go in the fields it keeps (moments, gates, moods, priority,
  takes) and in the CSV, never in the Animation.
- A line's id is its file name: renaming a line breaks a save or a Command that names it; rename with the bake's
  `--rename`.

## Decided (Q2545-Q2552, 2026-11-23)
V1 a (the Host); V2 a (baked Animation); V3 b (several takes, random); V4 a (priority, lower dropped); V5 b (Voice bus,
cutscene-only duck); V6 the old look with the speaker's icon, no name; V7 a (from the recording); V8 a (shown in
earshot). Where the text above assumed another option, these win.

## Choices for the designer

Each with 2-3 options; **(rec)** marks the recommendation.

- **V1. Who decides the Old Tree's lines in co-op?**
  a) **(rec)** The Host, as the washer: the Command names the player; one model for every speaker, testable in one way.
  b) Each machine for its own player, as the old game (no network traffic; two models).
- **V2. How a line drives the speaker's face (mouth, brows, moods, wiggle)?**
  a) **(rec)** The bake writes an Animation per line, played by the speaker's Looks' AnimationPlayer with the audio
     (the port's rule: state plays an AnimationPlayer in Looks).
  b) Keep the old 30 Hz curves in the line, sampled by code each frame (the old way, a direct port).
- **V3. Takes: more than one recording of a line?**
  a) **(rec)** One take per line; a new take replaces the file (the old way; simplest).
  b) Several takes per line, one picked at random each time (variety for short, frequent lines).
  c) Several takes kept, the designer marks the one used (a picking aid while recording).
- **V4. When two speakers would talk at once?**
  a) **(rec)** Fixed priority cutscene > washer > Old Tree; the higher cuts the lower; lower ones are dropped except
     story beats that wait (the old behaviour, made one rule).
  b) The same, but a dropped line is queued and said afterwards (if still fitting, within a few seconds).
  c) Speakers may overlap; only the same speaker replaces itself.
- **V5. The mix: a Voice bus and music ducking?**
  a) **(rec)** A Voice bus with its own volume slider; the music ducks under every voice line (a sidechain compressor).
  b) A Voice bus with its own slider; the music ducks only in cutscenes (the old duck, Q1867).
  c) Voices stay on SFX as before; cutscene-only duck.
- **V6. Subtitle look?**
  a) **(rec)** The old look (cream, black outline, bottom centre) on the Theme, one row per speaker, no name.
  b) The same with the speaker's name in their colour ("Washer:", "Old Tree:").
  c) The same with a dark band behind the text for readability.
- **V7. Where a line's text is first written?**
  a) **(rec)** From the recording: the bake transcribes (whisper, as before), the text is corrected in the string
     table.
  b) From a script: the designer writes the lines first (a `lines.md` per speaker, as the Old Tree's), the bake reads
     the text from it and only times it against the recording.
- **V8. Subtitle of a line heard through a shut Door?**
  a) **(rec)** Shown while within earshot, Door or not (the old rule; deaf or hard-of-hearing players still get it).
  b) Hidden when the line is muffled (subtitle follows exactly what is clearly heard).
