---
type: ticket
status: in-progress
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
- [later] Not built: the Hands keyed by the 128-bit player id (Design, Z1). They stay keyed by peer number;
  a leaver's Hands are emptied (D14), so a key never outlives its peer today. Worth its own ticket with the
  rejoin work.
- [later] Not built: the Host reading a Guest's own `HandsTuning` (D13). The Host uses its own player's tuning for
  a Guest; every player has the same numbers until Upgrades (M4).
- [later] Not built: G08/G09 (a ghost's cloth lies flat before the rest; the Mess Sock held back up to 1.5 s for
  it). The ghost eases onto the Host's rest (G07) and the Mess draws the Sock then.
- [later] Look, for the designer's eye: the Host starts a Guest's Throw at the Guest's avatar's hand (the
  HoldPoint, what the others see, Q2439), the thrower's ghost at its first-person hand. The thrower sees the
  difference (about 0.3 m) eased in over 0.2 s (G04), a short slide down at release. Keep, or start the Host's
  body at the thrower's own hand?
- [later] Wording: a guess that times out (Q2477) flies back (a pick) or comes back to the Hands (a Throw, a
  drop) with "refuse" and no text. Should a line show, and which?
- [later] Z7 (a spawned flight found by its id, not its name) not changed: only Throws are spawned now, and a
  thrown Sock cannot rest and be thrown again in one tick, so the rename cannot happen.

## Built log
- 2026-11-22 agent (coop/09): Changed: a Throw's body streams to every Guest as stamped rows (`FlightRow`:
  position, turn, velocity, spin, the Host's tick; one MultiplayerSynchronizer a body, spawned with its first
  row), played 0.1 s behind; coop/07's frozen copy is gone. A Guest's own pick, drop, Throw and wheel show at
  once as looks-only guesses (`GuestGhosts`, `ThrowGhost` on `Mess.LAYER_GHOST`, the HeldView's pick ghost),
  matched to the Host's answer by a Command `seq`; refusals fly back or return at once; 2 s with no answer goes
  back with "refuse". "pick" plays at the click, "throw" at release, "pair" on the answer. A Guest's Throw
  leaves from its avatar's eyes; a Guest hears a streamed Throw's bounces; refusals go to the asker alone.
- Measured (bytes from the Host, unreliable, per flying Throw): 0 ms one 5.58 KB/s, four 22.2 KB/s (5.54 a
  body), sixteen 5.57 a body; 50 ms one 5.56 KB/s, four 22.1 KB/s, sixteen 5.57 a body (coop/01's spike: 4.8;
  the row now carries the spin). Copy lag 0.100 s at 0 ms, 0.150 s at 50 ms; largest step a frame equals the
  Host body's. The Guest's ghost: largest change of step over its body's own 0.022 m.
- Files: `game/sock/flight_row.gd`, `game/hands/guest_ghosts.gd`, `game/hands/throw_ghost.gd`,
  `game/hands/ghost_tuning.gd`/`.tres`, `game/hands/held_view.gd`, `game/mess/mess.gd`, `game/parts/command.gd`,
  `game/parts/session.gd`, `tests/coop_hands_test.gd`, `tests/coop_flight_test.gd`.
- Verified: `run.sh --touched` re-run by agent_finish; coop_hands PASS 101 checks, 6 cases; coop_flight PASS 144 checks; coop_join PASS 183; stress coop_mess:pour_2000_50ms PASS, reliable 49.7 KB/s, worst second 83 KB (coop/08: 59.4, 90).
