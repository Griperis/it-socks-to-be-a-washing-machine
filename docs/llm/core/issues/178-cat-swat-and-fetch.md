---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[177-cat-petting-holding-throwing]]", "[[183-xray-show-pair-glows]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 8", "suggested model: opus"]
terms: [Cat, Sock, Pair, Mess]
suites: [cat, mess, coop_mess, handling, pairing, xray_mates]
---

# The Cat's swat and fetch

Now and then the Cat bats a loose Sock lying by it; and petted, it sometimes fetches: it walks to the nearest two loose
Socks of one Design, takes them in its mouth as a sock ball and sets them down as a Pair at the petter's feet with a
meow. Build `docs/architecture/cat.md` "Swatting", "Fetching", draft 151-C:

- the verbs `swat`, `knock` (the item flung 0.5 to 1 m at 0.45 of the swat by the Mess's drop patch, by nobody;
  nothing if it moved since the swat), `fetch_step` and the fetch roll in `pet` (`fetch_chance` 0.6, cooldown 45 s);
- `Mess.carried_patch(socks)` (HELD with no Hands) and `Mess.fetched_pair_patch(lead, other, pose)`; the Hands never
  read a HELD record as theirs unless their own lists name it;
- the mouth's drawing (`CatLooks.carry`: one Sock across `Mouth`, a Pair's sock ball at `Carry`, the Mess's own Looks
  for the Design);
- `CatLooks` joins the group `sock_carriers` (`drawn_sock(id) -> Node3D`), so a Sock X-ray's glow follows a mate in the
  Cat's mouth (Q2714; core/183 asks the group);
- the errand's ends: a pick (its Socks laid where it stands), a petter leaving, a load; `cat_swat` at the paw's contact,
  `pop` at the take, the meow at the Pair.

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): P2; S1; F1, F2.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`CatTuning`'s swat and fetch numbers; no new data; the swat's paw is the `swat` clip.

## Acceptance
- Real path: the player presses E on the Cat (zoo tuning, `fetch_chance` 1) with two Socks of one Design on the floor;
  the Pair the player then sees at their feet is picked with the left click into their Hands as one Pair.
- A loose Sock within reach is batted 0.5 to 1 m with `cat_swat`, never one in the Hands, inside furniture or above
  0.45 m.
- Behind a shut Door the Pair lies at the closest reachable spot; a petter walking 2 m off is followed; a petter leaving
  gets it set down where the Cat stands; a Cat picked up mid-errand lays its Socks where it stands.
- Every Design keeps two records throughout; a Guest sees the same (co-op case).
- With Show pair on (the case owns the X-ray through the level's `Upgrades`) and the active Sock's mate in the Cat's
  mouth, the glow sits at the Cat's mouth and follows it (core/183's `sock_carriers` ask, merged before this ticket).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The fetch of the nearest Pair at 0.6 and 45 s (Q2703, 2026-11-26).
- The Sock X-ray's glow follows a fetched mate (Q2714, 2026-11-26).

## Open follow-ups
