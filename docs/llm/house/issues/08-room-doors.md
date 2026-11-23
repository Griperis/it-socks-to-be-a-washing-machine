---
type: ticket
status: needs-info
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done:
blocked_by: [house/05-mess-in-the-house]
notes: ["Q2532; M3"]
terms: [Mess, Sock, Host, Guest, Part]
---

# The room Doors in the house

M3 plays the core loop in the house "with Doors and Drawers"; the house has open doorways and no room Doors (Q2532).

## Step 1: the behaviour list (stop for the designer's approval)
Port by examination: `reference/it-socks/game/house/doors.gd`, `door_rules.gd`, the Door entity and its Looks, the old
sounds and tuning (grep; never commit in reference/). Write `docs/migration/m06-lists/06-room-doors.md` in the shape of
lists 03-05: which doorways have Doors, how a Door is aimed, opened and shut (prompt, click, E), the swing (times,
eases, the hinge), pushing Socks and players, being blocked, sounds, locked Doors (Stages, M4: listed as "needs ..."),
the shut share at a New Game (Q2528), co-op (the Host's sweep, a Guest's view and ghost, a late joiner), every motion
and sound (Q2277). Mark open choices as questions. Stop and report.

## Step 2: build (after approval)
- The Door as an entity: behaviour (an Openable Part, Q2251) plus a swappable Looks scene, with the furniture's opening
  sounds rule (assets/07); placed in `game/house/house.tscn` in the old doorways; a zoo station first.
- Doors push Socks through the Mess's usual sweep; seen by Guests (the backlog line "Doors and drawers sweep on the
  Host only" is answered here).
- About a third shut at a New Game (Q2528), from the level's seed, with the generator (core/52).

## Acceptance
- Real path: in the house, aim at a Door, click: it swings open with its sound and pushes a Sock in its way; a Guest
  sees the swing and the Sock move; a late joiner sees the Door as it stands.
- Strip for the designer: a Door shut, mid-swing and open, and the station (`builds/review-house-08/`).

## Open follow-ups
- [blocking] Step 1's questions Q1-Q7 at the end of `docs/migration/m06-lists/06-room-doors.md` wait for the designer (ground floor doorways, sweep only or the old push too, the laundry-garage Doors open, shut at the start silent, the leaf's Looks, the leaf's size, old details).

## Built log
- 2026-11-23: Step 1 only. Changed: wrote the behaviour list (54 rows, 7 questions with recommendations). Files: `docs/migration/m06-lists/06-room-doors.md`, this ticket. Verified: docs only, no suite run.
