---
type: ticket
status: done
kind: design
area: core
feature: voice
priority: now
created: 2026-11-24
done: 2026-11-24
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

## Answers
Answered in one sitting, 2026-11-24 (`docs/migration/decisions.md`); `docs/architecture/voice.md` and `washer.md` are
written to them.
- W1 cutscene_3 plays the washer's recording alone in batch A; the Old Tree's line joins it in batch B by its file and
  trigger, no code (Q2633, 2026-11-24).
- W2 cutscene_5 plays whole at the fourth Fix; swapping a recording must be easy (Q2634, 2026-11-24).
- W3 The washer's comment set in the Laundry day is customisable; by default Stage 4's (Q2635, 2026-11-24).
- W4 cutscene_6 plays whole (Q2629, 2026-11-24).
- W5 Every speaker picks a fitting line, never the last one, each fitting line once before any repeats (Q2637, 2026-11-24).
- W6 Voice levels are not adjusted by the game or the bake; the recordings are fixed at the source (Q2638, 2026-11-24).
- W7 The voice bake is a command; no editor entry or automatic bake (Q2639, 2026-11-24).
- Lines are written in one JSON file per speaker, checked and built by the bake; replaces Q2608's Resource per line
  (Q2640, 2026-11-24).
- W8 The subtitle icon is a flat drawn icon in the UI icons' style, its own look ticket, assets/15 (Q2641, 2026-11-24).
- W9 The knockdown wash is batch A, the washer's last ticket, core/98 (Q2642, 2026-11-24).
- W10 The washer is silent until the First wash breaks it (Q2636, 2026-11-24).

## Open follow-ups
None: answered and filed by core/74.

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
