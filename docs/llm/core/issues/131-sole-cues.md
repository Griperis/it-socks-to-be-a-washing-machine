---
type: ticket
status: done
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[130-personal-upgrades]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 6", "suggested model: opus"]
terms: [Sole Mates, House, Teammate, Highlight, Player colour, Upgrade]
suites: [pings, coop_pings, outline, coop_hands, teammates]
---

# The Sole cues

The co-op mate cues built with the grid (Q2671): Sole Mates, Sole Hands and Mate Radar. Build
`docs/architecture/economy.md` "The Personal effects", the Sole row:

- Their stats (`sole_mates`, `sole_hands`, `mate_radar`: FLAG, House) set on their files.
- A `SoleCues` view on each machine (a node on the HUD's layer, no Command): a Teammate's active Sock that is the mate
  of your active Sock keeps the Highlight outline in their Player colour while in line of sight (0.15 s linger); with
  Sole Hands the whole Teammate is outlined while your active Sock's mate is in any of their slots; with Mate Radar
  both cues show through walls, with edge arrows through the existing `HintArrows`; when a match starts `match` plays
  once at the Teammate's Hands and your own Sock glows briefly; hidden in single player.

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Upgrades", the lines of Sole Mates,
Sole Hands and Mate Radar; GLOSSARY "Sole Mates".

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The linger, glow and arrow numbers in a `SoleCuesTuning` Resource (`# placeholder:` the old); `match` a SoundEvent with
the old pick (the first synth candidate at -8 dB). The outline is the kit's outline, the arrows the existing scene.

## Acceptance
- Real path (co-op): the team owns Sole Mates; player A holds a loose Sock as active; player B presses pick on its
  mate; on A's screen B's Sock is outlined in B's colour and `match` plays once.
- With Sole Hands, B holding the mate in a slot that is not active outlines the whole of B on A's screen.
- With Mate Radar the cue shows with a wall between them and an edge arrow points off screen.
- Solo: no cue, and the three Upgrades are hidden in the menu.
- Placeholders: `SoleCuesTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Sole Mates, Sole Hands and Mate Radar are built in batch B with the Upgrade grid (Q2671, 2026-11-25).

## Open follow-ups
