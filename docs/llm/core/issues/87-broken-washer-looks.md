---
type: ticket
status: done
kind: build
area: core
feature: washer
priority: now
created: 2026-11-24
done:
blocked_by: [core/86, core/76]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Stage, Fix]
---

# The broken washer's looks

How broken the washer looks, from the run: build `docs/architecture/washer.md` "How it looks, by state": the mood level and repair from
`Stages` (the Parts fitted of the Parts in the run; before the First wash it looks fine, the read core/94 wires), the
damage (sparks, smoke, flash, the `washer_buzz` loop) on a fixed clock with fixed seeds, the drum light's idle glow,
mood colour, dim and flicker, the angry rumble under the voice, `cutscene_looks` for core/88, and the `RidingBody`.

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "Its mood and repair" (all), "How it talks": the drum light and the rumble lines; "Its
cutscenes": the sparks' and the drum light's cutscene lines.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The numbers are the old ones in `washer_tuning.tres` (placeholders), judged in the batch's play review (Q2421: no
test of a look number). The washer station's mood pillars drive it.

## Acceptance
- Real path: in the washer station the player presses E on the "angriest" pillar; the sparks emit, the buzz plays and the drum light's energy is 0.3 of its idle; on "calm" none emit and the light is steady.
- With "From the run" each Part fitted in a stand-in run makes it one step calmer (no station change).
- A Sock lying on its top rides the talking bob and lean.
- Placeholders: the broken and glow numbers.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log

- 2026-11-25: The broken look is built on the washer Looks (`washer_looks.gd`, `looks_graybox.tscn`). Changed: sparks (two
  one-shot GPU bursts, fixed seeds, a fixed burst clock), smoke, flash and the `washer_buzz` loop under `Damage`, as strong
  as `damage` (the old floor of mood 1); the drum glow (lining and light) dimmed by `repair` to 0.3 and flickering 0.8 deep
  every 70 ms from a fixed seed; the `washer_rumble` loop under an angry voice (-36 to -12 dB by anger times wiggle); the
  cutscene look (`set_cutscene(WasherCutsceneLook)`, for core/88: repair and share, bursts on angry loud stretches, 0.15
  smoke otherwise, eased at 4 a second). "From the run" already read `Stages` in core/86 and is tested here. The
  `RidingBody` moves with the bob (tested). No station change. Files: game/entities/washer/washer_looks.gd,
  washer_tuning.gd, looks_graybox.tscn; game/audio/sound_catalogue.tres; assets/audio/washer_buzz__synth_a/c.ogg,
  washer_rumble__synth_a.ogg (+ SOURCES.md, game/ui/licence/credits.tres covers); tests/washer_broken_test.gd;
  docs/migration/batch-a-review.md (four settled rows). Placeholders: the new tuning numbers (flash, cutscene, rumble)
  are marked in `washer_tuning.gd`. The old drum light flickered the room light within 4 m too; that line is in the
  First wash's beats (core/94/96), not here. Verified: see the commit's `suite:` line.
