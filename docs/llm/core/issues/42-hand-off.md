---
type: ticket
status: done
kind: build
area: core
feature: core
priority: next
created: 2026-11-21
done: 2026-11-23
blocked_by: []
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M4", "triaged to M3, soon (Q2533, 2026-11-23)", "suggested model: opus (co-op netcode, one hit test with knockdown)"]
terms: []
---

# Hand-off between players

Port of the old game's Hand-off of a held Sock or Pair to a teammate (catalogue B01; refused for a Laundry bin, B33).

## Acceptance
- Built from `docs/migration/m3-lists/02-hand-off.md` as answered (Q2588-Q2590).
- Aiming a Teammate (lines 1-5): reach 2.5 m shortened by the first wall, body radius 0.3 m, entry point counts; a knocked-down Teammate is not aimed for a Hand-off (Q2589).
- The right-click short click aimed at a Teammate hands off the active Sock or Pair, never also a drop (lines 6-10); allowed only for a Pair, or a loose Sock completing a Pair there (lines 11-17); "Not their mate" to the giver, who keeps the Sock (line 14).
- The Host moves the item (lines 18-24): pick-in sounds and "Paired!" for the receiver, the giver's drop cue; no room means it lies at the receiver's feet and the receiver sees "Hands full" (line 23).
- Looks (lines 25-32): the item flies from the giver's hand into the receiver's Hands over 0.3 s with the 0.18 m arc, a Pair's small sparkle at a Teammate's hand, the Teammate's outline while aimed with an item; the corner hint stays "Drop".
- Catch by Throw (lines 33-39, Q2588): a Throw below full charge that hits a Teammate is caught under the same rule, bounces at 0.25 of its speed with no text if refused, lies at their feet with "Hands full" if no room; a full charge still knocks down; one hit test shared with knockdown (list 04 lines 12-26).
- A Guest's Hand-off or catch with no answer after 2 s leaves the item in the Hands with "refuse" only (Q2477, Q2482, line 42). A Guest predicts nothing (line 10).
- Things the port does not hold yet (lines 46-50) are not built.
- Real-path case (kit/docs/TESTING.md "The real path"): the giver's pressed right-click action aimed at a Teammate, with a loose Sock whose mate the Teammate holds, ends with the Pair made in the Teammate's Hands, the item gone from the giver's, and the flight drawn; with a non-mate Sock it ends refused with the text and the Sock still held.
- Co-op cases at 0 ms and 50 ms one way (two machines in one process): the Hand-off (accepted, refused, no room) and a below-full-charge Throw caught or bounced give the same Hands on both machines at 0 ms and 50 ms; a Guest's own Hand-off shows nothing before the Host's answer; a Guest with no answer returns to the Hands after 2 s.
- Small details kept (Q2277): every numbered line of the list is built, or named in the ticket as dropped by the designer; each carries a typed Resource number marked `# placeholder`. Look and feel numbers get no test (Q2421); its station shows them.
- A zoo station for the feature (the `zoo-design` skill), then it lands in the main scene; `kit/tools/run.sh --touched` ends PASS.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).
- Q2588: the catch by Throw is part of this ticket (2026-11-23). Q2589: a knocked-down Teammate cannot be handed a Sock (a change from the old). Q2590: every other recommended answer stands: the restriction stays; the refusal texts as old; a refused Throw bounces with no text; the corner hint "Drop"; no "who gave" line; a Guest's Hand-off times out after 2 s.

## Open follow-ups
- [answered, see Answers] Is the catch by Throw (list 02 section F) part of this ticket? It shares the rule and the hit test with the Hand-off and with knockdown. Options: (a) include (recommended: one rule, one hit test); (b) right-click Hand-off only, and any Throw that hits a Teammate bounces.
- [answered, see Answers] Does the restriction stay (lines 11-12)? Old: a loose Sock goes over only if it completes a Pair there; a Pair always. Options: (a) keep (recommended: Q652, Q658, Q663 made it the core of co-op); (b) any Sock may be handed over.
- [answered, see Answers] Refusal texts (lines 14, 23). Old: "Not their mate" to the giver; "Hands full" to the receiver, the giver sees nothing. Options: (a) keep (recommended: as old); (b) also tell the giver "Hands full".
- [answered, see Answers] Who may be handed to (line 4). Old: anyone aimed, a knocked-down Teammate included. Options: (a) refuse a knocked-down Teammate, as the knockdown exemptions do (recommended); (b) keep as old.
- [answered, see Answers] A refused loose Sock by Throw (line 35). Old: it bounces with no text. Options: (a) keep (recommended: like a Cabinet bounce); (b) tell the thrower "Not their mate".
- [answered, see Answers] The corner hint (line 32). Old: "Drop" while a Teammate is aimed. Options: (a) keep (recommended); (b) "Hand over" while a Teammate is aimed.
- [answered, see Answers] Telling the receiver who gave (line 43). Old: nothing. Options: (a) keep (recommended); (b) a line in the giver's colour ("<Name> gave you a Sock").
- [answered, see Answers] A Guest's Hand-off with no answer (line 42). Old: waits with no timeout. Options: (a) the 2 s timeout of Q2477 and Q2482 (the item stays, "refuse" only) (recommended: one rule for all Guest Commands); (b) keep waiting.
- [later] Catch of a lantern, Radio, Beeper, Guide card, Cat, Gift, Part and Laundry bin come with those things (M4/M5).
- [later] Lines of the list tagged "needs" another piece are not built and come with it, none dropped: 3 (the Elevator, M5), 13 and 15 (the Dirty Sock and the Laundry bin, M5), 17 and 39 (the Guide card and the devices, M5), 22 (the Sole Mates "match", M4), 46-50 (section I).

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/02-hand-off.md` (50 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). Section F (catch by Throw) is included pending question 1. Eight open choices. No game code.
- Files: `docs/migration/m3-lists/02-hand-off.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.

### 2026-11-23 (shaped)
- Changed: shaped for building after Q2588-Q2591: answers, checkable Acceptance, model, status ready-for-agent. Docs only.
- Files: this ticket.
- Verified: docs only.

### 2026-11-23 (built)
- Changed: the Hand-off. The Hands' `hand_off` verb (a Pair always, a loose Sock only completing a Pair there, "Not their mate" to the giver; no room: it lies at the receiver's feet across the way it came, "Hands full" to the receiver; never to a knocked-down Teammate, Q2589; within reach plus the Host's slack) and the Host-only `catch`, asked by the Knockdowns' one hit test for a Throw below full charge (a refused one bounces at 0.25 of its speed, upwards kept, no word). Aim: `AimFinder.mate()` (reach shortened by the first wall, body 0.3 m from 0.1 m over the feet, the entry point counts, nearer than the aimed Sock); the Player outlines the Teammate, keeps the crosshair white and the corner's Drop, and a short right click hands off instead of a drop. The receiver's HeldView flies the item in from the giver's hand as drawn on each machine, or from where a Throw hit (`pick_time` 0.3 s, `pick_hop` 0.18 m, flat, a random turn; the worn sparkle and the own pairing moment as a pick's). Hearing: the giver's drop, the receiver's pick or pair (pair buzz). A Guest guesses nothing; no answer in 2 s: "refuse" only. Numbers in `game/hands/hand_off_tuning.tres` (placeholders). The zoo's Hand-off station (two stand-in Teammates; the numbers board built at load); in the main scene through the level runtime's Hands, Knockdowns and Player. Session.PROTOCOL 16 (after main's 15, core/62 and core/63). knockdown:weak_throw now checks the bounce; pairing:never_split lists `hand_off`.
- Files: `game/hands/hands.gd`, `hand_off_tuning.gd/.tres`, `aim_finder.gd`, `held_view.gd`, `guest_ghosts.gd`; `game/knockdown/knockdowns.gd`; `game/player/player.gd`; `game/audio/hearing.gd`; `game/parts/session.gd`; `game/zoo/stations/hand_off.tscn`, `game/zoo/hand_off/`, `game/zoo/zoo.tscn`; `tools/shot_hooks.gd`, `tools/shots/sets/hand-off.txt`; `tests/hand_off_test.gd`, `tests/coop_hand_off_test.gd`, `tests/knockdown_test.gd`, `tests/pairing_test.gd`; `docs/architecture.md`, `docs/architecture/coop.md`.
- Verified: after merging main (6355372): `kit/tools/run.sh --touched`: PASS 18765 checks, 533 cases; `--grep=coop`: PASS 1062 checks, 44 cases (hand_off 52 checks, coop_hand_off 140 checks at 0 and 50 ms); grep_rules PASS. Stills and strips: `builds/review-hand-off/` (`tools/shots/sets/hand-off.txt`: flight and catch strips, Not their mate, Hands full).
