---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[169-vacuum-suck]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 6", "suggested model: opus"]
terms: [Spit, Pour, Sock vacuum, Tank, Mess]
suites: [vacuum, coop_flight, mess, throw, zoo]
---

# The Sock vacuum's Spit and Pour

The Tank's Socks come out again: holding the right button with the nozzle spits them, oldest first, one every 0.1 s,
landing scattered round the aim; the container's carrier holding E tips it and the Socks fall over its lip one by one.
Build `docs/architecture/devices.md` "`Vacuum`" (`spit`, `pour`), draft 150-H:

- `spit {from, vel}` from the holder's right hold past `spit_tap` 0.25 s (a tap still drops or hangs), oldest first,
  ignoring the Filter, with a scatter, starting on the room's side of a wall, as released bodies (`Mess.thrown_patch`
  with `drop`: never a Throw, no catch, no knock; build what the old did, VA:353-377), the stream waiting while 24
  released bodies fly (`spit_bodies`);
- `pour {on}`: the Host's timer lets one Sock fall over the front lip every `pour_every` 0.15 s at `pour_speed` until
  released, let go or empty; the container's `pour` clip (about 70 degrees forward over 0.25 s); a Teammate's suction
  refused "tilted" while it tips;
- `vacuum_spit_tick` at the nozzle's mouth (the SoundEvent's own 0.09 s gap); no pour sound (Q2698);
- the words "Hold: Spit out", "Hold: Pour out", "Put down".

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V10, V11, V18; V8's "tilted"; V30's spit tick.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`VacuumTuning`'s spit and pour numbers (`spit_every` 0.1 s set by Q2698 as a placeholder); `pour` is a clip in the Looks.

## Acceptance
- Real path: in the vacuums station with 10 Socks in the Tank, the holder holds the right button aimed at the floor 3 m
  away; Socks leave the nozzle one every 0.1 s and land round the aim; the release drops nothing more.
- The container's carrier (nozzle hung) holds E: it tips, one Sock falls over the lip every 0.15 s until released; a
  Teammate's suction pauses while it is tilted (co-op).
- With 24 released bodies in the air the stream waits; a spat Sock never knocks a Teammate down.
- Placeholders: the spit and pour numbers.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Spit 0.1 s a Sock (placeholder); no pour sound (Q2698, 2026-11-26).

## Open follow-ups
