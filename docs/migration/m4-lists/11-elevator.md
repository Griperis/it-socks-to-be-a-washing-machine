> Draft behaviour list for batch C's Elevator (core/148), written from the reference on 2026-11-26; for the designer
> to approve. No proposal is built on it yet: the design ticket follows the designer's look (index:
> `batch-c.md`).

# Batch C piece: the Elevator

Draft behaviour list (catalogue B12 Elevator, was the dumbwaiter; its three House Upgrades; the riders of house/35;
the Cat's naps in the car are list 12's, named here as the seam). Refs are in the old game (`reference/it-socks/`,
tag v0.1.1) unless they start with `port:`. Short forms: EL = `game/house/elevator.gd`, ER =
`game/house/elevator_rules.gd`, RD = `game/house/rides.gd`, EV = `game/house/elevator_view.gd`, EB =
`game/house/elevator_button.gd`, EH = `game/house/elevator_hatch.gd`, ELT = `game/house/elevator_letter.gd`, ERV =
`game/house/elevator_ride_view.gd`, HI = `game/house/house_installer.gd`, LV = `game/campaign/locks_view.gd`, LS =
`game/campaign/lock_sign.gd`, CA = `game/campaign/campaign.gd`, G = `game/core/game.gd`, UP =
`game/campaign/upgrades.gd`, SB = `game/audio/sound_bank.gd`, SJ = `data/sounds.json`, SV = `game/core/saves.gd`, TVD
= `game/audio/tree_voice_director.gd`, SEC = `game/campaign/secrets.gd`, CAT = `game/cat/cat.gd`, HL =
`assets/house/house_layout.json`, ME = `tools/blender/make_elevator.py`, UJ:<line> = `data/upgrades.json`,
T:<name> = `data/tuning/<name>.json` (every number there is a placeholder in the old game too), DH =
`docs/migration/digests/digest-house.md` section 4.

Marks: "(12)" a line of list 12 (the Cat), "(13)" of list 13 (the Radio), named here because the car carries it;
"(co-op)" a line that needs co-op (who sees what, the Host's answer); "(sound)" a sound, "(rumble)" a pad rumble
(the Elevator has none of its own); "(Secrets, later, Q2682)" a Secret that hangs on the piece, listed so it is not
lost. Not ported at all: the Grotto's floor hatch, which shared the hatch sounds (Q2599); the Guide card that rode
the car (no guide card, Q2695). The old model is `assets/house/elevator.glb` (built by ME, the
car's meshes adopted by EV); the port has the shaft's walls and hatch openings only, no car yet (port: `docs/architecture/house-kit-plan.md`
K09, `game/house/kit/house_kit_sizes.gd` `elevator_hatch`; house/04).

## Behaviour list

### Where it is and what it is
- When the house is built, then the Elevator is a small service lift in a shaft beside the kitchen's Food cabinet,
  through all four floors (basement, ground, first, attic): a stainless car about 0.6 m a side (inside 0.6 x 0.58 x
  0.54) behind a metal service hatch per floor, its sill at waist height (about 0.8 m), restaurant-like. (ref: EL:1-12;
  HL `elevator`; ME; DH; Q509-Q511, Q516; port: the shaft and its hatch openings, house/04, K09)
- When a New Game starts, then the car stands open at its home stop, the ground floor (the kitchen), empty. (ref:
  HL `elevator.car.home` 1; EL:45-63; DH Open house/17)
- When the Elevator is named in play, then it is "the Elevator" (renamed from the dumbwaiter everywhere). (ref: Q532)

### Calling and sending (the Host decides)
- When a player clicks (left click or E) the brass call button beside a hatch, then the car is called to that floor;
  its tooltip reads "Call the Elevator"; each hatch shows only this one button. (ref: EB:1-31; ER:32-36; Q512, Q533;
  designer 2026-10-31, house/23)
- When a player clicks a shut hatch, then the car is called there too ("Call the Elevator"); when the car stands at
  that floor, the click opens or shuts its hatch ("Open the hatch" / "Shut the hatch"). (ref: EH:1-5, EH:64-75; `game/house/openable.gd`:54-55; EL:115-139;
  Q533)
- When the call button is clicked where the car stands with its hatch shut, then the hatch opens (it never shuts it
  from the button). (ref: EL:120-131; DH Open house/26, built default never answered)
- When a call comes while the car rides, then the newest call wins: the car turns for it. (ref: ER:44; EL:120-126;
  Q513)
- When the car leaves, then its open hatch first slides shut (`hatch_time` 0.5 s), pushing every item on its sill into
  the car, never cutting or losing one; then it rides `floor_time` 2 s a floor; on the Host's word that it got there
  (`elevator_arrive`), the hatch there slides open. (ref: EL:6-12, EL:99-148; ER:77-90, ER:111-124; T:elevator; Q512,
  Q514) (co-op)
- When the car rides, then nothing is drawn moving: it stands at the floor it left while that hatch shuts, then stands
  at the floor it is bound for; what lies in it (Mess Socks, floor Pairs, the Radio (13), the encyclopedia book, the
  Cat (12)) lies frozen at that floor exactly as it lay, and comes back to life when the hatch opens. (ref: EL:10-12,
  EL:73-82; ER:96-173; EV:6-8, EV:283-297; Q534)
- When a call is decided, then the Host refuses it when the floor is wrong, when it comes from the floor letters and
  the caller is not a rider, when Elevator Repair is not bought ("Out of order (needs the Elevator Repair upgrade)"),
  or when the called floor or the clicked hatch's floor is locked ("Elevator locked"); a refused caller reads it as a
  Refusal. (ref: ER:42-75; G:248-250) (co-op)
- When a Guest clicks a button, then the click waits for the Host's answer (the round trip); the button's click sound
  is played from the answer. (ref: HI:103-110; DH Open house/17) (co-op)
- When the World is saved or a player joins, then the car's state (how far it got, where it is bound, where it left,
  whether it rides, whether its hatch is open, the hatch's wait) and who rides are in the save and the join snapshot.
  (ref: EL:151-163; SV:33-34, SV:134-136; Q991) (co-op)

### Locked and out of order
- When a Run is played and the House has not bought Elevator Repair, then the Elevator is out of order: every hatch
  wears an "OUT OF ORDER" plaque (red letters printed on it, not floating text) and reads "Out of order (needs the
  Elevator Repair upgrade)"; calls and climbs are refused so. (ref: CA:50-52; EH:16-17, EH:66-69; LS:19-25, LS:58-62;
  LV:89-93; G:250; UJ:365; Q1350)
- When Elevator Repair is bought, then the plaques drop and the floors' padlocks show where a floor is still locked.
  (ref: LV:73-74, LV:128-136)
- When the ground floor is not open yet, then the whole Elevator is locked; once open, it works for every unlocked
  floor only: a locked floor's hatch wears its padlock sign and reads "Elevator locked", and its button column wears
  its lock. (ref: CA:54-65; EH:12-14; LV:2-10, LV:69-93, LV:220; Q638, Q643, Q680; port: the floor locks of batch A,
  `docs/architecture/stages.md` "Elevator's stops read `floor_open(floor)`")
- When a floor opens, then its hatch's padlock drops as the other locks do. (ref: LV:120-136; port: `stages.md`
  `floor_opened` "batch C: the Elevator")
- When no Run is played (stages off: the zoo, a practice), then the Elevator is never out of order. (ref: CA:50-51)

### Things in the car
- When the hatch is open, then items fall in physically; the car's colliders are solid only while something lies in
  it or someone's body (a player's, a ragdoll's) is in it; empty, only the crosshair meets it (to drop into it).
  (ref: EV:20-28, EV:186-216; ER:195-208; Q816, Q846, Q848, Q850)
- When the car arrives, then everything in it lies exactly where it lay; Socks and Pairs riding it are drawn sliding
  with it while the hatch shuts. (ref: ER:111-173; EV:12-16; HI:162-183)

### Riders (house/35)
- When a player aims into the open car and presses Space, then they climb in (the corner hint "Climb in [Space]"):
  the Host checks they stand within `reach` 1.6 m of the open hatch, are not knocked down or in the drum, the car
  stands open, it is not out of order or locked, the Cat is not in it (12), and there is room. (ref: ERV:251-271;
  RD:49-76, RD:145-170; T:ride reach; Q645, Q989) (co-op)
- When the climb is refused, then the player reads it: "Out of order (...)", "Elevator locked", or "Elevator full"
  (also when the Cat lies in the car). (ref: RD:17-18, RD:156-166)
- When a creature climbs in, then on every machine it shrinks to `scale` 0.33, hops over the sill (a 0.3 m arc)
  through the hatch over `climb_time` 0.8 s, turns to face out and curls up (`curl` 70 degrees) in its slot; climbing
  out is the same backwards, onto the floor `exit_gap` 0.8 m in front of the hatch. (ref: ERV:1-18, ERV:177-249;
  T:ride; Q645) (co-op)
- When a player rides, then their own view is first person, low in the car (eyes 0.3 m over its floor), framed by its
  walls; while the hatch is shut it goes dim (to 0.6 dark over 0.4 s) and the view rumbles (12 mm shake) on the way;
  their own body is hidden once curled. (ref: ERV:5-6, ERV:467-515; T:ride dim, dim_time, shake, eye_height; Q834)
- When a player rides, then the ride's rumble loop ("elevator_ride", flat) plays for the rider alone from the hatch
  shutting to the arrival. (ref: ERV:516-565; SB:56; SJ:245-247) (sound)
- When a curled rider looks round, then their creature still faces their look and bends with their pitch on top of
  the curl, as others see it; a knocked-down body faces out and only curls. (ref: ERV:20-23, ERV:477-486; Q1134)
  (co-op)
- When two ride, then the second squeezes in: both squash and wobble (`squeeze` 0.25 over 0.7 s, three wobbles dying
  out), the view jostles, and a rubbery squeak ("elevator_squeeze") plays at the car. (ref: ERV:37, ERV:240-246,
  ERV:452-454, ERV:534-539; SB:62; SJ:287-289; Q836, Q991) (sound)
- When the car is full, then it takes `seats` 2 riders (3 with Roomy Car); a dragger counts with the body they drag.
  (ref: RD:44-46, RD:77-84; UP:215; T:ride seats; Q836)
- When a dragger climbs in, then the knocked-down body they drag comes as the second rider: it is first lifted from
  lying to standing at the hatch (`lift_time` 0.5 s), then climbs as a creature does; the drag holds through the ride
  and the body comes out with its dragger (half as far out), falling where it comes out. (ref: RD:4-6, RD:77-84;
  ERV:7-10, ERV:185-202, ERV:395-418; Q984, Q991) (co-op)
- When a rider rides, then they keep what is in their Hands; the car is called from the other floors as usual.
  (ref: RD:1-3; Q835)
- When a rider aims at the floor letters on the car's side wall (a column, B at the bottom, A on top), then a left
  click (or E) sends the car to that floor ("Send the Elevator to the first floor"); the car's floor is lit (warm
  amber, readable in the dim), a locked floor's letter is dark with a red ring and reads "Elevator locked"; only riders
  aim at them, and a teammate in the car does not block the aim; the Host grants it to riders alone. (ref: ELT:1-98;
  ERV:91-152; RD:204-208; ER:49-52; Q988; house/46) (co-op)
- When the car arrives anywhere, then every rider climbs out there; Space climbs out where it stands open (the hint
  "Climb out [Space]"). (ref: RD:116-125, RD:94-115; ERV:274-277; Q834; DH Open house/35)
- When a rider is in the car, then a Throw never knocks them down. (ref: port: Q2484)
- When a rider leaves the game, then they are out of the car; when the washer's rogue sequence ends, everyone is out.
  (ref: RD:127-143; Q759)
- When riders come by a join or a load, then they are drawn curled in their slots at once. (ref: ERV:78-90; Q991)
  (co-op)

### Sounds
- When the car arrives, then the bell rings at the arrival's hatch ("elevator_bell", sharing the ping's pool). (ref:
  HI:103-106; SB:63; Q515) (sound)
- When the car rides, then the rope and pulley creak in the shaft every `creak_every` 0.7 s, heard where the ride has
  got to (the basket's creaks as placeholders). (ref: EV:17, EV:261-267; HI:102; SB:55; SJ:237-242; T:elevator; Q515)
  (sound)
- When a hatch slides open or shut, then "hatch_open" / "hatch_close" plays at it (sharing the oven's pools). (ref:
  EH:77-78; EV:247-251; SB:53-54) (sound)
- When a floor button is pressed, then "elevator_button" plays at it (the device click). (ref: HI:107-110; SB:52)
  (sound)
- When a player climbs in or out, then no climb sound plays (an open question in the old). (ref: DH Open house/35)

### The Cat and the car (12)
- When the car stands open with nobody riding, then it is one more nap spot for the Cat; asleep in it, the Cat rides
  wherever the car is called and wakes on that floor; a call, a pet or a pick-up wakes it; nobody climbs in while it
  is in the car; shut in at its stop it naps on `car_shut_seconds` 20 s, then opens the hatch itself and walks out;
  dropped or thrown into the open car it lands inside. (ref: CAT:35-46; ER:88-89, ER:107, ER:166-167; RD:70-71;
  T:cat car_shut_seconds; Q1982-Q1984, Q2004-Q2007) (12)

### The Upgrades (batch B shows them "Coming soon", Q2669)
- `elevator_repair` (House, 1 Drawer, cell [0,0]): "The Elevator works. It is locked until bought." Without it, in a
  Run, the Elevator is out of order. (ref: UJ:365; CA:50-52; Q1350; port: core/129, "Coming soon" until this piece)
- `fast_elevator` (House, 2 levels, 2/2 Drawers, needs Elevator Repair, cell [0,1]): "The Elevator moves faster": 25 %
  off the 2 s a floor a level (2.0 s, 1.5 s, 1.0 s; never below 10 %); the card shows "%.1f s". (ref: UJ:384; UP:296-297;
  T:upgrades house elevator_drop_pct; port: core/129)
- `roomy_car` (House, 1 level, 2 Drawers, needs Elevator Repair, cell [0,2], co-op only): "Three can ride together":
  `seats` 2 + 1. Hidden when the game is single player. (ref: UJ:409; UP:215; RD:44-46; T:upgrades house
  car_extra_seats; Q1350, Q1357; port: core/129)

### The Old Tree's tip (batch B's speaker)
- When Elevator Repair is first bought in a Run, then the Old Tree's "tip_elevator" is due for each player, said once
  per player per run when they are near: "The elevator. Slow, a bit shaky, but it still beats the stairs. Mind the
  doors." (ref: TVD:32-39, TVD:214-221; `data/voiceover/old_tree/tree_tip_elevator_1.json`; Q1594, Q1606; port:
  core/132 copies the recording, core/133 leaves this trigger to batch C, `docs/architecture/economy.md` "Batch C")
  (sound) (co-op)

### Secrets that hang on it
- When two players (no dragged body) are in the car as it leaves and still in it when it arrives, then Elevator Duet
  is found: the car's caged brass lamp flickers gold, the Bellhop Cap for both. (Secrets, later, Q2682) (ref:
  SEC:31, SEC:241, SEC:318; Q1047, Q1107)

### Words
- When the Elevator's wording is shown, then it is the old: "Call the Elevator", "Send the Elevator to %s" (the
  basement, the ground floor, the first floor, the attic), the letters B, G, 1, A, "Elevator locked", "Out of order
  (needs the Elevator Repair upgrade)", "OUT OF ORDER", "Elevator full", "Climb in", "Climb out", "Open the hatch" / "Shut the hatch", and the three Upgrades' names and tooltips from UJ. (ref: EB:8-31; ELT:36, ELT:98; G:248-250;
  RD:18; ERV:269-277; LS:58-62)

## What was weak in the old Elevator
- The car's state was plain shared World data on the Game with two Commands; riders were a second record (Rides) and
  the Cat's car nap a third, each read by the others' code (ER calls `game.cat.wake_in_car()`, RD asks
  `game.cat.fills_car()`).
- `carry_along` moved each kind of thing by hand (Socks, Pairs, the Radio, Guide cards, the Cat, the book: ER:111-173):
  every new carried thing needed a new branch.
- The view built the car, hatches, buttons, letters and colliders in code from the layout, adopting the model's
  meshes (EV:65-185); the plaque was drawn by a SubViewport (LS).
- The climbs, curl, squeeze and rumble were procedural placeholders, "no animation clips" (ERV:16-18).
- The car's colliders switched on and off by events (Q850) to keep the Mess physics cheap.
- Sounds were placeholders borrowed from other pools (the oven, the basket, the ping); "elevator_ride" and
  "elevator_squeeze" were never picked (SJ).

## Open questions for the designer
1. Players ride the Elevator (shrink, hop in, curl, low dim view). Keep riders? (a) Yes, as the old (Q645, Q834-Q836);
   (b) the Elevator carries things only.
2. While the car rides, nothing is drawn moving: it stands at one floor, then at the other. Keep that? (a) Yes, as the
   old (Q534); (b) the car is seen moving in the shaft.
3. In a Run the Elevator is out of order until the House buys Elevator Repair, and locked until the ground floor opens,
   then works for open floors only. Keep both rules? (a) Both, as the old (Q643, Q1350); (b) only the floor locks; (c)
   only Elevator Repair.
4. At a New Game the car stands open and empty at the kitchen. Should the house's Sock bake put a few Socks in it?
   (a) No, empty, as the old; (b) a few Socks in the car.
5. Every rider climbs out on their own when the car arrives. Keep? (a) Yes, as the old; (b) riders stay in until they
   press Space.
6. The call button where the car stands with its hatch shut opens the hatch but never shuts it. Keep? (a) Yes, as the
   old (house/26 default); (b) the button toggles the hatch as a click on the hatch does.
7. The floor letters hang in a column on the car's +z side wall (B at the bottom, A on top). Keep? (a) Yes, as the old
   (Q988); (b) on the car's back wall.
8. Climbing in and out makes no sound; the ride's rumble and the squeeze's squeak are placeholder synth sounds. (a)
   Keep the old placeholders and no climb sound; (b) pick or make new sounds now (which?); (c) add a climb sound.
9. The Elevator's model (`assets/house/elevator.glb`: car, hatches, call buttons; the letters and the "OUT OF ORDER"
   plaque were built in code) is not ported yet. (a) Port the old model by the port rules (an asset piece with its strip);
   (b) a new model.
