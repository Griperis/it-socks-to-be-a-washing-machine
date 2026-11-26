---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: ["[[137-presents-under-the-old-tree]]", "[[141-looks-in-coop]]", "[[128-wardrobe-pieces-and-dressed-avatar]]", "[[124-coins-and-drawers]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 5", "suggested model: opus"]
terms: [Gift, Wardrobe, Coins, Rarity, Teammate]
suites: [final_screen, run_tallies, carry, coop_carry, save, menus]
---

# Opening a present and the reveal

The carrier opens their present: everyone sees it shake and pop, the opener sees the piece. Build
`docs/architecture/gifts.md` "Opening" and "The Final screen":

- `Present.open` (the carrier's second left click through the Hands' click routing for a carried thing): the Host
  checks the asker is `for_player` and holds it; the answer removes the row, puts `Roster.owned_patch(by, piece)` in for
  a new piece (S-122c), writes the refund (75) into the `Bank` as a bonus when they owned every piece (Q2673; the
  counter counts up, Q2668), appends `RunRecord.pieces` (a new piece only) and counts `RunRecord.gifts_opened`.
- `present_opening.tscn` (every machine): the box's Looks follows the carrier's hold point and plays the `open` clip
  (the old wobble 5 Hz quickening by 3 Hz, 0.04 to 0.3 rad by 70%, the crouch, the 0.45 hop, the lid's flight, the
  shrink, the 28-speck burst, `gift_rattle`), scaled to `shake` 1.0 s, then freed.
- `GiftReveal` on the opener's machine: `gift_reveal.tscn` (a CanvasLayer on the Theme; a 520 x 520
  `SubViewportContainer` with core/128's `preview_stage.tscn`, a turntable, the box playing `open` at 1.6 x; a
  `Caption` VBox: name, Rarity, "New in your Wardrobe" or "Already yours: +%d Coins"); the piece's preview pops in
  after the pop (0.35 s back-out, 1.6 rad/s, a Trail 0.5 rad/s tipped -0.6); stays `preview` 3.0 s; then any click or
  pad face button closes it and is consumed; a click during the shake is consumed; the player may walk. The opener's
  machine then calls `profile.unlock_piece`.
- The Final screen: each column's pieces strip from `RunRecord.pieces` (through `Wardrobe.preview`, fitted), two
  `FinalTotal` files `gifts_opened` ("Gifts opened") and `pieces_won` ("Wardrobe pieces won"); the Final screen
  station's pillars get pieces in their made-up records.
- `gift_rattle` as a SoundEvent (the first synthesised candidate).

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "Opening and the reveal" (the Coins line with
Q2673), "Saves and co-op" (an opened present's lines); `06-coins-drawers-upgrades.md` "Two currencies", the refund
line.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The `open` clip keyed in the box's Looks; the reveal a scene in nodes with Theme variations (Q2658), code only fills
it; `shake` and `preview` in `PresentTuning` (`# placeholder:`).

## Acceptance
- Real path: carrying their present the player left-clicks: the box shakes and pops, the reveal shows the piece's name
  and "New in your Wardrobe", a click closes it, and the profile lists the piece.
- Co-op: the Teammate's machine sees the box shake and pop where it is carried; the Host's `owned_of` for the opener
  now has the piece.
- Opening when the player owned every piece shows "Already yours: +75 Coins" and the Coins counter counts up by 75.
- The Final screen shows the opener's piece in their column and the two totals.
- Placeholders: `shake`, `preview`, `refund`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Coins (75) only once the player owns every piece (Q2673, 2026-11-25).
- A bonus shows as the counter counting up (Q2668, 2026-11-25).
- Each player opens their own present whenever they like (Q2674, 2026-11-25).

## Open follow-ups
- [later] Technical, for the lead: `player.gd` was out of bounds (core/130), so the carried present's left click and the
  reveal's click-taking poll the pick action before the player's tick and hold its input for that one tick
  (`game/gifts/gift_clicks.gd`). Once core/130 is in, a carried-thing click route in `player.gd` could replace it.
