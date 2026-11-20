---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: ["[[01-zoo-movement]]"]
notes: []
terms: []
---

# Handling Socks: pick, hold, drop, Throw

Milestone M0.5. A station with loose Socks: the Hands, picking a Sock the crosshair reaches, carry capacity, dropping, the Throw. Socks at this station are few and real entities; the Mess as one bulk system comes in M3 (Q2168), but the Sock's look and its state fields are the real ones.

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
Taken from `docs/migration/behaviour-core-loop.md` (rows M12-M15, H01-H30, T01-T16, read from the old code with
their test names) and the old `game/player/rig_click.gd`, `rig_drop.gd`, `rig_aim.gd`. Ids keep the survey's,
so each line can be traced. Numbers are **today's values, not decisions**: placeholders until the designer sets
them. M0.5 is one player (a Host of one); the co-op lines are listed at the end with where they go.

**Aim and pick**
- M12 When the crosshair rests on a Sock within reach (2.5 m) while standing, then the Sock is outlined and a left
  click can pick it; the first Sock on the aim line wins; the floor beside a Sock, or a Sock out of reach, picks
  nothing.
- M13 When a Sock lies under another but its tip sticks out, then aiming at the tip picks the lower Sock and the
  one on top stays.
- M14 When a wall (or a shut Door) is between you and a Sock, then it is not outlined and cannot be picked, not
  even just past the wall (3 cm slack).
- M15 When a cupboard or drawer is shut, then the Socks inside cannot be aimed at; open, they can. (The zoo's
  example cupboard.)
- H01 When you left-click an aimed Sock with a free place in the Hands, then it goes into the Hands and becomes
  the active item.
- H02 When you click Socks faster than the grab interval (0.35 s), then the extra clicks do nothing, no message.
- H03 The Hands hold 1 item to start (a Pair counts as one). (Big Hands raises it: M4.)
- H04 When the Hands are full and the clicked Sock is not the mate of a held Sock, then it stays and "Hands full"
  shows. (The mate case is core/03, pairing.)

**Holding**
- H06 When you hold several items, then the newest is active, drawn big right of centre, the others tucked small
  to the left; the wheel (LB/RB) steps through them and wraps; with one item nothing changes.
- H21 When you hold G, then the view eases in (75 to 50 degrees in 0.15 s), mouse look slows with it, and the
  active item comes close and large while tucked items keep their screen size; letting go puts it back. (Q2234)
- H22 When you hold R, then the active item turns where it hangs (a Sock about its long axis, one turn per 2 s)
  and keeps the angle when let go; looking, walking, clicking and the wheel still work.
- H23 When a Sock is held, then its Size letter shows. (The Design name and icon need the Sock Smarts and Sock
  Sense Upgrades: M4.)
- H28 When you press the right button with empty Hands, then nothing happens.

**Drop**
- H07 When you tap the right button (under 0.25 s) with the crosshair white, then the active item drops where the
  crosshair is, within reach, on a top flat enough (up to 25 degrees): the floor, a table, a shelf, a Heap.
- H08 When the crosshair is red (too far, a wall, a steep side, the ceiling, a gap narrower than 8 cm) and you
  release, then nothing drops, "Can't drop there" shows and the item stays; with empty Hands the crosshair is
  always white.
- H09 When the crosshair sees into an open cupboard or drawer, then a drop lands inside.
- H10 When a Sock is dropped, then after a 0.1 s flick from the hand it is let go 3 cm over the spot, falls as one
  physical body and lies where it settles; while it falls it cannot be aimed at or picked.
- H11 When dropped on a Sock, beside it, or half over a table's edge, then it settles or falls; it never floats or
  sinks into anything.

**Throw**
- T01 When you hold the right button past 0.25 s with something in the Hands, then a ring fills round the crosshair
  (full in 1.2 s) and releasing throws the active item along the aim with a gravity arc; no cancel.
- T02 When a charge is released under 15%, then it is a short lob (3.5 m/s forward, 2 m/s up), not a drop.
- T03 When thrown with more charge, then it flies faster: 3 m/s at the tap to 5 m/s at full charge. The free Throw
  is weak (Long Arm and Quick Charge: M4).
- T04 When you press Q, then nothing happens.
- T07 When a loose Sock is thrown at a Cabinet, then it bounces off and lies loose again, never shelved. (With
  core/04's Cabinet.)
- T08 When a Sock is thrown, then it never ends inside a wall or furniture and always ends up lying loose.
- T11 When a Throw faster than 1.5 m/s hits lying Socks, then it wakes the Sock hit and at most 8 touching it; a
  slow drop wakes none.
- T13 When a thrown Sock comes to rest, then it lies where its body stopped; a flight that never settles is put
  down after 6 s.
- T14 When a thrown Sock leaves the playable space or goes above the ceiling, then it comes down at once and lies
  at a set return spot (in the old game, in front of the washer; in the zoo, the station's).

**Invariants** (from the survey's part 4)
- I.1 No Sock is lost or doubled: each is in exactly one place (lying, in the Hands, in flight), through every
  pick, drop and Throw.
- I.3 An item is in at most one player's Hands.
- I.6 Every resting Sock lies on what is drawn; none in a wall, floor or furniture; none aimable inside a shut
  container.
- I.7 A drop is accepted only where it would rest, within reach; otherwise refused and the item stays.
- I.8 Nothing flies through walls; every flight ends exactly once.
- Every Hands change is asked as a Command and decided by the Host of one (Q2212); the held items are decided
  state, a Sock in flight is the Host's physics body (Q2221, Q2222).

**Not in this ticket**
- Pairs (H04's mate case, H12 picking up a floor Pair, a Pair's drop and Throw): core/03.
- Shelving by Throw (T05, T06): core/04.
- Co-op, M0.6: hand-off and its refusals (H13-H15), no stealing (H16), the race (H17), Guest prediction (H18,
  Q2220, Q2221), a leaver's Hands (H24), saves and joiners (H25, H26), knocked down (H27), match cues (H29), a
  teammate in the way (H30), Throws hitting a teammate (T09, T10), watching a Throw (T12, Q2226), spin guard (T15).
- Upgrades, M4: Quick Grab, Big Hands, Long Arm, Quick Charge, Sock Smarts, Sock Sense (base values above stay).
- New Game, M4: the Guide card in the Hands (H05).
- Other features, M5: things that take the whole Hands (H19), the Upgrade station's top (H20).
- Sounds and rumble (T16's sounds): with the first audio ticket; the ring itself is here.
- The Mess as one bulk system (laying, Heaps, the wake budget of 512): M3 (Q2168). Here a handful of real Socks.

## Design
<Step 2.>

## Acceptance
- Every change to the Hands goes through a Command answered by the Host of one (Q2212).
- A Sock's look comes from a Looks scene (graybox now); held, flying and resting are states, not code animation where an AnimationPlayer can do it (Q2213).
- Tests follow the approved behaviour list.

## Answers
- Zoom (G held: the view narrows 75 to 50 degrees over 0.15 s, eased; mouse look slows with it) is ported here, with the held Sock (Q2234, 2026-11-20).
- The behaviour list is approved as written (Q2243, 2026-11-20).
- Carry capacity is a field of the player's tuning, 1 by default; the zoo's player instance overrides it in the
  editor so H06 can be played (Q2244, 2026-11-20).
- Pad buttons as the old game: A picks (left click), B drops and throws (right button), Y is E (interact), X jumps,
  LB/RB the wheel (Q2245, 2026-11-20).
- The held items keep the old layout (active big right of centre, others tucked small left, G brings the active
  one close), taken from the old numbers and compared with the baseline still `held-sock.png` (Q2246, 2026-11-20).

## Open follow-ups

## Built log
