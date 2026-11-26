---
type: ticket
status: done
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[125-collections-as-data]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 2", "suggested model: opus"]
terms: [Wardrobe, Hat, Clothes, Socks piece, Trail, Avatar]
suites: [avatar, own_body, teammates, knockdown, coop_knockdown, zoo]
---

# Wardrobe pieces as data and the dressed Avatar

Every Wardrobe piece becomes one Resource with its Looks, and every Avatar can wear a look. Build
`docs/architecture/wardrobe.md` "The pieces as data" and "The dressed Avatar":

- `WardrobePiece`, `Wardrobe` (`all`, `of`, `row`, `pieces_of`, `piece_name`, `counted`, `owned`, `preview`),
  `WardrobeLook`, `WardrobeTuning`; the 112 `.tres` written once by a tool from the old `data/tuning/wardrobe.json` and
  `data/tuning/gifts.json` (the tool is kept in `tools/`), their Looks pointing at four graybox pieces (one per slot,
  `listed` off) until assets/18 and assets/19 land; the ten basic pieces with `owned_from_start` on (Q2679).
- A piece of a held-back Collection (the Lost Socks' six) is not listed or counted (Q2683), read from core/125's
  `SockCollection.held_back`; `row()` orders Collections by `Collections.all()`.
- `Dresser` on `AvatarLooks` (hat under `HatPoint` with the name tag lifted `tag_lift` over it, clothes skinned to the
  Avatar's skeleton and following its crouch, socks on `FootL` / `FootR`, swish, first person shows only Socks and
  Trail, the mirror body the whole look with no Trail), the `stepped(foot)` signal.
- The Trail frame (wardrobe.md "Trails: particle scenes authored in the editor", Q2680): `TrailMark` and the Dresser's
  marks (one per step at the foot, at most `max`, freed after `life`, freed at once on a changed Trail, the demo on a
  timer); Lint puffs as the first Trail scene, a first pass of its particles (core/144 judges every Trail on stills).
- `preview_stage.tscn` (the SubViewport stage with its WorldEnvironment, key light and camera as nodes, the old
  values) and `Wardrobe.preview(id, tint)` shown on it: the Wardrobe page (core/142) and the gift reveal (core/138)
  both use it.
- The Wardrobe station `game/zoo/stations/wardrobe.tscn` (instanced by hand in `zoo.tscn`): one stand per slot with
  each piece worn by its own `AvatarLooks`, labelled; a stand-in Teammate walking a loop in a look picked by four zoo
  switches (one per slot); built from the folder at load (Q2337). The switches set the stand-in's look directly until
  core/141's `wear` exists; core/141 points them at it.

The own body and the mirror body follow Dresser rules keyed on `AvatarLooks`' flags (set on their instances in
`player.tscn` if needed); which look they wear comes from the Roster in core/141.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The pieces", "The Avatar wearing
them", "The player's own body and the mirrors", "The piece's preview", and of "Trails" the frame lines (a mark per step
over 0.3 waddle, 0.006 m up, facing the heading; they stay, last `life`, at most `max`; every machine draws its own;
a changed Trail clears; no shadow) and Lint puffs. Not built: "every piece starts locked" (reversed by Q2679).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A designer adds a piece by dropping its model and making one `.tres` with its Looks: no code; the station, the rows,
presents and the Final screen pick it up. The rare touches are a `touch` clip in the piece's Looks (assets/18-19), not
code. A Trail is a scene of particle nodes authored in the editor (Q2680), its numbers on its nodes and `TrailMark`.
`WardrobeTuning` numbers `# placeholder:` the old `avatar.json` and `wardrobe.json` values.

## Acceptance
- Real path: in the Wardrobe station the player presses E on the stand-in's Hat switch: the stand-in Teammate walking
  its loop wears the next hat and its name tag rises over it; with the Trail switch on Lint puffs it leaves puffs as it
  walks, and they are gone after their life.
- `Wardrobe.owned([])` lists the ten basic pieces; `counted` leaves out the Lost Socks' six (held back).
- A skinned clothes piece crouches with the body; a hat is not drawn on the own body in first person.
- Placeholders: `WardrobeTuning`, Lint puffs' `life` and `max`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The ten basic pieces are owned from the start (Q2679, 2026-11-25).
- The Trails are remade as particle scenes authored in the editor; the look is judged on stills (Q2680, 2026-11-25).
- The Lost Socks' six pieces are hidden from the Wardrobe and its "N/M" until the Drum (Q2683, 2026-11-25).
- The 78 hats and clothes Looks (assets/18, `game/wardrobe/looks/<id>.tscn`) are yes: this ticket points the piece files at them and deletes the graybox pieces (Q2691, 2026-11-26).

## Open follow-ups
- [later] (lead) Names that differ from wardrobe.md "The shape": `WardrobeLook` is in `wardrobe_look.gd` (one class per file, named alike), and `TrailMark`'s cap is `max_marks` (`max` shadows the global function). The doc can follow.
- [later] (lead) No `graybox_*` piece files: the hats and clothes point at assets/18's Looks (Q2691); the 17 Socks pieces point at `game/wardrobe/graybox_socks.tscn` and the 16 Trails other than Lint puffs at `game/wardrobe/trails/graybox.tscn` until assets/19 and core/144 (rerun `tools/wardrobe_pieces_from_old.py` or repoint each `.tres`).
- [later] (lead) `docs/llm/PLACEHOLDERS.md` is stale (`placeholders.py --check`); left for the lead's refresh to avoid a merge conflict.
