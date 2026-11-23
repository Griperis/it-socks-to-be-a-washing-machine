# The Sock generator

A level's starting Mess, laid from a seed by nodes a level designer places (core/52, Q2518-Q2528; the old
`SockLayout`, behaviour list `docs/migration/m06-lists/05-sock-generator.md`). Read this before you change where
generated Socks land, how the preview draws, or how the start and a regeneration reach the Mess.

## Who owns what (`game/mess/`)

| File | Owns |
|---|---|
| `sock_generator.gd` (`SockGenerator`, `@tool` Node3D) | The level's generator: its areas, exclusions and trails are its children (any depth). `lay(seed, before)` runs one laying; `records(seed, catalogue, before)` turns it into Mess records (Designs, poses, Pairs); the editor preview; `show_preview()` for a shot. Exports: `tuning`, `seed`, `new_seed_each_start`, `collections`, `washer` (the thinning's marker), `scan` (where furniture is looked for: the level, or a station's root) |
| `sock_area.gd` (`SockArea`, `@tool`) | A box (origin at the middle of its bottom face, on the floor it covers; turned about up only): `pairs`, `hidden_share` (0.3), a weight per kind, `heap`, `rules` |
| `sock_area_rules.gd` + `.tres` (`SockAreaRules`) | The exclusion rules as numbers (Q2527): wall and furniture margins, headroom, floor band, the Cabinet's clear box, spacing |
| `sock_exclusion.gd` (`SockExclusion`, `@tool`) | A hand-placed box no Sock may touch (origin at its middle) |
| `sock_trail.gd` (`SockTrail`, `@tool`) | A stair trail: `socks` spread from the node to `to`, across the line (Q2528) |
| `sock_places.gd` (`SockPlaces`) | One area's landing places: open floor cells (a ray per grid cell, then a clearance box for walls and one for furniture), tops (`Spots/Top<n>`), insides (`Inside` and its `shelves_y`), under-gaps (`crawl_gap`, `crawl_box`, in strips along edges that see open floor), the boxes kept out (exclusions, every Cabinet's front) |
| `sock_laying.gd` (`SockLaying`) | One laying: per Sock a place by size x weight (and the washer's thinning), tries a point, rests it by rays (middle and ends) and an overlap test with the house, the kept-out boxes and the Socks laid before; a Heap's roll-down and stacking; the Pairs (`pair_up`, Q2525); the report (`fails`, `left_out`, `hidden_to_floor`) |
| `sock_preview.gd` (`SockPreview`) | The editor's looks: translucent boxes, a trail's line, dots tinted by kind (blue floor, yellow top, green inside, magenta under, orange trail), drawn through the furniture |
| `sock_generator_tuning.gd` + `.tres` (`SockGeneratorTuning`) | The level's numbers: the place box, tries, rest slack, the grid, Mates, Heaps, thinning, strips |
| `generated_socks.gd` (`GeneratedSocks`, the Part, the generator's `Generated` child) | State: `seed`, `first`, `socks` (which Mess records are the generator's). `make()` at the start; `regenerate` (Guest-allowed, rate 2, within `reach`) |

## Flows

- **The start.** `Mess._ready` (before anything binds) reads the SockSpots, then asks every `GeneratedSocks` in
  the group `generated_socks` whose `mess` is it, in tree order: `make()` picks the seed (the generator's, or
  `randi()` with `new_seed_each_start`) and returns the records, which the Mess appends LYING (Q2523: no fall, no
  sound). Every machine does this; a Guest's snapshot then replaces the Mess and the Part whole, so everyone has
  the Host's Socks and seed.
- **A regeneration.** `regenerate` on the Host: the next seed's records, avoiding every other lying Sock; one answer
  carries the Mess's rows patch (`taken_out_patch` of the old records, then `added_lying_patch` of the new) and the
  Part's new `seed`, `first`, `socks`.
- **A Heap's height (core/55, Q2531).** The laying stacks a Heap's Socks on the place box; `records()`,
  once each row's Design is known, brings every stacked row down onto the real leg and foot boxes under it
  (`SockLaying.restack`, `MessBodies.parts_at` its Size), so none hangs. Only height changes, only down:
  the preview's dots of a Heap's stacked Socks may stand up to a few cm over where they lie. A Sock that
  would still hang falls at the next tick (the Mess's `_fall_unsupported`).
- **The preview.** In the editor the generator lays `seed` and draws a dot per row; an area, exclusion or trail
  redraws it when moved or changed (0.2 s later), as does a generator number; furniture is not watched: "Refresh
  preview" on the generator. A game draws it only when a shot calls `show_preview(true, seed, before)`.

## Rules that keep the preview exact

- **One place box.** Every place is fitted for the biggest Sock's box (`tuning.place_box`), so where a Sock lies
  never depends on its Design: the preview (no Designs) and the game (Designs drawn after) lay the same points.
- **Dice per area.** Each area draws from `hash([seed, area name])`, each trail from its name, the Pairs from
  `hash([seed, "mates"])`: a change to one area moves no other area's Socks (a later area only avoids the ones laid
  before it, in tree order).
- **Height in a Heap only.** x, z and the turn of every Sock are exact; a stacked Heap Sock lies at its
  dot's height or lower (above).
- **Same queries.** Every ray and overlap goes through `PhysicsQueries` (also in the editor: the edited scene's
  world); nothing steps physics. The game's laying also avoids the Mess's other lying Socks (`Mess.lying_boxes`);
  the editor knows no Mess, so a SockSpot inside an area shows no gap in the preview.

## Gotchas

- `@tool` scripts here read non-tool code only through static functions and constants (`PhysicsQueries`,
  `MessBodies.boxes_meet`, `Mess.LAYER_HOUSE`, `Mess.pack` in the game) and `is Cabinet`; a Resource they read
  (`SockGeneratorTuning`, `SockAreaRules`) is `@tool` too, or the editor would hand them a placeholder.
- A furniture piece's weight override is its root's metadata `sock_weight` (a float, replacing the kind's weight for
  all its places).
- A hidden Sock whose hidden places are all full goes to open floor (the old rule); the report counts it
  (`hidden_to_floor`). A Sock with no place at all is left out and named in the log (never forced).
- The laying sees only `Mess.LAYER_HOUSE`: a reseed never sees the old Socks (lying bodies are
  `LAYER_LYING`), but it does see a player's body (the player's CharacterBody3D is on layer 1), so a
  reseed keeps clear of where players stand and differs from the preview there.
- The kit's stairs collide as a ramp for the player and the Mess; each stair piece also has a `Treads` body (a thin
  box on every step and landing, layer `SockTrail.LAYER_TREADS`, 128) that only a trail looks at: a trail Sock over a
  tread lies flat on it, its middle on the tread's middle line, its box inside the tread, and its house test leaves
  out the stair's own `Body` (the ramp passes over the tread). With no tread under it, it leans on the ramp (house/05,
  Q2530). A woken or falling Sock still meets the ramp.
- The zoo's station (`game/zoo/stations/sock_generator.tscn`, its button and sign in `game/zoo/sock_generator/`)
  sets `scan` to its root; a level sets it to the level. The house (house/05) has one generator per floor under `SockGenerators`, each
  its floor's two Cabinets' Collections and one `Floor` area (the old stage's Pairs, Heaps on), the stair trails
  under the floor they start from; the whole house lays in one start-up frame (about 1.7 s for 990 Socks, headless).
