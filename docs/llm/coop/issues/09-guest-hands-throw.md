---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: coop
priority: now
created: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 3, the Hands and Throw half; plan: docs/migration/coop-mess-sync.md (Throws on the stamped stream)"]
terms: [Host, Guest, Teammate, Hands, Throw, Mess, Flight, Pair, Cabinet]
---

# The Hands and the Throw in co-op: a Guest's pick, drop and Throw feel instant; Throws seen by all

A Guest picks, drops, throws, catches, pairs and shelves as the Host does. Its own actions show at once as
looks-only ghosts (Q2220, Q2221, Q2473), the Host decides, and everyone sees every Throw in flight.

## Behaviour list
`docs/migration/m06-lists/03-mess-throw-coop.md` sections D to M, the Backlog Co-op items Z1, Z2, Z6, Z7
and the invariants, with questions 1-9 answered (Q2439, Q2472-Q2479). One test per line, named after it.

## Design
- **Throws on the stamped stream** (coop/01 Option A, `docs/research/coop-flight-sync.md`): a thrown
  body stays on the spawner and gets one MultiplayerSynchronizer with a stamped row (position, rotation,
  velocities, the Host's tick); every other machine plays it 0.1 s behind with the easing coop/01
  measured. Mind coop/01's three conditions in `m06-backlog.md` (throttle held, whole arrays per row,
  `_launch` sets the pose before `add_child`). The thrower's own machine draws its ghost (Q2221) and hands
  over to the Host's body without a pop. A Teammate's Throw leaves the hand at once and waits only the
  0.1 s lag (Q2439).
- **Ghosts (looks only, never write state):** pick (Q2220), drop (Q2473), Throw (Q2221). The wheel turns
  at once and turns back silently on a refusal (Q2475). A second pick waits for the first answer (Q2474).
  A refused pick flies back (F01); a refused Throw or drop puts the item back at once (Q2476); no answer
  after 2 s goes back with the refusal look and "refuse" (Q2477, a typed Resource number). The pick sound
  plays at the click (Q2478); the pairing moment starts on the answer (Q2479).
- **Hands keyed by player id** (the 128-bit id from the Roster, not the peer number), so a rejoin and a
  late joiner see the right Hands; the Host reads each player's own `HandsTuning` (Z1, D13).
- **A Guest's Throw** leaves from its avatar's eyes, not `EYES_FALLBACK` (Z2); the thrower's own body lets
  its Sock through.
- **Teammate cues** as Q2453 and Q2470; footsteps spatial (Z6). A spawned flight is found by its id, not
  its node name (Z7).
- Refusals reach the asker alone (I13).

## Acceptance
- Real path: two zoos (Host, Guest) at 50 ms one way; on the Guest, input picks a Sock at the heap
  station: the ghost flies at once, "pick" sounds at the click, the Hands change on the answer; the Guest
  throws it: the ghost leaves at once and the Host's window shows the body in flight; it lands and both
  Messes are equal.
- A Guest's drop falls at once and ends where the Host's did.
- A refused pick (Hands full on the Host) flies back; a refused Throw puts the item back at once; an
  answer withheld 2 s puts the ghost back with "refuse".
- Two players click one Sock: one gets it, the other's grab fizzles with no sound (F04, L02).
- A Guest pairs (moment on the answer), shelves into a Cabinet drawer and earns Coins, seen by the Host.
- A late joiner mid-Throw sees the Throw fly on.
- Measured in the Built log at 0 and 50 ms: bytes a second for one Throw and for four at once.

## Answers
- Q2220, Q2221, Q2226, Q2439, Q2453, Q2470, Q2472-Q2480 (2026-11-22).

## Open follow-ups

## Built log
