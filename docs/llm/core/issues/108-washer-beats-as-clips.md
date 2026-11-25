---
type: ticket
status: ready-for-agent
kind: refactor
area: core
feature: washer
priority: now
created: 2026-11-25
done:
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

## Built log
