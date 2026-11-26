---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[182-xrays-owning-and-clock]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 3", "suggested model: opus"]
terms: [X-ray, Show pair, Teammate, Hands, Mess]
suites: [xray_mates, coop_xrays, pings, coop_pings, outline]
---

# Show pair: the mates glow

While Show pair is on, the mate of the active Sock glows through walls, Heaps and furniture with a pulsing cyan outline,
in a Teammate's Hands too, with an edge arrow when it is off screen; the glow follows the mate as it moves, thrown,
carried or fetched (Q2714, the designer's change from the old). Build `docs/architecture/x-rays.md` "Show pair:
`MateGlows`", "How both look", "The hint arrows", draft 152-B:

- `game/mess/sock_copy.gd` (a Mess Sock's live Looks copy at its drawn pose), moved out of `ping_mark.gd`, which uses
  it (the pings' look unchanged);
- `MateGlows` (`mate_glows.tscn`, `.gd`): a copy per Mess mate at `glow_scale` 1.08 wearing `xray_glow.gdshader`
  (ported: unshaded, no depth test, whitened towards the rim, breathing at 1.5 Hz) with `sock_xray_glow.tres`, outlined
  with `sock_xray_outline.tres` (width 1.5, the pulse numbers, priority above the pings' and the Sole cues'), following
  the mate each frame; a Teammate's held mate in any slot gets the overlay and a second Outline; a mate no Hands hold
  is asked of the group `sock_carriers` (`drawn_sock(id)`: its member is the Cat's, core/178) and glows there; the
  overlay taken off when the show ends or the Sock leaves;
- the arrows' source in `#33d6ff`, priority 0; `sock.tres`'s `view`;
- stills of a mate through the wall, under the Heap and in the stand-in Teammate's Hands in
  `<main checkout>/builds/review-xrays/` for the review sheet (the outline is judged at its first still, Q2701).

Behaviour lines (`docs/migration/m4-lists/10-x-rays.md`, by heading): "Show pair" lines 1, 2 and 4; "How they look" line 1 (the Sock X-ray's) and line 3 (its arrows); "Owning
and using" line 6 for the glows.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The glow material and the outline style in the inspector (`# placeholder:` the old); the breathing is the shaders'
pulse, no code motion (Q2697).

## Acceptance
- Real path: key 1, then the mouse wheel's cycle to another loose Sock, through the scene's wiring, to the outlined copy
  over the new active Sock's mate in the rendered view.
- The mate behind the wall and the one under the Heap show their copy with the glow and the cyan outline through them;
  a thrown mate's copy follows it in the air (Q2714); a Pair active shows none; All-Hands shows each held Sock's mate
  once.
- The mate held by the Teammate stand-in in a non-active slot carries the overlay and the outline, and they follow it
  as the stand-in moves.
- The off-screen mate has an edge arrow in `#33d6ff`, gone once on screen; the glow ends with the show.
- In co-op the Guest's X-ray glows the Host's held mate on the Guest's screen and the Host sees no glow; the pings'
  look is unchanged.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The outline judged at its first still, a Teammate's held Sock included (Q2701, 2026-11-26).
- The glow follows the mate as it moves (thrown, carried, fetched) (Q2714, 2026-11-26).

## Open follow-ups
