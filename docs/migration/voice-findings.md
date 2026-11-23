# Voice findings: how the old game made, played and subtitled its voicelines

core/56 step 1 (Q2535). Read by examination from `reference/it-socks` (v0.1.1). Paths below are in that
tree unless they start with `docs/`. The proposal built on this is `docs/architecture/voice.md`.

## 1. Every line kind

| Kind | Speaker | Count | Files | When it plays | Heard by |
|---|---|---|---|---|---|
| Comment | the washer | 15 (5 comment sets x A, B, C) | `audio/voiceover/stage_<N>_voice_<A-C>.wav` + `data/voiceover/<same>.json` | the Host's VoiceDirector picks one for a trigger: `stare`, `idle`, `progress`, `hit` (no line is tagged `hit`; an empty tag list suits any trigger) from the set of the current Stage | positional (AudioStreamPlayer3D on the washer, unit 6 m, max 30 m); subtitle only within `voice.earshot` 12 m and `voice.level_band` 2 m of height |
| Cutscene | the washer | 6 | `cutscene_1..6` | 1 at New Game (angriest), 2-5 at each Part fitted (`VoiceLines.cutscene_for_level`: the number is derived from the anger level), 6 after the Final wash's wash | flat (AudioStreamPlayer on SFX), every player, subtitles for all |
| Drum comment | the washer (inside the drum finale) | reuses 9 comment lines | names listed per trigger in `data/tuning/drum.json` `voice.lines` (`first`, `pair`, `last`, `refused`, `idle`, `out`) | `DrumRules._comment`: every refusal, first/last Pair, the way out; other Pairs by chance after a cooldown; the quiet spell (Q1885, Q1886) | as a comment |
| Old Tree line | the Old Tree | 161 placeholders over 42 moments | `audio/voiceover/old_tree/tree_<moment>_<n>.wav` + `data/voiceover/old_tree/<same>.json`; text in `audio/voiceover/old_tree/lines.md` | `TreeVoiceDirector` on each machine for its own player: first/greet/affordable/bought/idle; presents; Stage progress; Cabinet hints; floor hints; first-time tips; story beats (part_, floor_, final_wash); rivalry (grumble, peace) | positional from the tree (unit 2.5 m, max 9 m); subtitle within earshot 4.5 m and band 1.8 m |
| Tree call | the Old Tree | 5 (`tree_call_*`) | as above | the Host's clock after the first wash, every 25-55 s until a player comes near; sent as a `tree_call` Command so all play the same line | positional, louder and farther (`call_db` 12.5, `call_max_distance` 16 m) |

Not voicelines but close: the TV's sock puppets talk gibberish with bubble subtitles (`game/devices/tv_shows.gd`), and the
studio intro has its own wavs (`studio_intro/`). Neither uses the voice system.

## 2. How a line was authored

- **The washer (recorded).** A wav is dropped into `audio/voiceover/`; `tools/voiceover/voiceover.py` bakes
  `data/voiceover/<name>.json`: `duration`; `door` (the mouth: an RMS envelope, 20 ms windows, smoothed, gated at 8 %
  of peak, normalised per file, 30 keys a second, last key shut); `segments` (start, end, text) and `text` from a
  faster-whisper transcript (`small.en`, offline once downloaded). The text is then corrected by hand in the JSON; a
  rerun keeps it (`--retranscribe` overwrites). `triggers` are typed by hand into the JSON. `brows.py` adds the acting
  on every bake: `moods` (hand-set, seeded from `DEFAULT_MOODS` in the script), `brows` (4 floats per key, 30 a second)
  and `wiggle` (0-1 per key). One take per line; there is no notion of takes or picks: the file in the folder is the
  pick.
- **The Old Tree (synthesised placeholder).** The draft text lives in `lines.md` (`## <moment>` headings,
  `- tree_<moment>_<n>: <text>` bullets, agent-drafted for the designer to edit, Q1545). `old_tree_voice.py`
  synthesises each with Piper (`en_US-norman-medium`), then **ages** it: Piper slowed 1.12, played 1.22 slower (pitch
  and formants down about 3.4 semitones), vocal-fry creak (depth 0.45, 34-52 Hz, strongest at phrase ends), breath
  noise at -21 dB, three wooden resonances (190, 520, 1250 Hz), 0.42 s between sentences. Then the same door bake;
  segments are the sentences (no transcription), `triggers` = the moment, `placeholder: true`. Dropping a bullet
  deletes its wav and JSON.
- **Naming carries the meaning.** A comment's Stage is in its file name (`stage_3_...`), a tree line's moment in its
  name (`tree_hint_attic_2`); the tree director probes `tree_<moment>_1..30` with `file_exists` (MAX_PER_MOMENT). The
  drum's lines are listed by name in tuning JSON. Cutscene numbers come from a formula on the anger level.

## 3. How a line was triggered

- **Washer comments:** `VoiceTriggers` senses on each machine: a stare (this player looks at the machine 4 s, within
  8 m and 12 degrees, then a 50 % chance on the Host), and on the Host a Pair shelved or a Cabinet filled
  (`progress`), a thrown item landing within 1.4 m (`hit`), 60 s with no Pair shelved (`idle`). Each asks the Host with
  a `voice` Command; the Host's `VoiceDirector.request` applies a 120 s cooldown, a block while a cutscene runs, the
  Stage's set, the trigger fit, never the line before, and puts the chosen name in the event; every machine plays it
  (`Game.voice_line`). Nothing plays when the last item goes in (Q1413).
- **Cutscenes:** ride the rogue sequence (`RogueMachine._start_voice`), which owns the camera, fades, the Host's skip
  and the respawn; the sequence stretches to the line (lead-in 0.6 s, tail 0.9 s). A line the Host plays on its own
  as a cutscene (`own`) freezes the players and cuts to the machine, and any player may skip it on their machine.
  The camera cuts between a wide and a close shot at each subtitle segment.
- **Drum:** the Host's `DrumRules._comment`, its own cooldown and chance, the house cooldown not applied (Q1886).
- **Old Tree:** sensed and decided on each machine from shared state (no Command, Q1544), except the calls (a Host
  Command). Its own cooldown (120 s); story beats skip it but keep a 20 s gap and lapse after 120 s if nobody comes
  near; within a moment every line plays once before any repeats, never the same twice running.

## 4. How a line was played

- **One player per speaker.** `VoicePlayer` (washer) has one 3D player, one flat player and a rumble loop under the
  voice when angry; `OldTreeVoice` has one 3D player. A new line stops the speaker's current one (no queue).
- **Priority, implicit:** a cutscene blocks comments (`blocked_until`); the tree never starts while `busy` (a cutscene
  or the washer talking) and a washer line cuts the tree off; a tree call stops when a player comes near so it does not
  talk over the "first" line. Requests that arrive while busy are dropped, except the tree's story beats, which wait.
- **Levels:** voices go on the SFX bus (there is no Voice bus and no voice volume setting); `comment_db` +6,
  `cutscene_db` 0, the tree's `voice_db` +12.5 (made 3x louder by the designer, 2026-11-12). Clip peaks were noted as
  low (-5.9 dBFS, P109). The 3D voice uses the sound system's muffled bus behind a shut Door.
- **Music ducking:** only during a cutscene (`MusicDuck`): an AudioEffectAmplify on the Music bus fades to 0.25 of
  itself over 0.5 s and back (`audio.cutscene_duck_level`, `..._seconds`, Q1867). Comments and the tree do not duck.
- **The face:** each frame `VoicePlayer.step(t)` samples the line's door, brows, moods and wiggle and writes them to
  `WasherFace` (the door is the mouth, mood colours on the drum glow, 0.4 s mood blends, the body bounces or rumbles
  only while talking, Q1411, Q1412, Q1436). The tree's motion (`OldTreeMotion`) rustles from the same door keys and
  pulses its bulbs.

## 5. How a line was subtitled and localised

- One Label built in code (`VoicePlayer.subtitle_label`, font 30, cream, black outline 10, bottom, 160 px margins) on
  a CanvasLayer 26; the tree builds its own copy on its own layer 26. No speaker name, no Theme, no background.
- The segment showing is the one begun and not ended, lingering 0.25 s.
- **Heard only when audible** (rogue-machine/06, Q1587): a comment's or tree line's subtitle shows only while the
  local camera is within earshot and level band, checked every frame (`VoicePlayer.within_earshot`, shared by both).
  A cutscene's shows to everyone. The setting `game.subtitles` (on by default) turns them all off.
- **No localisation.** The text is English inside the JSON; nothing goes through `tr()`; no string table.

## 6. What was weak

1. **Meaning in file names and tuning lists.** Stage sets, moments and drum pools are spelled in names and probed
   with `file_exists`; a typo is silence, not an error. Three pickers (VoiceDirector, TreeVoiceDirector, DrumRules)
   repeat the same "fit, not the last" logic with small differences.
2. **The text in two places.** The tree's text is in `lines.md` and again in each JSON; the washer's is a whisper
   transcript corrected by hand in a generated file.
3. **Big baked JSON sampled by code.** 30 Hz arrays (door, 4 brow floats, wiggle) read and interpolated per frame in
   GDScript: code animation, where the port's rule is an AnimationPlayer in Looks.
4. **Subtitles built in code, twice,** on the same layer (a washer line and a tree line could overlap), off the Theme,
   no speaker, no `tr()`.
5. **Two co-op models.** The washer is Host-decided; the tree is decided on each machine (except its calls). Both
   worked; the rule of which is which lived in comments.
6. **Priority by special cases** (`busy` callables, `blocked_until`, `calling()` checks) and no queue: a comment
   asked during a cutscene is lost.
7. **No Voice bus:** voices share SFX; no volume of their own; levels above 0 dB to make up for quiet clips; only
   cutscenes duck the music.
8. **The subtitle and the sound disagree:** the sound is muffled behind a Door, the subtitle ignores walls; the sound
   carries to `max_distance`, the subtitle stops at `earshot`.
9. **Takes and placeholders unmarked:** only tree lines say `placeholder`; there is no place for alternative takes.

## 7. What the port already decided

- Q2535: voicelines are designed first, before the washer, the Old Tree and the cutscenes (M5).
- Q2506: the Old Tree's motion, flicker and voice are not ported now; the tree will be reworked.
- Q2296, core/17: the plug-and-play sound system (SoundEvent, SoundCatalogue, `Sounds`, buses Master/SFX/Ambient/
  Music/UI and the Muffled ones, per-bus volume settings).
- Q2337: a zoo station that shows game data is built from that data at load.
- `kit/docs/agents/shipping-basics.md`: every text through `tr()` with a key in one CSV; subtitles for anything
  spoken.
