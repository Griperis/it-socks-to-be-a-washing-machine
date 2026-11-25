---
type: ticket
status: done
kind: refactor
area: core
feature: washer
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: [assets/14]
notes: ["suggested model: opus", "designer 2026-11-25: do it; state plays an AnimationPlayer in Looks, not code animation", "after assets/14 merges: the real Looks needs the same clips"]
terms: [Looks]
---

# The washer's wash beats as animation clips, not code motion

`game/entities/washer/washer_looks.gd` (640 lines) moves the washer in code for the First and Final wash beats.
Our rule: state plays an AnimationPlayer in Looks.

## What moves into clips
- The Final wash without a line (`set_voiced(false)`): the body's hop and sway and the warm glow pulse
  (`happy_hop`, `happy_hop_rate`, `happy_sway`, `happy_sway_rate`, `happy_glow_*`, today `sin()` in `_process`).
- The wide shot's bob (`shot_bob`, `shot_bob_rate`) and the Final wash's camera push, if they are a loop or a
  one-off motion and not driven by a live number.
- The drum's ramp up and ease down (`calm_wash`, `happy_wash`, `happy_done`).
- The door (`door_open`/`door_close`, today a Tween): a clip or a seek on the existing `mouth`, whichever is
  simpler.
- The `WashCalm` AudioStreamPlayer3D that `calm_wash` makes in code becomes a node in the Looks scene.

## What stays in code
What follows a live number: the glow easing toward the mood, `repair` dim and flicker, the broken look's strength
(sparks, smoke, buzz, rumble scaled by `damage`). The ticket says which and why.

## Acceptance
- The clips are in the washer Looks (the graybox and assets/14's real one), named in `looks_contract.json`;
  `asset_lint` passes for both.
- The tuning numbers that drew the motion become keys in the clips at the same values (or the clip's speed reads
  the number). The moved numbers leave `WasherTuning`, and the ticket lists where each one went.
- Same look: a before/after strip of each beat (the calm wash, the break, the happy wash with and without a line,
  the door) in `builds/review-core-108/`. The motions match frame for frame within a frame's tolerance.
- The washer, laundry and cutscene suites pass, the full suite passes, nothing flaky. The tests that read
  `shot_bob()`, `shot_push()` and the like still read what the player sees.
- `washer_looks.gd` gets shorter. The report gives the before and after line counts.

## Open follow-ups
- [later] `tools/shot_hooks.gd` is 1402 lines (grep_rules' note: split it when next touched); this ticket added the
  `washer_beat` hook to it rather than split it.
- [later] The clips run past their beats (`calm_wash` 6 s, the happy washes 10 s) and hold their last key: a
  `wash_seconds` or `happy_lead` longer than that in the data needs a longer clip (batch-a-review.md, core/108 rows).

## Built log

### 2026-11-25
- Changed: the First and Final wash beats are clips of the washer Looks (both the graybox and the real one, the same
  keys): `Beats` (`calm_wash`, `wash_break`, `happy_wash`, `happy_wash_unvoiced`, `happy_done`, `happy_done_unvoiced`)
  keys the root's `spin`, `shot_height`, `push_share`, `position:y`, `rotation:z`, `lit`, `glow_colour`,
  `glow_energy`, `Bubbles:emitting`, `WashCalm:playing`; `Door` (`door`) replaces the door's Tween; `WashCalm` is a
  node of the scene. Bezier keys baked once from the old formulas (smoothstep ramps exact with two keys; sines and
  the hop an eighth of a period apart, Hermite on the slope). `WasherLooks` keeps flags and plays clips; what follows a
  live number stays code: the glow's ease toward the mood (a live target), the repair's dim and flicker (`repair`), the
  broken look's sparks, smoke, buzz and rumble (`damage`, the acting's anger and wiggle), the door's seek of `mouth`
  (`door`, also set live by the knockdown wash and the spray). Fixed on the way: `door_close` on a shut door no
  longer swings it open (the Final wash's start).
- Where each number went: `wash_spin` 0.8 and `wash_ramp` 1 s: the `spin` keys of `calm_wash`, `happy_wash`;
  `shot_bob` 0.01 and `shot_bob_rate` 2.2: the `shot_height` keys of the three wash clips; `happy_push` 0.4 (of
  `happy_lead`): the `push_share` keys (2.6 s); `happy_spin` 1.2 and the unvoiced ramp (0.2 of `happy_lead`, 1.3 s):
  the `spin` keys of `happy_wash_unvoiced`; `happy_hop` 0.06 / `happy_hop_rate` 1.1: its `position:y` keys;
  `happy_sway` 3 / `happy_sway_rate` 0.55: its `rotation:z` keys; `happy_glow_colour`, `happy_glow_energy` 0.5,
  `happy_glow_pulse` 0.2: its `glow_colour` and `glow_energy` keys; `after_spin` 0.12 and `happy_after_rate` 0.5: the
  `spin` keys of `happy_done` (1.36 s) and `happy_done_unvoiced` (2.16 s); `happy_bubbles_off` 1 s: their
  `Bubbles:emitting` key; `break_height` 0.4: `WashCalm`'s position (the loop and the clanks). Kept in
  `WasherTuning`: `happy_lead` and `happy_bubbles` (the cutscene's `$` numbers) and `room_flicker_range`.
- Same look: a per-frame trace of every beat on both Looks, old code against new (spin, bob, push, hop, sway, glow,
  lit, bubbles, door, the door bone, the loop): calm, voiced and door identical to 1e-4; unvoiced sway within
  0.00027 rad (0.5% of 3 degrees), the target glow within 0.0002, the drum light's eased energy one frame earlier.
  The drum's turn runs about 0.7 frame ahead (5 degrees of the drum), the clips being on physics frames.
  Strip: `builds/review-core-108/washer-beats-before-after.png` (`kit/tools/shot_set.sh washer-beats --before b058f113`,
  34 pairs): the door and the break 0 differing pixels; the calm and voiced washes a few hundred to 5000 pixels (the
  bubbles, the drum's phase, the camera reading the push one frame sooner); the unvoiced wash up to 36000 pixels where
  the push and hop are fastest: the same one-frame read, the trace above shows the motion itself equal.
- `washer_looks.gd`: 640 lines before, 622 after.
- Files: game/entities/washer/{washer_looks.gd, washer_tuning.gd, looks_graybox.tscn, looks_washer.tscn,
  looks_contract.json}; tests/{washer_test.gd (new case `beats`, the contract's `clips`), first_wash_test.gd,
  final_wash_test.gd}; tools/shot_hooks.gd (`washer_beat`), tools/shots/sets/washer-beats.txt;
  docs/architecture/{washer.md, run-ends.md}; docs/migration/batch-a-review.md.
- Verified: `PASS 22971 checks, 720 cases` (--touched, 90 suites); `PASS rules`; `PASS asset_lint: 2 look scenes, no problem`; `PASS uids`.
