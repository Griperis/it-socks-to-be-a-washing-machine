---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 1", "suggested model: opus"]
terms: [Hat, Clothes, Wardrobe, Rarity]
suites: []
---

# The Wardrobe's hats and clothes

The 78 hats and clothes (the ten basic pieces and the 17 Collections' two hats and two clothes each) imported from the
old `assets/avatar/wardrobe/*.glb` (Q914; Q1629's line-ups approved in the old game) by the asset port rules into
`assets/wardrobe/`, one Looks scene per piece in `game/wardrobe/looks/<id>.tscn` (`docs/architecture/wardrobe.md` "A
piece's Looks"): a hat in the HatPoint's frame, clothes keeping their skin and their "Crouch", "SwishL" and "SwishR"
blend shapes; the rare touches of these pieces as an autoplay `touch` clip in the Looks (the "Touch" blend shape wave,
the `_glow` surfaces' emission as staggered keys, drops as a `GPUParticles3D` with the old rate, life, gravity, size and
colour), not code. The Secrets' eight pieces are not imported (Q2682). The piece files (core/128) are pointed at their
Looks on the designer's yes; the graybox hat and clothes go then.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The pieces" and the rare touches of
"The Avatar wearing them".

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
Inherited scenes of the imported glbs; touches as clips in each Looks; the shared materials where the port's rules swap
them (Q2177).

## Acceptance
- Look work: a line-up, one strip per Collection and one of the basic pieces, every piece on the Avatar in the old
  views beside the old game's shots, in `builds/review-assets-18/`; `ready-for-human`.
- No real-path case (a look ticket, Q2421); every Looks scene instances on an `AvatarLooks` without errors.

## Answers
- The ten basic pieces are owned from the start (Q2679, 2026-11-25).
- No Secrets in batch B (Q2682, 2026-11-25).

## Open follow-ups
