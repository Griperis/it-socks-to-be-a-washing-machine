---
type: ticket
status: done
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[129-upgrades-and-menu]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 3", "suggested model: opus"]
terms: [Old Tree, Upgrade, First wash, Door, Voice line]
suites: [voice, voice_bake, washer, cutscene, fix_scene, first_wash, room_doors, furniture]
---

# The Old Tree's voice

The Old Tree speaks in batch B; nothing on it moves until its rework (Q2670, Q2506). Build
`docs/architecture/economy.md` "The Old Tree talks" for the voice and its first moments:

- The speaker `game/voice/speakers/old_tree.tres` (no acting), the lines `game/voice/lines/old_tree.json` with the old
  recordings copied into `assets/voice/old_tree/` (162 lines of the old `data/voiceover/old_tree/`, less `tip_dirty`,
  `tip_pairing` and the three Grotto ones; the presents' eleven included, their triggers are core/140's; the old
  +12.5 dB baked into the copies once, Q2638); the bake run; credits for the recordings (the old "norman" voice:
  its licence check before a shipping build stays a `[later]`, Q1575).
- `OldTree.talk {trigger}` (the Host runs the cooldown, `busy` with a cutscene or the washer, the chance and the
  picker; every machine plays the answered line from the tree, heard and subtitled only near it), its saved state
  (`met`, `tips`, `calling`, `beat`, `said`) and `OldTreeTuning` (the voice numbers only).
- The moments `tree_call` (the Host's call timer from the First wash's end until a player comes near; the Doors on the
  way from the laundry to the garage start open at a New Game, Q1864), `tree_first` (a first visit), `tree_greet` (near
  again after `away` 45 s), `tree_idle` (40 s near with nothing said: a musing), `tree_affordable` (an Upgrade newly
  affordable, now or on the next visit, in place of the greeting) and `tree_bought`.
- `cutscene_fix_2`: the tree's line joins the washer's by its recording and trigger, no code (Q2633), when a recording
  exists.

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Old Tree moves and talks": the voice,
the earshot, the cooldown and picker, first, greet, affordable, bought, the idle musing, the call and the Doors, the
New Game reset, co-op's one line for everyone, cutscene 3. The motion lines (breathing, flicker, the rustle and pulse
while talking) wait for the rework (Q2670), named there; the grumble, hints, tips, Fix comments and beats are core/133's,
the presents' core/140's.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Lines as one JSON per speaker, built by the bake command (Q2640, Q2639); a trigger is a file in `game/voice/triggers/`
picked in the inspector. `looks_old_tree.tscn` is not changed. `OldTreeTuning` (`game/furniture/old_tree_tuning.tres`)
`# placeholder:` the old `old_tree.json` voice numbers.

## Acceptance
- Real path: in the Economy station the player walks up to the Old Tree; its "first" subtitle shows; walking away and
  back after the away time gives a "greet".
- Buying an Upgrade near it gives a "bought" line; a line is heard only within earshot and level band.
- After the First wash in the house the tree calls until a player comes near.
- Co-op: the Host picks the line and both players near see the same subtitle.
- Nothing on the tree moves while it talks (its Looks unchanged).
- Placeholders: `OldTreeTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Old Tree's voice comes in batch B; its motion waits for its rework (Q2670, 2026-11-25).
- Voice levels are fixed at the source, not by the game (Q2638, 2026-11-24).
- The Host decides every speaker's line (Q2545).

## Open follow-ups
- [later] The old voice "norman" (Piper, LibriVox): its licence check before a shipping build (Q1575, old ticket 95);
  the credits entry now covers `assets/voice/old_tree/*`.
- [later] The +12.5 dB baked into the 145 copies (Q2638) clips 2.3 % of their samples (every old recording peaks
  near 0 dBFS); a fix at the source (a limiter, or less gain) is the designer's (batch-b-review.md, core/132).
- [later] The Old Tree's subtitle icon: none yet (the Theme's plain disc); a drawn icon is a look ticket.
- [later] `game/house/door_shut_rules.gd`'s `keep_open` still reads `# placeholder: waits for the Old Tree (M4)`;
  it is Q1864's answer now (not this ticket's file).
