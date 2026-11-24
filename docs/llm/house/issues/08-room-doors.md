---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done: 2026-11-24
blocked_by: []
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
- [later] A Sock may be laid where an open Door's leaf stands against the wall (the laying sees the leaf at its state's pose but has no clearance rule for it); not seen in the stills; a `SockExclusion` per Door would remove it.
- [later] The leaf has no bevel (the old leaf's 4 mm one); the garage door has no track and spring gear (the exterior ticket).

## Answers (step 2)
- Q2595 the Door's sound plays 1 m up, as in the old game (designer, 2026-11-24, after the strips). The other two later details (a Sock laid behind an open leaf, the leaf's bevel) stay [later]; the designer has seen them.

## Answers (step 1)
- Q2568 no Doors in the 2 open ground-floor doorways; Q2569 the physics sweep only; Q2570 the start-shut Doors already
  shut and silent; Q2571 the real leaf now, ported from `make_house.py`'s Door_<doorway> geometry as a Looks scene
  (the front and garage doors' leaves match it). Kept as the old (lead, from the list): LaundryLobby and LobbyGarage
  always open; the quiet walk-through and the nudge of a standing player; the Cat opening Doors waits for the Cat.
  Leaf size from the kit's real openings. Build step 2 to the end; strip to builds/review-house-08/ for the
  designer's review before the merge.

## Built log
- 2026-11-23: Step 1 only. Changed: wrote the behaviour list (54 rows, 7 questions with recommendations). Files: `docs/migration/m06-lists/06-room-doors.md`, this ticket. Verified: docs only, no suite run.
- 2026-11-24: Step 2. Changed: the eight room Doors in the old doorways (`Doors/<Doorway>` in `house.tscn`, none in the ground floor's two, Q2568); the Door entity with the real leaf (`room_door.tscn` and `room_door_flipped.tscn`, the two hands, Looks `looks_leaf*.tscn`, made by `tools/door_build.gd` from make_house.py's Door_<doorway> geometry and make_flat.py's materials; `door.tscn` keeps its graybox for the zoo's other stations); the front and garage leaves in the same materials; `DoorShuts` and `door_shut_rules.tres` (3 of 8 start shut from the seed, never LaundryLobby or LobbyGarage, silent; it poses every leaf before anything is laid, so the laying reads the same physics world whenever it runs); the zoo's Doors station (`game/zoo/stations/doors.tscn`, at 40, 0, 6); the sweep and a Guest's view are the existing Openable ones (coop/08); muffling lists the new scenes; shot actions `doors`, `door_house`, `door_use` and the set `house-08-doors`; `tests/saves/house_ids.txt` gains the eight Doors' ids. Files: see the commit. Verified: `kit/tools/run.sh --touched` (the commit's verdict lines); stills in `builds/review-house-08/` (`strip-station.png`: a Door shut, three frames of the swing, open, both hands; `strip-house.png`).
- 2026-11-24: Q2595. Changed: `Openable.sound_height` (default 0, so every other Openable sounds where it did); the two room Door scenes set it to 1 m; the real-path case checks the sound's place. Files: `game/parts/openable.gd`, `game/entities/door/room_door.tscn`, `room_door_flipped.tscn`, `tests/room_doors_test.gd`. Verified: the commit's verdict lines.
