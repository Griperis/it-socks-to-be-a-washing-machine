---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: ["[[04-one-cabinet]]"]
notes: []
terms: []
---

# One Mess and one Hands for the zoo

Milestone M0.5. core/04 gave the Cabinet station its own `Socks` (Mess, Hands, Coins) beside the handling
station's, and the player uses the Hands of whichever station it stands in (`game/player/player.gd:111-134`). So a
Pair made at the handling station is gone from the Hands when the player walks to the Cabinet. The designer wants one
Mess and one Hands for the whole zoo (Q2284), as the house will have one per level (M2).

## Behaviour list
From Q2284; no line of an approved list changes.
- Z01 When you hold Socks or Pairs at one station and walk to another, then they are still in your Hands: a Pair made
  at the handling station is shelved at the Cabinet by a click or a Throw.
- Z02 The zoo has one Mess, one Hands and one Coins; every station's Socks are records of that one Mess, lying where
  the station places them.
- Z03 A station still runs alone (the wiring check, `zoo:alone`, each station's own real-path case): instanced
  without the zoo, it plays as it does today.
- Z04 A Sock thrown out of bounds comes back to a return spot (core/08) in the zoo's Mess as before.

## Design
Drafted by the agent (core/10), then built.
- **Who owns `Socks`.** `zoo.tscn` gets the level's `Socks` (one `Mess`, one `Hands`, one `Coins`) with its own
  `Spots` (empty), `Lying`, `Flights`, `FlightSpawner` and `ReturnSpot`; its Mess's bounds are the zoo's floor
  (40 x 40 m, 6 m high). Every station scene keeps its own `Socks` unchanged, so a station alone (the wiring check,
  `zoo:alone`, its own suite) plays as today (Z03).
- **How a station joins.** `ZooStations` gets `@export var socks: Node` (the zoo's). In `_enter_tree`, before a
  station is added (so before any `_ready` and before Parts binds), `_join_socks()`: the station's Mess hands its
  `spots` node to the zoo's Mess (`Mess.more_spots`, read after `spots` in `_ready`), every stored link of a station
  node to a node of its own `Socks` (the Cabinet's `hands` and `coins`) is set to the node at the same path under
  the zoo's `Socks`, and the station's `Socks` is freed. With `socks` empty a station keeps its own. The station's
  `Lying`, `Flights`, `FlightSpawner` and `ReturnSpot` stay, empty and unused.
- **Sock ids.** The zoo's records are its own SockSpots (none), then each station's in file-name order, each in its
  `Spots` order: the same on every machine. A SockSpot keeps the id it became (`SockSpot.sock`), so tests and shot
  hooks find a station's Sock without counting.
- **The player.** `Player.hands()` no longer looks for the Hands whose Mess's bounds it stands in: it takes the
  level's one Hands (the first of the group, one of its own scene first when several levels share the tree, as two
  zoos in the co-op test do). `_stands_in()` goes.
- **Part ids and PROTOCOL.** The Socks' ids become `Socks/Mess`, `Socks/Hands`, `Socks/Coins` (were
  `Stations/<Station>/Socks/...`) and flights spawn under the zoo's `Flights`: `Session.PROTOCOL` 4 -> 5.

## Acceptance
- One test per behaviour line; the real-path case: in the zoo scene, the player pairs two Socks at the handling
  station, walks to the Cabinet station and shelves the Pair by a click.
- The touched suites pass (handling, throw, pairing, cabinet, zoo, player).

## Answers
- One Mess and one Hands for the zoo (Q2284, 2026-11-20).
- Merged as built (Q2289, 2026-11-20).
- Designs may repeat across stations in the zoo; the zoo gets a station showing every Sock of the game laid out on
  the ground, at the end (Q2290, 2026-11-20; its own ticket).
- The return scatter and pop, and a sunk Sock pushed back up, wait for the polish pass (Q2291, 2026-11-20).

## Open follow-ups
- [closed 2026-11-21] The zoo's return spot stands at (1.5, 0, 2.5), beside the spawn (placed by the agent). — stations and spots are placed by hand in the editor (Q2359); the designer moves it there
- [moved 2026-11-21] `docs/architecture.md` (the zoo paragraph) could say the zoo owns the one Mess, Hands and Coins. — to docs/migration/m06-backlog.md

## Built log
- Model: Opus (lead): it moves ownership of the Mess and Hands across scenes, Part ids and every station's suite.
- 2026-11-20. Changed: the zoo owns the level's `Socks` (one Mess, Hands, Coins, its own Lying, Flights,
  FlightSpawner, ReturnSpot); `ZooStations._join_socks()` hands each station's SockSpots to the zoo's Mess
  (`Mess.more_spots`), relinks the station's links to its own Socks (the Cabinet's) to the zoo's and drops the
  station's Socks; a station alone keeps its own. `SockSpot.sock` keeps the id a spot became. `Player.hands()` takes
  the level's one Hands (its own scene's first). `Session.PROTOCOL` 5. Shot hooks find the handling Socks by spot.
  Files: game/zoo/zoo.tscn, game/zoo/stations.gd, game/mess/mess.gd, game/mess/sock_spot.gd, game/player/player.gd,
  game/parts/session.gd, tools/shot_hooks.gd, tests/zoo_test.gd. Verified: PASS 873 checks, 126 cases
  (`run.sh --touched`: cabinet, handling, pairing, player, runner, scene_parts, throw, wiring, zoo).
- Merged: 1aba3aac (2026-11-20, branch core/10-one-mess-for-the-zoo)
