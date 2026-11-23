---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: next
created: 2026-11-21
done:
blocked_by: []
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M4", "triaged to M3, soon (Q2533, 2026-11-23); to shape with its behaviour list"]
terms: []
---

# Hand-off between players

Port of the old game's Hand-off of a held Sock or Pair to a teammate (catalogue B01; refused for a Laundry bin, B33).

## Acceptance
- Step 1 (2026-11-23): the behaviour list `docs/migration/m3-lists/02-hand-off.md` (the `migration-port` skill, step 1:
  every line, motion, glide, pop and sound with its old file:line; what was weak) and its open choices as
  `[blocking]` Open follow-ups. Then the designer approves the list and the ticket is shaped for its build.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).

## Open follow-ups
- [blocking] Is the catch by Throw (list 02 section F) part of this ticket? It shares the rule and the hit test with the Hand-off and with knockdown. Options: (a) include (recommended: one rule, one hit test); (b) right-click Hand-off only, and any Throw that hits a Teammate bounces.
- [blocking] Does the restriction stay (lines 11-12)? Old: a loose Sock goes over only if it completes a Pair there; a Pair always. Options: (a) keep (recommended: Q652, Q658, Q663 made it the core of co-op); (b) any Sock may be handed over.
- [blocking] Refusal texts (lines 14, 23). Old: "Not their mate" to the giver; "Hands full" to the receiver, the giver sees nothing. Options: (a) keep (recommended: as old); (b) also tell the giver "Hands full".
- [blocking] Who may be handed to (line 4). Old: anyone aimed, a knocked-down Teammate included. Options: (a) refuse a knocked-down Teammate, as the knockdown exemptions do (recommended); (b) keep as old.
- [blocking] A refused loose Sock by Throw (line 35). Old: it bounces with no text. Options: (a) keep (recommended: like a Cabinet bounce); (b) tell the thrower "Not their mate".
- [blocking] The corner hint (line 32). Old: "Drop" while a Teammate is aimed. Options: (a) keep (recommended); (b) "Hand over" while a Teammate is aimed.
- [blocking] Telling the receiver who gave (line 43). Old: nothing. Options: (a) keep (recommended); (b) a line in the giver's colour ("<Name> gave you a Sock").
- [blocking] A Guest's Hand-off with no answer (line 42). Old: waits with no timeout. Options: (a) the 2 s timeout of Q2477 and Q2482 (the item stays, "refuse" only) (recommended: one rule for all Guest Commands); (b) keep waiting.

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/02-hand-off.md` (50 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). Section F (catch by Throw) is included pending question 1. Eight open choices. No game code.
- Files: `docs/migration/m3-lists/02-hand-off.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.
