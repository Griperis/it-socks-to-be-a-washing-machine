---
type: ticket
status: done
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[154-batch-c-groundwork]]", "[[130-personal-upgrades]]", "[[139-encyclopedia-book]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 2", "suggested model: opus"]
terms: [Radio, Carrying the Radio, Throw, Hand-off, Teammate, Hands]
suites: [carry, coop_carry, throw, knockdown, coop_knockdown, hand_off, coop_hand_off, handling, save, zoo]
---

# The Radio carried and thrown; the thrown-knock rule

The Radio is a carried thing, and with it come the two shared pieces every thrown carried device of batch C uses: the
Throw of a `Carriable` and its knock (Q2700), and the held thing's input. Build `docs/architecture/devices.md` "The
thrown-knock rule" and "The held thing's input", `tv-and-radio.md` "The Radio as a carried thing", draft 150-A:

- on `Carriable`: `throwable`, `radius`, the verbs `throw {from, vel, charge}` (the carrier's, the Hands' charge time
  and Throw speed read through `Upgrades.value`, core/130), `land {at, yaw}` and `bounce {from, vel}` (Host only),
  `flight` in its State (`from`, `vel`, `t0`, `by`, `charge`; so a late joiner and a save see it mid-air), the Host's
  sweep against the house, the lost-thing return lying in front of the washer, and the pick's Mess `fall` of what
  rested on it;
- `Knockdowns`' hit test reads `Carriable.FLYING` beside `Mess.throws`: full charge knocks down and bounces off (a new
  arc in the same answer); below full charge it bounces off to their feet, never caught; the thrower, a player down or
  in the drum are not hit (the rider exemption is core/157's);
- the thrower's Throw looks-first (a ghost eased onto the answer's arc, `GhostTuning`); the rumbles `throw` and
  `knock`;
- the held thing's input in `player.gd`: while the Hands hold a carried thing or a taker, `pick`, `drop_throw` (with
  its held time), `interact` and `hands_next` / `hands_prev` go first to its `held_input(by, action, pressed,
  held_seconds) -> bool`; core/139's "E reads the active book" folded in;
- `radio.tscn` (graybox Looks at 1.5 its size, `Carriable` `throwable` and `handable`, `hold_slot_radio.tres`; silent
  until core/164), `radio_land` on landing (its SoundEvent is core/154's);
- the Radio in the TV and Radio station (shell from core/154 at x = 264).

Behaviour lines (`docs/migration/m4-lists/13-tv-and-radio.md`): R20, R23, R24, R25, R26, R27, R28, R29 (carrier,
spot, turn, flight); R1's scale; R2's "Radio"; the words "Radio", "Hands full". `09-vacuums-and-detector.md` V41's rule
(the detector uses it in core/167).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The Carriable's exports and the hold slot in the inspector; graybox Looks, then assets/28. The arc and its speeds are the
Hands' existing numbers (`KnockdownTuning.min_charge` for full charge). No code motion: the flight is the scripted arc
every machine replays.

## Acceptance
- Real path: in the TV and Radio station the player left-clicks the lying Radio (two Socks lying on it fall), holds the
  right button and releases at full charge toward the floor; it flies, lands with `radio_land` and lies there.
- Co-op: a full-charge Throw at a Teammate knocks them down and bounces off; a weak one drops at their feet, never
  caught; an aimed right tap hands it into their empty Hands, or at their feet with "Hands full"; a leaver drops it at
  their feet; a late joiner sees it mid-air.
- With anything in the Hands (the book included) the pick reads "Hands full".
- Thrown off the level (a house case), it comes back lying in front of the washer.
- Saved and joined (carrier, spot, turn, flight); a Guest's carried Radio is saved lying where they stood.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A thrown detector, Radio or Cat that hits a Teammate: a full-charge Throw knocks down, a weaker one bounces off to
  their feet, never caught; an Elevator rider is never hit (Q2700, 2026-11-26).
- The TV and the Radio as the old; Socks on a picked-up Radio fall (Q2704, 2026-11-26).

## Open follow-ups
