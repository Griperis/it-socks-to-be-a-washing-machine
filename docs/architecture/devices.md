# The Sock vacuum, the Backpack vacuum and the Sock detector

**Status: build plan for batch C (designed in core/150 on the designer's answers Q2697-Q2706, with Q2710 and Q2711
for the Sock vacuum in the Elevator; 2026-11-26). Filed by core/153: 150-S became the whole batch's groundwork core/154;
150-A core/163, 150-B core/164, 150-C core/165, 150-D core/166, 150-E core/167, 150-F core/168, 150-G core/169, 150-H
core/170, 150-I core/171, 150-J core/172, 150-K core/173, 150-L core/174, 150-M and 150-N together core/175; AS-C2-1
assets/24, AS-C2-2 assets/25, AS-C2-3 assets/26, AS-C2-4 assets/27, AS-C2-5 assets/28. The build order is
`docs/migration/milestones.md` "Batch C".** Behaviour list: `docs/migration/m4-lists/09-vacuums-and-detector.md` (53 lines, here V1-V53 in
its order). The TV and the Radio are the other half of this design: `docs/architecture/tv-and-radio.md` (its lines
R1-R33). Both docs share the two rules every carried device follows (below).

## What it owns

The house's one Sock vacuum (the container, the nozzle, the hose, the Tank, the Spit, the Pour, the Filter and the
Nozzle display), its two Backpack vacuums, the Sock detector, the five vacuum Upgrades' effects (`big_bag`,
`strong_suction`, `long_hose`, `wide_nozzle`, `filter_nozzle`, core/129 shows them "Coming soon"), the Old Tree's
`tree_tip_vacuum` trigger, and two rules shared by every carried device of batch C: **the whole-Hands rule** and **the
thrown-knock rule**.

It does not own: the Elevator's carry rule (core/149: this doc writes only what the devices bring to it), the Cat
(core/151: it uses the two rules, its side is its own), the drum's Secrets (Q2682, Q2699), the Drum at the run's end
(batch D: the detector moved into it at the pull, V46), the pad bindings (batch D's controller work; the old
placeholders until then, Q2698).

## The designer's answers this doc is built on

- **Q2698** (list 09 questions 1-11, 15): as the old. All the devices are in the house from a New Game, the vacuums
  behind the ground floor's lock; the Spit is 0.1 s a Sock (a placeholder); a full vacuum just stops (the motor runs
  on, no sound); taking the nozzle plays the Hands' pick rustle; the motor has one pitch with its 0.12 s fade; a
  poured Sock has no sound of its own; both orders of shared carrying work; a dropped nozzle lies where it was
  dropped; at the hose's length only the hose shakes; the detector lies on the workbench beside the book; its beep is
  the ping's pool; the pad bindings stay the old placeholders until batch D.
- **Q2699** (list 09 question 12): every carried thing rides the Elevator by one item rule, **the detector too**, like
  the Radio (this changes V45's "it does not ride"); putting things into the washer's drum is a Secret and waits
  with them.
- **Q2700** (list 09 question 13; 12-7, 13-7): a thrown detector, Radio or Cat that hits a Teammate: a full-charge
  Throw knocks down, a weaker one bounces off to their feet, never caught; an Elevator rider is never hit.
- **Q2705** (list 09 question 14): the models are ported from the old game by the port rules, each family with its
  strip and the old colours.
- **Q2697**: motion is AnimationPlayer clips in a Looks scene, never code tweens.
- **Q2710**: the Sock vacuum's container rides the Elevator only with its nozzle on its hook (narrows Q2699).
- **Q2711**: a player holding the nozzle may climb into the car with the container outside; nothing stops it and the
  hose stretches between floors, as the old.

## The two shared rules

### The whole-Hands rule (V4, V16, V32, V33, V40; R20; the Cat, core/151)

One rule for every thing that takes the whole Hands: the nozzle, the Sock vacuum's container, a Backpack vacuum
(carried or worn), the detector, the Radio, the Cat.

- It comes only into empty Hands. "Empty" counts a one-slot item (core/139's book) as held: with anything in the
  Hands the pick is refused and they read "Hands full" (the Carriable's `full`, exists).
- **The one exception, the nozzle (Q736):** with Socks, Pairs or the book in the Hands, taking the nozzle drops them
  round the player's feet as a leaver's Hands drop (the old `decide_spill`, which laid the book with the Socks); with
  a carried thing (the Radio, a present, a bin, a Machine Part, the detector) it is refused "Hands full".
- While it is held no Sock, Pair or one-slot item comes in (a pick is refused "full", a Hand-off or a catch lies at
  their feet): `Hands.carries()` (exists for `Carriable`).
- A right click puts it down where aimed (the Hands' place check, exists); aimed at a Teammate a `handable` thing goes
  into their empty Hands, else at their feet ("Hands full"); a Teammate never takes it from the carrier.
- A leaver, or a player knocked down (coop/10 drops their Hands as a leaver's, Q2485), lets it go where they stood;
  the nozzle goes back on its hook (the old `player_left`, VA:622-645).
- A load lays it where it last lay; a Guest's held one is saved lying where they stood (Q295; `Carriable.loaded()`).

**How:** the container, a Backpack vacuum, the detector, the Radio and the Cat are `Carriable`s (core/78, exists). The
nozzle is not a thing that lies about on its own (it hangs on its vacuum or lies on its hose), so it is state of the
`Vacuum` Part; a worn Backpack's nozzle too. **One seam on `Hands`:** a group `Hands.TAKERS` whose Parts answer
`takes_hands_of(by: int) -> bool`; `Hands.carries()` (and so every "full" check) counts them as it counts a
Carriable. `Vacuum` is in it. Built by 150-F.

**The held thing's input (one seam on `player.gd`, built by 150-A):** while the Hands hold a carried thing or a
taker, the player's `pick` (left button), `drop_throw` (right button, with its held time), `interact` (E, pressed and
released) and `hands_next` / `hands_prev` (the wheel) go first to that thing's `held_input(by, action, pressed,
held_seconds) -> bool`; it returns whether it used them. Today's behaviour is the default (`Carriable`'s own: right
tap puts down, right hold throws when `throwable`). The Radio's E turns its dial (R21), the container's held E pours
(V18), a carried Backpack's E puts it on (V33), the nozzle's held left button sucks (V5), its right tap drops or hangs
it and its right hold spits (V9, V10), the wheel steps the Filter (V24). core/139's "E reads the active book" is the
same seam's first user if it lands first; 150-A generalises it then.

### The thrown-knock rule (V41; R25, R26; the Cat, core/151)

One rule for every thrown carried thing (the detector, the Radio, the Cat), as the old (Q2700, Q1935, Q1936):

- A `throwable` Carriable leaves the Hands on the right button held and released as a Sock's Throw does (the Hands'
  charge time and Throw speed, `Upgrades.value` of `charge_time` and `throw_speed`, core/130), along the aim.
- It flies on a scripted arc (coop-structure: "scripted-arc items, the Command answer only, each machine replays the
  arc"): the `throw` answer carries `from`, `vel`, `charge` and the thrower; every machine flies the same arc
  (`Arc`, exists) with the Carriable's `holder` 0 and a new State field `flight: Dictionary` (`from`, `vel`, `t0` on
  the Host's clock, `by`, `charge`; empty when it lies), so a late joiner and a save see it mid-air.
- **The Host** sweeps the arc each physics tick: against the house (a shape cast of the Carriable's own shape), the
  first touch answers a Host-only `land {at, yaw}` (it lies there; its landing sound plays: the Radio's
  `radio_land`); against players by `Knockdowns`' hit test (coop/10), which grows one source beside `Mess.throws`: the
  Carriables in the air (group `Carriable.FLYING`, each giving its position, `radius`, `by` and `charge`). The old
  exemptions stay (Q2484): the thrower, a player already down, one in the drum, an Elevator rider (core/149 adds that
  one to the hit test for every Throw).
- **Full charge** (`KnockdownTuning.min_charge`): the Teammate is knocked down (the `knock` answer, exists) and the
  thing bounces off their body (a new arc in the same answer, the old C27). **Below full charge:** it bounces off and
  drops at their feet; it is **never caught** (a Carriable has no catch: unlike a Sock below full charge, core/42).
- Out of the level's bounds or inside a wall it is lost and comes back lying in front of the washer, the Mess's return
  spot (R28, Q2559 "lost things back by the washer"): one rule for every Carriable.
- The thrower's own Throw is looks-first: their machine flies the arc at once from the asked `from` and `vel` (a
  ghost) and eases onto the answer's arc over the ghost blend (`GhostTuning`, exists), as a Guest's Sock Throw does.
- Its rumble is the Throw's "throw" buzz for the thrower and the knock's buzz for the knocked (`rumble_throw.tres`,
  `rumble_knock.tres`, exist); a device has none of its own.

**How:** `Carriable` grows `@export var throwable := false` and `@export var radius := 0.15` (its ball for the hit test),
the verbs `throw {from, vel, charge}` (the carrier's) and `land {at, yaw}` / `bounce {from, vel}` (Host-only), and
`flight` in its State. Built by 150-A with the Radio as its first user; the detector (150-E) and the Cat (core/151)
set `throwable` and get it all.

## The shape

Inheritance stays one step (Q2251): every script below is a `Part`, or a view with no state. A thing gets a script
only when no Part does the job: the container, a Backpack and the detector reuse `Carriable` for their carry.

| Scene | Nodes | State kind |
|---|---|---|
| `game/entities/sock_vacuum/sock_vacuum.tscn` | root `SockVacuum` (Node3D); `Carriable` (the container: title "Sock vacuum", `handable` off, `slot` `hold_slot_vacuum.tres`); `Vacuum` (Part); `VacuumFilter` (Part, 150-I); `Hose` (a view: the rope); `Looks` | decided (Parts); the hose is looks on every machine |
| `game/entities/backpack_vacuum/backpack_vacuum.tscn` | root `BackpackVacuum`; `Carriable` (title "Backpack vacuum", `handable` on, `slot` `hold_slot_backpack.tres`); `Vacuum` (the same Part, its `worn` mode); `Looks` | decided |
| `game/entities/sock_detector/sock_detector.tscn` | root `SockDetector`; `Carriable` (title "Sock detector", `handable` on, `throwable` on, `slot` `hold_slot_detector.tres`); `DetectorScreen` (a view, no state); `Looks` | decided; the reading is looks on every machine |

All three are **placed** in `house.tscn` by hand (static Parts: their ids are in the layout hash; nothing is bought or
spawned during play now that the Splitter is not ported, Q2599). The Socks in a Tank are **Mess records** (HELD, like
a Sock in Hands), never copies, so every Design keeps its two records (I.1).

### `Vacuum` (`game/devices/vacuum/vacuum.gd`): one Part for both kinds

| Field | Meaning |
|---|---|
| `nozzle_by: int` | the player whose Hands the nozzle takes (0: nobody). For a Backpack: its wearer |
| `nozzle_at: Vector3` | where the nozzle lies on its hose; `INF` on its hook (Sock vacuum only) |
| `nozzle_yaw: float` | its turn lying |
| `tank: PackedInt32Array` | the Mess ids in the Tank, oldest first |
| `pour: bool` | the container tips and pours (Sock vacuum only) |

Exports: `tuning: VacuumTuning` (one `.tres` per kind), `hose: bool` (the Sock vacuum's), `wearable: bool` (a
Backpack's), `pours: bool`. It finds its sibling `Carriable` (the container or the Backpack) and, when present, its
sibling `VacuumFilter`.

| Verb | Who | What it decides |
|---|---|---|
| `take_nozzle` | a player, the nozzle aimed (Sock vacuum) | refused "gone" (someone holds it, or this player carries the container: tools/10's "a Teammate's carried one is free"), "full" (a carried thing in the Hands), "far"; else `nozzle_by`, with the Hands' spill patch of what they held (the whole-Hands exception) |
| `put_nozzle {at, yaw}` | the holder, right tap | within `hang_reach` (0.6 m) of the hook, or aimed at its own container: hung (`nozzle_at = INF`, "Hang the nozzle"); else refused "far" past the hose's length along the Host's rope plus `host_slack` ("The hose won't reach"), "nowhere" by the Hands' place check; else it lies there ("Drop the nozzle") |
| `wear` / `unwear` | the carrier / the wearer, E (Backpack) | the Carriable's holder goes to `nozzle_by` (worn: the nozzle takes the Hands), and back ("Put it on" / "Take it off") |
| `suck {sock, from}` | the holder, while the left button is held | refused "not_held", "gone", "full" (the Tank at capacity), "tilted" (a teammate's Pour), "filtered" (the Filter), "far" (past the hose plus slack, or past reach plus slack from `from`); and by rate (the suck interval, `accepts()`); else the Sock goes HELD into the Tank (`Mess.held_patch`) |
| `spit {from, vel}` | the holder, while the right button is held past `spit_tap` | refused "empty", "not_held", "busy" (the spat-bodies budget); else the oldest Tank Sock leaves `from` with `vel` (`Mess.thrown_patch`, `drop` on: a released body, never a Throw: no catch, no knock; check VA:353-377 and build what the old did) |
| `pour {on}` | the container's carrier, E held / released | `pour`; the Host's own timer then lets one Sock fall over the front lip every `pour_every` with `pour_speed` forward until off, let go or empty |

`takes_hands_of(by)` is `nozzle_by == by` (the `Hands.TAKERS` seam). `left(by)`: a leaver's (or a knocked player's)
nozzle goes back on its hook, a worn Backpack drops beside them with its load (V37), a pour stops. `loaded()`: nobody
holds a nozzle (hung back), nothing pours. Saved and joined by its State group.

**The Filter** (`VacuumFilter`, `game/devices/vacuum/vacuum_filter.gd`, a Part, 150-I): `size: int` (-1 any) and
`collection: StringName` (&"" any), saved and in the snapshot; the verb `step {half, by}` (the holder's wheel, only
when `filter_nozzle` is bought); `accepts(design) -> bool` (both halves, either "any"). The Collection list is the
Collections with a loose Sock in the Mess now, Lost Socks when one lies loose, read from the data (core/125); a set
Collection stays set when it runs out and the next step starts from "any" (Q2121-Q2124).

### The hose (looks, every machine)

A rope that drapes over furniture and wraps round door frames, never through walls (V12): Godot's own nodes, not a
tube built by hand each frame (the old weakness). The hose is a skinned tube mesh (the asset, graybox: a cylinder with
bones) whose bones are `PhysicalBone3D`s under a `PhysicalBoneSimulator3D` (Jolt), pinned at the container's top cuff
and at the nozzle's cuff (a joint to an `AnimatableBody3D` that follows the nozzle). Its collision mask is the house
and the furniture and the moving leaves of room Doors, furniture doors and drawers (so they push it, V13); never the
Elevator's car (V13: core/149 names the car's layer). Its length along where it lies is the sum of its bone spans.

- **At its length** (`VacuumTuning.hose` 5 m, `long_hose` +2 m a level): the walker's own machine stops their walk
  away (local: the body is the player's own), and the hose's Looks plays its `tug` clip (0.25 s of shaking) on that
  machine only (Q2698: only the hose shakes). With one player carrying the container and another holding the nozzle
  (V17), whichever walks away is stopped; neither drags the other.
- **The Host's check** reads its own rope plus `host_slack` (1 m), as the old: each machine lays its own (V14). Two
  machines may disagree by a little; the slack covers it.
- **Cost** (V15): bones sleep when the hose is idle; only a vacuum in use, a tug or a moving hose simulates (at most
  `hose_budget_ms` 0.3 ms a physics tick for a held hose: the profiler suite's budget).

### The Sock detector

`Carriable` with `throwable` (the thrown-knock rule) and `handable` (a Hand-off, V40). Its reading is looks, worked
out by **every machine** for whoever holds it (V42): every `update_every` (0.2 s) `DetectorScreen` finds the nearest
LYING Sock in the Mess on any floor from the holder's eyes (this machine's player's camera, or the Teammate's avatar's
eyes), its distance band (`far_m` 10 m, `near_m` 3 m), and whether it lies on another floor (the floor's height
band, `Stage.floor` heights), and tells the Looks: one to three bars in the band's colour, an up or down arrow, or the
bars dimmed when no loose Sock is left. The beep (V43): `beeper_beep` (3D at the model, -6 dB, the ping's pool, Q2698)
at a gap from `interval_near` 0.12 s (within `close_m` 0.5 m) to `interval_far` 1.6 s (from `beep_far_m` 20 m),
linear between; it plays only while held, heard by the holder and anyone near (3D attenuation). Lying, it has no
collision with falling Socks (its body's layer is not in a Sock flight's mask, V45: "no Mess collider").

## How it is authored (Q2607)

- **Typed Resources edited in the inspector** (every number `# placeholder:` the old `data/tuning/*.json` unless a Q
  set it):
  - `VacuumTuning` (`game/devices/vacuum/vacuum_tuning.gd`): `sock_vacuum_tuning.tres` (capacity 24, reach 2 m,
    `cone_deg` 22, `fly_time` 0.2 s, `suck_interval` 0.12 s, `hang_reach` 0.6 m, `spit_tap` 0.25 s, `spit_every`
    0.1 s (Q2698), `spit_reach` 4 m, `spit_speed` 4 m/s, `spit_scatter`, `spit_bodies` 24, `pour_every` 0.15 s,
    `pour_speed` 0.6 m/s, `pour_tilt_seconds` 0.25, `host_slack` 1 m) and `backpack_tuning.tres` (capacity 16, the
    same reach, cone, rate and spit, no pour).
  - `HoseTuning` (`game/devices/vacuum/hose_tuning.tres`): length 5 m, bone count, radius, damping, `tug_seconds`
    0.25, `hose_budget_ms` 0.3.
  - `DetectorTuning` (`game/entities/sock_detector/detector_tuning.tres`): `near_m` 3, `far_m` 10, `update_every`
    0.2 s, `close_m` 0.5, `beep_far_m` 20, `interval_near` 0.12, `interval_far` 1.6, `volume_db` -6, the three band
    colours (green, amber, red: the old `screen_*`).
  - `HoldSlot`s: `hold_slot_vacuum.tres`, `hold_slot_backpack.tres`, `hold_slot_detector.tres` (bigger and closer,
    the old `hold.json` "beeper", Q1857, Q1861-Q1863), `hold_slot_nozzle.tres` (low and right in front of the camera
    along the aim; a Teammate's in their hand along their aim: a new `HoldSlot.follows_aim` field).
  - The suck's look numbers (constants in the old view, a weakness) are the `GPUParticles3D` nodes' own fields in the
    nozzle's Looks (18 streaks of 0.28 s, 14 motes of 0.7 s), edited in the inspector: no Resource of their own.
  - The five vacuum `UpgradeStat`s (150-K): `big_bag` (ADD, base 24, step 12, "%d": the Sock vacuum's capacity; a
    Backpack adds the same over its 16), `suck_interval` (ADD, base 0.12, step -0.02, shown as Socks a second
    "%.1f/s": a new `UpgradeStat.per_second` flag shows 1/value), `long_hose` (ADD, base 5, step 2, "%d m"; nothing for
    the Backpack), `wide_nozzle` (ADD, base 0, step 1, no format: each level adds `VacuumTuning.wide_reach` 1 m and
    `wide_cone_deg` 10 to both vacuums), `filter_nozzle` (FLAG). Set as `stat` on the five existing `.tres` in
    `game/economy/upgrades/`; they stop being "Coming soon".
- **Dropped in with no code change:** a new Sock Design shows in the Tank's heap, the Filter's lists and the
  detector's search (the catalogue, the Mess); a new Collection joins the Filter's Collection list (core/125's data);
  a new hold slot is a `.tres`. Nothing else here is a list a designer grows.
- **Zoo stations, built from the data at load (Q2337):**
  - `game/zoo/stations/vacuums.tscn` (its own things under `game/zoo/vacuums/`): the real Sock vacuum and two
    Backpack vacuums; a small room with a room Door, a table and a drawer to see the hose drape, wrap and be pushed; a
    `SockGenerator` laying the catalogue's Designs loose (a new Design shows with no change); the station's own
    `Upgrades` and `Bank`; a board listing every Upgrade in the folder whose `stat` a `Vacuum` reads, with its level
    and the stat's now -> top, and the two `VacuumTuning`s' numbers; switches: each vacuum Upgrade's level up and
    down (`set_level`), "Refill Socks".
  - `game/zoo/stations/detector.tscn` (`game/zoo/detector/`): the detector; loose Socks at the band edges (0.5, 3,
    10, 20 m) and one on a raised second floor to see the arrow; a board of `DetectorTuning`'s bands; a "Take all
    Socks" switch to see the bars dim.
- **Authored in nodes (Q2658):** the Nozzle display is a small Control scene (`nozzle_display.tscn`: the fill bar,
  the Size word, the Collection's icon and name, the red frame) in a `SubViewport` on the nozzle's pod; the detector's
  screen is a Control scene (`detector_screen.tscn`: three bar panels, two arrows) in a `SubViewport` on its face;
  the hints are the existing prompt rows. Code fills them, never builds a Control or StyleBox.
- **Motion as clips in the Looks (Q2697):** the container's `pour` (tip about 70 degrees forward over 0.25 s, and back);
  the heap's `settle` (a sucked Sock drops onto the top of the heap and settles, played on the arriving Sock's node,
  which then takes its place: the heap's places are `Marker3D`s in the Looks, filled bottom up); the gauge and the
  Backpack's dial needle as a `fill` clip seeked to the Tank's share; the hose's `tug`; the motor's `motor_on` /
  `motor_off` (0.12 s fades keyed on its `AudioStreamPlayer3D`'s volume); the Backpack's `worn` / `lying` (straps
  round the body or hanging loose, the nozzle out of or in its clips); the Nozzle display's `blink` (the red frame
  each half second); the detector's band and arrow states are node visibility set by the view. The streaks and motes
  are `GPUParticles3D` in the nozzle's Looks, emitting while the suction is on.
- **Looks contracts:** each entity's `looks_contract.json` names its nodes and clips (the Sock vacuum: `Body`, `Hook`,
  `NozzleMouth`, `HoseTop`, `Window` heap markers, `Gauge`, `Pod` with its SubViewport, `Streaks`, `Motes`, `Motor`,
  clips `pour`, `settle`, `fill`, `motor_on`, `motor_off`; the hose: `tug`; the Backpack: `Tank` heap markers, `Port`,
  `Dial`, `Straps`, clips `worn`, `lying`, `fill`; the detector: `Screen`, `Speaker`).
- **Sounds** (`sound_catalogue.tres`, the old picks or shares, all added at once by core/154, the batch's groundwork): `vacuum_motor` (3D loop at
  the container), `vacuum_thwip`, `vacuum_spit_tick` (at the nozzle's mouth; the per-Sock sounds 0.09 s apart per
  vacuum: the SoundEvent's own gap), `vacuum_nozzle_hang`, `vacuum_nozzle_drop`, `vacuum_lift`, `vacuum_set_down`,
  `beeper_beep` (shares the ping's pool, Q2698). Taking the nozzle plays the Hands' pick rustle (Q2698). Not carried
  over: the dead `vacuum_mode_click` and `vacuum_spit_out` (removed with tools/25, Q2097, Q2119).

## What each line becomes

| Lines | Draft |
|---|---|
| V1 (the New Game spots), V2 (behind the ground floor's lock), V3 (`tree_tip_vacuum`) | 150-L |
| V4 (the nozzle takes the Hands), V9 (tap: drop or hang), V12 (the hose), V13 (Doors push it; its car half: 150-M), V14 (each machine lays its own), V15 (its cost), V16 (carry the container), V17 (shared carrying, both orders, Q2698), V20 (the load in the hint), V21 (the held hints), V22 (the held nozzle seen), V31 (hang, drop, lift, set-down sounds) | 150-F |
| V5 (the suction), V6 (a Guest's predicted suck), V7 (full), V8 (the refusal reasons; "tilted" with 150-H, "filtered" with 150-I), V19 (the canister's window heap and gauge), V28 (streaks and motes), V29 (the motor), V30 (the thwip; the spit tick with 150-H) | 150-G |
| V10 (the Spit), V11 (the spat-bodies budget), V18 (the Pour) | 150-H |
| V23 (the Nozzle display), V24-V27 (the Filter) | 150-I |
| V32-V39 (the Backpack vacuum) | 150-J |
| V48-V52 (the five Upgrades) | 150-K |
| V40 (carry, drop, Hand-off, leaver), V41 (the thrown knock, Q2700), V42 (the bars), V43 (the beep), V44 (the held look), V45 (no Mess collider, not into the drum: Q2699), V47 (saved and joined) | 150-E |
| V45's ride (Q2699 changed it: it rides like the Radio) | 150-M (core/175) |
| the Sock vacuum and the car (Q2710, Q2711) | 150-N (core/175) |
| V46 (moved into the Drum at the pull) | not drafted: batch D's (Q1891) |
| V53 (the words) | each draft its own words: "Hold: Vacuum", "Vacuum: full", "Drop the nozzle", "Hang the nozzle", "Take the nozzle   %s", "Pick up   %s", "Sock vacuum   %s", "Hands full", "The hose won't reach" (150-F, 150-G); "Hold: Spit out", "Hold: Pour out", "Put down" (150-H); "Up: Size  Down: Collection" (150-I); "Backpack: full", "Put it on", "Take it off" (150-J); "Sock detector" (150-E); the Upgrades' names and tooltips (exist) |

The behaviour list's "not ported" stay out (Q2599: the Splitter and its four Upgrades, the pairing machine's feed,
the Wide Funnel, the Hampers' pour; tools/25's removals).

## Saves, joins and co-op

Nothing writes save code: `Vacuum`, `VacuumFilter` and the three `Carriable`s are saved and joined by their State
groups (`docs/architecture/saves.md`); the Tank's Socks are HELD records of the Mess's snapshot. A Guest's held nozzle
is saved hung, their worn or carried Backpack lying where they stood with its load (V38), their detector likewise
(V47). The save tests' `shape.json` grows the new Parts.

- **Who decides:** the Host, every verb above (scene parts; `coop-structure-for-the-port.md` "Devices": one Part each,
  Host timers, Host-only Commands; the hose stays local).
- **Prediction is looks only** (V6, V39): a Guest's suck flies a ghost of the Sock to its nozzle at once (the
  `GuestGhosts` pattern, coop/09); the Host's answer confirms it (the Sock is HELD in the Tank) or the ghost lands
  back where the Sock lies. A Guest's spit and pour wait for the answer, as the old.
- **Who sees what:** the suction's look (streaks, motes, motor) on every machine from the holder's `pose_suction`, a
  new avatar pose flag (on while their left button is held with a nozzle, and the Tank not full), as the old pose
  carried it (V28: "a teammate's comes with their pose"); the Pour's tilt from `pour` (decided); the held nozzle in
  the Teammate's hand along their synced aim (V22); a worn Backpack on their back (V36); the detector's reading and
  beep worked out on each machine for whoever holds it (V42, V43).
- **Shared numbers:** House Upgrades are read when used (`Upgrades.value`), never cached at ready: a bought Big Bag
  grows every vacuum at once, a late joiner's too.

## Seams to the other pieces

- **core/78 (`Carriable`, `Hands`):** `Hands.TAKERS` (150-F); `throwable`, `radius`, `throw`, `land`, `bounce`,
  `flight`, the lost-thing return and the held thing's input (150-A). The Hand-off's aim, the place check, the put's
  ease and the leaver's lay are reused as they are.
- **core/139 (the book's one-slot item):** the book counts as held for every whole-Hands pick (refused "Hands full");
  the nozzle's take lays it round the feet with the Socks. The detector's New Game spot is 0.35 m beside the book,
  turned 20 degrees (150-L reads the book's placed spot in `house.tscn`).
- **coop/10 (the knockdown):** `Knockdowns`' hit test reads the Carriables in the air (150-A); a knocked player lets
  go as a leaver (the nozzle hung, a Backpack dropped beside them, V37).
- **core/129 (the Upgrade grid):** the five stats (150-K); `UpgradeStat.per_second` (one field, one line in
  `text_at`).
- **core/132, core/133 (the Old Tree):** `tree_tip_vacuum` is a trigger file, its three recordings (copied by core/132)
  and its JSON entry, due once per player per run when the ground floor opens, said when they are near: the field
  core/133 gives the tips, on the ground floor's Stage `.tres` (150-L). No code if core/133's tips are data as its
  ticket says.
- **core/149 (the Elevator's carry rule), this side only:** the container, a lying Backpack, the detector (Q2699) and
  the Radio are `Carriable`s lying in the car, carried by core/149's one item rule (they need nothing more than a
  writable `at`, which they have); a lying detector or Radio keeps working on the ride. The hose's mask leaves out the
  car's layer, so the car never pushes it (V13). A rider keeps what they hold (list 11). The container rides only
  with its nozzle on its hook (Q2710): `Vacuum` answers the carry rule's `may_ride()` (core/149's `Carriable`) with
  `nozzle_at == INF`, so with the nozzle out the container stays at its stop. The nozzle's holder may climb into the
  car with the container outside (Q2711): nothing stops it; while the holder rides and after, the hose is drawn
  stretched from the container's cuff to the nozzle's, through the shaft, its bones laid along the line with their
  collision off until the nozzle is back within the hose's length of the container, as the old drew a straight tube
  (VV); the length rule and the Host's checks stay as they are (VA:383-450 measures only sucks and drops). core/175.
- **core/151 (the Cat):** the whole-Hands rule and the thrown-knock rule are the Cat's too; the Cat sets `throwable`
  on its Carriable and needs no other code from this doc. Its own side (held in the world at the hands, Q2703) is
  core/151's.
- **core/128 (the Wardrobe):** a worn Wardrobe backpack is hidden while a Backpack vacuum is worn (V36): a new
  `WardrobePiece.on_back` field set on the four backpack pieces (`backpack`, `balloon_backpack`,
  `bubble_tea_backpack`, `fruit_basket_backpack`), and the Dresser hides `on_back` pieces while its player wears one
  (150-J).
- **The Mess (core/13, coop/08):** the Tank's Socks are HELD records (`held_patch`); the Spit and the Pour are released
  bodies (`thrown_patch` with `drop`), counted against `spit_bodies` (24) of the released bodies (V11); a spat Sock
  starts on the room's side of a wall (the Hands' throw's start check).
- **Batch D:** the detector moved into the Drum at the pull (V46); the pad bindings of the Spit, the Pour and the
  wheel (Q2698).

## Changed technically from the old (no choice: tell the designer at the sitting)

- Each device is a Part with its own verbs, not plain data on the Game with a Command prefix.
- The hose is a physics rope of Godot's own nodes (`PhysicalBone3D` on Jolt) over a skinned mesh, not a tube mesh
  built by hand each frame (VV, 1378 lines).
- The Backpack and the Sock vacuum are one `Vacuum` Part in two modes; the Backpack no longer calls into the Sock
  vacuum's view for its suction.
- The Tank holds the Socks' own Mess records (HELD), not copies of their Designs.
- The detector's screen is a Control scene in a SubViewport, not plain meshes laid over the model.
- The suck's look numbers are the particle nodes' own fields, not constants in a view.

## Asset drafts (Q2705: the port rules, one family each, look work)

Each: the old `tools/blender/make_*.py` (or `assets/vacuum_devices/make_*.py`) re-made as the game's
`tools/blender/<asset>.py` by the Blender skill; technical improvements only (origins, scale, names, collision, shared
materials, file size); the old colours; its Looks scene passes `kit/tools/asset_lint.py` and its `looks_contract.json`
(above); a before-and-after strip in `<main checkout>/builds/review-<family>/`; **stops at its first line-up**
(`status: ready-for-human`) and waits for the designer's go (the `review-material` skill). Swapping the Looks in is
the same ticket after the go. Suggested model: opus (Blender).

- **AS-C2-1 The Sock vacuum** (`make_sock_vacuum.py`; `assets/vacuum_devices/make_nozzle_display.py` for the nozzle's
  pod, named by Q2705 beside it): the mint canister of the retro appliance family, the capsule window, the gauge slot,
  the parking clip, the nozzle, the hose's cream ribbed tube with chrome cuffs (re-made as a skinned tube with bones
  for the rope), the pod.
- **AS-C2-2 The Backpack vacuum** (`make_backpack_vacuum.py`, `vd_common.py`): the capsule tank, porthole, straps, the
  port, the nozzle with its dial gauge; its worn and lying poses as the `worn` / `lying` clips.
- **AS-C2-3 The Sock detector** (`make_sock_detector.py`): the flat handheld gadget whose screen fills almost all its
  face plate.

(AS-C2-4 the TV and AS-C2-5 the Radio are in `tv-and-radio.md`.)

## Build drafts (filed by core/153; each heading names its ticket)

Every core draft builds on graybox Looks and waits for no asset; every number `# placeholder:` the old unless a Q
set it. Every old detail of its lines is built (Q2277); one left out goes to the lead before the merge. Real paths
drive player input through the scene's own wiring (`kit/docs/TESTING.md` "The real path").

**150-S The devices' groundwork: sounds and station shells** (sonnet; filed as the whole batch's groundwork, core/154)
- Lines: none of their own; it gives every later draft its sounds and stations so none of them edits
  `sound_catalogue.tres` or `zoo.tscn`.
- Build: the SoundEvents of both docs in `game/audio/sound_catalogue.tres` with the old files copied into
  `assets/audio/` and credited in `assets/audio/SOURCES.md` (`vacuum_motor`, `vacuum_thwip`, `vacuum_spit_tick`,
  `vacuum_nozzle_hang`, `vacuum_nozzle_drop`, `vacuum_lift`, `vacuum_set_down`, `beeper_beep` sharing the ping's pool;
  `device_click`, `tv_static`, `radio_static`, `tv_puppets`, `tv_shop`, `tv_news`, `tv_testcard`, `radio_land`); if
  core/149 adds `device_click` for the Elevator's button first, reuse it. Three station shells in
  `game/zoo/stations/` (`vacuums.tscn`, `detector.tscn`, `tv_radio.tscn`: a floor, a `ZooLabel`, a Spawn) instanced
  by hand under `Stations` in `zoo.tscn`.
- Acceptance: real path: in the Sounds station (built from the catalogue at load) the player walks to the
  `vacuum_thwip` pillar and presses E; it plays (the station's own wiring). The three shells load in the zoo; the
  wiring check passes. Placeholders: the sounds the old marked placeholder.
- `suites: [sounds, sound_wiring, zoo]`
- Authored: SoundEvents in the catalogue (the Sounds bench swaps any); stations are scenes.

**150-E The Sock detector** (opus; after 150-A; filed: core/167)
- Lines: V40, V41, V42, V43, V44, V45 (no Mess collider; not into the drum, Q2699), V47; its word "Sock detector".
- Build: `sock_detector.tscn` (`Carriable` `throwable` and `handable`, `hold_slot_detector.tres`), `DetectorScreen`,
  `detector_screen.tscn` in a SubViewport, `DetectorTuning`, graybox Looks and contract; the detector station filled.
- Acceptance: real path: in the detector station the player left-clicks the lying detector, walks toward a loose Sock
  3 m away and the screen shows three red bars and `beeper_beep` plays at about 0.12-0.6 s gaps; right click aimed
  at the floor puts it down. A Throw at full charge at a Teammate knocks them down (co-op case); a weak one drops at
  their feet. With the Hands holding a Sock the pick reads "Hands full". A Sock on the raised floor shows the up arrow;
  "Take all Socks" dims the bars. Saved and joined (carrier, spot, turn, flight). A falling Sock passes through it.
- `suites: [carry, coop_carry, knockdown, coop_knockdown, save, zoo]` (a new `detector` suite for its reading)
- Authored: `DetectorTuning` and the hold slot in the inspector; the screen in nodes; Looks graybox, then AS-C2-3.

**150-F The Sock vacuum: the nozzle, the hose and the container** (opus; after 150-A; filed: core/168)
- Lines: V4, V9, V12, V13 (the Doors), V14, V15, V16, V17, V20, V21, V22, V31; the words of these lines.
- Build: `sock_vacuum.tscn` with the container's `Carriable`, `Vacuum` (take and put the nozzle, the Tank empty for
  now, `left`, `loaded`), `Hands.TAKERS` in `hands.gd`, the hose (`PhysicalBoneSimulator3D` rope, `HoseTuning`,
  `tug` clip), `hold_slot_vacuum.tres`, `hold_slot_nozzle.tres` with `HoldSlot.follows_aim`, the hints, the four
  sounds; the vacuums station filled (the room, Door, table, drawer). **Spike first:** the rope pinned at both ends
  through a door frame at the hose budget; if `PhysicalBone3D` cannot do it, a chain of `RigidBody3D` capsules with
  `ConeTwistJoint3D`s is the fallback, the rest unchanged.
- Acceptance: real path: in the vacuums station the player left-clicks the hung nozzle (two Socks in the Hands fall
  round their feet), walks through the Door with it, and the hose lies through the door frame; walking 5 m along the
  hose the walk stops and `tug` plays; a right tap within 0.6 m of the hook hangs it ("Hang the nozzle"), one past
  the hose's length reads "The hose won't reach". The Door closed on the hose pushes it. Co-op: one carries the
  container while the other holds the nozzle, both orders; whichever walks away is stopped; a leaver's nozzle hangs
  itself. The profiler budget holds with a held hose; an idle one costs nothing.
- `suites: [carry, coop_carry, handling, hand_details, room_doors, profiler, save, zoo]` (a new `vacuum` suite)
- Authored: `VacuumTuning`, `HoseTuning`, the slots in the inspector; Looks graybox (a canister, a hook, a nozzle, a
  boned tube), then AS-C2-1.

**150-G The suck** (opus; after 150-F; filed: core/169)
- Lines: V5, V6, V7, V8, V19, V28, V29, V30 (the thwip).
- Build: `suck` with its refusals and rate; the Tank's HELD records; the fly to the nozzle (looks, `fly_time`); the
  heap's places and `settle`, the gauge's `fill`; `pose_suction` on the avatar (`avatar.gd`, `avatar.tscn`); the
  Guest's ghost suck (`guest_ghosts.gd`); streaks, motes, `motor_on` / `motor_off`, `vacuum_thwip`. The hooks the next
  drafts fill without editing `vacuum.gd`'s suck: a sibling `VacuumFilter` asked `accepts(design)` when present, the
  wheel forwarded to it, a "tilted" check that reads `pour`.
- Acceptance: real path: in the vacuums station the player holding the nozzle aims at loose Socks and holds the left
  button; the nearest in the 2 m, 22-degree cone flies in one every 0.12 s, the heap grows in the window and the
  hint reads "Sock vacuum   n/24"; a Pair, a held Sock and a shelved Sock are never taken; at 24 it stops ("Vacuum:
  full"), the motor running on with no other sound. Co-op: a Guest's suck flies at once; refused (the Sock taken by
  another first), the ghost lands back; the Teammate sees the streaks and hears the motor.
- `suites: [coop_hands, coop_mess, mess, teammates, avatar, zoo]` (the `vacuum` suite)
- Authored: the particles' fields and the clips in the Looks; the numbers in `VacuumTuning`.

**150-H The Spit and the Pour** (opus; after 150-G; filed: core/170)
- Lines: V10, V11, V18; V8's "tilted"; V30's spit tick; the words "Hold: Spit out", "Hold: Pour out", "Put down".
- Build: `spit` (from the holder's right hold past `spit_tap`, oldest first, ignoring the Filter, a scatter, the
  room's side of the wall, the 24-body budget), `pour` with the Host's timer and the `pour` clip, the "tilted" pause
  of a teammate's suction, `vacuum_spit_tick`.
- Acceptance: real path: in the vacuums station with 10 Socks in the Tank, the holder holds the right button aimed
  at the floor 3 m away; Socks leave the nozzle one every 0.1 s and land round the aim; the release drops nothing
  more. The carrier of the container (nozzle hung) holds E: it tips, one Sock falls over the lip every 0.15 s until
  released; a Teammate's suction pauses while it is tilted (co-op). With 24 released bodies in the air the stream
  waits.
- `suites: [coop_flight, mess, throw, zoo]` (the `vacuum` suite)
- Authored: `VacuumTuning`'s spit and pour numbers; `pour` is a clip.

**150-I The Filter nozzle and the Nozzle display** (opus; after 150-H; filed: core/171)
- Lines: V23, V24, V25, V26, V27; V8's "filtered"; the words "Up: Size  Down: Collection".
- Build: `VacuumFilter` (state, `step`, `accepts`), the Collection list from the Mess's loose Socks and the data;
  `nozzle_display.tscn` in the pod's SubViewport (the fill from the start, Q2187; the Size and Collection once
  `filter_nozzle` is bought), its `blink` clip while a set Filter matches nothing in front of the nozzle.
- Acceptance: real path: in the vacuums station with Filter nozzle bought (the station's switch), the holder rolls the
  wheel up to a Size and down to a Collection; the pod shows both; holding the left button sucks only Socks matching
  both; aimed where nothing matches, the red frame blinks. Without the Upgrade the wheel does nothing and the pod
  shows only the fill. The Filter is saved and joined, shared by whoever holds the nozzle (co-op).
- `suites: [save, coop_join, zoo]` (the `vacuum` suite)
- Authored: the display in nodes on the Theme; the lists from the catalogue and the Collections (a new Collection
  shows with no change).

**150-J The Backpack vacuum** (opus; after 150-H; filed: core/172)
- Lines: V32-V39; the words "Backpack: full", "Put it on", "Take it off".
- Build: `backpack_vacuum.tscn` (`Carriable`, `Vacuum` in `wearable` mode, `backpack_tuning.tres`), `wear` /
  `unwear`, the worn views (the wearer's nozzle with its dial, a Teammate's tank on the back with its hose to the
  nozzle, `worn` / `lying`), `WardrobePiece.on_back` on the four backpack pieces and the Dresser's hiding, two
  Backpacks in the vacuums station.
- Acceptance: real path: in the vacuums station the player left-clicks a lying Backpack with empty Hands, presses E
  (it is worn, "Take it off [E]"), holds the left button at loose Socks and they fly in to 16 ("Backpack: full"); a
  right hold spits them; E takes it off into the Hands, a right click puts it down. Co-op: another player's pick of a
  carried one is refused; a Teammate sees it on the wearer's back and the wearer's Wardrobe backpack hidden; knocked
  down, the wearer drops it beside them with its load; saved and joined.
- `suites: [carry, coop_carry, wardrobe, wardrobe_looks, knockdown, save, zoo]` (the `vacuum` suite)
- Authored: `backpack_tuning.tres`; Looks graybox, then AS-C2-2; the piece flag in the inspector.

**150-K The five vacuum Upgrades take effect** (sonnet; after 150-I and 150-J; filed: core/173)
- Lines: V48-V52.
- Build: the five `UpgradeStat`s in `game/economy/stats/`, set on the five Upgrade `.tres`; `UpgradeStat.per_second`;
  `Vacuum` reads capacity, interval, hose, reach and cone through `Upgrades.value` when it uses them; the real Old
  Tree (`old_tree.tscn`) placed in the vacuums station beside its own `Upgrades` and `Bank`.
- Acceptance: real path: in the vacuums station with 5 Drawers the player presses E on the Old Tree, clicks Big Bag
  (it reads "1/2"), closes the menu, takes the nozzle and holds the left button at 40 loose Socks: the Tank stops at
  36 ("Sock vacuum   36/36"); a Backpack then fills to 28. The cards read "24 -> 36", "8.3/s -> 10.0/s", "5 m ->
  7 m"; none of the five is "Coming soon" any more. Long Hose lets the walk go 7 m; Wide Nozzle takes a Sock 2.8 m
  away at 30 degrees.
- `suites: [upgrades, economy, zoo]` (the `vacuum` suite)
- Authored: the stats are `.tres` (a new effect is a file plus one line in `Vacuum`).

**150-L The devices in the house** (sonnet; after 150-J, core/139, core/133; filed: core/174)
- Lines: V1, V2, V3; R1 and R15's New Game (with `tv-and-radio.md`).
- Build: in `house.tscn` the Sock vacuum in the kitchen, two Backpacks beside it, the detector on the workshop's
  workbench 0.35 m beside the book turned 20 degrees, the TV in the living room in front of the north window, the
  Radio on a kitchen shelf (both from 150-B and 150-C); a New Game puts each back; `tree_tip_vacuum`'s trigger file and
  its field on the ground floor's Stage.
- Acceptance: real path: in the house at a New Game the player walks to the workbench and left-clicks the detector
  beside the book; it is in their Hands. With the ground floor locked the kitchen's vacuums are behind its lock; once
  it opens and the player walks near the Old Tree, the vacuum tip is said once (subtitle), not again that run. The
  Radio plays Theme from the New Game.
- `suites: [house, floor_lock, voice, stages, save]`
- Authored: placed by hand in the editor; the tip is data.

**150-M The devices ride the Elevator** (after 150-L and core/149's carry-rule draft; filed with 150-N as core/175)
- Lines: V45's ride (Q2699), V13's car half, R30.
- Build: nothing new if core/149's item rule moves every lying `Carriable` in the car: cases only, and the hose's mask
  leaving out the car's layer.
- Acceptance: real path: in the house with Elevator Repair bought, the player puts the detector and the Radio into the
  car and presses the call button on the other floor; both arrive lying in the car, the Radio still playing. A lying
  Backpack rides too. The car moving past a lying hose does not push it.
- `suites: [house, carry]` (core/149's elevator suite)
- Authored: nothing new.

**150-N The Sock vacuum and the Elevator** (answered Q2710, Q2711; filed with 150-M as core/175, opus)
- Lines: none of list 09 (the gap Q2699 left, answered).
- Build: `Vacuum.may_ride()` (true only with the nozzle on its hook) read by the carry rule; the hose drawn stretched
  across floors while its nozzle's holder rides or stands beyond the hose's reach on another floor (above).
- Acceptance: real path: in the house with Elevator Repair bought, the container in the car with its nozzle hung rides
  to the other floor on a call; with the nozzle out it stays at its stop. A player holding the nozzle presses Space at
  the open car: they climb in, ride, and the hose is seen stretched through the shaft on both machines; nothing is
  refused.

## Waves

Superseded by the batch's one build order, `docs/migration/milestones.md` "Batch C" (core/153), which merges the four
designs' waves. The clashes it keeps apart: `house.tscn` (150-L; core/149's Elevator, day and
exterior; core/151's Cat and litterbox), `zoo.tscn` and `sound_catalogue.tres` (only
core/154, the groundwork, edits them), `carriable.gd` and `knockdowns.gd` (150-A; core/149's
rider exemption, core/151's Cat), `hands.gd` (150-F; core/151 if the Cat touches it), `avatar.gd` / `avatar.tscn`
(150-G; core/149's riders' curl), `player.gd` (150-A; core/149's ride input), the Upgrade `.tres` folder (150-K; core/149's
three Elevator ones, core/152's eight X-ray ones: different files, but `upgrade_stat.gd` only once). Batch B's
core/139 (the book) must be merged before 150-L, core/133 (the tips) before 150-L's tip, core/130 before 150-A's
Throw reads `charge_time` and `throw_speed`.

## Gotchas for the build

- The three entities are placed Parts: renaming or moving one in `house.tscn` once a build is shared breaks saves
  and the join gate (the layout hash).
- `Hands.carries()` returns a `Carriable` today; with `TAKERS` it returns a Part. Every caller that reads Carriable
  fields from it must check the type.
- The Tank's Socks are HELD but in no Hands: anything that walks `Mess` HELD records to find their Hands (the Sole cues,
  the Hand-off) must skip ids a `Vacuum` holds.
- A spat or poured Sock is a released body, not a Throw: `Knockdowns` must not catch or knock with it (check
  `Mess.is_throw`).
- House Upgrades change every vacuum at once: read `Upgrades.value` when used.
- The rope's two pinned ends and Jolt's sleeping must not wake each tick while idle (the budget).
- `ResourceLoader.list_directory()` (4.4+) for any folder the stations list, so an export finds remapped files.
