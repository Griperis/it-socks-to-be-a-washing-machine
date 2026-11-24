---
type: ticket
status: needs-info
kind: design
area: core
feature: voice
priority: now
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: opus", "batch A (Q2606, Q2614)", "voice system decided: docs/architecture/voice.md, Q2545-Q2552, Q2608, Q2609"]
terms: [Stage, Voice line]
---

# Batch A: the voice system and the talking washing machine (design)

The voice system is designed (core/56, `docs/architecture/voice.md`, Q2545-Q2552) and its authoring decided (Q2608:
drop a recording into the speaker's folder, a tool makes the line Resource, subtitle key and animation, the trigger
picked from a list in the inspector, a Voice station plays every line). The speakers are the washer, the Old Tree and
cutscenes 1-6; the washer and the Old Tree both talk in cutscene 3 (Q2609, the lead's reading to confirm here).
Batch A builds the system and the washing machine; the Old Tree (batch B) and the other cutscenes (batch D) plug in
later. A design ticket: findings and a proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks`, `docs/migration/voice-findings.md` and `digest-devices-cat-story.md`: the
washing machine (B34: its model, the face rig `face_rig` and its 8 animations, the rogue machine, where it stands,
what it does in a run), its voiced comments (stage_1..5 voices A/B/C) and which cutscenes it is in, the recordings
in `reference/it-socks/audio/voiceover/` (21 wav) with their timing json, subtitles. Which cutscenes belong to batch
A's run (First wash, Final wash) and which wait (Drum, batch D). Write `docs/migration/m4-lists/05-washer-and-voices.md`
in the shape of `02-lobby.md`: every line, motion, face pose and sound (Q2277), old file:line; what was weak.

## Step 2: proposal (stop for the designer)
Update `docs/architecture/voice.md` from proposal to the build plan with Q2608's authoring flow made concrete (the
folder layout, the bake tool, the trigger list and how a new trigger is added, the Voice station), and
`docs/architecture/washer.md`: the washer as an entity (behaviour plus Looks with its AnimationPlayer), its model and
rig ported by the port rules (`assets_src/`, the Blender skill), its triggers from core/71's Stage seams and core/72's
sequences (read those tickets). Name the M1 asset work (model, rig, animations) as its own ticket.

## How the proposal is shaped (Q2603, Q2604, Q2607)
Batch A is built unattended after the designer approves the proposals in one sitting, then reviewed in play as a
whole (Q2603, Q2605). So the proposal must leave no open choice for the build: every design uncertainty is a
choice below, and every piece says **how it is authored**: what is a typed Resource edited in the inspector, what a
designer adds by dropping a file or a Resource with no code change, and which zoo station shows it (built from the
data at load, Q2337). Where the old game was weak, say so and propose the fix as a choice, the old way as one option.
A detail the old game settles is ported as it was (Q2277); a detail it does not settle is a choice here, not left to
the build (Q2604 is only the fallback).

## Acceptance
- The behaviour list and the proposal exist; every old detail is listed or named as dropped with its Q.
- The build is split into tickets of one mergeable piece each, in the most efficient build order, each with its real-path case named; written as `ready-for-agent` drafts in the proposal (the lead files them).
- The choices are `[blocking]` Open follow-ups here, 2-3 options each with a recommendation; `docs/migration/decisions.md` read first, nothing answered asked again.
- No game code changed.

## Open follow-ups
Choices for the designer (W1-W10), each with 2-3 options; **(rec)** is the recommendation. The build plan follows the
recommendations (`docs/architecture/voice.md`, `docs/architecture/washer.md`); another answer changes one paragraph.
- [blocking] W1 (Q2609's reading, to confirm) The Old Tree in cutscene 3? a) **(rec)** Yes, as two lines of one
  cutscene: batch A plays cutscene_3 as the washer's recording alone; the Old Tree's line is written and recorded in
  batch B and joins it by its file and trigger, no code. b) Both from batch A: a placeholder tree line synthesised now
  (the old Piper tool). c) The reading is wrong: the tree is in no cutscene (the designer says what "3" meant).
- [blocking] W2 cutscene_5 at batch A's fourth Fix (its second half sends the players to "an ancient complex cave
  system", the Drum, batch D)? a) **(rec)** Cut at 6.88 s ("...I'll take care of...") by the line's `end_at`; the whole
  line comes back with the Drum. b) Whole, as recorded. c) No cutscene at the fourth Fix in batch A.
- [blocking] W3 The washer's comments during batch A's Laundry day (after the fourth Fix, before the Final wash; the old
  stage_5 set is about the dungeon)? a) **(rec)** Stage 4's set goes on. b) Silent until the Final wash. c) The
  stage_5 set, as the old.
- [blocking] W4 cutscene_6 opens "You're alive! And you've got the last ingredient!" (the old return from the Drum): in
  batch A? a) **(rec)** As recorded. b) Start it after "You're alive!" (about 1 s in) until the Drum comes.
- [blocking] W5 How the washer picks among its lines? a) **(rec)** One rule for every speaker: a line fitting the
  trigger, never the last one, each fitting line once before any repeats. b) The old washer rule: fitting the trigger,
  never the last one, otherwise at random.
- [blocking] W6 Loudness of the recordings (the old clips peak near -5.9 dBFS, so comments ran at +6 dB)? a) **(rec)**
  The bake matches every take to one loudness (a gain stored with the take, the wav untouched); the speaker's level is
  a trim at 0 dB. b) Keep the files as recorded and the old levels (comments +6 dB, cutscenes 0 dB).
- [blocking] W7 How the designer runs the bake after dropping a recording? a) **(rec)** A "Bake voices" entry in the
  editor and the same command for agents; transcription runs only for new lines. b) The editor bakes by itself when a
  recording appears in a speaker folder (transcription in the background). c) The command only.
- [blocking] W8 The washer's subtitle icon (Q2550)? a) **(rec)** A round crop of a render of the washer's face
  (porthole and brows) from its model, made by the model ticket; until then a grey disc with a porthole ring in the
  Theme's colours. b) A flat drawn icon in the UI icons' style, its own look ticket.
- [blocking] W9 The knockdown wash (drag a knocked player into the drum; Q2437 waits for the washing machine)? a)
  **(rec)** Batch A, as the washer's last ticket (the drag is already in play). b) Batch C, with the Cat's and the
  Radio's loads (one drum rule for all).
- [blocking] W10 Comments before the First wash breaks the machine (the old game let a stare at the machine that still
  looks fine say "I don't wanna talk to you!")? a) **(rec)** Silent until the First wash breaks it. b) As the old:
  comments from the New Game on.

## Built log
### 2026-11-24
- Changed: step 1 and step 2, docs only. Behaviour list of the washer and its voice (where it stands, mood and repair,
  the 15 comments and their triggers, the six cutscenes and their frame, the face's acting, what the rig gives the
  washes, the knockdown wash, the old zoo section), with old file:line, dropped details with their Q, and what was
  weak. voice.md made the build plan (folders, types, the bake, the trigger list and how one is added, playing,
  cutscenes as multi-speaker triggers, co-op, the Voice station). washer.md new: the entity and its Looks contract,
  the broken looks, the cutscene frame proposed as one shared ticket, the seams named from core/71 and core/72, the M1
  asset ticket, seven ticket drafts in order. Choices W1-W10 above.
- Files: docs/migration/m4-lists/05-washer-and-voices.md, docs/architecture/voice.md, docs/architecture/washer.md, this ticket.
- Verified: docs only, no game code changed (agent_finish --no-test).
