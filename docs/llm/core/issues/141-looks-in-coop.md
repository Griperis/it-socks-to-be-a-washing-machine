---
type: ticket
status: done
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[127-profile-file-and-tallies]]", "[[128-wardrobe-pieces-and-dressed-avatar]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 3", "suggested model: opus"]
terms: [Wardrobe, Player colour, Teammate, Host, Guest, Avatar, Profile]
suites: [avatar, own_body, teammates, coop_join, coop_guard, game_link, lobby, save, main]
---

# Looks, colours and owned pieces in co-op

What a player wears, owns and has tallied travels with them and is decided by the Host. Build
`docs/architecture/wardrobe.md` "What a player owns and wears, in co-op":

- The Roster's entry grows `look`, `owned`, `tallies`; `owned_of(player_id)` returns `Wardrobe.owned(owned)` (the ten
  basic pieces always in, Q2679); `owned_patch(by, piece)` for core/138's open answer.
- The word at the gate (`session_gate.gd`) carries the profile's `look`, `owned`, `tallies` and colour wish; the Host
  clamps them (known ids only, at most 112, `WardrobeLook.allowed`; tallies finite, 0 to 999,999,999; the colour in
  range; the wished colour if free, else the next free) and `joined()` writes them.
- The verbs `wear {look}` (refused unless every piece is owned), `colour {index}` (refused `taken`: the swatch springs
  back), `own {piece}` (an Achievement's reward); a Guest asks for itself only.
- Every machine's `Avatar._dress()` reads `look`; the Player's own body and mirror body read their own entry; the
  Roster's save merge keeps a present player's live `look`, `owned`, `tallies`; this machine's profile follows its own
  entry's applied `look` and `colour` (`save_soon`). Solo has the lone player's Roster entry.
- The Wardrobe station's four switches (core/128) ask the real `wear`.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "Teammates", "Saves and co-op", and
"Where a piece comes from" (a worn piece no longer owned comes off; unlocked pieces stay; not "every piece starts
locked", reversed by Q2679).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
State on the Roster Part (Host decides, Parts sync and save); no new Resource. The clamps' limits are constants beside
the gate's other limits.

## Acceptance
- Real path (co-op): a Guest presses E on the Wardrobe station's Hat switch (asking the real `wear`); on the Host the
  Guest's Avatar wears the hat; a `wear` of a piece the Guest does not own is refused and the Host still shows the old
  look.
- A fresh profile can wear a basic hat; a Guest's forged look of unknown ids is cleaned at the gate.
- Two players wishing the same colour: the second gets the next free one.
- The own body in first person shows only the Socks piece and Trail of the player's own look.
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The ten basic Wardrobe pieces are owned from the start (Q2679, 2026-11-25).

## Open follow-ups
- [later] The Wardrobe zoo station's switches step only through pieces the player owns (as the page will), so
  for a fresh profile the Socks and Trail switches offer only None (no basic Socks or Trail exist). The old zoo
  showed every piece unlocked (M/M, behaviour list "Where a piece comes from"); granting all in the zoo would
  leave the acceptance's "wear of an unowned piece is refused" untestable there. Lead: keep, or add a zoo-only
  "own every piece" switch (as core/145's "Grant all")?
