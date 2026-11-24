# The washing machine (build plan)

**Status: build plan for batch A (core/73, Q2606), waiting on the designer's answers W1-W10 (core/73's Open
follow-ups).** The behaviour list: `docs/migration/m4-lists/05-washer-and-voices.md`; the voice system it talks
through: `docs/architecture/voice.md`. core/71 (Stages) and core/72 (First wash, Laundry day, Final screen) are designed
beside it; this file names what the washer needs from them ("Seams"), not their parts.

## What it owns

The basement washing machine as an entity: where it stands, its body, its outline and name, its talking face (mouth,
brows, lean, bob, drum light), how broken it looks (sparks, smoke, buzz, the drum light's dim flicker), its comments
(the triggers it senses and the Host's director), its acting in cutscenes, its two camera shots, and what its rig
offers the washes (drum spin, door, laundry pile). It does not own the Fix (core/71), the washes and the spit (core/72),
the cutscene frame (see "The cutscene frame") or the lines themselves (voice).

## The entity (behaviour plus Looks, Q2213, Q2251-Q2253)

`game/entities/washer/`:

- **`washer.tscn`**, root `Washer` (a StaticBody3D on the house layer, at the house's old `Washer` marker's place and
  path, so the Sock generators' `washer` NodePath and the lost-thing spot keep working: house/05, core/16):
  - `Shape`: the 0.7 x 0.95 x 0.7 m box of the old Station (the asset ticket may replace it by the model's collider);
    `PlayerBody` on `Player.BLOCK_LAYER` as the furniture's.
  - **`Washer` Part** (`washer.gd`, extends Part): the speaker's Part. Command `talk {trigger}` (any machine; a Guest's
    stare); its `decide()` is the Host's comment director: the speaker's cooldown (120 s), no comment while
    `Voices.cutscene_playing()` or before the run has broken the machine (W10), the trigger's chance, the Stage's set
    (core/71's current Stage number), `VoicePicker`; it answers `{line, take}` or a silent no. `applied` on every machine:
    `Voices.say(line, take, looks)`. Command `say_line {line}`: granted only in the zoo (the Voice and washer stations).
    State on the Part: none saved (the old saved none); the director's memory is the Host's and starts fresh on a load.
  - **`WasherSenses`** (`washer_senses.gd`, a child node, looks only): this machine's stare (4 s, 8 m, 12 degrees at the
    middle 0.5 m up, once per look) sends `talk washer_stare`; on the Host only, the progress (a Pair shelved answer from
    Mess, core/71's Cabinet filled), the hit (a Throw's landing answer within 1.4 m on the floor plane) and the idle clock
    (60 s since the last Pair, checked once a second, only when the director could speak). Off when the level is not a
    staged run (core/71's flag) except in the washer station, where it is on. Nothing at the run's last Pair (Q1413).
  - `Looks`: an instance of `looks_graybox.tscn` now, `looks_washer.tscn` once the asset ticket lands (the swap is the
    one line in `washer.tscn`).
  - `Outline` and the name "Washing machine" for the crosshair; no use of its own (E does nothing at it, as the old
    `hint_only`). A held Part's "Fit the <part>" (core/71) and a full bin's "Load the washing machine" (core/72) are
    those features' prompts at the washer: the washer offers `Washer.is_washer(node)` and its door point.
  - `Shots/Wide` and `Shots/Close` (Marker3D each, with a `fov` field): the cutscene's two camera spots, placed in the
    editor at the old numbers (wide 2.0 m out along the front, 0.95 m up, 0.35 m to the right, looking at the middle 0.05
    m up, fov 60; close 0.75 m out from the face, 0.42 m up, 0.06 m right, looking at the face at 0.57 m). Moving a shot
    is moving a marker (Q2164: a placed prop's number is a field on it).
  - `Spawns/1..4` (Marker3D): where everyone respawns after a cutscene, side by side by the machine (Q745).
  - `Door` (Marker3D): the middle of the door's front on the floor (the knockdown wash's reach, the spit's origin, the
    lost-thing spot's base), and `Porthole` (the bubbles' spot).
- **`washer_tuning.tres`** (`WasherTuning`): the senses' numbers, the broken look's numbers, the glow per mood, the repair
  dim and flicker, the spins, the no-voice cutscene lengths, `cutscene_looks: Array[WasherCutsceneLook]` (per cutscene
  trigger: its repair 0-1 and its damage share 1, 0.8, 0.6, 0.4, 0.2, 0, Q1427). All `# placeholder:` as in the old
  tuning ("Numbers" below).
- **`looks_contract.json`**: what every washer Looks has (the graybox and the real one), checked by the Looks test:
  - a `Skeleton3D` named `face_rig` with the bones `lean`, `bob` (under lean), `door_hinge`, `brow_left_pivot`,
    `brow_right_pivot`, `drum_spin`, `laundry_tumble` (under bob), rests the neutral face;
  - an `AnimationPlayer` with `angry`, `calming`, `entitled`, `surprised` (held poses), `talk`, `rumble`, `spin` (loops)
    and `mouth` (shut to 40 degrees open), and an `AnimationTree` made in the editor: the take's acting (a library the
    Looks fills at `act()`), the loops on `bob` weighted by the acting's `wiggle` (talk, or rumble by its `angry` share),
    `spin` on the drum's two bones by a time scale, `mouth` seek for the door outside a line;
  - the root script **`WasherLooks`** (extends `VoiceSource`) with the properties the acting and the washes set:
    `wiggle`, `angry`, `glow_colour`, `glow_energy` (keyed by the acting Animation), `door` (0-1, the spit's and the
    wash's door outside a line), `spin` (turns a second), `pile` (0-1), `repair` (0-1), `damage` (0-1), `lit`;
    `act(take)`, `rest()`, `bubbles(on)`;
  - `DrumLight` (OmniLight3D on a BoneAttachment3D of `drum_spin`, range 0.45, lighting only its own render layer, which
    the drum and laundry meshes are on), the `drum_glow` material on the lining and power light;
  - `Damage`: `SparksBack`, `SparksCable` (GPUParticles3D, blue-white), `Smoke`, `Flash` (OmniLight3D), `Buzz` (a
    looping world sound of the catalogue's `washer_buzz`), `Rumble` (the voice rumble loop, `washer_rumble`); `Bubbles`;
  - a `RidingBody` (AnimatableBody3D on `bob`) so a Sock lying on the top rides the talking bob and lean (rogue/03, Q867).
- **`looks_graybox.tscn`**: the old stand-in's colour (0.6, 0.85, 0.75) box, a door disc and two brow bars on BoneAttachments
  of a hand-made `face_rig` with the contract's bones, a drum disc, the contract's nodes; its AnimationPlayer's eight
  animations are simple hand keys. The acting Animations drive it as they will the real one (the same bone tracks).
- **`looks_washer.tscn`** (the asset ticket): the ported model and rig with the same contract.

## How it looks, by state

- **Mood level and repair** come from the run: before the First wash it looks fine (no damage, repair 1, core/72's
  `broken` false); then the angriest level is the number of Parts (core/71's total) and each Fix is one step calmer;
  `repair = 1 - level / total`; fixed: level 0, repair 1. While a cutscene plays, its `WasherCutsceneLook` sets the
  repair and the damage share instead (one place, where the old had two: weak point fixed).
- **Damage** (`damage` 0-1 from the level): the old curves from mood 1 to the angriest (sparks 6-40 a burst, a burst every
  2.4-0.5 s, smoke 0.8-4 puffs a second, buzz -22 to -6 dB); bursts on a fixed clock with fixed seeds (shots and tests see
  the same). In a cutscene: the share times 0.4-1 by loudness on angry stretches, 0.15 smoke on other moods (Q1427):
  the acting's `angry` and `wiggle` tracks carry what that needs.
- **Drum light**: silent, the lining's idle glow (0.9, 0.75, 0.5 at 0.6), light off; speaking (`lit`), the light on in the
  acting's glow colour; both dimmed to 0.3 at repair 0 and flickering 0.8 deep (a new level every 70 ms), steady at 1.
- **Silent** it keeps the basic pose (Q1436); the acting eases in and out over 0.4 s at a line's start and end.
- **Angry rumble** under the voice: the `Rumble` loop from -36 to -12 dB by `angry * wiggle`.

## Cutscenes: the washer's part

- The washer plays every batch A cutscene's lines as the speaker (`Voices.play_cutscene(trigger, takes)`), its acting on
  its Looks, its damage and repair from `cutscene_looks`.
- It offers the frame its two shots (`Shots/Wide`, `Shots/Close`) and the cut rule: the wide shot for the first segment,
  then at each `segment_changed` the close and the wide in turn (`shot = 0 if index < 1 else index % 2`, the old rule).
- Batch A's cutscenes: `cutscene_first_wash` (cutscene_1), `cutscene_fix_1..3` (cutscene_2..4), `cutscene_fix_4`
  (cutscene_5, W2), `cutscene_final_wash` (cutscene_6, W4). cutscene_3 with the Old Tree is W1.

## The cutscene frame (shared; the lead places it)

Every batch A cutscene needs one frame: core/71's Fix, core/72's First wash and Final wash. The old frame was
`RogueMachine` (weak: four jobs in one class). Proposed here as its own ticket (draft 5), so core/71 and core/72 call it
rather than each build one; if core/72's proposal also designs it, the lead keeps one of the two.

- **`CutsceneState`** (a Part in the level runtime, Host-authoritative): `playing` (the trigger), `takes`, `lead` (s of
  the sequence's own part before the line: core/72's wash), `ends` (the respawn, or core/72's Final screen). Started by
  the sequence's answer, ended by the Host's timeline or skip (a `skip` Command from the Host only, Q751). A late joiner
  during it spawns after it at the laundry (Q864): the snapshot carries `playing`.
- **On every machine** (looks only): input off and the HUD hidden; Socks, Pairs, items, Laundry bins and bodies not drawn
  (Q1425, Q1426); open menus closed; the camera at the washer's wide shot; out of black over the shared fade (0.5 s);
  `lead` seconds for the sequence's beats; then the lines with the cuts; 0.9 s tail; fade to black; the Host's end
  respawns everyone at `Spawns`, every knockdown ended (Q745, Q759); the HUD and input back; fade in. The "[Space] Skip"
  keycap at the bottom right on the Host's screen only (Q862, Q1395); the pad's Start too.
- Without a voice line: the wide shot for the old fixed length (5 to 10 s by level).
- The music duck is `Voices`' (it knows the cutscene channel).

## Seams: the triggers this needs from core/71 and core/72

Named, not designed; each is a read of their Part or an answer of their Command.

| From | What the washer needs | Used for |
|---|---|---|
| core/71 | the current Stage number (the run Part) | the comment set (`VoiceLine.stages`) |
| core/71 | a Cabinet filled (its answer) | `washer_progress` (a Pair shelved is the Mess's answer, which exists) |
| core/71 | the Fix: a Part clicked into the washer, its answer naming the Stage's `fix_cutscene: VoiceTrigger` and the takes; the cutscene frame plays it; after Fix 1-3, core/72's spit follows | cutscene_2..5, the mood one step calmer |
| core/71 | the Parts fitted and the Parts in the run (read) | mood level and repair |
| core/71 | whether the level is a staged run | the senses on or off |
| core/72 | `broken` (false until the First wash breaks the machine) | it looks fine; no comments before (W10) |
| core/72 | the First wash's beats: the calm wash (`spin`, `bubbles`), the break (spin stops, damage on), then `cutscene_first_wash`, then the spit (`door` open 0.4 s, shut over the last 0.6 s) | the washer's looks in its cutscene |
| core/72 | a Laundry bin loaded (k of n) | `pile` grows a step |
| core/72 | the Final wash: its wash (`spin` 0.8, `bubbles`), `cutscene_final_wash` after it (spin easing to 0.12), the frame's end going to the Final screen | the washer's looks in its cutscene |
| core/72 | the run ended | the senses off |

What the washer gives them: `Washer.is_washer(node)`, the `Door` and `Porthole` points, `WasherLooks` properties
(`door`, `spin`, `pile`, `bubbles`), the shots and spawns, and the cutscene triggers' files.

## The model and rig (M1 asset work: its own ticket, draft 6)

Ported by the port rules (Q2151-Q2153: technical improvements only; a before/after strip proves the looks unchanged):
`reference/it-socks/assets_src/blender/washing_machine.blend` to `assets_src/blender/appliance/washing_machine.blend`,
`tools/blender/make_washing_machine_face.py` ported into `tools/blender/` (the brows, the lit drum, the laundry, the rig
`face_rig` and its eight actions; build() safe to re-run), exported to `assets/appliance/washing_machine.glb` with the
actions, a collider, the shared materials (Q2177), and `looks_washer.tscn` built to the contract. The game's AnimationTree
and properties stay in the Looks scene, not in the glb. Look work: it stops at its first line-up (the old and the port
side by side, each mood pose, the mouth open) for the designer's go; assets are approved per family batch.

## Numbers (`washer_tuning.tres`, `washer.tres` speaker; every one a placeholder, as the old)

Senses: stare 4 s, 8 m, 12 degrees, 0.5 m up, chance 0.5 (the trigger's); idle 60 s; hit 1.4 m; cooldown 120 s. Hearing:
unit 6 m, max 30 m, earshot 12 m, level band 2 m, comment +6 dB, cutscene 0 dB (W6 may change both), lead-in 0.6 s, tail
0.9 s (0.3 of it for a comment), linger 0.25 s, mood blend 0.4 s. Face: glow angry (1, 0.02, 0.005) 3.0, calming (1, 0.45,
0.12) 2.0, entitled (0.5, 0.06, 1) 2.4, surprised (0.95, 0.8, 0.55) 1.2, idle (0.9, 0.75, 0.5) 0.6; light 0.6, range
0.45; repair dim 0.3, flicker 0.8 at 70 ms; rumble -36 to -12 dB. Washes: wash spin 0.8, after spin 0.12. Broken: sparks
6-40, every 2.4-0.5 s, smoke 0.8-4, buzz -22 to -6 dB, cutscene shares 1, 0.8, 0.6, 0.4, 0.2, 0, calm 0.15. No-voice
cutscene: 5, 5.5, 6.5, 7.5, 8.5, 10 s. Knockdown wash (W9): reach 1.5 m, 3 s, 1.2 turns/s, slide 0.35 s, out 2 s, tilt 70,
2.5 m/s out, 1.5 m/s up, twist 0.4, door open 1 s, fade out 0.4 s, in 0.6 s.

## The washer station (`game/zoo/stations/washer.tscn`)

The feature's station first, then the house (Q2359): the real `washer.tscn` on the zoo floor with a Door-less wall
behind; pillars (E) for each mood level 0..5 and "From the run" (a zoo-only Command on core/71's run Part, as the old
zoo's "Mood"), "Break it" and "Fix it" (core/72's `broken`), and one per cutscene trigger ("Play cutscene_fix_2" through
the cutscene frame, a zoo-only start); the senses on, so a stare or a thrown Sock at it comments. Built from the data:
the cutscene pillars come from the CUTSCENE triggers found at load (Q2337).

## Batch A's tickets for the voice system and the washer (drafts, `ready-for-agent` once W1-W10 are answered)

In build order. Drafts 1, 2, 3 run one after another; 4 and 5 in parallel after 3; 6 from the start beside them (it
meets the others only at the Looks contract); 7 after 3 if W9 says batch A. The lead files them with their numbers.

1. **Voice data and the bake** (core, voice; model: sonnet). The voice Resources (`VoiceLine`, `VoiceTake`,
   `VoiceSegment`, `VoiceMoodKey`, `VoiceSpeaker`, `VoiceActing`, `VoiceTrigger`), `VoiceBook` with its load checks, the
   bake (`tools/voice_bake.gd`, `.sh`, the editor entry per W7) and `tools/voice_transcribe.py`; the 21 washer recordings
   copied to `assets/voice/washer/` and baked; the CSV with the old corrected texts (Q1382, Q1473), triggers and Stages
   set as the old tags and sets; `washer.tres` and `washer_acting.tres` with the old numbers; batch A's trigger files; the
   CSV registered in Localization. Real-path case: the designer's path: a fixture wav dropped into a speaker folder and
   the bake run headless gives a `VoiceLine` the VoiceBook lists at the next load, with a take whose acting opens the
   mouth on the loud parts and hand-set fields kept on a second bake. Acceptance: the 21 lines load with no VoiceBook
   error; every key has CSV text; no game behaviour changes.
2. **Voices, Subtitles and the Voice station** (core, voice; sonnet). `Voices` (channels, priority, `waits`, the Voice and
   new MuffledVoice bus, earshot and level band, `display/subtitles`, the cutscene duck, `play_cutscene`, the signals),
   `VoicePicker` (W5), `VoiceSource`, `subtitles.tscn` on the Theme with the speaker's icon (W8's placeholder), the Voice
   station built from the VoiceBook with a zoo-only stand-in source. Real-path case: in the Voice station the player
   presses E at a washer line's pillar; the Subtitles row shows the line's first segment text with the washer's icon and
   the stand-in's AnimationPlayer plays the take's acting; behind the shut Door the row still shows and the voice is on
   MuffledVoice. Blocked by 1.
3. **The washer entity and its comments** (core, washer; sonnet). `washer.tscn` with the `Washer` Part, `WasherSenses`,
   `WasherLooks`, the contract, `looks_graybox.tscn`, shots, spawns and points; it replaces the house's `Washer` marker
   (paths kept); the washer station (moods via a stand-in until core/71's run Part exists). Real-path case: in the main
   scene the player looks at the washing machine for 4 s from 3 m (the stare's chance set to 1 in the case's tuning); a
   `stage_1` stare line's subtitle shows and the door bone opens; a Guest's stare plays the same line on both machines.
   Blocked by 2.
4. **The broken washer's looks** (core, washer; sonnet). Mood level and repair from core/71 and core/72 (stand-ins until
   they land), the damage effects and buzz, the drum light's idle glow, mood colour, dim and flicker, the angry rumble
   under the voice, the riding body. Real-path case: in the washer station the player presses E on the "angriest" pillar;
   the sparks emit, the buzz plays and the drum light's energy is 0.3 of its idle; on "calm" none emit and the light is
   steady. Blocked by 3; the numbers are the old ones, judged in batch A's play review (Q2421: no test of a look number).
5. **The cutscene frame** (core, cutscene; opus: co-op timing). `CutsceneState` and the frame as above, the washer's shots
   and cuts, `cutscene_looks`, the respawn, the Host's skip, a late joiner after it; core/71's Fix and core/72's washes
   call it. Real-path case: in the washer station the player presses E on "Play cutscene_fix_1"; the current camera is the
   washer's wide shot, the subtitle shows cutscene_2's first segment, at its second segment the camera is the close shot;
   the Host presses Space and the player stands at a spawn with input back and the HUD shown. Blocked by 3.
6. **The washing machine's model, rig and animations** (assets, M1; opus: Blender). As "The model and rig" above. Look
   work: stops at its first line-up, `ready-for-human`. No real-path case (a look ticket, Q2421); the Looks contract test
   passes on `looks_washer.tscn`. Not blocked.
7. **The knockdown wash** (core, knockdown; sonnet), if W9 says batch A: a let-go body at the door slides in, spins 3 s
   with the spinning view, bursts out knocked down; one at a time; a cutscene's end or a leaver ends it; not saved; the
   old numbers. Real-path case: in the knockdown station with the washer, the player drags the knocked Teammate to the
   door and lets go; the Teammate's body is hidden, their view spins, and after 3 s they lie knocked down in front of the
   door. Blocked by 3.
