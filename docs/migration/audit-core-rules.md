# Audit: the core's rules, numbers, controls and feel of play, new against old

Read-only comparison made on 2026-11-20. Old = `reference/it-socks/` at `v0.1.1`; new = `game/` on `main`.
Only differences that are neither in `docs/migration/old-details-backlog.md`, nor in the behaviour lists and
Answers of `docs/llm/core/issues/0*.md` and `1*.md`, nor decided in `docs/migration/decisions.md`.
Looks, sounds and screen text are left to the other audit. Paths are relative to each project.
"Checked equal" lists the numbers compared that match, so the table below is only the differences.

Where a row says "unverified", I read the code but did not run the game.

## Movement

| difference | old (file:line, value) | new (file:line, value) | how a player would notice |
|---|---|---|---|
| Walk direction is normalised in the old game: any stick tilt past the deadzone walks at full speed | `game/player/player.gd:404-405` `dir = (basis * Vector3(move_intent...)).normalized()`; pace = speed | `game/player/player.gd:~168-170` `Input.get_vector(...)` is used as is, length 0..1, so a half-tilted pad stick walks at half speed | on a pad: slow creeping is possible now, the old game was always full speed. Keyboard unchanged. (W01 says only "a diagonal is no faster") |
| Crouch headroom test is a different shape | `player.gd:783-787` a single ray from 1.0 m to 1.75 m, mask `Layers.WORLD` only | `player.gd` `_update_crouch`: `test_move` of the whole crouched capsule up 0.7 m, every layer the body collides with | under a low shelf or beside a wall edge the new body can stay crouched where the old one stood up (the capsule is wider than the ray); also a Door or drawer in the way now counts |
| Pad crouch (LT) trigger threshold | `project.godot` `crouch` pad axis 4 `deadzone 0.5` | `project.godot` `crouch` axis 4 `deadzone 0.2` | the trigger crouches at a light pull, not at half pull |
| Pad right-stick look: per-axis deadzone and no pitch factor | `data/tuning/pad.json` `look_deadzone 0.15` (radial), `pitch_factor 0.7` (up/down at 70% of the turn rate); the four `look_*` actions have `deadzone 0.0`; `player.gd:~340-350` | `project.godot` `look_*` `deadzone 0.2` per axis; `player.gd:_process` pitch and yaw at the same rate `pad_look_speed 170` | looking up and down on a pad is 1.43 times quicker than in the old game; stick drift handling differs. (The curve 1.8 and the speed-up 1.6 are in Q2235, the pitch factor and deadzone shape are not named there) |
| Pad zoom and turn buttons are not bound | `project.godot` `zoom` pad button 11, `turn` pad button 7 | `project.godot` `zoom` and `turn` have the keyboard only | on a pad the Sock cannot be zoomed or turned (the other pad bindings of the Hands are there) |
| Zoom slows the look by a different curve | `player.gd:449-450` `look_delta` times `fov / base_fov` (linear: x0.667 fully zoomed) | `game/player/player.gd` `zoom_slow()` `tan(fov/2) / tan(base/2)` (x0.608 fully zoomed) | zoomed in the mouse is about 9% slower to turn than in the old game |
| The click that captures the mouse also acts | `player.gd:~232-240` a click on an uncaptured window only captures; the right button, Zoom and Turn also need the capture (`zoom_intent = ... and _captured()`) | `game/player/player.gd:_update_hands` polls `Input.is_action_just_pressed(PICK / DROP_THROW)`, `ZOOM`, `TURN` without `_captured`; `_unhandled_input` only sets `_captured`. Unverified in the running game | the first click on the window (or any click after Esc) can also pick a Sock or start a drop timer: L03 says "that click does nothing else", the code does not guarantee it. With the mouse free after Esc, clicks and G still act |

## Camera

| difference | old | new | how a player would notice |
|---|---|---|---|
| none beyond the Zoom row above | FOV 75, zoom 50, 0.15 s, 0.0025 rad/px, pitch 85: `view.json`, `player.gd:37,119` | same numbers in `move_tuning.gd`, `hands_tuning.gd` | - |

## Hands: pick, hold, cycle

| difference | old | new | how a player would notice |
|---|---|---|---|
| Aim forgives a miss of 3 cm and also picks a Sock only its box edge touches | `game/world/sock_picks.gd:11-16,60-90` `PAD 0.03`, candidates within `CANDIDATE_REACH 0.12` by padded boxes, first box the line enters, else first within 3 cm | `game/player/player.gd:_update_hands` `RayCast3D` against the Sock's collision box only (`Mess.AIM_MASK`), no padding | thin Socks and the edge of a Sock lying half under another are harder to hit; M13 covers only "the tip sticks out" |
| A lying Pair (ball) and a Sock are not compared by distance | `game/player/rig_aim.gd:30-40` the nearer of a Sock and a ball under the crosshair wins, the ball's surface against the Sock's middle | one ray, the first collider wins | rarely felt; ball on top of a Sock behaves the same |
| A woken or moving Sock can be aimed and picked mid-slide | `game/world/sock_picks.gd` `SOCK_AIM_MASK` includes `SOCK_LIVE`: a Sock that was woken (Moving) is found by the aim | `game/mess/mess.gd:_launch` a woken Sock is FLYING, layer 2, never in `AIM_MASK`; H10 only says a dropped Sock cannot be picked | a Sock knocked loose cannot be grabbed until it comes to rest; the old game let you catch it sliding |
| After fusing, the Pair goes to the end of the Hands and becomes active | `game/hands/hands.gd` `try_pick`: the held Sock is popped, marked a pair and appended; `active = size - 1` | `game/hands/hands.gd` pick answer: `_patch(by, held_items, held_items.find(lead), stamp)` keeps the Pair where its lead was and active at that place | with 3 places held (zoo), the order the wheel steps through and which item is drawn big after a pairing differs |
| Dropped item keeps the turn it was drawn with | `game/player/rig_drop.gd:70-78` turn = the held item's drawn rotation (the R turn included), Q1207 | `game/hands/hands.gd:_let_go` flat, yaw only: its length across the dropper's view | turning a Sock with R and dropping it: the old Sock landed at that angle, the new one always lies square to you |
| Drop onto a lying Sock or ball is allowed anywhere on it | `rig_drop.gd:88-100` a Sock or Pair the crosshair meets: ok at the entry point, no slope test | `game/hands/hands.gd:drop_refusal` slope test on the first thing hit (Sock box or ball sphere via `PhysicsQueries.ball_hit` with `AIM_MASK`) | aiming at the side of a Pair's ball or the edge of a Sock gives a red crosshair and "Can't drop there" (the sphere is steeper than 25 degrees nearly everywhere except its top) |
| "Rests there" rule uses other distances | `game/core/game.gd:241,289` `LANDING_LIFT 0.15`, `DROP_FALL 0.1` against the surface span under the spot (headroom too) | `game/hands/hands.gd:30` `SPOT_PROBE 0.05` straight down from 5 cm over the spot, flat enough | edge cases only: a drop at a ledge, under a low shelf (the old span also tests headroom) |
| Host re-check slack | `game/core/game.gd:286` `HOST_SLACK 0.5` plus `PICK_SLACK 0.03` | `hands_tuning.gd` `reach_slack 1.0` | not felt alone (co-op) |
| Cycle direction | wheel down +1, wheel up -1 | same | - |

## The Throw

| difference | old | new | how a player would notice |
|---|---|---|---|
| Spin is random, not fixed (the behaviour list says "the old fixed (2, 1, 3)") | `game/hands/hands_rules.gd:~16,345-349` `THROW_SPIN (6, 3, 6)`: each axis random in plus or minus that; (2, 1, 3) is only the default of an unused argument, `game/world/flights.gd:204` | `game/hands/hands_tuning.gd` `spin = (2, 1, 3)` fixed; `hands.gd:launch_of` | every thrown Sock tumbles the same way and slower; in the old game each throw looks and lands differently (a ball spins too) |
| Thrown and dropped bodies bounce and slide differently | `data/tuning/upgrades.json` `throw.restitution 0.35`, `friction 0.6`; applied to every released body incl. a plain drop: `game/world/sock_flights.gd:165-166`, `flights.gd:207-210` | `game/sock/flight.tscn` `friction 0.9`, `bounce 0.0`; `ball_flight.tscn` `friction 0.9`, no bounce | a thrown Sock or ball no longer bounces off the floor or a wall (35% of its speed came back) and no longer skids a bit further |
| A woken Sock moves like a loose Mess Sock in the old game | `data/tuning/mess.json` `friction 0.9`, `linear_damp 0.6`, `angular_damp 3.0` | `flight.tscn` has no damp set, the Godot default (0.1 / 1.0) applies unless thrown (0.05 / 0.8 on the throw only) | knocked Socks slide and roll longer in the new game |
| Dropped Sock damping | `sock_flights.gd:~207-212` a loose Sock released by a drop also gets `thrown_linear_damp 0.05`, `thrown_angular_damp 0.8` | `game/mess/mess.gd:_launch` no override for a drop: the default 0.1 / 1.0 | small: a dropped Sock settles a little sooner |
| A thrown Pair has no drag in the air; slow ones are heavy at once | `sock_flights.gd:206-212` Pair: damp 0.0 in the air until the first impact (speed change over 0.6), or from the start when under `wake_speed` 1.5 | `mess.gd:_launch` a thrown Pair gets the Sock's 0.05 / 0.8 in the air, the Pair 2.5 / 8 from the first contact | a thrown sock ball flies slightly shorter |
| What wakes lying Socks | `sock_flights.gd:255-285` any released body at 1.5 m/s or more wakes the resting Socks in a 12 cm ball placed two ticks ahead of it (`IMPACT_REACH 0.12`), and up to `IMPACT_WAKES 8` touching them, before it arrives | `mess.gd:_on_contact` `body_entered` after the hit, when `_speeds` (the body's speed before the step) is over 1.5 | the hit Sock is pushed by the real impact in the old game (mass and speed); in the new it is woken at the contact. Numbers match, timing differs |
| Picking a Sock wakes the Socks lying on it | `game/world/sock_bodies.gd:278-282,371` `wake_above`, `PICK_WAKES 40`, loose Socks included | `game/mess/mess.gd` only Pairs fall (`fall`, P08); a loose Sock lying on a picked Sock is not touched (lying Socks are static poses) | a Sock left on top of a picked Sock stays floating in mid-air; the old stack collapsed (up to 40 Socks) |
| Settle limit of a flight | `sock_flights.gd:242` `f.clock > f.max_age * 2.0` = 12 s (`release.json max_age 6`); rest = under 0.05 m/s (Pair 0.25) and 0.5 rad/s (Pair 3.0) for 0.3 s | `hands_tuning.gd` `settle_limit 6.0`; `mess.gd:_physics_process` rest when Jolt reports sleeping after 0.1 s of flight | a Sock that jitters on a slope is put down sooner; the "rest" instant is Jolt's sleep rather than the old thresholds. T13 lists 6 s as "the old" value; the jolt path used 12 s |
| Thrown Pair shelves on any touch of the Cabinet, old only on the drawer fronts | `game/world/sock_flights.gd:_touch_stations` overlap against `Layers.STATION` (the drawer front boxes only; hidden Rows are not STATION); the shell is `WORLD or AIM` | `game/entities/cabinet/cabinet.gd:_owns` any collider under the Cabinet's root (`_on_flight_touched`) | a Pair that lands on top of or beside a Cabinet is shelved in the new game; in the old it bounced unless it touched a drawer front |

## Pairing

| difference | old | new | how a player would notice |
|---|---|---|---|
| Ball size per Collection | `game/world/sock_ball.gd:99` `SockBall.radius` from the Collection's ball model bounds times Size | `game/sock/sock_dress.gd:19` `BALL_RADIUS 0.042` times Size, one value for all | the pick, drop and bounce size of a ball no longer follows the model. Unverified which Collections differ |
| Order after pairing, wake on pick | see the Hands table | | |

## The Cabinet and Doors

| difference | old | new | how a player would notice |
|---|---|---|---|
| The Cabinet's body takes a shelve by the use button | `game/player/rig_click.gd:use` only a `CabinetDrawer` station shelves; the shell is not a Station | `game/entities/cabinet/cabinet.gd:use` the body shelves into the bottom drawer with Pairs held | pressing E on the Cabinet's frame between drawers shelves now; in the old game nothing happened |
| A swinging Door or sliding drawer wakes and pushes Socks lying where it moves, and Socks inside ride a drawer out | `game/world/sock_bodies.gd:sweep` (`SWEEP_CAP`), `data/tuning/doors.json` `reach 0.12`; `game/house/openable.gd` `ride()` | lying Socks are static poses; `game/parts/openable.gd` only plays the "open" animation | a Door can swing through a Sock lying in its path; a Sock inside a drawer would not follow it. (The cupboard is a solid graybox, "hollowing" is in follow-up of core/02, the sweep and ride are not) |
| Door and drawer ease | `game/house/openable.gd:80-85` `TRANS_SINE`, `EASE_OUT`; 0.35 s default, drawer 0.3 s, room Door 0.6 s | Looks' animation, linear keys (`looks_graybox.tscn` 0.4 s, `looks_alt.tscn` 0.6 s) | the old move starts fast and slows into place; the graybox Door is 0.4 s (Q2213 names 0.6) |
| Coins arrive at once to the shelver | `cabinets.gd:_shelve_designs` Coins to the player and flown to the bank per drawer | `cabinet.gd:_shelve` `coins.paid_patch` in the answer | the amounts match (10 x 1/2/5), only the flight is M4 (already in the backlog) |

## Input map

| difference | old | new | how a player would notice |
|---|---|---|---|
| Keyboard | W A S D, E, Space, Ctrl, G, R, Esc, mouse 1/2, wheel | the same codes | - |
| `sprint` (Shift, RT) missing | `project.godot` `sprint` | none | Q2233: Upgrades in M4, decided |
| Pad `zoom` / `turn` missing, `crouch` trigger deadzone | see Movement | | |

## Checked equal (no difference)

Walk 4.0, crouch factor 0.5, jump 5.5, gravity 20, sensitivity 0.0025, pad turn 170, pitch limit 85, FOV 75,
zoom 50 / 0.15 s, stand 1.7, crouch 1.0, eye 0.1, radius 0.35; reach 2.5, grab interval 0.35, tap 0.25, drop slope 25,
drop gap 0.08, drop lift 0.03, flick 0.1; charge 1.2 s, tap charge 0.15, lob 3.5 / 2.0, speeds 3 to 5, thrown damping
0.05 / 0.8, wake speed 1.5, wake count 8, Pair damping 2.5 / 8, wake reach 0.03, wake gap 0.006; throw start 0.35
ahead, 0.08 low, 0.09 clear; turn 2.0 s, ball scale 1.6, held positions; Sock mass 0.05 (Pair 0.1), Size scales
0.8 / 1 / 1.25, box 0.3 x 0.026 x 0.18; drawer capacity 25, Coins 10 x 1 / 2 / 5; refusal order Wrong / Locked / Full.

## The ones that change play the most

1. Thrown and dropped Socks do not bounce or skid (bounce 0 and friction 0.9 against 0.35 / 0.6) and tumble the same
   way every time (fixed spin (2, 1, 3) against a random plus or minus (6, 3, 6)). The Throw's feel is the biggest gap.
2. Picking a Sock does not wake the Socks lying on it, so a stack leaves Socks floating; a Door or drawer does not push
   Socks in its path.
3. Dropping on a lying Pair or Sock is refused by the slope rule on the ball's or box's side, where the old game
   always allowed it; a dropped Sock does not keep the turn the player gave it with R.
4. The click that captures the mouse (and clicks with the mouse free) also pick, drop or zoom, against L03.
5. The pairing moves the Pair in the Hands order (the old: newest, last).
6. A thrown Pair is shelved by touching any part of the Cabinet, not only a drawer front.
7. Pad: analog walking instead of full speed, no 0.7 pitch factor, trigger crouch deadzone, no pad zoom or turn,
   and the aim has no 3 cm forgiveness.
