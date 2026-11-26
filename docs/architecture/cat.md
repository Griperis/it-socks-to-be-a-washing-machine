# The Cat and the litterbox

**Status: build plan for batch C (designed in core/151 on the designer's answers Q2699, Q2700, Q2703, Q2705;
2026-11-26). Not filed yet: the drafts below are for the lead to file.** Behaviour list:
`docs/migration/m4-lists/12-cat-and-litterbox.md` (40 lines). Batch C is built unattended and reviewed in play as a
whole, as batches A and B were (Q2603-Q2605). An open choice an agent meets in the build takes the old game's answer
and goes on the batch's review sheet.

## What it owns

The house's Cat as decided state: where it is and what it does (couch, roam, rest, nap, walk), its navigation and gait,
its head turn and meows, the pet and the purr, being picked up, held, set down and thrown (the Cat's side: core/150
owns the whole-Hands and thrown-knock rules), the swat, the fetch, its watchdog, its coat; the litterbox visit (the
litterbox itself is built: assets/07, Q2600); the Cat's naps in the Elevator's car (the Cat's side: core/149 owns the
car and the one carry rule); the Cat's drum cycle and coat change (Q2703: now, an exception to Q2699); the Cat's model
and clips (Q2705); what a World keeps of all of it.

It does not own the Hands, the Throw, its flight or the knock (core/150's rules for every thing that takes the whole
Hands, built on the Hands and `Knockdowns`), the Elevator, its verbs and its carry rule (core/149), the washer, its door
and the knockdown wash (batch A, built: this piece adds one load to its `WasherWash`), the floor locks (core/80, built:
it reads them), the Sock generator's `Inside` spots (they lay the litterbox's Socks, Q2600), or the Secrets that hang on
the Cat (Cat on the Piano, Radio Dance, Clock Stare, Fur Fetch, Cat Cradle: later, Q2682). Where they meet it, it names
the seam.

## The shape

The old Cat was one 2057-line class that the others reached into (`game.cat.wake_in_car()`, `fills_car()`). Here the
Cat is one entity with one Part for its body, and **each place the Cat uses offers itself** (a nap spot, the litterbox,
the car, the drum) through one small group contract, so a new place is a node or a Part on that place's scene, never a
branch in the Cat.

- **`game/entities/cat/cat.tscn`**, root `Cat` (a Node3D the Part moves; no physics body: it walks a planned path and
  walks through players, Q1902):
  - **`Cat`** (`game/entities/cat/cat.gd`, a Part, on the root): the body's decided state, the Host's brain (timers,
    choices, the walks it plans) and every verb. Saved and joined by its State group.
  - `Aim` (an Area3D on the crosshair's layer, a sphere of `CatTuning.reach` 0.22 m round its middle): what the crosshair
    and the outline see; it never blocks a player, a Sock or a Throw.
  - `Looks`: `looks_graybox.tscn` now, `looks_cat.tscn` once the asset ticket lands (the swap is the one line in
    `cat.tscn`).
  - `Gait` (`cat_gait.gd`, `CatGait`, a plain node, looks only): turns the decided walk (path, start, run) into the
    pose of this frame on every machine, the same on each (a pure function of the path and the time since the walk's
    answer was applied).
  - `Nav` (`cat_nav.gd`, `CatNav`, a plain node, Host only): the navigation maps and the route queries (below).
  - Children that later drafts add: `Hold` (the whole-Hands member, 151-B, by core/150's rule), `CarNap` (151-E).
- **`CatTuning`** (`game/entities/cat/cat_tuning.gd`, `cat_tuning.tres`): every number of the old `data/tuning/cat.json`
  (below), all `# placeholder:` as the old but the two Q1946 set (`fetch_chance` 0.6, `fetch_cooldown` 45 s).
- **`CatCoat`** (`game/entities/cat/cat_coat.gd`; `game/entities/cat/coats/<nn>_<name>.tres`): one coat.
- **Places** (the group `cat_places`, below): `LitterVisit` on the litterbox (151-D), `CarNap` on the Cat (151-E), the
  washer's `WasherWash` (151-F). Nap spots are plain `Marker3D`s in the group `cat_nap`.

### The kinds of state (`coop-structure-for-the-port.md`)

| What | Kind | Where |
|---|---|---|
| where the Cat is, its mode, its walk (path, run, what comes after), its timers, its coat, what is in its mouth, its errand | decided state | the `Cat` Part |
| who holds the Cat | decided state | the whole-Hands member (`Hold`, core/150's rule) |
| a thrown Cat in the air | core/150's thrown-item flight (the coop doc's "scripted-arc items: the Command answer only; each machine replays the arc") | core/150 |
| the Socks it carries, swats, fetches or hides | the Mess | moved by the Mess's own patches in the Cat's answers |
| the litterbox's flap, the car's hatch | decided state | their `Openable`s, patched in the Cat's answers (the flap) or asked of the Elevator (the hatch, `open_hatch`) |
| the Cat in the car | decided state | the `Cat` Part's `place` (no field on the Elevator: it reads `fills_car()`) |
| the Cat in the drum | decided state | the `Cat` Part (`mode` DRUM) and the washer's `WasherWash` load, one answer |
| the walk's pose this frame, the head turn, the clips, the hearts, the coat's colour | looks | `Gait` and the Looks, from applied answers |

### `Cat`'s state

All the Cat's fields are in 151-A, so the Cat's entry in `tests/saves/shape.json` changes once (151-F adds only the wash's two load fields).

| Field | Meaning |
|---|---|
| `mode: int` | `COUCH` (sits on the ground floor's couch until the ground floor opens), `STAND`, `SIT`, `NAP`, `WALK`, `HELD`, `FLYING`, `SWAT`, `BOXED` (in the litterbox), `DRUM`, `DIZZY` |
| `at: Vector3`, `yaw: float` | where it stands and faces (a walk's start while it walks) |
| `path: PackedVector3Array`, `run: bool` | the walk the Host planned (empty: none); a run is a run-off (`run_speed`, `run_accel`) |
| `then: int`, `rest: float` | what it does at the walk's end (STAND, SIT, NAP, SWAT, BOXED) and for how long (s) |
| `walked: float` | metres of `path` already done as of the answer; `save_state()` gives the live value, so a load or a join resumes the walk where it got |
| `left: float` | seconds left of the timed mode (a rest, a nap, a swat, a scratch, a hold, the dizzy spell, the car's shut nap) as of the answer; live in a save |
| `purr_left: float` | seconds of purr left (over any mode) |
| `place: NodePath` | the place it is in, when one holds it (the car's `CarNap`, the litterbox's `LitterVisit`, the washer's `WasherWash`); empty on the floor |
| `coat: StringName` | its coat's id (the `CatCoat` file's stem without its number); a New Game's is `black` |
| `mouth: PackedInt32Array` | Mess ids it carries: one Sock across its jaws (a litter visit), or the two Socks of a fetched Pair (drawn as a sock ball) |
| `errand: Dictionary` | the Host's errand under way: `{kind: "fetch", for: player id, socks, phase}`, `{kind: "litter", place, sock, phase}`, `{kind: "swat", sock, to}`; `{}` none |
| `due: Dictionary` | seconds left until the next meow, swat, litter visit and fetch-ready (the cooldown), live in a save |

Host-only timers fire Host-only verbs; nothing on a Guest decides. A Guest's machine walks a walk from when its answer
is applied, so it is half a round trip behind the Host, as the old.

### Its verbs (`Parts.ask`, decided on the Host)

| Verb | Who | What it decides |
|---|---|---|
| `pet` | a player aiming at it with E (151-B) | refused (silently: no prompt shows then) when it is HELD, FLYING, BOXED, in the DRUM, or in a shut or riding car; else it stops where it is (the walk cut at its drawn point), `purr_left` = `purr_seconds`; with `fetch_chance` and `due.fetch` run out, the errand `fetch` for the petter (151-C) |
| `rest_over`, `walk`, `meow` | Host only, its own timers (151-A) | the next walk (a roam to a spot 1.5 to 7 m off on its map, or to a nap spot, chance 0.3, a sit 0.25, else a stand), a meow (not while it naps, and not in the DRUM) |
| `free` | Host only, `hold_seconds` after a pick (151-B) | it wriggles free: the holder's Hands empty (core/150's patch), it jumps down `free_ahead` 0.5 m in front of them and runs `run_from` 2 m off |
| `landed` | Host only, the thrown-item flight's landing (151-B; core/150's call) | on its four paws where it came down (a place's `takes_cat` first: the open car keeps it), then a run-off |
| `swat`, `knock` | Host only (151-C) | the swat starts (it faces the item, SWAT for `swat_seconds`); at `swat_contact` of it, `knock`: the Mess's patch flings the item 0.5 to 1 m |
| `fetch_step` | Host only (151-C) | the fetch's next phase: walk to the Socks, take (Mess held, `mouth`), carry, set the Pair down |
| `put` | Host only, the watchdog (151-A) | stood back on the nearest spot it can walk from |
| `wake` | Host only, the car's arrival or a call where it lies (151-E) | it wakes in the car (then hops out at an open hatch) |

`accepts()`: `pet` `{}` at 4 a second; the Host-only verbs are not accepted from a Guest. A pick, a set-down and a Throw
are the whole-Hands member's verbs (core/150's rule), not the Cat's.

### Signals (every machine, from applied answers): the seams

| Signal | Who plugs in |
|---|---|
| `moved()` | the Looks (the clip of the new mode, the cross-fade), `Gait` (a new walk) |
| `petted(by)` | the Looks' hearts, the purr sound; the Secrets later (Cat Cradle) |
| `meowed()` | the meow sound at the Cat |
| `landed_at(at)` | `cat_land`; the Secrets later (Cat on the Piano, Fur Fetch) |
| `swatted(sock)` | `cat_swat` at the paw's contact |
| `took(socks)`, `brought(at)` | `pop` at the Socks; the meow at the Pair |
| `coat_changed(coat)` | the Looks' fur |

## Navigation and the gait (151-A; Q1901, Q1902)

Godot's own navigation does the work the old did with layout data and per-room bakes in code (weak point 2):

- **One `NavigationRegion3D` per floor**, under the Cat's `Nav` in the level, its mesh baked at the level's load on
  the Host from the house's static colliders (walls, floors, furniture, the stair ramps), with the Cat's size (agent
  radius 0.12 m, height 0.3 m, climb 0.05 m, cell 0.05 m), so it walks under furniture it fits under. A flight of
  stairs belongs to the floor it leads up to. Each floor's region has its own navigation layer bit; a route query asks
  only the bits of the open floors (`Stages.floor_open(floor)`; a level with no `Stages` has every floor open). Only
  the Host bakes and plans (Guests walk the path the answer carries).
- **The static part is parsed once** (`NavigationServer3D.parse_source_geometry_data` at load, kept); **what moves is
  added as projected obstructions** at each bake: every Heap higher than `heap_over` 0.12 m (from
  `Mess.lying_boxes()`) and every open Door leaf. A floor is baked again, off the main thread
  (`bake_from_source_geometry_data_async`), when the Host is about to plan a walk on it and its Heaps or leaves changed
  since its last bake; the Cat stands meanwhile. (The old baked per room and could hitch 5 to 70 ms; the async bake
  must not cost the main thread more than 2 ms: 151-A measures it.)
- **Doors**: the bake cuts each doorway (the Door scene's leaf and a `NavigationObstacle3D` with
  `affect_navigation_mesh` across its gap); a `NavigationLink3D` in each Door scene joins the two sides, `enabled`
  while the Door is open. A Door shut across a walk under way (the Openable's `shown`) makes the Host plan the walk
  again (CN, CAT:1293-1300). A locked Door is a shut one.
- **The walk** (`CatGait`, the old `cat_gait.gd`): a smooth curve with corners rounded within `corner` 0.35 m, easing
  up from a standstill (`accel` 1.2 m/s2, a run `run_accel` 4.0), slowing before it stops (`decel` 1.5), turning on the
  spot before it sets off and slowing through bends at `turn_rate` 150 degrees a second; at `speed` 0.55 m/s (a run
  `run_speed` 1.6). One stride is 0.32 m: the walk and run clips play at the speed that fits it (the AnimationTree's
  time scale, the number in the clip, not code).
- **Nap spots**: every `Marker3D` in the group `cat_nap` in the level (the middle of the sofa's, the double bed's, the
  bunk bed's and the old cot's tops, placed in those furniture scenes; the floor just inside each low window, placed in
  `house.tscn`), plus any place whose `nap_spot()` offers one now (the open car, 151-E), each at the same weight.
  A nap spot it cannot reach on its map is skipped.

## Places: the one group contract

Every node in the group `cat_places` may have these methods (read with `has_method`); the Cat names no kind of place:

| Method | Asked when | Members |
|---|---|---|
| `nap_spot(cat) -> Variant` | the Host chooses a nap spot: a `Transform3D` to nap at, or null | `CarNap` (the car open, nobody riding, Q1982) |
| `holds_cat(cat) -> bool` | the watchdog: the Cat stands off every map but this place vouches for it | `LitterVisit` (BOXED), `CarNap` (in the car), `WasherWash` (the DRUM) |
| `takes_cat(cat, at: Vector3, aimed: Node, thrown: bool, onto: Dictionary) -> Dictionary` | a set-down, a wriggle free or a landing at `at` (aimed at `aimed`): a patch when this place takes it, else `{}` | `CarNap` (lands inside the open car and stays, Q2005), `WasherWash` (set down by the washer's door, aimed at the washer: the drum cycle, Q2703) |

## How it is authored (Q2607)

- **Typed Resources edited in the inspector** (every number `# placeholder:` the old unless a Q set it):
  - `CatTuning` (`game/entities/cat/cat_tuning.tres`): `speed` 0.55, `run_speed` 1.6, `stand_min`/`max` 1/4 s,
    `sit_min`/`max` 4/10 s, `nap_min`/`max` 20/45 s, `nap_share` 0.3, `sit_share` 0.25, `walk_min`/`max` 1.5/7 m,
    `meow_min`/`max` 12/30 s, `purr_seconds` 2.5, `hold_seconds` 3, `free_ahead` 0.5 m, `run_from` 2 m, `reach` 0.22
    m, `swat_min`/`max` 60/120 s, `swat_reach` 0.55 m, `swat_up` 0.45 m, `swat_seconds` 1, `swat_contact` 0.45,
    `knock_min`/`max` 0.5/1 m, `dizzy_seconds` 2.5, `fetch_chance` 0.6 and `fetch_cooldown` 45 s (set, Q1946),
    `fetch_pause` 0.4 s, `fetch_take_reach` 1.7 m, `fetch_drop_reach` 1.2 m, `fetch_redirect` 1.2 m, `accel` 1.2,
    `run_accel` 4, `decel` 1.5, `turn_rate` 150, `corner` 0.35 m, `heap_over` 0.12 m, `head_radius` 2.5 m,
    `head_angle` 100, `head_turn` 200, `head_height` 1.1 m, `head_max` 70, `park_seconds` 90, `litter_every` 240 s,
    `litter_jitter` 45 s, `litter_seconds` 6 (Q2703 keeps 240 +- 45, 6, 1 in 3 as placeholders), `litter_retry` 15
    s, `litter_hide_chance` 0.33, `litter_sock_reach` 5 m, `litter_take_reach` 0.6 m, `car_shut_seconds` 20.
    The Host reads it when it decides, never caches it at ready.
  - `WasherTuning` (151-F adds two fields): `cat_seconds` 4, `cat_spin` 0.45 (the old `wash.json`).
  - **The motion's numbers are the clips' keys, not code (Q2697):** the held Cat's 55-degree tip and wriggle, the
    dizzy stagger (sway 0.22 rad at 3.2 a second, the feet wandering 0.05 m, the head circling, the eyes half shut),
    the nap's breathing and shut eyes, the tail's swish, the hop into the car, the swat's paw. The cross-fade (0.4 s,
    Q1173) is the AnimationTree's. The head turn follows a live target, so it is a `LookAtModifier3D` on the neck and
    one on the head (the neck taking 0.4 of the turn by its influence), limited to `head_max`, set in the inspector.
- **`CatCoat`** (Resource): `title`, `fur: Color`, `rim: float` (the soft rim on the dark coats), `patches: bool`
  with `patch_colours: PackedColorArray` (calico: ginger, then black, over white; the belly and legs stay white),
  `whiskers: Color` (dark on the light coats, Q1143). The five old coats as `01_black.tres` .. `05_calico.tres` with the
  old colours (Q2705: the old colours): black (0.06, 0.055, 0.075) rim 0.45; grey (0.3, 0.3, 0.32) rim 0.25; ginger
  (0.78, 0.4, 0.13); white (0.88, 0.87, 0.84); calico white with patches (0.8, 0.42, 0.13) and (0.07, 0.065, 0.08); dark
  whiskers (0.22, 0.22, 0.24) on ginger, white and calico.
  **A designer adds a coat by dropping a `.tres` into `game/entities/cat/coats/`**: the wash cycles through the folder
  in file-name order (`ResourceLoader.list_directory()`, so an export lists it too) and back to the first; the zoo's
  board shows it. No code.
- **Added by dropping a node, no code:** a nap spot is a `Marker3D` in the group `cat_nap` (placed in a furniture scene,
  every copy has it); a litterbox is a `litterbox.tscn` (its `LitterVisit` comes with it); a place the Cat uses is a
  Part in `cat_places`; a sound is a clip added to its SoundEvent on the Sounds bench.
- **The zoo station** `game/zoo/stations/cat.tscn` (its own things under `game/zoo/cat/`), built from the data at load
  (Q2337): two graybox rooms (house kit pieces) joined by a real Door and a short stair to a raised landing, a sofa and
  a bed (their nap markers), a low-window nap marker, the real litterbox, the real washer (`washer.tscn`), a
  `SockGenerator` area, the real `cat.tscn` with the station's own `CatTuning` copy (`game/zoo/cat/cat_tuning_zoo.tres`:
  short timers, `fetch_chance` 1, `litter_every` 30 s, `swat_min`/`max` 10/20 s); a board listing every coat in the
  folder (a swatch and its name), the nap spots found, the Cat's SoundEvents and the tuning's numbers. 151-E adds the
  real Elevator (two stops). Only the drafts that say so edit the station's scene; the later drafts need no switch (the
  zoo tuning's short timers bring the swat, the fetch and the visit; the drum needs only the washer).
- **Authored in nodes (Q2658):** the Cat, its `Aim`, the hearts (a `GPUParticles3D` `Hearts` in the Looks: little pink
  hearts, (1, 0.42, 0.62), floating up and fading, emitting for `purr_seconds`), the mouth (`Mouth`, a
  `BoneAttachment3D` on the head bone: the Sock across its jaws; `Carry`, a `Marker3D` 0.2 m up and 0.2 m ahead: the
  sock ball), the prompts through the existing crosshair rows. No Control, mesh, material or particle built in code;
  the Sock and the sock ball it carries are the Mess's own Looks scenes for that Design (`looks_of`, as the Hands
  show them).
- **Motion is clips in Looks (Q2697):** the contract (`game/entities/cat/looks_contract.json`) names a `Skeleton3D`
  (the old 16-bone rig's bones, `neck` and `head` among them), the `eyes_closed` shape key, the nodes `Hearts`,
  `Mouth`, `Carry`, `Fur` (the fur's mesh, its material the coat's), and an `AnimationPlayer` with `stand` (the tail's
  swish), `sit`, `curl` (eyes shut, breathing), `fall` (paws out: the throw, the hop into the car), `held` (tipped up
  55 degrees under its front legs, wriggling), `walk`, `run`, `swat`, `dizzy`, `scratch` (Q2703: its own clip); the
  loops `stand`, `sit`, `curl`, `held`, `walk`, `run`, `dizzy`, `scratch`. The root script `CatLooks` has `play(mode)`,
  `coat` (a `CatCoat`), `carry(designs)`, `hearts(seconds)`, and the head's target. `looks_graybox.tscn` (a black
  rounded box body, a sphere head, ears, a tail on a hand-made skeleton with the contract's bones, each clip simple hand
  keys; `scratch` keyed as a placeholder copy of `swat` until the asset clip) and `looks_cat.tscn` (the asset ticket)
  both meet it.

## The pieces

### Couch, roaming and resting (151-A)
A New Game places the Cat on the ground floor's couch (`CatStart`, a Marker3D on the living room's sofa in
`house.tscn`): `COUCH`, sitting, until `Stages.floor_opened` names the ground floor (or a load finds it open); then
it roams (cat/02, Q2703). It walks its map's open floors, never through a shut or locked Door, never onto a locked floor,
never into the Elevator's shaft by walking: a walk of 1.5 to 7 m, then a stand (1 to 4 s), a sit (4 to 10 s, chance
0.25) or a nap at a nap spot (20 to 45 s, chance 0.3). It walks through players and over small Socks (no avoidance,
Q1902). Awake (not napping, held, flying, boxed or in the drum), its head turns toward the nearest player's head
(`head_height` over their feet) or moving Sock within `head_radius` and `head_angle` either side of its nose (each
machine's own looks); it meows every 12 to 30 s ("cat_meow" at it, the Host's `meow`). Each mode plays its clip,
cross-fading 0.4 s.

### The watchdog (151-A; cat/10)
The Host checks once a second: the Cat off every open floor's map (outside every room, on a locked floor, in the shaft
but not the car, under a floor, inside furniture, in the air, on a patch its roams cannot reach, on a top with no way
down) and no place's `holds_cat()` vouching for it, or standing still for `park_seconds` 90 s (not held, not COUCH):
`put` at the nearest spot of its map (`NavigationServer3D.map_get_closest_point` on the open floors' layers), for
everyone. The old Grotto cases are gone with the Grotto (Q2599).

### Petting and holding (151-B; the Cat's side of core/150's whole-Hands rule)
- E aimed at the Cat: `pet`: it stops at once (as the old), purrs ("cat_purr") for 2.5 s, the hearts float up;
  everyone sees and hears it. A napping Cat is woken by it. The crosshair rows read the old words: "Pet" with E and
  "Pick up" with the left click (RC:41-55).
- **Held, by core/150's rule.** The Cat's `Hold` child is the whole-Hands member for the Cat (the rule's own scene
  part, a `Carriable` if core/150 keeps that shape: `handable` off, `slot` = `hold_slot_cat.tres`, `title` "Cat"): it
  comes only into empty Hands ("Hands full" otherwise), never from someone else's Hands, and is laid where a leaver
  stood; the pick plays "pick" and a meow. What the Cat needs of the rule, and asks core/150 to keep:
  1. a pick refusal its owner adds: refused when the Cat is FLYING, BOXED, in the DRUM, or in a shut or riding car (the
     prompt does not show);
  2. the owner told in the same answer of a pick, a set-down, a hand-off and a Throw (to set `mode`, cut a walk or an
     errand, drop what is in its mouth where it stands, and start `left` = `hold_seconds`);
  3. a Host-only release by the owner's timer (`free`) that empties the holder's Hands and says where the thing lands;
  4. the Throw's flight told to the owner at launch and at the landing (the arc's from and velocity; the landing spot),
     and the thing's pose in flight left to the owner's Looks (the `fall` clip, upright, facing its velocity);
  5. the thrown knock (Q2700: a full-charge Throw knocks a Teammate down and bounces off; a weaker one bounces off to
     their feet, never caught; a rider of the Elevator, someone down or in the drum is not hit) applied to the Cat as
     to every thrown whole-Hands thing, with its rumble "knock".
- Held, it is drawn at its holder's hands in the world, for everyone (Q2703: held in the world, not in the held view):
  the hold slot puts its middle there, the `held` clip tips it and wriggles. After `hold_seconds` 3 s, `free`: it jumps
  down `free_ahead` 0.5 m in front of the holder and runs `run_from` 2 m off.
- Set down (the right click): it stands at the nearest spot of its map to where the crosshair put it, then runs 2 m off,
  as from a landing; on the stairs it stays on its step; a place's `takes_cat` goes first (the car keeps it, the washer
  takes it) (CAT:358-364, CAT:831-845; a detail of the reference the list's line leaves out).
- Thrown: "cat_hiss" at the throw (the real spitty hiss, Dan Knoflicek's Cat 8, CC-BY: credited), the throw's buzz
  "throw" on the thrower's pad; it flies paws out (`fall`), always lands on its four paws ("cat_land"), then runs off
  (1.6 m/s, 2 m); landing in the open car it stays (151-E). Where it lands: the flight's rest point, back along its
  facing by the old `FLY_AHEAD`, put on its map if it is off it (CAT:1846-1862).

### Swatting (151-C; cat/03)
On the Host's timer (every 60 to 120 s), when it walks or stands by a loose Sock or Pair lying within `swat_reach` 0.55
m along the floor and no higher than `swat_up` 0.45 m over its feet, on its own floor: `swat` (it stops, faces it,
plays `swat` for 1 s); at 0.45 of it, `knock`: the item flies 0.5 to 1 m for everyone (the Mess's drop patch with a
small push from the Host, by nobody), landing like a drop (off a low piece of furniture it falls); "cat_swat" at the
paw's contact, soft. Never from a Cabinet, a Drawer, inside furniture (a Sock on a `SockSpot` inside) or the Hands; not
while BOXED, in the car or in the drum. A `knock` whose item moved since the `swat` does nothing.

### Fetching (151-C; cat/07, Q1830-Q1833, Q1946, Q1947)
A `pet` with `fetch_chance` 0.6 and the cooldown run out (45 s after an errand) sends it: it walks to the two loose
Socks of one Design nearest to it (both lying still on an open floor, outside furniture, with a way to both; Q1831:
the nearest pair, Q2703), stops `fetch_pause` 0.4 s within `fetch_take_reach` 1.7 m of the second, takes them (the
Mess holds them, `mouth` names them; "pop"), carries them as a sock ball in its mouth (`Carry`) to the petter and sets
the Pair down at their feet with a meow (within `fetch_drop_reach` 1.2 m): an ordinary floor Pair (the old counted no
tally, CAT:555-558). A petter out of reach (a shut Door, another floor): set down at the closest spot it can walk to,
with a meow; a petter who walks more than `fetch_redirect` 1.2 m off meanwhile is followed; a petter who leaves the game
gets it set down where the Cat stands. A Cat picked up with Socks in its mouth lays them where it stands (the old's
`_end_errand`). It never fetches unasked (Q1947).

### The litterbox visit (151-D; cat/11, cat/14; Q1950, Q2008, Q2009, Q2011, Q2703)
`LitterVisit` (`game/furniture/litter_visit.gd`, a Part with no state, a child of `litterbox.tscn`, in `cat_places`)
offers the visit's spots (Marker3Ds in the litterbox scene: `CatFront` on the floor in front of the flap, `CatSill`,
`CatInside` on the litter; `CatDrop` where a hidden Sock lies) and runs the visit's steps on the Host as the Cat's
errand `litter` (the Cat's `due.litter`, `errand`, `mode`). About every 240 s (give or take 45): the Cat walks to
`CatFront`; noses the flap open if it is shut (the flap's Openable opened in the same answer, so "litter_flap_open"
plays; pushing it open again if a player shut it on the Cat); steps in over the sill (the `fall` hop, walking the
fixed in-path `CatFront` -> `CatSill` -> `CatInside`, not its map); BOXED: scratches for 6 s (its own `scratch` clip
and its own sound "litter_scratch", Q2703); walks out the same way; the Host shuts the flap behind it, whoever opened it
(Q2009). A visit that cannot start (no way there, the Cat busy, held, in the car) tries again in 15 s. On 1 in 3
visits (0.33) it first takes the nearest loose Sock within 5 m (standing within 0.6 m of it) across its jaws (`Mouth`:
its real Design), "pop", carries it there and drops it on the litter (`CatDrop`, the Mess's lying patch) (Q1943,
Q2011, Q2059). While BOXED it cannot be petted, picked up or swat. The litterbox itself, its Socks (laid by the Sock
generator, Q2600) and its flap sounds are built (assets/07).

### The Cat's side of the car (151-E; cat/13, cat/14; Q1982-Q1984, Q2003-Q2007)
`CarNap` (`game/entities/cat/cat_car_nap.gd`, a Part with no state, a child of `cat.tscn`) is the Cat's member of
core/149's `elevator_cargo` and of `cat_places`; it finds the level's `Elevator` and reads its `Car/CarBox` and the
stops' hatches (no new Elevator function):
- `nap_spot()`: the car standing OPEN at a stop, nobody riding: the middle of `CarBox`'s floor, hopped into from the
  floor in front of its hatch (the `fall` clip, "cat_land").
- `rides_patch(box, sill, delta, onto)`: the Cat in the box rides (`at += delta`); `fills_car(box)`: the Cat in the
  box: nobody climbs in ("Elevator full", core/149's words); `called_patch(box, onto)`: a call for the floor where it
  lies wakes it; a call elsewhere lets it sleep on and ride.
- On `Elevator.arrived(floor)` with the Cat in the car, the Host asks `wake`: it wakes on that floor and hops out.
- Shut in the car at its stop, not riding: it naps on `car_shut_seconds` 20 s (`left`), then the Host asks the
  Elevator's `open_hatch {floor}` and the Cat walks out (Q2004). While the car rides or its hatch is shut it is out of
  reach (no pet, no pick: 151-B's refusal reads `place`).
- `takes_cat()`: set down or thrown into the open car, it lands inside and stays: it may nap there or ride (Q2005).
- `holds_cat()`: the Cat in `CarBox` (the watchdog lets it be in the shaft only so).

### The drum cycle and the coats (151-F; secrets/02 for the Cat only, cat/05; Q1106, Q1125, Q1127-Q1129, Q2703)
`WasherWash` (built, core/98) takes one load beside its washed player: State `load: NodePath` (the load's Part, empty
none) and `load_left`; one thing at a time (a load and a washed player keep each other out, Q758, and neither starts
while a cutscene plays). It joins `cat_places`: `takes_cat()` when the Cat is set down standing within `wash_reach` of
the washer's `Door` and aimed at the washer, the machine free: the answer puts the Cat in the DRUM (`place` the wash)
and starts the load for `cat_seconds` 4. `WashView` shows it as the knockdown wash's: the blob in the coat's colour
sliding in, the door slammed (`wash_slam`), `wash_slosh` at the porthole, the drum and the face's `spin` at `cat_spin`
0.45 turns a second, the blob turning slowly behind the porthole; at the end the door bursts open. The Host's end
answer stands the Cat just out of the door (0.2 m out), DIZZY for `dizzy_seconds` 2.5 (the `dizzy` clip), with a
meow, in its next coat (the folder's next, after the last the first), then it runs off 2 m. The coat lasts until its
next wash and is saved; a New Game's Cat is black. A save or a join while it spins: the load is not saved (as the
knockdown wash), so a load stands the Cat in front of the door in its old coat (the old `drum_cleared`). The other
loads (the Radio, a Gift box) stay with the Secrets (Q2699); the load field is generic so they need no new shape.

### Saves, joins and the Lobby
Nothing writes save code: `Cat` and `WasherWash` are saved and joined by their State groups (`docs/architecture/saves.md`);
`walked`, `left`, `purr_left` and `due` are live in `save_state()`. A held or flying Cat is saved standing where it is
(the holder's Hands empty in the save, the old rule). Socks in its `mouth` are laid at its feet by its `loaded()`. A
`place` that is not in the loaded level is cleared. `tests/saves/shape.json` changes in 151-A only (the Cat) and 151-F
(the wash's two load fields).

## Sounds (SoundEvents in `sound_catalogue.tres`, the old picks; all added by 151-A so the later drafts do not touch the catalogue)

| Event | When | Space | Old pick |
|---|---|---|---|
| `cat_meow` | a meow (the Host's, a pick, a fetch's Pair, out of the drum) | world, at the Cat | SB:57 |
| `cat_purr` | a pet, 2.5 s | world | SB:58 |
| `cat_hiss` | a throw | world | SB:59 (Dan Knoflicek, Cat 8, CC-BY: in `credits.tres`) |
| `cat_land` | a landing, the hop into or out of the car | world | SB:60 |
| `cat_swat` | the swat's contact | world | SB:61 |
| `litter_scratch` | the litterbox scratch, while BOXED | world, at the litterbox | **open (Q2703 asks its own sound): `[blocking]` below**; until answered, the swat's clips as a placeholder |
| `pop` (exists) | the Cat takes Socks | world | shared |
| `pick` (exists) | the pick | the picker's | shared |

The Cat has no rumble of its own: a Throw of it buzzes "throw", a knock "knock" (core/150's).

## Seams to the other pieces

- **core/150 (the whole-Hands and thrown-knock rules; designed beside this):** the Cat is one more whole-Hands thing
  (its `Hold` member) and one more thrown thing; the five needs above are what this side asks of the rule. If core/150's
  rule does not offer one of them, 151-B adds it to the rule's own file in its wave and says so in its report.
- **core/149 (the Elevator; designed beside this):** `CarNap` joins `elevator_cargo` (`rides_patch`, `fills_car`,
  `called_patch`), listens to `arrived`, asks `open_hatch` (Host only); the car's StaticBody is what a thrown Cat lands
  on, `CarBox` decides "in the car". core/149-A calls the group and 149-C moves the other cargo; 151-E needs both merged.
- **Batch A's washer (built):** `WasherWash` gains the load (151-F); `Knockdowns._let_go_at` is unchanged (a body and the
  Cat share `busy`). `Washer.busy()` reads the load too.
- **core/80 (floor locks; built):** the Cat reads `Stages.floor_open(floor)` (its map's layers) and `floor_opened` (the
  couch ends at the ground floor's).
- **The Mess (built):** two new patches, both Host-made in the Cat's answers (151-C): `Mess.carried_patch(socks)` (HELD
  with no Hands holding them: the Cat's `mouth` says whose) and `Mess.fetched_pair_patch(lead, other, pose)` (the two
  laid as one floor Pair: the only Pair made outside the Hands' pick answer); the swat uses `thrown_patch` with `by` 0
  (nobody). The Hands must never read a HELD record as theirs unless their own lists name it (151-C checks).
- **The Sock generator (built):** the litterbox's Socks are its `Inside` spots (Q2600); the Cat's hidden Sock is laid at
  `CatDrop`, not a generator spot.
- **Secrets (later, Q2682):** Cat on the Piano and Fur Fetch hang on `landed_at`; Radio Dance and Clock Stare on the
  Cat's place and mode over time; Cat Cradle on `petted` with a holder (a held Cat may be petted only with the Secrets
  on). The Looks keep the head's and tail's bones for their tells. Not built.

## Changed technically from the old (no choice: tell the designer at the sitting)

- One Part for the Cat's body; each place it uses (the litterbox, the car, the drum, a nap spot) offers itself through
  one group contract instead of the old Cat reaching into each and each reaching into the Cat.
- Routes from Godot's navigation (a region per floor, Door links, Heaps and leaves as obstructions), baked off the main
  thread; the old planned rooms, doorways and ramps in code and baked per room on the main thread.
- The Socks it carries stay Mess records (held by the Cat), not taken out of the World and made again.
- The held tip, the wriggle, the dizzy stagger and the breathing are clips in Looks, not code; the head turn is Godot's
  `LookAtModifier3D`.
- Coats are files, one per coat, in a folder the wash cycles through.

## The designer's answers this piece rests on

- Q2703: the Cat as the old (the couch until the ground floor opens; the fetch of the nearest Pair at 0.6 and 45 s; the
  litterbox every 240 +- 45 s, 6 s, 1 in 3; held in the world at the hands), except its drum cycle and coat change
  come now, without the other Secrets, and the litterbox scratch gets its own clip and sound.
- Q2700: a thrown Cat that hits a Teammate: a full-charge Throw knocks down, a weaker one bounces off to their feet,
  never caught; an Elevator rider is never hit.
- Q2699: every carried thing rides the Elevator by one rule (the Cat is cargo); putting other things into the drum waits
  with the Secrets.
- Q2705: the Cat and its clips are ported from the old game by the port rules, with the old colours.
- Q2682: the Cat's five Secrets wait with the Secrets subsystem. Q2599: no Grotto. Q2600: the litterbox's Socks are the
  generator's.

## Draft tickets (ready-for-agent; the lead files them)

Each builds on graybox Looks and waits for no asset (Q2705); every number `# placeholder:` the old unless a Q set it.
"Lines" are list 12's by heading and order (W What it is, R Roaming and resting, P Petting, H Picking up, holding,
throwing, S Swatting, F Fetching, L The litterbox, C Naps in the car, WD The watchdog, D The drum and the coats, Wo
Words). Every list line is in one draft below or named after them.

### 151-A The Cat walks the house: the entity, its map, roaming, resting and the watchdog
- **Lines:** W1 (graybox look; the model is AS-C), W2, W3; R1, R2 (the sofa, beds and window spots; the car spot is
  151-E's), R3, R4, R5, R6, R7 (every clip in the graybox Looks, `scratch` a placeholder copy of `swat`); WD1.
- **Build:** `cat.tscn` (root, `Cat` Part with every State field of this doc, `Aim`, `Gait`, `Nav`, graybox Looks
  with its contract and every clip, `Hearts`, `Mouth`, `Carry`, `CatLooks` with the coat), `CatTuning` and its `.tres`
  (every field above), `CatCoat` and the five coats, the verbs `rest_over`, `walk`, `meow`, `put` and the Host's timers,
  the group contracts `cat_nap` and `cat_places` (the calls, no member yet), the per-floor regions and the async bake,
  the Door scene's `NavigationLink3D` and doorway obstacle, `CatStart` and the window nap markers in `house.tscn`, the
  nap markers in `sofa.tscn`, `double_bed.tscn`, `bunk_bed.tscn`, `old_cot.tscn`, the Cat placed in `house.tscn`, every
  Cat SoundEvent of the table (and the hiss's credit), the station `cat.tscn` with its board and zoo tuning, the station
  under `Stations` in `zoo.tscn`, `tests/saves/shape.json`.
- **Acceptance:** in the house from a New Game (stages on) the Cat sits on the living room's couch and stays there while
  the ground floor is locked; when the ground floor opens (the real `open_floor`) it walks off within a rest's length;
  it is never seen on a locked floor, through a shut Door or in the shaft (a 10-minute seeded soak of the house at
  a raised time scale finds no watchdog `put` but by `park_seconds`, and the Cat on a map spot every second: the old's
  seed-8 failure on the stairs, DC B4, is one of the seeds); it naps at nap spots with `curl`; a meow plays every 12 to
  30 s while awake; its head turns toward a player in front within 2.5 m; a Guest sees the same walk (positions within
  0.05 m of the Host's at the same walk time) and a late Guest sees it mid-walk; save mid-walk and load: the walk
  resumes; a Cat placed inside furniture is `put` back at once; the async bake costs the main thread under 2 ms.
  **Real path:** in the Cat station, with the Cat's walk planned through the Door to the far room (the zoo tuning's
  seed), the player's left click shuts the Door; the Host plans again and the Cat the player sees never crosses the
  doorway while it is shut, and walks through it once the player opens it again.
- **suites:** [cat, save, stages, room_doors, zoo]
- **Model:** opus.
- **Authored:** `CatTuning` and the coats in the inspector; nap spots as markers in the group; clips in the graybox
  Looks; the station built from the coats folder, the markers and the catalogue.

### 151-B Petting, holding and throwing the Cat
- **Lines:** P1, P3; H1, H2, H3 (with the run-off, the stairs step and the places' `takes_cat` first: details from the
  reference, CAT:358-364, CAT:831-845), H4, H5 (the Cat's side of Q2700); Wo1.
- **Build:** the verb `pet` and its refusals; `free` and `landed`; the `Hold` whole-Hands member on `cat.tscn` by
  core/150's rule (`hold_slot_cat.tres`); the five needs of "Petting and holding" (in the rule's file only if core/150's
  rule lacks one, said in the report); the calls of `takes_cat` at a set-down, a free and a landing (no member yet); the
  crosshair words; the hearts and the purr from `petted`.
- **Acceptance:** E aimed at the Cat stops it, "cat_purr" plays, the hearts emit for 2.5 s, on every machine; the left
  click with empty Hands puts it at the player's hold slot (drawn in the world, `held`), a meow and "pick" play; with a
  Sock in the Hands it reads "Hands full"; a Teammate cannot take it from the holder; after 3 s it stands 0.5 m in
  front of the holder and runs 2 m off; the right click sets it down at the crosshair and it runs off; on the stairs it
  stays on its step; a Throw hisses, it flies with `fall`, lands upright with "cat_land" and runs off; a full-charge
  Throw at a Teammate knocks them down and bounces off, a weak one drops at their feet and is not caught, a rider is not
  hit (co-op cases: the Host and a Guest each throwing); boxed, in the drum or flying it cannot be petted or picked (the
  prompt hides); a holder who leaves lays it where they stood; a save with the Cat held loads it standing there.
  **Real path:** the player presses E aimed at the Cat in the Cat station and the hearts and purr the player sees and
  hears start; then the left click with empty Hands, and the Cat the player sees is at their hands until it jumps down.
- **suites:** [cat, carry, coop_carry, knockdown, coop_knockdown, throw]
- **Model:** opus. **After:** 151-A and core/150's whole-Hands and thrown-knock drafts.
- **Authored:** no new numbers (CatTuning's); the hold slot a `.tres`; the words in the crosshair rows.

### 151-C Swatting and fetching
- **Lines:** P2; S1; F1, F2.
- **Build:** the verbs `swat`, `knock`, `fetch_step` and the fetch roll in `pet`; `Mess.carried_patch`,
  `Mess.fetched_pair_patch`, the swat's drop by nobody; the mouth's drawing (`CatLooks.carry`: one Sock across `Mouth`,
  a Pair's sock ball at `Carry`, the Mess's own Looks for the Design); the errand's ends (a pick, a leaver, a load).
- **Acceptance:** in the Cat station a loose Sock within reach is batted 0.5 to 1 m at the swat's contact with
  "cat_swat", never one in the Hands, inside furniture or above 0.45 m; with `fetch_chance` 1 a pet sends the Cat to the
  nearest two Socks of one Design, they leave the floor with "pop", it carries a sock ball and a Pair lies within 1.2 m
  of the petter's feet with a meow; behind a shut Door the Pair lies at the closest reachable spot; a petter walking 2 m
  off is followed; a petter leaving gets it set down where the Cat stands; a Cat picked up mid-errand lays its Socks
  where it stands; every Design keeps two records throughout; a Guest sees the same (co-op case). **Real path:** the
  player presses E on the Cat (zoo tuning, `fetch_chance` 1) with two Socks of one Design on the floor; the Pair the
  player then sees at their feet is picked with the left click into their Hands as one Pair.
- **suites:** [cat, mess, coop_mess, hands, pairing]
- **Model:** opus. **After:** 151-B.
- **Authored:** CatTuning's swat and fetch numbers; no new data.

### 151-D The litterbox visit
- **Lines:** L4, L5, L6, L7. L1, L2, L3 are built (assets/07; the generator's `Inside` spots, Q2600; the flap's
  sounds) and are checked again by this draft's case.
- **Build:** `LitterVisit` on `litterbox.tscn` with its markers (`CatFront`, `CatSill`, `CatInside`, `CatDrop`), the
  visit's steps as the errand `litter` (the flap's Openable patched in the answers), the hiding visit, the scratch with
  `scratch` and `litter_scratch`, `holds_cat` while BOXED.
- **Acceptance:** with the zoo tuning's `litter_every` the Cat walks to the flap, a shut flap opens ("litter_flap_open"
  plays), it steps in, scratches 6 s with `scratch` and "litter_scratch", walks out and the flap shuts behind it even
  if a player opened it; a flap a player shuts on it is pushed open again; with `litter_hide_chance` 1 it first carries
  the nearest loose Sock in its jaws and drops it inside; inside it cannot be petted, picked up or swat; a visit with no
  way there tries again in 15 s; the watchdog leaves it alone inside; a Guest sees the same. **Real path:** the player
  shuts the flap with a left click before the visit; at the visit the flap the player sees opens and shuts again; the
  player's left click opens it and the hidden Sock lies inside, picked through the flap into their Hands.
- **suites:** [cat, furniture, cupboard, mess]
- **Model:** sonnet. **After:** 151-C (the mouth's drawing).
- **Authored:** the spots are markers in the litterbox scene (moving the litterbox moves the visit); the numbers are
  CatTuning's.

### 151-E The Cat's naps in the Elevator's car
- **Lines:** C1, C2, C3, C4 (the Cat's side; the carry rule and the refusal words are core/149's).
- **Build:** `CarNap` on `cat.tscn` (`nap_spot`, `rides_patch`, `fills_car`, `called_patch`, `takes_cat`,
  `holds_cat`), the `wake` verb from `arrived` and a call, the shut nap and `open_hatch`; the real Elevator (two stops)
  in the Cat station.
- **Acceptance:** in the Cat station with the car open and empty the Cat naps in it (its hop with `fall` and
  "cat_land"); a call from the other stop takes it along asleep and it wakes and hops out there; a call where it lies
  wakes it; Space aimed into the car while it is in it reads "Elevator full"; the hatch shut on it at its stop: after
  20 s the hatch opens by itself and it walks out; while riding or shut in it cannot be petted or picked; set down or
  thrown into the open car it stays in; a load mid-ride keeps it in the car; a Guest sees it ride. **Real path:** the
  player clicks the other stop's call button with the Cat asleep in the car; at the arrival the Cat the player sees
  wakes there, and the player's Space at the car reads "Elevator full" while it is inside.
- **suites:** [cat, elevator, elevator_cargo]
- **Model:** opus. **After:** 151-B, core/149-A and core/149-C.
- **Authored:** no data of its own (CatTuning's `car_shut_seconds`); the car is a place by the group contract.

### 151-F The drum cycle and the coats
- **Lines:** D1 (Q2703: now, for the Cat only).
- **Build:** `WasherWash`'s `load` and `load_left` (State, one at a time with a washed player), its `takes_cat` and
  `holds_cat`, the end answer (the next coat, DIZZY, the meow, the run-off), `WashView`'s blob in the coat's colour at
  `cat_spin`, `WasherTuning.cat_seconds` and `cat_spin`, `Washer.busy()` reading the load, `tests/saves/shape.json`.
- **Acceptance:** the Cat set down by the washer's door aimed at the washer goes in: the blob slides in, the door slams,
  the drum turns at 0.45; after 4 s the door bursts open and the Cat stands out of it dizzy for 2.5 s with `dizzy` and a
  meow, then runs off grey; five washes go black, grey, ginger, white, calico, black; a coat `.tres` dropped into the
  folder joins the cycle; the coat is saved and a New Game's Cat is black; a body let go at the door while the Cat spins
  just lies there, and the Cat is not taken while a player spins; a save while it spins loads it in front of the door
  in its old coat; a Guest sees the same. **Real path:** the player carrying the Cat right-clicks aimed at the washer
  standing by its door; the Cat the player sees is gone into the drum, and after the cycle it stands by the door in
  the grey coat.
- **suites:** [cat, wash, washer, knockdown, save]
- **Model:** opus. **After:** 151-B.
- **Authored:** coats are files in the folder; the cycle's numbers are `WasherTuning`'s; the blob's colour is the coat's.

### AS-C The Cat's model and clips (asset ticket, `assets/<NN>`; Q2705)
- **Lines:** W1's look (the model), R7's real clips.
- **Build:** by the port rules (technical only): the old `assets/cat/cat.glb` from `tools/blender/make_cat.py` and its
  clips from `tools/blender/cat_anims.py`, ported into `assets_src/generate/cat/` and built by `build.py -- cat` to
  `assets/cat/cat.glb` (the 16-bone rig, `eyes_closed`, the nine old clips: stand, sit, curl, fall, held, walk, run,
  swat, dizzy; the held tip and the dizzy stagger baked into their clips where the old did them in code, keeping their
  numbers), the calico patches as a vertex colour layer made once from the rest pose (the old CV:39-57 rule: frequency 9,
  cut 0.12, white below 0.1 m), shared materials (Q2177), and `looks_cat.tscn` meeting the contract (`scratch` still the
  placeholder until AS-K). Passes `kit/tools/asset_lint.py`.
- **Acceptance:** the before-and-after strip in `builds/review-cat/` (the old and the port side by side: each clip's
  key pose, each coat, held, curled); stops at its first line-up for the designer's go (look work). The swap in
  `cat.tscn` is the one line done after the go.
- **suites:** [] (the Looks test of 151-A runs on it once swapped)
- **Model:** opus. **After:** 151-A (the contract).
- **Authored:** the generator script; the clips' keys are the motion's numbers.

### AS-K The litterbox scratch clip (asset ticket; Q2703)
- **Lines:** L4's own clip.
- **Build:** a new `scratch` clip on the ported rig (front paws digging, the old swat's timing only as a starting
  point), added to the generator, exported with the others; `looks_cat.tscn`'s `scratch` points at it.
- **Acceptance:** a strip of the scratch beside the old swat in `builds/review-cat-scratch/`; stops at its first strip
  for the designer's go (look work: a new motion is the designer's to judge).
- **suites:** []
- **Model:** opus. **After:** AS-C's go.
- **Authored:** the clip's keys.

### Behaviour lines not in a draft
- The five Secrets lines (Cat on the Piano, Radio Dance, Clock Stare, Fur Fetch, Cat Cradle): later, with the Secrets
  subsystem (Q2682). The drum line is not among them: Q2703 brings it now (151-F).
- Not ported: the Cat in the Lost Sock Grotto (Q2599); the litterbox's fixed three starting Socks (Q2600: the generator's).

## The waves (this doc; for the lead to merge with the other batch C designs)

Waves run side by side, at most 5 agents; a wave starts when the waves before it are merged.

| Wave | Drafts (suggested model) | Files each is alone on in its wave |
|---|---|---|
| 1 | 151-A The Cat walks the house (opus) | `game/entities/cat/*`, `house.tscn`, `zoo.tscn`, `game/zoo/stations/cat.tscn`, `game/zoo/cat/*`, `sofa.tscn`, `double_bed.tscn`, `bunk_bed.tscn`, `old_cot.tscn`, the Door scenes (`door.tscn`, `room_door*.tscn`), `sound_catalogue.tres`, `credits.tres`, `tests/saves/shape.json` |
| 2 | 151-B Petting, holding and throwing (opus; after core/150's rules); AS-C The Cat's model (opus) | 151-B: `cat.gd`, `cat.tscn`, `cat_looks.gd`, `hold_slot_cat.tres`, (core/150's rule file only if needed); AS-C: `assets/cat/`, `assets_src/generate/cat/`, `assets/blender_assets.json`, `game/entities/cat/looks_cat.tscn` |
| 3 | 151-C Swatting and fetching (opus); 151-F The drum cycle (opus) | 151-C: `cat.gd`, `cat_looks.gd`, `mess.gd`, `hands.gd` (only if the HELD check needs it); 151-F: `washer_wash.gd`, `wash_view.gd`, `washer.gd`, `washer_tuning.gd`, `washer_tuning.tres`, `tests/saves/shape.json` |
| 4 | 151-D The litterbox visit (sonnet); 151-E The car naps (opus; after core/149-A, -C); AS-K The scratch clip (opus; after AS-C's go) | 151-D: `litterbox.tscn`, `game/furniture/litter_visit.gd`; 151-E: `cat.tscn`, `cat_car_nap.gd`, `game/zoo/stations/cat.tscn`; AS-K: `assets/cat/`, `assets_src/generate/cat/`, `looks_cat.tscn` |

Where the chains run: `cat.gd` 151-A, B, C in waves 1-3 (151-D, E, F add their own Parts and call the Cat's patch
functions; they do not edit `cat.gd`); `cat.tscn` 151-A, B, E in waves 1, 2, 4; `cat_looks.gd` 151-B then C;
`tests/saves/shape.json` 151-A then F; the Cat station 151-A then E; `assets/cat/` AS-C then AS-K. AS-C's swap line in
`cat.tscn` is done after the designer's go and outside a wave where 151-B or 151-E edits `cat.tscn`.

Across the batch C designs (not this doc's to order; for the lead when the four are filed): 151-A edits `house.tscn`,
`zoo.tscn`, `sound_catalogue.tres`, `credits.tres` and `tests/saves/shape.json`, which core/149's 149-A, 149-G, 149-H
and core/150's drafts also edit: keep them out of 151-A's wave. 151-B needs core/150's whole-Hands and thrown-knock
drafts merged (and may touch their file). 151-C edits `mess.gd`, which 149-C also edits: not in one wave. 151-E needs 149-A and 149-C merged. 151-F edits the washer's files, which no
other batch C draft names. The Door scenes (151-A's `NavigationLink3D`) are named by no other batch C draft.

## Gotchas for the build

- The walk is the Host's path and the time since its answer was applied, nothing else: `CatGait` must be a pure
  function of them (no physics, no `_process` integration that drifts), or a Guest's Cat walks elsewhere.
- `parse_source_geometry_data` runs on the main thread: parse the static house once, then add Heaps and leaves with
  `add_projected_obstruction`; never parse per walk.
- A `NavigationLink3D` needs both ends on a region's polygons: place its ends 0.2 m clear of the doorway's cut on each
  side; check a link per Door in a test.
- A held or boxed Cat must not be `put` by the watchdog: it asks the places (`holds_cat`) and skips HELD and FLYING.
- A pet stops the walk at once, as the old (the list's weak point says so, and Q2703 keeps the old): cut the path at the
  drawn point, do not ease it out.
- Socks held in the Cat's mouth are HELD Mess records no Hands names: the Hands' leaver, snapshot and catch code must
  read their own lists, never "every HELD record" (151-C).
- A swat's `knock` checks that the item still lies where the `swat` saw it (0.1 m); a Sock picked in between is left.
- `Openable.loaded()` shuts every Openable: a load mid-visit finds the flap shut; the Cat's `loaded()` stands it at
  `CatFront` if it was BOXED.
- The Cat in the car is in the shaft's box: the watchdog's "never in the shaft" must ask `holds_cat` first.
- The old seed-8 soak failure (off the stairs after a pet, 1638 s, cause unknown, DC B4): keep seed 8 in 151-A's soak.
