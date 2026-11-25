# The washing machine (build plan)

**Status: build plan for batch A (designed in core/73; W1-W10 answered Q2633-Q2642; filed by core/74 as core/86-88
and core/98, assets/14 and assets/15).** The behaviour list: `docs/migration/m4-lists/05-washer-and-voices.md`; the voice system it talks
through: `docs/architecture/voice.md`. core/71 (Stages) and core/72 (First wash, Laundry day, Final screen) are designed
beside it; this file names what the washer needs from them ("Seams"), not their parts.

## What it owns

The basement washing machine as an entity: where it stands, its body, its outline and name, its talking face (mouth,
brows, lean, bob, drum light), how broken it looks (sparks, smoke, buzz, the drum light's dim flicker), its comments
(the triggers it senses and the Host's director), its acting in cutscenes, its two camera shots, and what its rig
offers the washes (drum spin, door, laundry pile). It does not own the Fix (core/71), the washes and the spit (core/72),
the cutscene frame (`run-ends.md` "The Cutscene frame", core/88) or the lines themselves (voice).

## The entity (behaviour plus Looks, Q2213, Q2251-Q2253)

`game/entities/washer/`:

- **`washer.tscn`**, root `Washer` (a StaticBody3D on the house layer, at the house's old `Washer` marker's place and
  path, so the Sock generators' `washer` NodePath and the lost-thing spot keep working: house/05, core/16):
  - `Shape`: the 0.7 x 0.95 x 0.7 m box of the old Station (the asset ticket may replace it by the model's collider);
    `PlayerBody` on `Player.BLOCK_LAYER` as the furniture's.
  - **`Washer` Part** (`washer.gd`, extends Part): the speaker's Part. Command `talk {trigger}` (any machine; a Guest's
    stare); its `decide()` is the Host's comment director: the speaker's cooldown (120 s), no comment while
    `Voices.cutscene_playing()` or before the First wash has broken the machine (silent until then, Q2636), the
    trigger's chance, the run's comment set (`Stage.comment_set` of the current Stage, or
    `StagePlan.laundry_day_comment_set` in the Laundry day, Stage 4's by default, Q2635), `VoicePicker` (Q2637); it answers `{line, take}` or a silent no. `applied` on every machine:
    `Voices.say(line, take, looks)`. It grants no other Command (core/107: the washer station's switches are its run
    stand-in's, `game/zoo/washer/washer_run.gd`). Its run (`stages`) is any Part with the Stages reads
    `wants_first_wash()`, `under_way()`, `comment_set()`, `parts_missing()`, `part_total()`, `last_pair_in()`: the house's
    `Run/Stages`, or in the washer station the `WasherRun` stand-in, which owns broken, the mood and the Stage.
    State on the Part: none saved (the old saved none); the director's memory is the Host's and starts fresh on a load.
  - **`WasherSenses`** (`washer_senses.gd`, a child node, looks only): this machine's stare (4 s, 8 m, 12 degrees at the
    middle 0.5 m up, once per look) sends `talk washer_stare`; on the Host only, the progress (a Pair shelved answer from
    Mess, core/71's Cabinet filled), the hit (a Throw's landing answer within 1.4 m on the floor plane) and the idle clock
    (60 s since the last Pair, checked once a second, only when the director could speak). Off when the level is not a
    staged run (its run's `under_way()`; the washer station's stand-in always is). Nothing at the run's last Pair (Q1413).
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
- **`looks_contract.json`**: what every washer Looks has (the graybox and the real one), checked by the Looks test and the kit's asset lint (`nodes` and `animations` are plain name lists for the lint; `paths` holds nested nodes, `players` which player has which animation):
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
  (cutscene_5, whole, Q2634), `cutscene_final_wash` (cutscene_6, whole, Q2629). cutscene_3 plays the washer's line alone;
  the Old Tree's joins it in batch B by its file and trigger (Q2633).

**Built (core/92).** `Washer.busy()`; the `SockSpray` child of `washer.tscn` and the beat `spray` (a method of the
`Washer` Part, which the frame calls when the Looks have no such beat): the door opens over `SockSprayTuning.door_open`,
the Socks spray from the `Porthole` along its +Z, the door shuts over the last `door_close`; the frame's `ended` cleans
it up after a skip. The Fix scenes are `game/run/fix_scenes/fix_scene_1..4.tres`, named by the Stages.

## The cutscene frame

Every batch A cutscene plays on one frame, core/88, designed in `run-ends.md` "The Cutscene frame" (core/72's and
core/73's proposals merged; the old `RogueMachine` did four jobs in one class). The washer gives it the shots and
spawns above, its cut rule, its `cutscene_looks`, and the no-voice lengths (5 to 10 s by level).

## The knockdown wash (core/98)

A knocked-down Teammate dragged to the door and let go goes for a spin (list 05 "The knockdown wash"; old `washes.gd`,
`wash_view.gd`, `rig_wash.gd`). Inside `washer.tscn`, so it is in the house with no edit of the house:

- **`Wash`** (`washer_wash.gd`, `WasherWash`, extends Part): State `peer` (who spins, 0 nobody), `spin_left`, `from` (where
  the body lay), `by` (who let go), `serial`, `out_serial`; none saved. The start is not its own Command: the Host's answer to
  the dragger's `let_go` (`Knockdowns._let_go_at`) finds the washer whose `Door` is within `wash_reach` (1.5 m on the floor
  in front, 1 m up or down), and if it is free (nobody spinning, no cutscene) ends the body's knockdown and starts the wash
  in the same answer (`why: "wash"`); a busy machine's door is no door, the body just lies there (Q758). The end is the
  Host's `end {serial}` once every machine's own clock has run out `wash_seconds` (3 s, the slide in included), held while a
  cutscene plays; its answer lays the player down at the door's front (0.2 m out, 0.3 up) by `Knockdowns.tumble()`: head
  first (70 degrees tipped), every bone launched out of the door at 2.5 m/s and up at 1.5, a 0.4 twist, no push, down
  2 s. A cutscene's end (`Cutscenes._ended`) and a leaver's `left()` end it with no tumble.
- **Out of play** (`Knockdowns.is_washed(peer)`): the washed player is not down, so no grab finds them; no Throw hits them
  (`_bodies()` leaves them out) and `Hands.is_down()` is true (nothing is handed or caught to them); their avatar is not
  drawn and its Mate and Back are off (`Avatar.set_washed`); their own body is held still in the machine and their input
  and HUD are off (`Player.set_washed`, Q991).
- **`WashView`** (`wash_view.gd`, a child of the washer, looks only): the blob in their Player colour sliding in over 0.35 s
  (squared), the door open then slammed (`wash_slam` at the porthole), `wash_slosh` looping at the porthole, the drum and
  the face's `spin` at 1.2 turns a second, the blob tumbling behind the porthole for everyone but the washed player, whose
  own camera sits in the drum (0, 0.42, 0.12) turning with it and lolling, black over the last 0.4 s; at the end the door
  bursts open (slam), stands open 1 s, swings shut over 0.5 s, and their screen fades in over 0.6 s.
- Numbers: `washer_tuning.tres` "Knockdown wash", all placeholders. The tumbling body starts where the ragdoll's own
  `knock()` is given the entry's `tilt`, `launch` and `speed`; the one who let go is let through it (as in the drag).
- Not in this ticket (batch C): the item loads (a Gift box, the Radio, the Cat) through the same door.

## Seams: the triggers this needs from core/71 and core/72

Named, not designed; each is a read of their Part or an answer of their Command.

| From | What the washer needs | Used for |
|---|---|---|
| core/71 | the current Stage number (the run Part) | the comment set (`VoiceLine.stages`) |
| core/71 | a Cabinet filled (its answer) | `washer_progress` (a Pair shelved is the Mess's answer, which exists) |
| core/71 | the Fix: a Part clicked into the washer, its answer naming the Stage's `fix_cutscene: VoiceTrigger` and the takes; the cutscene frame plays it; after Fix 1-3, core/72's spit follows | cutscene_2..5, the mood one step calmer |
| core/71 | the Parts fitted and the Parts in the run (read) | mood level and repair |
| core/71 | whether the level is a staged run | the senses on or off |
| core/72 | `is_broken()` (not `Stages.wants_first_wash()`: the level's `LaundryDay.first_wash` past PENDING, the First wash has broken it; built by core/94, read through the run since core/107) | it looks fine; no comments before (Q2636) |
| core/72 | the First wash's beats: the calm wash (`spin`, `bubbles`), the break (spin stops, damage on), then `cutscene_first_wash`, then the spit (`door` open 0.4 s, shut over the last 0.6 s) | the washer's looks in its cutscene |
| core/72 | a Laundry bin loaded (k of n) | `pile` grows a step |
| core/72 | the Final wash: its wash (`spin` 0.8, `bubbles`), `cutscene_final_wash` after it (spin easing to 0.12), the frame's end going to the Final screen | the washer's looks in its cutscene |
| core/72 | the run ended | the senses off |

What the washer gives them: `Washer.is_washer(node)`, the `Door` and `Porthole` points, `WasherLooks` properties
(`door`, `spin`, `pile`, `bubbles`), the shots and spawns, and the cutscene triggers' files.

## The model and rig (M1 asset work: assets/14)

Ported by the port rules (Q2151-Q2153: technical improvements only; a before/after strip proves the looks unchanged):
`reference/it-socks/assets_src/blender/washing_machine.blend` to `assets_src/blender/appliance/washing_machine.blend`,
`tools/blender/make_washing_machine_face.py` ported into `tools/blender/` (the brows, the lit drum, the laundry, the rig
`face_rig` and its eight actions; build() safe to re-run), exported to `assets/appliance/washing_machine.glb` with the
actions, a collider, the shared materials (Q2177), and `looks_washer.tscn` built to the contract. The game's AnimationTree
and properties stay in the Looks scene, not in the glb. Look work: it stops at its first line-up (the old and the port
side by side, each mood pose, the mouth open) for the designer's go; assets are approved per family batch.

The subtitle icon is not a render of the model: a flat drawn icon in the UI icons' style, its own look ticket, assets/15
(Q2641).

## Numbers (`washer_tuning.tres`, `washer.tres` speaker; every one a placeholder, as the old)

Senses: stare 4 s, 8 m, 12 degrees, 0.5 m up, chance 0.5 (the trigger's); idle 60 s; hit 1.4 m; cooldown 120 s. Hearing:
unit 6 m, max 30 m, earshot 12 m, level band 2 m, voice 0 dB for comments and cutscenes (no game gain, Q2638), lead-in 0.6 s, tail
0.9 s (0.3 of it for a comment), linger 0.25 s, mood blend 0.4 s. Face: glow angry (1, 0.02, 0.005) 3.0, calming (1, 0.45,
0.12) 2.0, entitled (0.5, 0.06, 1) 2.4, surprised (0.95, 0.8, 0.55) 1.2, idle (0.9, 0.75, 0.5) 0.6; light 0.6, range
0.45; repair dim 0.3, flicker 0.8 at 70 ms; rumble -36 to -12 dB. Washes: wash spin 0.8, after spin 0.12. Broken: sparks
6-40, every 2.4-0.5 s, smoke 0.8-4, buzz -22 to -6 dB, cutscene shares 1, 0.8, 0.6, 0.4, 0.2, 0, calm 0.15. No-voice
cutscene: 5, 5.5, 6.5, 7.5, 8.5, 10 s. Knockdown wash (batch A, Q2642): reach 1.5 m, 3 s, 1.2 turns/s, slide 0.35 s, out 2 s, tilt 70,
2.5 m/s out, 1.5 m/s up, twist 0.4, door open 1 s, fade out 0.4 s, in 0.6 s.

## The washer station (`game/zoo/stations/washer.tscn`)

The feature's station first, then the house (Q2359): the real `washer.tscn` on the zoo floor with a Door-less wall
behind; pillars (E) for each mood level 0..5 and "From the run" (a zoo-only Command on core/71's run Part, as the old
zoo's "Mood"), "Break it" and "Fix it" (core/72's `broken`), and one per cutscene trigger ("Play cutscene_fix_2" through
the cutscene frame, a zoo-only start); the senses on, so a stare or a thrown Sock at it comments. Built from the data:
the cutscene pillars come from the CUTSCENE triggers found at load (Q2337).

## Tickets (filed by core/74)

| Draft | Ticket |
|---|---|
| 1 Voice data and the bake | core/84 (lines as one JSON per speaker, Q2640; the bake a command, Q2639; no gain, Q2638) |
| 2 Voices, Subtitles and the Voice station | core/85 |
| 3 The washer entity and its comments | core/86 |
| 4 The broken washer's looks | core/87 |
| 5 The cutscene frame | core/88 (merged with core/72's draft 4) |
| 6 The washing machine's model, rig and animations | assets/14 |
| 7 The knockdown wash | core/98 (batch A, Q2642) |
| W8 the subtitle icon | assets/15 (Q2641) |

The Fix as a cutscene (core/71's `part_fitted` played on the frame with the washer's new mood) is core/92. The order and
waves: `docs/migration/milestones.md` "Batch A".

## Answers (W1-W10, 2026-11-24)

- W1 cutscene_3 plays the washer's recording alone; the Old Tree's line joins it in batch B, no code (Q2633).
- W2 cutscene_5 plays whole at the fourth Fix; swapping a recording must be easy (Q2634).
- W3 The Laundry day's comment set is customisable, Stage 4's by default (Q2635).
- W4 cutscene_6 plays whole (Q2629).
- W5 One picker for every speaker: fitting, never the last, each once before repeats (Q2637).
- W6 No level adjustment by the game or the bake; the recordings are fixed at the source (Q2638).
- W7 The bake is a command only (Q2639). And lines are one JSON per speaker (Q2640).
- W8 The subtitle icon is a flat drawn icon, its own look ticket (Q2641).
- W9 The knockdown wash is batch A, the washer's last ticket (Q2642).
- W10 Silent until the First wash breaks it (Q2636).
