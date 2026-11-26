---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: audio
priority: now
created: 2026-11-26
done:
blocked_by: ["[[164-radio-channels]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 5", "suggested model: opus"]
terms: [TV, Channel]
suites: [sounds, outline, save, profiler, menus, zoo]
---

# The TV and its Test card

The TV in the living room: E turns its knob, static fills the screen between channels, its picture is a show in a
SubViewport through a CRT look, its sound heard near it; switched off the picture collapses to a line. This ticket
brings the set and its fourth channel, the Test card. Build `docs/architecture/tv-and-radio.md` "The TV", draft 150-C:

- `tv.tscn` (a static body of the old size 1.5 x 0.46 x 1.22 m), its `ChannelKnob` with `keeps_on_load` off (a load
  turns it off, R19), `TvScreen` (the SubViewport with the channel's show scene, the CRT shader, at most `fps` 15 and
  only while on, past its static and on screen: `VisibleOnScreenNotifier3D`), `TvSound` (3D, `unit_size` 2.5, heard
  within `earshot` 7 m when `Sounds.reach_of` is CLEAR or MUFFLED, on Music at -7.2 dB under the Radio), `TvTuning`;
- graybox Looks and contract with `Glass` left out of the outline and the `static`, `off`, `on` clips (the power light);
- `testcard.tscn` (colour bars, a grey step strip, "IT SOCKS TV" in a ringed box, its 1 kHz tone `tv_testcard`) and its
  channel file;
- the TV in the TV and Radio station.

Behaviour lines (`13-tv-and-radio.md`): R7, R8, R9, R13; R4's TV static, R6's power light, R19's TV off, R2's "TV"; the
words "TV", "Test card".

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`TvTuning` in the inspector; the Test card a scene in nodes on the Theme (Q2658); the static, off and on are clips in
the Looks (Q2697); then assets/27.

## Acceptance
- Real path: in the TV and Radio station the player presses E on the TV: `device_click`, the screen fills with static
  for 0.6 s and the Test card shows, its tone heard 3D.
- Walking 8 m away it is silent; through a wall silent, through a shut Door muffled; E past the last channel collapses
  the picture to a line and the glass goes dark.
- The picture is not drawn while off or off screen (a counter); a load turns it off; the outline never covers the glass.
- Placeholders: `TvTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The four shows with their texts and timings; a load turns the TV off; the TV's spot (Q2704, 2026-11-26).

## Open follow-ups
