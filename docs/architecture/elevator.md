# The Elevator and its riders

**Status: build plan for batch C (designed in core/149 on the designer's answers Q2699, Q2700, Q2702, Q2705, with
Q2710 and Q2711 for the Sock vacuum in the car; 2026-11-26). Filed by core/153: 149-A core/155, 149-C core/156, 149-D
core/157, 149-E core/158, 149-F core/159, AS-L assets/21; every sound and the station's shell come with the batch's
groundwork, core/154. The build order is `docs/migration/milestones.md` "Batch C".** Behaviour list:
`docs/migration/m4-lists/11-elevator.md` (46 lines). The day cycle and the exterior, designed in the same ticket:
`docs/architecture/day-and-exterior.md`. Batch C is built
unattended and reviewed in play as a whole, as batches A and B were (Q2603-Q2605).

## What it owns

The Elevator as decided state: where the car stands or rides, its hatches, the calls and the sends, the
Host's timers for the hatch and the ride, the refusals (out of order, locked, full); what rides in the car, by
**one carry rule** for every thing (Q2699); the riders (climbing in and out, the curl, the low dim view, two in the
car, a dragged body, the floor letters); the Elevator's sounds; the three Elevator Upgrades' effects; the Old Tree's
`tree_tip_elevator` trigger; what a World keeps of all of it.

It does not own the floor locks or `HouseLights` (core/80, built: it reads them), the Upgrade grid or the `buy` verb
(core/129, built: it gives three Upgrades their `stat`), the Old Tree's tips machinery (core/133), the Cat's naps
(core/151: the Cat is one more thing in the car, by the same rule), the devices and the Radio (core/150: carried
things, by the same rule), knockdown and Drag (`Knockdowns`, built: it reads who is down and who drags whom), or the
Secrets (Elevator Duet waits with the others, Q2682). Where they meet it, it names the seam.

## The shape

One entity, `game/entities/elevator/elevator.tscn`, placed once in `house.tscn` at the shaft (house-kit-plan K09:
inside x 3.24..3.94, z 4.8..5.5) and once in its zoo station. It holds:

- **`Elevator`** (`game/entities/elevator/elevator.gd`, a Part, on the root): the car, the riders, every verb. Saved
  and joined by its State group. One Part, not three: the old split the car (`ElevatorRules`), the riders (`Rides`)
  and the Cat's nap across three records that read each other (weak point 1); here the riders are the car's state
  and the Cat is cargo.
- **`Car`** (a Node3D the Elevator moves from stop to stop; its child `Looks` is the car's Looks scene): the car's
  floor and walls (a StaticBody3D), `CarBox` (an Area3D whose box is what rides, `SillBox` the strip over the open
  hatch's sill), the seats (`Seat1`..`Seat3`, each with its `Eyes` marker), and the floor letters' column (`Letters`, a
  VBoxContainer-like Node3D the Elevator fills at ready, one `elevator_letter.tscn` per stop, B at the bottom).
- **The stops** (`elevator_stop.tscn`, one child per floor, placed by hand at the floor's height, `floor` set in the
  inspector): the hatch (an `Openable` whose leaf is an AnimatableBody3D, so the slide pushes Socks as a Door does,
  core/13), the brass call button, the padlock sign and the "OUT OF ORDER" plaque, each in the stop's Looks.
- **`ElevatorControl`** (`game/entities/elevator/elevator_control.gd`, a Part with no state, the old button, hatch and
  letter in one script): `floor`, `kind` (BUTTON, HATCH, LETTER), its prompt and refusal words; `use()` asks the
  Elevator. One script for the three clickable kinds because they differ only in the verb they ask and their words
  (Q2251-Q2253: a thing gets a script only when no Part can do the job).

Everything else is a view of the Elevator's state: the car's position, the hatches' clips, the plaques, the
padlocks, the lit letter, the riders' seats and the ride view.

### The kinds of state (`coop-structure-for-the-port.md`)

| What | Kind | Where |
|---|---|---|
| where the car is, is bound, its phase and timer; the riders and the dragged bodies | decided state | the `Elevator` Part |
| each hatch open or shut | decided state | the stop's `Openable` (`open`; `keeps_open_on_load`), written only in the Elevator's answers |
| Socks and floor Pairs in the car | the Mess | moved by the Mess's own patch in the Elevator's answer |
| a carried thing in the car (the book, the Radio, the detector, a Machine Part) | decided state | its `Carriable` (`at`), patched in the same answer |
| the Cat in the car | decided state | the Cat's Part (core/151), patched in the same answer |
| a rider's avatar | the player's synchronizer, overridden | while riding every machine draws it at its seat from decided state; only its look (yaw, pitch) is read from the sync |
| a climb, the curl, the squeeze, the dim, the shake, a hatch slide, the creak's place | looks | clips in Looks, started from applied answers |

### `Elevator`'s state

| Field | Meaning |
|---|---|
| `stop: int` | the floor (`HouseLights.floors` index: 0 basement, 1 ground, 2 first, 3 attic) the car is drawn at: where it stands, the one it is leaving while its hatch shuts, the one it is bound for once it departs (no car is seen moving, Q2702) |
| `bound: int` | the floor it is bound for; -1 while it stands |
| `phase: int` | `OPEN` (standing, hatch open), `SHUT` (standing, hatch shut), `CLOSING` (the hatch slides shut before it departs), `RIDING` |
| `from: int`, `progress: float` | where the ride began and how many floors of it are done, for the newest call to turn it (Q513) and for the creak's place |
| `left: float` | seconds left of `CLOSING` or `RIDING` as of the answer; `save_state()` gives the live value, so a load or a join resumes the ride where it got (the old "how far it got", Q991) |
| `riders: Array[int]` | player ids in seat order (`Seat1` first) |
| `dragged: Dictionary` | dragger id -> the knocked-down body's player id; the body sits in the next seat and counts as a rider (Q836, Q984) |

A New Game: `stop` 1 (the ground floor, the kitchen), `phase` OPEN, empty (Q2702; the old `home` 1). The fields are
all in core/149-A, so `tests/saves/shape.json` changes once.

### Its verbs (`Parts.ask`, decided on the Host)

| Verb | Who | What it decides |
|---|---|---|
| `call {floor, hatch}` | a player through a stop's BUTTON or HATCH | refused (below) or: the car stands at `floor` with its hatch shut -> the hatch opens (the button never shuts it, Q2702); stands elsewhere -> `CLOSING` (its open hatch slides shut, `hatch_time`) bound for `floor`; rides or closes -> the newest call wins: bound for `floor` from where it got (Q513); every cargo Part's `called_patch` (the Cat wakes, core/151) |
| `hatch {floor}` | a player through the HATCH of the floor the car stands at | the hatch opens or shuts ("Open the hatch" / "Shut the hatch", Q533) |
| `send {floor}` | a rider through a LETTER | as `call`, granted to riders alone (Q988) |
| `climb_in` | a player aiming into the open car with Space | refused or: the asker joins `riders` (with the body they drag, `dragged`) |
| `climb_out` | a rider with Space while the car stands open | the asker (and the body they drag) leaves `riders` |
| `depart`, `arrive` | Host only: the Elevator's own timers (`hatch_time`, then `floor_time` a floor x the Fast Elevator stat) | `depart`: what lies in `CarBox` or on `SillBox` rides (the carry rule below), the car's `stop` becomes `bound`, `RIDING`; `arrive` (the old `elevator_arrive`): `OPEN` at `bound`, the hatch there opens, every rider climbs out (Q2702) |
| `open_hatch {floor}` | Host only, for another Part's Host code: the Cat opening a shut hatch from inside after `car_shut_seconds` (core/151) | the hatch opens |
| `everyone_out` | Host only: the First wash's end (the old rogue sequence's end, Q759; core/94's signal) | every rider out |

**Refusals**, each read by the asker as a Refusal (the old words): a call or send while Elevator Repair is not bought
in a Run: "Out of order (needs the Elevator Repair upgrade)"; to or from a locked floor (the called floor or the
clicked stop's, `Stages.floor_open(floor)` false; before the ground floor opens the whole Elevator is locked):
"Elevator locked"; `climb_in` when the car is not open, the asker is beyond `reach` of the open hatch, down or in the
drum, or there is no seat (`seats` + the Roomy Car stat, a dragger needing two) or a cargo Part `fills_car()` (the Cat
asleep inside): "Elevator full" for no seat or the Cat, the out of order and locked words as above; a wrong floor or a
send from a non-rider is refused silently. A level with no `Stages` (the zoo, a practice) is never out of order and
has no locked floor; a level with no `Upgrades` reads Elevator Repair as bought.

`accepts()`: `call`, `hatch`, `send` `{floor: int 0..3}` at 4 a second; `climb_in`, `climb_out` `{}` at 2 a second;
the Host-only verbs are not accepted from a Guest. A Guest's click waits for the answer (the round trip); its
button sound is played from the answer, on every machine.

### Signals (every machine, from applied answers): the seams

| Signal | Who plugs in |
|---|---|
| `hatch_moved(floor, open)` | the stop's Openable plays its clip and `hatch_open` / `hatch_close` (its own sounds) |
| `departed(from, to)` | the creak (every `creak_every` s at the shaft, between `from` and `to` by the ride's time), the riders' ride view; the Cat (core/151) |
| `arrived(floor)` | the bell at that stop; the Cat wakes on that floor (core/151) |
| `climbed(player, into)` | the seat's clip; the ride view on the climber's machine; the squeeze when a second rider comes |
| `refused(player, words)` | the kit's Refusal (as every refused Command) |

## The one carry rule (Q2699; the old `carry_along` had a branch per kind)

Whatever lies in the car when it departs rides it; nothing else does. The rule names no kind of thing:

1. At `depart` the Elevator asks every Part in the group `elevator_cargo` for `rides_patch(box: AABB, sill: AABB,
   delta: Vector3, onto: Dictionary) -> Dictionary`: each owner moves what of its own lies in `box` (or on `sill`,
   pushed into the box) by `delta` (from the stop's height to the bound one's), and returns the patch. All of it is one
   answer with the car's move, so it is never seen half moved, cut or lost.
2. The members today: the **Mess** (its records lying in the box, Socks and floor Pairs, through a new
   `Mess.rides_patch`; a Moving Sock in the box is laid at its pose first; at `arrive` the Mess wakes those records
   so they settle as the hatch opens), and every **`Carriable`** (one implementation in `carriable.gd`: when nobody
   holds it, `at` is in the box or on the sill and no sibling's `may_ride()` says no, `at += delta`, clamped into the
   box; the Sock vacuum's container says no while its nozzle is out, Q2710). So the encyclopedia book,
   the Machine Parts, the Laundry bins, and core/150's Radio and detector (Carriables) ride with no line of theirs.
   The **Cat** (core/151) joins the group with its own `rides_patch`.
3. Three optional methods of the same group, read with `has_method`: `fills_car(box) -> bool` (the Cat asleep in the
   car: no rider may climb in, "Elevator full"), `called_patch(box, onto) -> Dictionary` (a call wakes the Cat, who
   then rides and wakes at the arrival, Q1982-Q1984), and `car_opened(box)` (Host only, after the `arrive` answer is
   applied: the Mess wakes its records in the box so they settle as the hatch opens).
4. While the car rides, what is in it lies still at the bound stop behind the shut hatch: lying records and lying
   Carriables do not simulate, so "frozen" needs no code. While the hatch slides shut, its AnimatableBody pushes the
   Socks on the sill into the car (the Doors' push, core/13); a Carriable on the sill is clamped in at `depart`.

A new carried thing is a `Carriable` (rides at once) or a Part that joins the group with `rides_patch`: no change here.

## The riders (house/35; Q2702 keeps them)

- **Climb in** (Space aimed into the open car: the corner hint "Climb in [Space]"; the `jump` action, no new input):
  the Player's jump asks the aimed Elevator first. On the answer every machine plays the seat's `climb_in` clip on the
  rider's avatar (shrink to 0.33, hop over the sill on a 0.3 m arc, turn to face out, curl 70 degrees, 0.8 s); the
  avatar is drawn at its seat from then on, its look (yaw, pitch) from the sync on top of the curl (Q1134); a
  knocked-down body faces out and only curls. Joins and loads draw riders curled at once (Q991).
- **The rider's own view:** first person from the seat's `Eyes` (0.3 m over the car floor), framed by the walls; its
  own body hidden once curled; while the hatch is shut the `ride_view.tscn` overlay plays `dim_in` (to 0.6 dark over
  0.4 s) and the camera's shake node plays `ride_shake` (12 mm) until the arrival; the ride's rumble loop
  (`elevator_ride`, flat) for the rider alone from the hatch shutting to the arrival. Movement input moves nothing;
  the Hands keep what they hold (Q835); Space climbs out where the car stands open ("Climb out [Space]").
- **Two in the car** (`seats` 2, 3 with Roomy Car; a dragger counts with the body they drag): the second squeezes in,
  both play `squeeze` (0.25 over 0.7 s, three dying wobbles), the view jostles, `elevator_squeeze` at the car.
- **A dragger** climbs in with the body: the body is lifted from lying to standing at the hatch (`lift`, 0.5 s), then
  climbs as a creature does; the drag holds through the ride; at the climb out the body comes out with its dragger,
  half as far out, and falls where it comes out (Q984).
- **The letters** (a column on the car's +z side wall, B at the bottom, A on top, Q2702): only riders aim at them, and
  a Teammate in the car does not block the aim; a left click or E sends the car ("Send the Elevator to the first
  floor"); the car's floor's letter plays `lit` (warm amber, readable in the dim), a locked floor's plays `locked`
  (dark with a red ring) and reads "Elevator locked".
- **Out:** every rider climbs out at the arrival (Q2702) onto the floor `exit_gap` 0.8 m in front of the hatch
  (`climb_out`, the climb backwards); a rider who leaves the game is out (the Elevator's `left()`); `everyone_out` at the
  First wash's end. No climb sound (Q2702).
- **A Throw never knocks a rider down** (Q2484, Q2700): `Knockdowns` refuses the knock when the target rides.

## Locked and out of order

- In a Run, until the House buys Elevator Repair, every stop's Looks plays `out_of_order` (the plaque with red
  printed letters, not floating text, Q1350) and calls and climbs are refused so. When it is bought
  (`Upgrades.bought`), every stop plays `repaired` (the plaque goes) and the padlocks show where a floor is still
  locked.
- A locked floor's stop shows its padlock sign and its letter its `locked` clip; when the floor opens
  (`Stages.floor_opened`), its padlock plays `unlock` as the floor locks' do (`stages.md` "The floor locks"). This is
  core/80's seam "the Elevator's stops read `floor_open(floor)`".
- A load or a join shows the end pose of each (`_show(now)`).

## How it is authored (Q2607)

- **Typed Resources edited in the inspector** (every number `# placeholder:` the old, `data/tuning/elevator.json` and
  `ride` in the old):
  - `ElevatorTuning` (`game/entities/elevator/elevator_tuning.tres`): `hatch_time` 0.5 s, `floor_time` 2.0 s,
    `creak_every` 0.7 s, `reach` 1.6 m, `seats` 2, `exit_gap` 0.8 m, `eye_height` 0.3 m. The Host's timers read
    `hatch_time` and `floor_time`; a clip that shows one of them is played at the speed that fits it, so the number
    lives in one place.
  - The motion's numbers (scale 0.33, hop 0.3 m, climb 0.8 s, curl 70 degrees, dim 0.6 over 0.4 s, shake 12 mm,
    squeeze 0.25 over 0.7 s, lift 0.5 s) are **the clips' keys**, not code (Q2697): the designer edits them in the
    Looks' AnimationPlayer.
  - The Upgrades (their `.tres` exist, "Coming soon" until now, Q2669): `elevator_repair` gets `stat` =
    `game/economy/stats/elevator_repair.tres` (FLAG); `fast_elevator` gets `elevator_floor_time` (SCALE_DOWN, base 1,
    step 0.25, least 0.1, format "%.1f s" of 2 s x it: 2.0, 1.5, 1.0 s); `roomy_car` gets `car_extra_seats` (ADD,
    base 0, step 1, format "%d"). The Elevator reads `Upgrades.value()` when it decides, never at ready.
- **Added by dropping a file, no code:** a stop is an `elevator_stop.tscn` instance with its `floor` (the letters
  column and the station's board are built from the stops at load); a carried thing is a `Carriable` (it rides); a
  sound is a clip added to its SoundEvent.
- **The zoo station** `game/zoo/stations/elevator.tscn` (its own things under `game/zoo/elevator/`), built from the
  data at load (Q2337): a two-storey shaft (house kit pieces, the real `elevator.tscn` with two stops), a board listing
  every stop, the tuning's numbers and the three Elevator Upgrades from the Upgrades folder with their stat now ->
  top, a `SockGenerator` area and a Carriable (a Laundry bin) by the lower hatch to load the car, its own `Run` mini
  plan with a lock on the upper floor and its own `Upgrades`, and switches: "Repair" (Elevator Repair on/off), "Open
  upper floor", "Fast Elevator +1", "Roomy Car +1". Only the drafts that say so edit the station's scene.
- **Authored in nodes (Q2658):** the car, the stops, the letters (`elevator_letter.tscn`: the letter mesh and its ring
  in Looks; code instances one per stop and sets its text), the plaque, the ride view (`ride_view.tscn`: a
  CanvasLayer with a ColorRect, its AnimationPlayer `dim_in` / `dim_out`), the prompts through the existing
  crosshair rows. No Control, mesh or material built in code.
- **Motion is clips in Looks (Q2697):** the stop's Looks: `open`, `shut` (the hatch leaf, an AnimatableBody3D keyed
  itself, as core/80 learned), `out_of_order`, `repaired`, `locked`, `unlock` (the padlock); the button's `press`;
  the car's Looks: each seat's `climb_in`, `climb_out`, `squeeze`, `lift`; each letter's `lit`, `dark`, `locked`; the
  avatar's Looks: `curl` (a pose the seat blends in). The Player's camera rig: `ride_shake`. The Looks contract
  (`game/entities/elevator/looks_contract.json`) names these nodes and clips; the graybox Looks and the ported model
  (asset draft AS-L) both meet it.

## Sounds (SoundEvents in `sound_catalogue.tres`; the old placeholders and shares, Q2702; all added by core/154)

| Event | When | Space | Old pool |
|---|---|---|---|
| `elevator_bell` | the arrival, at that stop | world | the ping's (`ping` clips) |
| `elevator_creak` | every `creak_every` s while riding, at the shaft where the ride has got to | world | the basket's creaks (`basket_open` / `basket_close` clips) |
| `hatch_open`, `hatch_close` | a hatch slides | world | the oven's (`oven_open`, `oven_close` clips) |
| `elevator_button` | a call button's answer | world | `device_click`: the TV and Radio's knob click (added once, by core/154) |
| `elevator_ride` | the rider alone, hatch shut to arrival | flat, loop | the old synth placeholder |
| `elevator_squeeze` | a second rider squeezes in, at the car | world | the old synth placeholder |

No climb sound (Q2702). The Elevator has no rumble of its own.

## Saves, joins and the Lobby

Nothing writes save code: the Elevator, the stops' Openables (`keeps_open_on_load`), the Mess and the Carriables are
saved and joined by their State groups. `left` is the live remaining time in the save and the snapshot, so a ride
resumes; riders are kept (Q991: a join or a load draws them curled). A rider who is not in the loaded World's Roster
is dropped from `riders` by the Elevator's `loaded()`.

## Seams to the other pieces

- **core/80 (floor locks, `HouseLights`; built):** the Elevator reads `Stages.floor_open(floor)` and listens to
  `Stages.floor_opened`; it plays its own padlocks' `unlock`. It does not touch the lamps (the day's lamps rule is in
  `day-and-exterior.md`).
- **core/129 (the Upgrade grid; built):** the three Upgrades get their `stat` (above); they stop being "Coming soon";
  Fast Elevator and Roomy Car keep `needs` Elevator Repair; Roomy Car stays co-op only. `Upgrades.bought` for
  `elevator_repair` drops the plaques.
- **core/132 and core/133 (the Old Tree's voice and tips):** `tree_tip_elevator` (its recording copied by core/132) is
  a trigger file `game/voice/triggers/tree_tip_elevator.tres` named in the Old Tree's tips (core/133's "once per player
  per run"); it is due for each player once Elevator Repair is first bought in the Run (Q1594, Q1606): "The elevator.
  Slow, a bit shaky, but it still beats the stairs. Mind the doors." Draft 149-F, after core/133.
- **core/150 (the devices, TV and Radio; designed beside this):** the Radio and the detector ride as Carriables
  (Q2699); a thrown one never knocks a rider (Q2700, `Knockdowns`'s rule here); `device_click` is shared with the
  Elevator's button. The Sock vacuum's container rides only with its nozzle on its hook (Q2710): it lies still at its
  stop while its nozzle is out, so the carry rule asks a Carriable whether it may ride (a sibling's
  `may_ride() -> bool`, read with `has_method`; the `Vacuum` answers `nozzle_at == INF`). A player holding the nozzle
  may climb into the car with the container outside: nothing stops it and the hose stretches between floors, as the
  old (Q2711). core/150 writes its side (core/175).
- **core/151 (the Cat; designed beside this):** the Cat joins `elevator_cargo` (`rides_patch`, `fills_car`,
  `called_patch`), naps in the open car with nobody riding, asks `open_hatch` after `car_shut_seconds` 20 s, listens to
  `departed` / `arrived`, and lands inside when dropped or thrown into the open car (the car's StaticBody). core/151
  writes its side.
- **Knockdowns (built):** `climb_in` reads `is_down`, `dragging_of`; the dragged body's seat and its exit fall are
  the Elevator's; `Knockdowns._decide_knock` refuses a rider (Q2484).
- **Secrets (later, Q2682):** Elevator Duet (two players, no dragged body, in from departure to arrival; the car's
  caged brass lamp flickers gold; the Bellhop Cap) hangs on `departed` / `arrived` and `riders`; the car's Looks keeps a
  `lamp` node for it. Not built.

## Changed technically from the old (no choice: tell the designer at the sitting)

- One Part for the car and its riders; the Cat is cargo, not a third record read by the car's code.
- One carry rule by a group contract, not a branch per kind of thing.
- The car's colliders are always on (the old switched them on and off by events to keep the Mess cheap, Q850); in the
  port a still StaticBody costs nothing, and the empty car still only meets the crosshair, as before.
- The climbs, curl, squeeze, dim and shake are clips in Looks, not procedural code.
- The plaque and the letters are modelled parts (Q2705), not drawn by a SubViewport and code.

## The designer's answers this piece rests on

- Q2702: the Elevator as the old (players ride; no car seen moving; out of order until Elevator Repair and locked
  until the ground floor opens, then open floors only; empty at a New Game; riders climb out on arrival; the call
  button only opens a shut hatch; the letters on the car's side wall; the old placeholder sounds, no climb sound).
- Q2699: every carried thing rides by one item rule, the detector too.
- Q2700: a thrown thing never hits a rider.
- Q2705: the model is ported by the port rules, with the letters and the plaque as modelled parts.
- Q2706, Q2693, Q2694: in `day-and-exterior.md`.

## Draft tickets (filed by core/153; each heading names its ticket)

Each builds on graybox Looks and waits for no asset (Q2705); every number `# placeholder:` the old. "Lines" are the
behaviour list's (`11-elevator.md`) by heading.

### 149-A The Elevator: the car, calls, hatches, locks and out of order (filed: core/155)
- **Lines:** "Where it is and what it is" (all 3); "Calling and sending" lines 1-5 and 7-9 (the sill push of line 5 is
  149-C's, the send from the letters 149-D's); "Locked and out of order" (all 5); "Things in the car" line 1 (the hatch and the car's colliders); "Sounds"
  (bell, creak, hatch, button; no climb sound); "The Upgrades" `elevator_repair` and `fast_elevator`; "Words" (all but
  the riders' words).
- **Build:** `elevator.tscn` with graybox Looks and its contract, `elevator_stop.tscn`, `elevator_letter.tscn` (the
  column built, the letters' clips; the send is 149-D), `Elevator` with every State field of this doc (riders empty)
  and the verbs `call`, `hatch`, `depart`, `arrive`, `open_hatch`; the cargo group's calls (`rides_patch` at `depart`, `fills_car` at `climb_in` once 149-D asks it, `called_patch` at
  `call`, `car_opened` after `arrive`) with no member yet;
  `ElevatorControl` (BUTTON, HATCH, LETTER); a small `Openable` export `driven` (use() asks nothing; aimed through the
  stop's ElevatorControl); `ElevatorTuning`; the two stats; placed in `house.tscn`; the station filled (its shell and
  the SoundEvents are core/154's).
- **Acceptance:** in the house from a New Game (stages on), clicking the ground floor's call button with the mouse
  reads "Out of order (needs the Elevator Repair upgrade)" and the plaque shows; after Elevator Repair is bought
  (the real `buy`) and the ground floor is open, a click on the basement's button shuts the kitchen hatch (its clip
  plays, `hatch_close` sounds), and after `hatch_time` + `floor_time` the basement hatch opens with the bell; a call
  while riding turns the car; a click on the shut hatch where the car stands opens it, the button never shuts it; a
  locked floor's stop reads "Elevator locked"; Fast Elevator level 2 makes a floor 1.0 s; save mid-ride and load:
  the ride ends at its floor; a Guest's click waits for the answer and its button sound comes from it; a late Guest
  sees the car where it is. **Real path:** the player's left click on the stop's call button, through the scene's
  wiring, to the hatch Openable's open state and the bell heard at the arriving stop.
- **suites:** [elevator, save, upgrades, stages]
- **Model:** opus.
- **Authored:** `ElevatorTuning` and the two stats in the inspector; stops dropped as scenes; clips in the stop's
  Looks; the station built from the stops and the Upgrades folder.

### 149-C What rides: the one carry rule (filed: core/156)
- **Lines:** "Calling and sending" line 5's push (the hatch pushes every item on its sill in, never cutting or losing
  one) and line 6 (nothing drawn moving; what lies in it lies frozen at the bound floor, back to life when the hatch opens);
  "Things in the car" line 2 (everything lies where it lay; Socks and Pairs pushed in with the hatch).
- **Build:** `Mess.rides_patch` (lying records in the box or on the sill moved by `delta`; a Moving one laid first)
  and `Mess.car_opened` (the wake), `Carriable.rides_patch` (`at += delta`, clamped into the box), both joining
  `elevator_cargo` (149-A already calls the group; `fills_car` and `called_patch` get their member with the Cat,
  core/151).
- **Acceptance:** in the Elevator station, Socks from the generator and a floor Pair put into the open car with the
  Hands, and the Laundry bin set on the sill, ride to the upper stop and lie there in the same places (relative to the
  car) when its hatch opens; nothing in the car moves while it rides; none is lost or left in the shaft; on a Guest the
  same; a load mid-ride keeps them in the car. **Real path:** the player drops Socks into the car with the right
  click and clicks the other stop's call button; at the arrival the Socks the player sees lie in the car there.
- **suites:** [elevator_cargo, mess, carry]
- **Model:** opus.
- **Authored:** no data of its own; a new carried thing is a Carriable, or a Part in the group.

### 149-D The riders (filed: core/157)
- **Lines:** "Calling and sending" the send from the letters; "Riders" lines 1-6 and 10-15 (climb in, refused, the
  climb, the rider's view with its dim and shake, the rumble loop, looking round curled, keeping the Hands, the
  letters, climbing out on arrival and with Space, a Throw never knocks a rider, leaving and `everyone_out`, joins and
  loads curled); "Sounds" `elevator_ride`; "Words" (Climb in, Climb out, Elevator full, "Send the Elevator to %s").
- **Build:** `climb_in`, `climb_out`, `send`, `everyone_out` and `left()`; the Player's jump asks the aimed Elevator
  first; the rider's camera at the seat's `Eyes`; `ride_view.tscn`; the seats' clips and the avatar's `curl`;
  `ride_shake`; the letters aimed by riders only (the aim skips Teammates in the car); `Knockdowns` refuses a rider
  (for every thrown thing: Socks and core/150's Carriables); `elevator_ride` played (its SoundEvent is core/154's).
- **Acceptance:** in the house with Elevator Repair bought, the player presses Space aimed into the open car and is
  curled in it (the hint "Climb in [Space]"); a click on the "1" letter sends the car; the view dims and shakes while
  the hatch is shut and the rumble plays for the rider only; at the arrival the rider is out 0.8 m in front of the
  hatch; Space climbs out where it stands open; a refused climb reads its words; a Guest rider seen on the Host is
  curled and faces their look; a late Guest sees a rider curled at once; a Throw at a rider never knocks them down; a
  rider who leaves is out. **Real path:** the player's Space aimed at the open car, through the Player's wiring, to the
  camera at the seat's eyes and, after a letter click and the ride, the camera back on the floor in front of the other
  stop's hatch.
- **suites:** [elevator_riders, knockdown, net_elevator]
- **Model:** opus.
- **Authored:** the motion is clips (seat, curl, ride view, shake); the reach and eye height in `ElevatorTuning`.

### 149-E Two in the car and the dragged body (filed: core/158)
- **Lines:** "Riders" lines 7 (two ride: squeeze, jostle, squeak), 8 (seats 2, 3 with Roomy Car; a dragger counts
  with the body) and 9 (the dragger: lift, climb, the drag holds, out half as far, falls); "The Upgrades" `roomy_car`.
- **Build:** the second seat's `squeeze` clip and its sound; the `car_extra_seats` stat on `roomy_car.tres`; the
  dragged body as the dragger's next seat (`lift` then `climb_in`; the ragdoll hidden while seated, put back at the
  exit spot to fall).
- **Acceptance:** two players climb in: both play the squeeze and `elevator_squeeze` sounds at the car; a third is
  refused "Elevator full" until Roomy Car is bought; a player dragging a knocked-down Teammate climbs in with them and
  both come out at the arrival, the body half as far and falling; on a Guest the same. **Real path:** a Guest's Space
  aimed into the car where the Host already rides, to both avatars drawn squeezed in their seats on both machines.
- **suites:** [elevator_riders, net_elevator, knockdown]
- **Model:** opus.
- **Authored:** `roomy_car`'s stat in the inspector; the squeeze and lift are clips.

### 149-F The Old Tree's Elevator tip (filed: core/159)
- **Lines:** "The Old Tree's tip" (1).
- **Build:** `tree_tip_elevator.tres` named in the Old Tree's tips (core/133's mechanism), due once Elevator Repair is
  first bought in the Run. Waits for core/133 to be merged.
- **Acceptance:** after the real `buy` of Elevator Repair, a player coming near the tree hears the tip once this run;
  a second player hears it once too. **Real path:** the player's click on Elevator Repair in the Upgrade menu, then
  walking to the tree, to the line's subtitle shown.
- **suites:** [old_tree, voice]
- **Model:** sonnet.
- **Authored:** a trigger file and its line's JSON entry: no code.

### AS-L The Elevator's model (filed: assets/21)
Ported from the old `tools/blender/make_elevator.py` (`assets/house/elevator.glb`) by the port rules (Q2705, the old
colours): the car (stainless, its caged brass lamp), the hatch and its frame, the brass call button, with the floor
letters and their rings and the "OUT OF ORDER" plaque and the padlock sign now modelled parts (they were built in
code). Fitted to the port's shaft and hatch (house-kit-plan K09: 0.7 x 0.7 m, hatch 0.54 x 0.58 at sill 0.8 m). Its
Looks scenes meet `looks_contract.json` (149-A); the before-and-after strip in `builds/review-elevator/`; stops at its
first line-up (`ready-for-human`). Model: opus. No core ticket waits for it.

### Behaviour lines not in a draft
- The Cat and the car (12): core/151's (the cargo contract above is this side).
- Elevator Duet: a Secret, later (Q2682).
- Not ported: the Grotto's floor hatch (Q2599), the Guide card riding (Q2695).

## The waves

Superseded by the batch's one build order, `docs/migration/milestones.md` "Batch C" (core/153), which merges the four
designs' waves and keeps their clashes apart (`house.tscn`, `elevator.gd`, `knockdowns.gd`, `player.gd`,
`player.tscn`, the Elevator station). Every SoundEvent and the stations' shells are core/154's, so no draft here edits
`sound_catalogue.tres` or `zoo.tscn`.

## Gotchas for the build

- The edge cases of a call (a call for the floor the car is shutting at, a call while the hatch is mid-slide, two calls
  in one tick) follow the old `ER:32-90` and `EL:99-148` exactly: read them before writing `call`.
- A hatch's AnimatableBody3D must have its own transform keyed, not a parent's (core/80's lesson), or it pushes nothing.
- `Openable.loaded()` shuts every Openable: the stops' hatches need `keeps_open_on_load` or a load shuts the car.
- A House Upgrade bought changes the ride at once: read `Upgrades.value()` at `call` and `depart`, never cache it.
- The Elevator is in the zoo with no Run: "never out of order" means no `Stages` in the level, not a flag.
- A rider's avatar is drawn from decided state, not its synced position: the synchronizer keeps sending, the
  receiving machines ignore the position while `riders` holds the player.
