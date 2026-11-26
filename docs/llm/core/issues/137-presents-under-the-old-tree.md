---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: ["[[126-spawned-parts]]", "[[125-collections-as-data]]", "[[128-wardrobe-pieces-and-dressed-avatar]]", "[[141-looks-in-coop]]", "[[127-profile-file-and-tallies]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 4", "suggested model: opus"]
terms: [Gift, Stage, Collection, Old Tree, Part, Hands, Teammate]
suites: [stages, machine_part, carry, coop_carry, hand_off, coop_hand_off, house, save, coop_join, aim_screen, run_tallies]
---

# Presents under the Old Tree

When a Stage completes, each player gets a present per Collection the team completed in it, lying under the Old Tree,
to pick up and carry. Build `docs/architecture/gifts.md` "A Collection completes", "Stage presents" ("A present is a
spawned scene" from `present.tscn` on, "The drop", "The heap", "The Machine Part's pop spot", "The box's Looks",
"Prompts and sounds"):

- `Stages.completed` and the Host-only `note_complete` with the `collection_completed(collection, by)` event, the
  completer's "done" rumble, and the one line in core/127's `TallyRecorder` counting `collections_completed`.
- `Presents` (Part in `run.tscn`), `PresentDraw` with the G1 rule (Q2673): a piece of the completed Collection the
  player lacks and has not waiting (RARE weighs `rare_weight` 0.25); owning it whole, a lacked piece of another
  unlocked, not held-back Collection; lacking none at all, any piece of the completed one, whose opening refunds. The
  owned pieces come from `Roster.owned_of` (S-122b), the pieces from `Wardrobe.pieces_of` (S-122a).
- `present.tscn` (`Carriable` with `handable` off and never thrown, `present_hold.tres`; `Present` Part with
  `for_player`, `piece`, `collection`; graybox `Looks` with `Box`, `Box/Lid`, `Glow`, `Sparkle`, `Tag`, `Burst`, the
  clips `drop`, `lying`, `RESET`), `gift_paper.gdshader` (the old wrapping shader, ported), the wrapping from the
  completed Collection's file.
- The `carry_guards` seam on `Carriable` (`pick_refusal`, `aimable_by`): a Teammate's present is refused silently and
  not aimed or outlined.
- The heap round a `PresentSpot` marker placed by hand at the Old Tree's south foot in `house.tscn` and on the Stages
  station's mini run (`heap_spots`: hex grid 0.42 m, nearest first, clear of lying boxes, nudged by the Host's rng).
- **Carried from batch A** (`docs/migration/batch-a-review.md` question 4, core/79): the Machine Part's pop spot moves to
  the nearest hex spot clear of any lying present (the old `CA:439-479`).
- The hints (Q2677): aimed own present "[LMB] Pick up"; carried "[LMB] Open" and "Drop [RMB]"; sounds `pick`, `drop` as
  SoundEvents (the landing silent).
- The Gifts station's "Drop presents" (a Collection picked on a dial) and "Complete a Collection" switches, each
  Collection's pieces laid out through `Wardrobe.preview`.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "When presents come", "What is inside" (with
Q2673 over the old Coins line), "The presents under the Old Tree", "Picking up and carrying", "Saves and co-op" (the
presents' lines). Opening is core/138's; the tree's lines core/140's.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The clips' keys in the editor (the entity's state plays in its Looks); `PresentTuning` (`rare_weight`, `refund` 75,
`apart`, `shake`, `preview`, `tiles`, `ink_strength`), `# placeholder:` the old. The `PresentSpot` is placed by the
level's author. The Looks follows the contract assets/16's model will keep.

## Acceptance
- Real path: on the Stages station's mini run the player shelves Cabinet A's last Pairs by clicks, the Stage completes,
  a present wrapped in A's Collection drops at the spot labelled for the player; a left click carries it ("[LMB] Open"
  shows); a right click puts it down.
- Co-op: one present each; the Teammate's is not aimable and a click on it does nothing.
- A Stage that completes no Collection drops nothing; a player who owns every piece of the completed Collection gets a
  piece of another unlocked one.
- The Machine Part popped while presents lie lands clear of them.
- Save and load with presents lying and one carried; a late joiner sees them.
- Reachable in the main scene: presents drop under the Old Tree in a house run.
- Placeholders: `PresentTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A present whose Collection the player owns whole gives a piece of another unlocked Collection they lack; Coins only
  once they own every piece (Q2673, 2026-11-25).
- Each player picks up and opens their own present whenever they like (Q2674, 2026-11-25).
- "[LMB] Pick up" aimed at your own present, "[LMB] Open" while carrying it (Q2677, 2026-11-25).
- The first presents come after Stage 2, as the rules fall out (Q2678, 2026-11-25).
- Gifts come as Stage presents under the Old Tree when a Stage ends (Q2612, 2026-11-24).
- The present box model (assets/16, `assets/present/present_box.glb`: `Box`, `Box/Lid`) is approved; this ticket swaps it into the box's Looks in place of the graybox (Q2692, 2026-11-26).

## Open follow-ups
- [later] Two readings of Q2673 the lead made, built so and listed on the review sheet for the designer: "unlocked" is
  the Host's unlocked set (the one the draw used), and the box keeps the completed Collection's wrapping whatever piece
  it holds.
- [later] For core/138: the approved model comes as one glb instance, so the Looks' lid is `Looks/Box/Box/Lid` (the
  turning `Box` is the glb's root, its `Box` mesh and `Lid` under it), not `Box/Lid`; `Present.MESHES` names both.
- [later] The Stages station's own mini run (2 Pairs a Drawer, Cabinets of six Drawers) never completes a Collection,
  so in the zoo presents come from the Gifts station's switches; the real-path case plays the station with a plan of
  1 Pair a Drawer and six starting Rows. A zoo plan that ends in presents is the lead's call.
- [later] The Gifts station's "Complete a Collection" is read as "own every piece of the dial's Collection for this
  session" (so the next "Drop presents" shows G1); a lead's reading of the zoo switch, on the review sheet's list.
- [later] The Collections station's wrapped box (gifts.md "Zoo stations") is core/136's file; `Present.wrap_looks()`
  is the call it needs.
