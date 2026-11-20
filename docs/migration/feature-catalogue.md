# It Socks: feature catalogue for the move to a fresh project

Read at `main` (2026-11-19, after `9b9234af`). Read-only pass: nothing was run, no tests, no game. Terms follow
`GLOSSARY.md`. The ticket vault (`docs/llm/`) is not carried over; this file is the one list of everything the
game has and everything planned, asked for, started or parked that is not in the game.

How to read it: Part 1 is what is built. Part 2 is what is not. Part 3 is what waits on the designer. Part 4 is
known bugs. Part 5 is one list the designer marks. Part 6 is counts and gaps. Appendix A lists all 578 tickets
(id, status, title), so a built thing can be traced to its ticket. Appendix B lists the parked branches.

Row ids: `B..` built, `P..` planned, `W..` waiting on the designer, `X..` bugs. Part 5 repeats the B and P ids.

Line counts are GDScript lines measured with `wc -l` on the listed files (blank lines and comments included);
groups share files where a feature has no folder of its own, so group sizes do not add up exactly to the
76,473 lines of `game/` (315 files). `tests/` is 44,048 lines in 94 `*_test.gd` suites (98 `.gd` files with the
runner). `tools/` has 4,544 lines of GDScript plus Python and shell tools.

---

## Part 1. Built and in the game today

State column: **on** = in play; **off (switch)** = built, code and tests kept, switched off by the designer.
Switches found: `data/tuning/hamper.json enabled=false` (since 2026-11-10, progression/78),
`data/tuning/pairing.json enabled=false` (since 2026-11-19, tools/26), `data/tuning/laundry.json dirty_socks=false`
(ADR-0011, progression/83), the Lost Sock Grotto hidden behind `data/tuning/drum.json on=true` (ADR-0012,
dungeon/04, kept switchable by Q1873). Every other `data/tuning/*.json` carries no `enabled` flag (grep checked);
`secrets.json` has `on=true`.

### 1.1 Core loop

| Id | Feature | What it is | Code | Suites | State | GDScript lines |
|---|---|---|---|---|---|---|
| B01 | Hands, pick, drop, Throw, Hand-off | Pick a Sock under the crosshair, hold several (Carry capacity), cycle the wheel, turn (R) and zoom the held item, drop where aimed or be refused, hold right click to Throw a Flight (a full-charge Throw knocks a teammate down), hand an item to a teammate; one hold system, held things crouch with you | `game/hands/`, `game/world/flight*.gd`, `game/world/floor_balls.gd`, `game/player/rig_*.gd` | hands, hold, throw, throw_knock, release, carried, prompt, net_hands, net_throw, freed | on | 5,036 (Hands and Flights) + 4,102 (Player, Rig, Avatar) |
| B02 | The Mess: SockWorld | The World's one record of every Sock, Pair and item: Resting Socks are static colliders drawn as MultiMeshes per room, a budgeted few Moving Socks are Jolt bodies; seeded layout (SockLayout) per New Game; Hiding spots, Crawl spaces, Heaps; lost items return before the washer; LOD meshes; cloth actors for held Socks | `game/world/` | sockworld, mess, spawning, colliders, cloth, lost, pair_wake, world_codec, layers, prints, catalogue | on | 7,727 |
| B03 | Pairing | Two matching Socks in the Hands fuse into a Pair (a sock ball); the paired moment (pop, sparkles); Pairs shelve into a Drawer by aim; the Mate distance rule; mates on other floors | `game/hands/paired_moment.gd`, `game/hands/hands_rules.gd`, `game/world/sock_ball.gd` | hands, mess, drawers | on | 287 (paired moment) + shared |
| B04 | Cabinets, Drawers, Rows, payout | Eight themed Cabinets plus eight more Collections' Cabinets, Drawers that grow one per floor, Rows, the Collection bonus, Coins flying to the bank (Coins personal, Drawers team), Collection-complete moment, per-room Cabinet pools and a draw per New Game | `game/campaign/cabinet*.gd`, `coin_bank.gd`, `data/cabinet_pools.json` | drawers, stages, catalogue, stage_bar, spawning | on | part of 5,188 |
| B05 | Catalogue of Designs | Designs are data (ADR-0002): `data/designs.json` holds 1,005 Design entries in 17 Collections plus a Dirty group; Sizes, Rarity, print atlas, four Sock shapes and sock balls | `game/core/catalogue.gd`, `design.gd`, `game/world/sock_look.gd`, `data/designs.json`, `tools/gen_designs.py` | catalogue, prints | on | within core 5,222 |
| B06 | Held info, hints, prompts, Highlight, crosshair | Size/Collection/Design name beside the held item, key hints from the Input Map, one Prompt record, the outline Highlight, red crosshair when a drop is refused, off-screen hint arrows | `game/ui/hud.gd`, `prompts.gd`, `highlight.gd`, `hint_arrows.gd`, `game/player/rig_aim.gd` | ui, prompt, hint_arrows | on | within ui 5,489 |
| B07 | Player movement | First-person walk, sprint, crouch, jump, squash and stretch, waddle, Avatar look bend, stacking on a teammate's back, slower base walk | `game/player/player.gd`, `rig_stack.gd` | players, synergy, ride | on | within 4,102 |

### 1.2 The house

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B10 | The house (still called "the flat" in code) | Four levels (basement, ground, first floor, attic) plus a garage and a Lost Sock Grotto level, 73 furniture placements, 28 furniture builders, 32 top-level sections in `house_layout.json` (167 KB), furniture manifest (1.2 MB), authored colliders for shell and furniture, sky HDRI, day cycle (in-game sun, lamps, night), mirrors (bedroom, bathroom), exterior outside the windows | `game/house/`, `assets/house/`, `tools/blender/make_house.py`, `house_furniture/` | room, locks, graphics, house_effects, uid, blender_assets | on | 6,918 |
| B11 | Doors and openables | Room Doors swing and push things; `Openable` is the one base (Drawer, Door, hatch, lids, car doors, flap); each has its sound; Socks inside ride with an openable | `game/house/openable.gd`, `doors.gd`, `room_door.gd`, `door_rules.gd` | doors, room | on | within 6,918 |
| B12 | Elevator (was dumbwaiter) | A car and a hatch per floor, one call button, riders (players, the Cat, items) ride as data, creatures climb in, letters, Roomy Car upgrade, locked until Elevator Repair in a Run | `game/house/elevator*.gd`, `rides.gd`, `ride_part.gd`, `tools/blender/make_elevator.py` | elevator, ride | on | 1,740 |
| B13 | Piano | All 88 keys playable (Remeau upright samples), lid, behind the sofa | `game/devices/piano_key.gd` | piano | on | within 1,313 |
| B14 | TV and Radio | TV with four channels and shows on a widescreen retro filter, Radio with five channels is the music source and can be carried | `game/devices/device.gd`, `tv_*.gd`, `radio_rules.gd`, `data/tv.json`, `data/radio.json` | device, hands | on | 1,313 |
| B15 | Lantern, Cellar hatch, Grotto | The Lost Sock Grotto (ladder, lantern, drips, hatch) under the basement | `game/house/grotto*.gd`, `lantern_*.gd`, `tools/blender/make_grotto.py` | grotto | **off (switch)**: hidden since dungeon/04 while the drum is on | 206 + lantern |
| B16 | Litterbox | Litterbox in the bathroom, 3 Socks start inside, the Cat visits every about 4 minutes and sometimes hides a Sock in it | `game/cat/cat_litter.gd`, `tools/blender/house_furniture/first.py` | cat | on; numbers are placeholders awaiting the designer (cat/11 is `ready-for-human`) | part of Cat |
| B17 | Studio intro | "Hudry Games" intro with a purple turkey, falling letters, sounds supplied by the designer | `studio_intro/`, `tests/intro_test.gd` | intro | on | small |

### 1.3 The frame of a run: Stages, Laundry day

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B20 | Stages and floors | Floor-by-floor campaign (ADR-0007): Stage bar, Rows per Stage, Stage spawning (50/160/150/130/50 Pairs), locked doors with chain and padlock, dust sheet, unlock by fixing the washing machine with Parts, Parts models | `game/campaign/stages.gd`, `campaign*.gd`, `lock*.gd`, `padlock.gd`, `part_view.gd`, `washer_damage.gd` | stages, locks, stage_bar, spawning, after_fix_hud, net_campaign | on | 5,188 |
| B21 | First wash | New Game starts with the washing machine breaking and spitting out the Socks (voiced cutscene), and a spit after every Stage | `game/devices/first_wash_spit.gd`, `rogue*` | first_wash, rogue | on | in 1,279 |
| B22 | Laundry day: bins and the Final wash | Prefilled Laundry bins stand in the house; each bin loads the machine; after the last Fix the Final wash ends the Run (happy cutscene); the Dirty Socks mode is off | `game/campaign/laundry*.gd`, `data/tuning/laundry.json` | laundry, bins, wash, final_screen | on (bins ending); Dirty Socks **off (switch)** | 1,279 |
| B23 | Final screen | Animated end screen of every Pair and piece, who unlocked what, Continue to the Lobby | `game/ui/ending_screen.gd`, `game/campaign/final_record.gd` | final_screen | on | in ui |
| B24 | The Drum finale | The fifth and last Stage inside the washing machine: bigger-on-the-inside drum under water, Drum hatch as the Lost Socks Cabinet where Pairs are handed out, intro suck-in and spit-out, the washer's voiced comments | `game/dungeon/`, `data/tuning/drum.json` | drum | on (`drum.on` true) | 2,426 |
| B25 | Gifts and Stage presents | Gift boxes per player with reveal, presents under the Old Tree after each Stage, a gift per completed Collection, refund in Coins when owned | `game/campaign/gift*.gd` | gifts | on (Coins refund is "not final", Q1609) | within 5,188 |
| B26 | Guide card | A held card the player reads; first wash page; owner only | `game/campaign/guide*.gd`, `tools/guide_card.py` | guide | on | 872 (with book) |
| B27 | Whiteboard | Collection board in the laundry; hold Tab for it anywhere; tallies per player | `game/campaign/whiteboard*.gd` | whiteboard | on | within 1,749 |
| B28 | Hampers | A bought carrier for many Socks, pours, tips | `game/devices/hamper*.gd` | hamper, hampers_off | **off (switch)** since 2026-11-10 | 939 |
| B29 | Secrets | Hidden triggers (Duet in the Elevator, Piano Four Hands, Rubber Duck Load, Radio Dance...) that give a Secret piece; the Cat and the Radio can go in the drum | `game/campaign/secrets*.gd` | secrets | on (`secrets.json on`) | 979 |

### 1.4 Devices and tools

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B30 | Sock vacuum | Container plus nozzle on a hose (hose wraps geometry, pushed by doors and drawers), suck cone, window showing the load, hand mode and timed rear spit, carried by two players, effects and sounds | `game/devices/vacuums.gd`, `sock_vacuum_view.gd`, `vacuum_fx.gd`, `hose_rope.gd`, `window_heap.gd` | vacuum, net_devices, synergy | on (planned rework, see P01) | 2,620 |
| B31 | Sock pairing machine | Hopper, start button, rolled Pairs as Jolt bodies, Auto Pair mode, 4 Upgrades | `game/devices/pairing*.gd` | pairing_machine, pairing_off | **off (switch)** since 2026-11-19 (none placed, Upgrades hidden) | 1,223 |
| B32 | Sock detector | Handheld finder that beeps near a Sock, pushes its carrier back | `game/devices/beeper*.gd` | beeper | on | 601 |
| B33 | Laundry bin | Carried bin, controls, rotation kept, hand-off refused | `game/campaign/laundry_view.gd` | bins | on | in 1,279 |
| B34 | Washing machine and rogue machine | Talking washing machine (voiced cutscenes, face, subtitles heard only when audible), Parts, Fix; the old rogue choreography was removed (Q1470) | `game/devices/rogue*.gd`, `washer_face.gd`, `tools/voiceover/` | rogue, voice, wash | on | 1,114 |
| B35 | Knockdown, drag, wash a player | Ragdoll knockdown from a Throw or anything thrown, drag a knocked-down teammate, wash them in the machine, struggle with Space | `game/knockdown/`, `game/player/ragdoll.gd` | net_knockdown, drag, wash, throw_knock | on | 1,840 |
| B36 | Upgrades and the Upgrade menu | Two currencies; 33 Upgrade nodes in `data/upgrades.json` (all `built: true`), Personal and House trees, Old Tree is the Upgrade station, icon per effect, Sole Mates, Sock Sense, Sock Smarts | `game/campaign/upgrade*.gd` | upgrades, synergy, xray | on | 1,749 |
| B37 | X-rays | Sock X-ray (key 1, Show pair) and Cabinet X-ray (key 2) with cooldown, own colours, outlines | `game/campaign/xray*.gd`, `cabinet_xray*.gd` | xray, cabinet_xray | on | 750 |

### 1.5 Characters

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B40 | The Cat | Black cat: naps, swats Socks, navigates the house on a navigation mesh, can be petted/picked up/thrown, brings Socks when petted, gets lost and is recovered by a watchdog, naps in the Elevator, comes out of the washing machine in a new coat, real animations and a real hiss, litterbox visits | `game/cat/` | cat | on | 3,434 |
| B41 | The Old Tree | In the garage; the Upgrade station; breathes and talks (voice ageing, calls the players at the start, says when presents are ready, hints a Mate's floor) | `game/campaign/old_tree_motion.gd`, `game/audio/*tree*`, `data/voiceover/old_tree/` | old_tree | on | 784 |
| B42 | Avatar: the sock creature | Bends with the look, pupils follow teammates, trim darker, jump squash, first-person belly | `game/player/avatar.gd`, `tools/blender/make_avatar.py` | avatar, net_avatar | on | in 4,102 |

### 1.6 Progression

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B50 | Wardrobe | Slots Hat, Clothes, Socks piece, Trail; "< NAME >" selector per slot, everything starts locked, shows only unlocked pieces; 120 piece glb files in `assets/avatar/wardrobe/`, 28 builders; animated touches for rare pieces; 17 Trails; piece models for the eight new Collections | `game/player/wardrobe*.gd`, `trail_effect.gd`, `trails/`, `piece_touch.gd` | wardrobe | on | 2,713 |
| B51 | Profile, Lifetime tallies, Sock encyclopedia | Profile (name, id, colour, look, unlocked pieces, tallies, encyclopedia); lifetime unlocks; the encyclopedia book in the house | `game/player/profile*.gd`, `game/campaign/book*.gd`, `encyclopedia_view.gd` | wardrobe, save | on | within 2,713 |
| B52 | Gifts, milestones | Wardrobe pieces come as Gifts; the milestone table is empty (Q308); Secrets give pieces | see B25, B29 | gifts, wardrobe | on | n/a |
| B53 | Achievements | Not built (see P20); Lifetime tallies exist | n/a | n/a | not in game | 0 |

### 1.7 Menus, lobby, saves, settings, net

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B60 | Main menu, Options, Licence, loading, cursor | Title with World rows, Options (volume, mouse speed, FPS cap, graphics Auto/Low/Medium/High, fullscreen), Licence/credits, loading screen with a fade, own cursor, Profily frame overlay (F3) | `game/ui/title_screen.gd`, `options_view.gd`, `licence_view.gd`, `loading_screen.gd`, `game/core/settings.gd` | menus, ui, graphics | on | in ui 5,489 |
| B61 | Lobby | A Lobby screen with pedestals, ready state, countdown, a Wardrobe page, stats card, World settings sidebar drawer; a greyboxed giant sock drawer scene exists | `game/lobby/`, `game/net/lobby.gd` | lobby, worlds | on | 1,617 |
| B62 | Worlds and Groups | One Solo World and five co-op Worlds per Host; each co-op World belongs to a fixed Group by player key (ADR-0010) | `game/core/world_meta.gd`, `worlds.gd` | worlds | on | in core |
| B63 | Saves | One World encoding for stream, join and save; autosave; the old file is kept when a write fails; every carried thing survives save, quit and join | `game/core/saves.gd`, `game/world/world_codec.gd` | save, world_codec | on | in core |
| B64 | Co-op (Host listen server over ENet) | Host decides everything, Guests send Commands and predict their own picks/drops; Command table with parts registering their own Commands; join snapshot; Host checks Guest RPC payloads; Session in parts; Loopback for solo | `game/net/`, `game/core/command/` | net_*, commands, command_table, net_guard, net_join, net_title | on | 2,583 + command flow |
| B65 | Pings | Middle mouse bubble ping; emoji wheel; marker at screen edge; teammate outlines through walls | `game/ui/pings.gd`, `ping_wheel.gd` | net_ping | on | in ui |
| B66 | Controller | Pad driven play and menus: look curve, rumble, focus rules (pad-only focus), mappings A primary, B secondary, RT sprint, LT crouch; all 47 actions in the Input Map | `game/player/pad_*.gd`, `game/ui/pad_*.gd`, `project.godot [input]` | pad | on (polish is P40) | in 4,102 |
| B67 | Graphics presets and bench | Auto, Low, Medium, High (cheap Low preset: no lamp shadows), mirror cost cuts, ambient dust, quality keys | `game/core/graphics.gd`, `data/tuning/graphics.json` | graphics | on | 1 file |

### 1.8 Sound and music

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B70 | Sfx bank and picks | `data/sounds.json` events with candidates and designer picks, sound bench tool, per-event CC0 candidates, rate limits, credits | `game/audio/sfx.gd`, `sound_bank.gd`, `tools/sound_bench.gd`, `assets/audio/` | sfx | on; many events use a placeholder (first candidate) | 2,409 |
| B71 | Music, Radio source, ducking | Radio channels are the music; music ducked in cutscenes; wash sounds | `game/audio/music_duck.gd` | sfx | on | in 2,409 |
| B72 | Voiceover | Washer's voiced comments (stage_1..5 voices A/B/C), cutscenes 1 to 6, the Old Tree's voice; transcripts via `tools/voiceover/`; subtitles | `data/voiceover/`, `game/audio/voice_*.gd` | voice, old_tree | on | in 2,409 |

### 1.9 Debug tools

| Id | Feature | What it is | Code | Suites | State | Lines |
|---|---|---|---|---|---|---|
| B80 | Zoo | A test scene with every mechanic and a panel (22 sections), sandbox World, no save | `game/debug/zoo.gd`, `zoo_section.gd`, `zoo/` | zoo, debug_menu | on (debug builds) | 3,057 |
| B81 | F1 debug menu in the game | Basic debug menu (stuck test, X-ray of all loose Socks, quick actions) | `game/debug/debug_menu.gd`, `debug_tools.gd` | debug_menu | on (debug builds) | in 3,057 |
| B82 | Bench, stress test, probes | `--bench` (honest machine record, low-end script), PhysicsStress scenarios S0..S10, frame and tick probes, Profily wrapper | `game/debug/bench.gd`, `physics_stress.gd`, `stress_*.gd`, `profiler.gd`, `frame_probe.gd`, `tick_meter.gd` | stress_check, graphics | on (debug) | 2,565 |
| B83 | Graybox kit and Machines row | A kit (stands, ports, labels) and a zoo Machines row of prototype stands | `game/debug/graybox/`, `machines/` | graybox | on in `main` for the first kit; stands 1-12 live on parked branches (see P03) | 1,182 |
| B84 | Test harness and shot tools | `tools/run.sh` (one verdict line), `tools/shot.sh`, suites.sh, shot_set.sh, png_strip.py, layout.py, agent_start/finish, agent_cost.py, integrate.sh, export.sh, code_map.py, dup_scan.py, grep_rules.py, sound_bench, voiceover, Blender MCP pipeline | `tests/`, `tools/` | all | on | tests 44,048; tools GDScript 4,544 |

### 1.10 Asset pipeline (content already made)

Blender builders: `tools/blender/make_*.py` (one per asset: avatar, cabinets, cat, clock, elevator, exterior, flat/house, grotto, hamper, laundry bin, leg socks, pairing machine, parts (belt, detergent, filter, motor, softener), radio, sock balls, sock detector, sock vacuum, socks, tv, wardrobe, wardrobe station, washing machine face), `house_furniture/` (about 4,100 lines), `wardrobe_pieces/` (28 builders). Outputs under `assets/` (house, cat, avatar with 120 wardrobe glbs, etc.). Detail is in `docs/research/nativize/fresh/assets-inventory.md`.

---

## Part 2. Planned, not in the game

State words: **asked** (the designer asked for it), **proposed** (an agent proposed it, the designer has not picked), **waiting** (waiting for a designer pick or an answer), **started** (code or material exists on a branch, not merged), **parked** (the designer said not now), **closed** (wontfix, listed so it is not rebuilt by mistake).
Kind: **new** feature, **change** to an existing feature, **fix**, **content** (models, sounds, Designs, text).

### 2.1 Devices, tools and the machines the designer wants next

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P01 | Three final vacuum devices: Smart Sock vacuum (today's vacuum plus a filter Upgrade), Backpack vacuum (worn, own tank 16, no filter, spit-out only), Splitter (carriable, two filtered outputs, 0.5 s a Sock, hopper 40, three Upgrades). The pairing machine is off. Spec is the Answers of tools/24 (Q2087-Q2142) | tools/24 (`in-progress`), designer 2026-11-19 | asked; spec done; build tickets `ready-for-agent` | P02 first | new |
| P02 | The shared piece: vacuum Pour (carrier holds E, container tips 70 deg, one Sock every 0.15 s), nozzle Spit-out stream (hold right click, ignores the filter), the Filter (Size and Collection, wheel steps, shared by whoever holds the nozzle, saved and joined), and removal of the old unload (mode button, take-one click, rear outlet spit, Quick Spit Upgrade) | tools/25; branch `tools/25-vacuum-pour-spit-and-filter` (1 commit, 23 files, +1,144 -618); code to lift on branch `tools/23-nozzle-filter-variants` | started on a branch; ticket `ready-for-agent`; one owner (Q2114) | none | change |
| P03 | Backpack vacuum: two lie in the kitchen from New Game whatever the player count; click picks up, E wears it on the back (nozzle out takes the whole Hands), worn Wardrobe backpack hidden, drops on knockdown | tools/27 | asked; `ready-for-agent` | P02, P06 | new |
| P04 | Splitter: one stands on the pairing machine's old spot (first-floor bathroom); outputs have the nozzle's filter and display; Upgrades faster (3 levels), bigger hopper (2), Collection filter (1), third output (1); new suite `splitter` | tools/28 | asked; `ready-for-agent` | P02, P06 | new |
| P05 | The filter nozzle Upgrade (display plus both filters, end of the vacuum row, 2 Drawers placeholder); replaces the flag `vacuum.filter_unlocked` | tools/29 | asked; `ready-for-agent` | P02 | new |
| P06 | Models: Backpack vacuum (variant b, the capsule tank), Splitter (variant a, the tower with the paddle wheel), nozzle display (variant a, the clip-on pod). Picks are made (Q2171-Q2174); line-ups on branches `tools/30-vacuum-device-models` and `-final` and in `builds/review-vacuum-devices/` | tools/30 | picked; model build waiting | none | content |
| P07 | Glossary terms missing: Smart Sock vacuum, Backpack vacuum, Splitter, Filter, Spit-out, Pour; open placeholders: third output place, what E does while the splitter is carried, pad bindings, spit pace | tools/24 follow-ups | proposed | P01 | content |
| P08 | Parked graybox machines from the Machines row (stands 1-9 on branch `tools/machines-review`, 8 commits ahead; stands 10-12 on `tools/23-nozzle-filter-variants`, 10 ahead; per-ticket branches tools/19, 20, 21): the Sorter in three forms with sacks and three ways to key a sack (sample Sock, cartridges, dial); Laundry chute (several openings, one exit, players ride it, plain physics); Clothesline (hang Socks by hand, mates auto-pair on the line, 10 pegs); Sock launcher (aim, preset auto launch); Size grate. The designer picked stand 5 (the nozzle filter) and said "the test row's other machines stay parked on their branches" (Q2112) | tools/19-23 (`ready-for-human`) | parked | graybox kit (tools/18, merged) | new |
| P09 | Chute and clothesline "in the real house": where the openings and exit go; chute exit design (a catch basket vs the shaft's bottom behind a lip) | tools/20 follow-ups | proposed | P08 | new |
| P10 | Back-mounted collecting devices: idea sheet of five (Vac-Pack, Catch Basket, Hamper Pack, Sweeper Tail, Pairing Pack) with greybox stills; "back devices - park for now" | tools/16; branch `tools/16-back-devices`; `docs/llm/tools/back-devices-ideas.md`; `builds/review-back-devices/` | parked (Q2060); reminder promised (Q1852) | P01 (relation to vacuum and Hampers, Q1829) | new |
| P11 | Pairing machine sounds: hopper drop, start click, running loop, count tick, Pair out, done bell, refusal (the vacuum's sounds are done) | tools/06 (`ready-for-agent`, later) | asked | pairing machine switched back on | content |
| P12 | Sock detector, Hampers, pairing machine, Dirty Socks and the Grotto are built but off: the designer decides which come back (the new project may simply leave them) | switches, ADR-0011/0012, progression/78, tools/26 | off since 2026-11-10 / 2026-11-19 | n/a | decision |

### 2.2 Progression, rewards, play modes

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P20 | Achievements: a Profile-kept badge system, definitions as data (`data/achievements.json`), toast, page on the title and pause menu, rewards some Wardrobe pieces, hidden ones "???", fake backend for tests, Steam mirror later behind one seam (ADR-0009 proposed). System only for now, no list (Q1688-Q1699). Replaces the empty Wardrobe milestone table | progression/81 (`needs-info`, priority next); branch `progression/81-achievements` (docs, 565 lines) | asked; design answered in part; open questions in Part 3 | Profile; Steam (P40) for the mirror | new |
| P21 | Wash cycles: replayable modes chosen by the Host at New Game (one per Run), first completion of each gives a themed Wardrobe piece. Throwaway prototypes exist: movement (Tumble Dry, Static Cling, Rinse, Heavy Duty), rules and area (Hand Wash, Mixed Load, Darks, Rising Foam, Pre-wash), Cabinets (Shuffle, Basic Everywhere, Blank Labels, Picky Drawers); ideas not prototyped: Delicates, Colour Run, Hot Wash, Quick 15', Lost & Found, Split Senses, Cat Nap, Shared Hands | progression/73 (`needs-info`); branches `proto/73-wash-movement`, `proto/73-wash-rules-area`, `proto/73-wash-cabinets` (throwaway); `builds/review-wash-*` | asked; parked until its grilling (Q1962) | Cabinet pools per room (progression/71, merged); a Collection on several Cabinets (refactor) | new |
| P22 | Rethink what a Drawer and a Cabinet completion gives (Coins, Drawers, gifts and confetti all at once feel overwhelming; a growing Cabinet must reward partial completion quietly) | progression/72 (`needs-info`) | asked; its own grilling | none | change |
| P23 | Co-op variants of the cosmetic pieces: an 8-piece 7th piece per Collection (56 in all), earned by completing a Collection's Pairs in a co-op session, a gift to everyone there; the co-op mark on the piece open | progression/34 (`ready-for-agent`, priority next), Q964, Q965 | asked | Blender (Opus), Wardrobe | content |
| P24 | Gifts when the player owns every piece: now pays Coins "not final". Options asked: a piece from any Collection, give it to a teammate who lacks it, a colour variant, or Coins | progression/84 (`needs-info`, later), Q1834 | waiting | none | change |
| P25 | A new Drawer drops in only when a player first sees it, decided by the Host | progression/31 (`ready-for-agent`, later), Q824 | asked | none | change |
| P26 | Co-op-only Gifts (Q655) | progression/07 follow-up | proposed | none | new |
| P27 | Player stacking leftovers: a solo way to reach high spots (an Upgrade such as a jump or long Throw), stack height limits and animation, carrier jump rules | progression/10 follow-ups | proposed | none | new |
| P28 | Drum finale leftovers: what happens to the handed-out Pairs pile after the drum (when, how, seen or not), the drum's Blender art (Q1899), the drum's final name (placeholder "the Drum"), the washer's drum lines to record (cutscene_5 still says "dung... eon"), water sounds, suck-in polish, hatch height | dungeon/04, dungeon/06, dungeon/07 follow-ups | proposed | designer records lines | content |
| P29 | The drum's shuffle spin: now and then the machine spins and every loose Sock and Pair is thrown to a new spot, players tumble and are knocked down; when it spins is open | dungeon/05 (`needs-info`, later), Q1881-Q1883 | asked, tracked "don't do it now" | the drum (built) | new |
| P30 | Try more mechanics and layouts for the inside of the washing machine: questions carried from dungeon/01 (UV lantern, does shelving reveal the true Design, sock balls showing marks); the UV-lantern generic-Sock idea of dungeon/01 was closed as superseded | dungeon/02 (`needs-info`); dungeon/01 and 03 `wontfix` | asked; likely superseded by the drum finale (designer to confirm) | none | new |
| P31 | Final-level idea notes: about 85 ideas (comfort rules, level concepts, pacing of one wash cycle, set pieces, feeling-led ideas); only the drum is built | `docs/ideas/final-level/01-05` | ideas, nothing decided | P28, P29 | new |
| P32 | A talking NPC that tells the plot: who (a new character or the Old Tree), moves or appears in later Stages, synthesised voice other than the Old Tree's, subtitles; the designer writes the plot | story/01 (`needs-info`, later), Q1838-Q1841 | asked; designed in the future | none | new |
| P33 | Polish rounds the designer has not started: Wardrobe pieces of the new Collections (about 7 questions: hoods and hats, glows, names "Porthole visor", placeholder touch numbers); the living Old Tree (co-op lines, away/affordable lines, washer cut-off, "upgrade unlocked" and "after a stage" moments not built); Stage presents and the Mate-floor hint; Secrets (discovery hints, finding moment, models) | progression/94, 95, 96, secrets/05 (all `needs-info`) | asked; waiting for the designer's list | none | content |
| P34 | Balance and feel round: the designer tunes hundreds of placeholder numbers in `data/tuning/*.json` (62 sections) after a full playtest: rarity tiers, Mate distance, payouts, Hands/Throw feel, spill counts, Stage Pair counts, Upgrade prices and levels, Drawer payout scale | questions/06 (`ready-for-human`), Q164, Q1111 | waiting for a playtest | all features | change |
| P35 | Wardrobe: locked pieces show their unlock progress ("12 / 50 Pairs shelved"); where else pieces come from once milestones are replaced by Achievements (Q1692) | progression/32, 22 follow-ups | proposed | P20 | change |
| P36 | Final screen leftovers: "who did what" titles (most throws, most Cat pets), names on hover for previews, and what the Lobby offers after an ending (a finished World, or only New Game); staying in a finished World to keep tidying | progression/85 follow-ups | proposed | none | change |

### 2.3 Co-op, net, Steam

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P40 | Steam: GodotSteam 4.24 `SteamMultiplayerPeer` (server_relay, star), friends-only lobby of exactly 4, Steam name cut to 16 characters, Steam Cloud for the Profile and Worlds, rich presence, "Invite friends" in the Lobby, Join by address hidden in Steam builds, Player key `steam:<id>`; develop on app 480 until the designer pays the Steamworks fee; Steam Input and Steam Deck are not targets | multiplayer/12 (`needs-info`, later), Q1674-Q1687, `docs/research/steam.md`, ADR-0009 | parked "starts only when the designer says so" (Q1957) | Lobby, Worlds, the NetBackend seam (built) | new |
| P41 | Proximity 3D voice chat, open mic by default with push-to-talk, built last (Q256-Q261); codec, echo, mute per player open | multiplayer/13 (`ready-for-agent`, later) | asked | Steam (works through both peers?) | new |
| P42 | A per-player secret so a hostile Guest cannot take another player's Upgrades by sending their profile id | multiplayer/36 (`ready-for-agent`, later), Q1187 | asked | bump `SAVE_VERSION` | fix |
| P43 | Guest low FPS over the internet: the report is done (`docs/perf/guest-fps-report.md`, a measuring tool `tools/guest_fps.*`), the designer picks which findings become fix tickets; the first finding is teammates and thrown Socks stuttering while the own camera is smooth | multiplayer/37 (`ready-for-human`, priority now), Q1814-Q1860 | waiting | none | fix |
| P44 | Net stream rework flagged by the deep review: poses and flights go as Variants every tick, uncapped; reliable on Steam; Commands have no rate limit; a Command the Host drops is never undone on the Guest (N6); wrong-build refusal (N4) | `docs/research/deep-review.md`, multiplayer/33 follow-ups, lobby/01 follow-ups | proposed; no ticket | P40, P43 | change |
| P45 | Physics stress verdicts still missing: S4 (picks, drops, Throws), S5 (vacuum and pairing machine), S8 (ragdolls on Heaps), rogue spew as MultiMesh, chunked join/save for big worlds, network stress N1/N2 through a lossy relay (stubs) | physics/31 (`ready-for-agent`, next) | asked | the stress tool | fix |
| P46 | Keep the players' spawn spots clear of Heaps (1.5 m circle, `mess.spawn_clear`) | physics/28 (`ready-for-agent`, later), Q959 | asked | none | fix |
| P47 | House collider budget decision (raise the target, not merge furniture, Q1097; waits for the low-end PC bench numbers) and measuring Jolt's contact buffers in play (5,000-Sock rain loses no Socks) | physics/29 (`needs-info`), physics/30 (`ready-for-agent`) | waiting / asked | low-end bench | fix |
| P48 | Multiplayer zoo: Host hosts a zoo, Guests join, F1 panel for everyone in the zoo only, actions as Commands, debug builds only | maintenance/119 (`needs-info`, next), Q1729-Q1740 | parked (Q1961) | Lobby (built) | new |

### 2.4 Performance, graphics, rendering

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P50 | Compile shaders before play: shader baker on in `export_presets.cfg` (the lead edits with the designer's OK) and every material drawn once behind the loading card; target a steady 30 fps on Low with no freezes on an Intel UHD 620 | graphics/03 (`ready-for-agent`), Q1972, Q1973, `docs/perf/low-end-report.md` | asked | none | fix |
| P51 | A fourth graphics preset, Lowest (render scale 0.5, bilinear, no FXAA, sky radiance 32, cheap sun shadow; auto for the oldest GPUs) | graphics/05 (`needs-info`), Q1975 | waiting for the low-end PC bench runs (maintenance/134) | P55 | new |
| P52 | Socks glow too much in dim rooms: suspects are RIM/RIM_TINT, fabric sheen, shadows on the Mess; per-suspect shot sets with tuning keys | graphics/06 (`ready-for-agent`); branch `graphics/06-sock-glow`; `builds/review-sock-glow/` | started; the designer's pick: "idk yet" (Q2061) | none | change |
| P53 | Physics tick spikes: the bench times each tick itself, profile the 4-5 ms tick, cheap safe fixes | maintenance/108 (`ready-for-agent`, next) | asked | P54 | fix |
| P54 | Aim chain at a lower rate (`players.aim_every_ticks`, 1, 2 or 3); the designer plays `builds/review-aim-rate/every-2-ticks` and `every-3-ticks` | maintenance/110 (`ready-for-human`, next) | waiting | none | change |
| P55 | Low-end bench window size bug (the 720p and 540p runs ran at the saved fullscreen size); unknown stop names fail loudly | maintenance/136 (`ready-for-agent`) | asked | none | fix |
| P56 | Day cycle writes lights only when they change (re-measure the 6th-frame spike); measure interpolated transforms and MultiMesh AABB; tick cost by system cut ideas (Rig 0.84 ms of 2.0, secrets_washes, move_movers) | maintenance/70, 87, 135 | asked | none | fix |
| P57 | Occlusion culling for the house (baked occluders of the shell; X-ray, stickers set to ignore culling) | maintenance/72 (`needs-info`, later), Q1955 | parked; may come with the move | the house kit | new |
| P58 | Graphics fidelity choices never made: GI path and day-cycle strategy, room ambient colours, colour grade, sun shafts, how lived-in, texture grain, MSAA 4x on High | `docs/research/graphics-fidelity.md` section 4 | proposed; no ticket | none | change |
| P59 | Mirror viewport 2x MSAA dropped (first Medium mirror froze 8.8 s); the sun shadow in reflections; designer re-measures | graphics/02 follow-ups | proposed | P50 | fix |
| P60 | A floor's Socks hitch (100-290 ms at the Fix): `SockLayout._plan()` off the main thread; option D "revisit with more Socks per floor" | maintenance/109 follow-ups, `docs/research/spawn-lag.md` | proposed (partly done) | none | fix |

### 2.5 Input, menus, UI

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P70 | Controller and controls polish: rebinding keys and pad buttons in Options (not built; key hints are fixed text), pad focus glow colour, one combined LB+RB glyph, Join by IP is keyboard-only, Steam Input, rumble strengths, aim assist (Q1554: none), look curve and deadzone defaults, Upgrade tooltip covers neighbours; the controls report's scheme proposal | maintenance/107 (`needs-info`, later), `docs/research/controls-map.md`, `controller-support.md`; branch `proto/103-controller-feel` (WIP prototype) | parked until the designer lists what to polish (Q1962) | none | change |
| P71 | A mouse and keyboard rebinding screen; conflict groups (Space jump + skip_cutscene, B back + secondary) | maintenance/115 follow-ups | proposed | P70 | new |
| P72 | Localisation: no `tr()` anywhere | maintenance/131 follow-up | proposed | the move | new |
| P73 | Lobby leftovers: dim the Lobby behind the drawer, close on outside click, the "One Play" button on the title, the Guest's view while the Host is in a menu, the wording of refusals, Host name field place | lobby/05-08 follow-ups | proposed | none | change |
| P74 | A game icon (the build uses Godot's default); Licence/credits wording | flat/42, flat/46 follow-ups | proposed | none | content |
| P75 | Lobby by Steam: "Invite friends" | lobby/03, 07 follow-ups | proposed | P40 | new |
| P76 | Options leftovers: a tick per slider step, which sounds belong on the UI bus | flat/46 follow-ups | proposed | none | change |

### 2.6 Cat, house, content from review follow-ups

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P80 | Cat: the Throw rule (the Cat can be thrown only once the player has Throw?), what the Cat does after knocking someone down, the Cat's swat as a way to wake her in the Elevator, a refusal wording while she is in the car, ease-out cross-fades, the long soak stress case run regularly (about 9 min) | cat/01, 06, 13, 16, knockdown/04 follow-ups | proposed | none | change |
| P81 | Litterbox: flap sound, visit feel (scratch 6 s, flap shut again) and placement judged in play; numbers `litter_*` in `data/tuning/cat.json` | cat/11 (`ready-for-human`), Q1993 | waiting | none | content |
| P82 | House: rename "the flat" to "the house" everywhere (GLOSSARY, UI text, docs, code names `FlatLayout`, `flat_layout.json`, `make_flat.py`) | house/07 (`ready-for-agent`, next), Q411, Q1954 | asked; free in a fresh project | none | change |
| P83 | Basement drying rack removed "for now": delete for good or bring back; the unused armchair piece; bikes remodel closed (house/13 wontfix, Q1146) | house/34, 32, 13 | proposed / closed | none | content |
| P84 | Sound hunt 2: CC0 candidates for knockdown, tv_static, lid_open/lid_close, car_door_open/close; the designer then picks on the sound bench | flat/64 (`ready-for-agent`, later), Q478 | asked | sound bench | content |
| P85 | Sound picks the designer has not made: wash_calm, wash_bin, machine_break, socks_pour, xray_ready, the elevator ride and squeeze, the dust-sheet pull, door open/close, gift rattle, ping blip per emoji, the pairing hold ticks; until then the first candidate plays | many follow-ups; `data/sounds.json` | waiting | sound bench | content |
| P86 | Idea parked in the move plan: SoftBody3D for held Socks, cutscenes as AnimationPlayer scenes, crouch animation instead of per-point offsets, Resources instead of `sounds.json`, delete the Grotto | maintenance/131 follow-ups | proposed | the move | change |
| P87 | Studio intro leftovers: trailer export codec; a squash on the GAMES slam | intro/01, 02 follow-ups | proposed | none | content |
| P88 | Ambient effects: which presets get which, whether effects react to play (dust bursts at the vacuum) | graphics/01 follow-ups | proposed | none | change |

### 2.7 The move itself and tooling

| Id | What it is | Source | State | Depends on | Kind |
|---|---|---|---|---|---|
| P90 | The move to a fresh project: core first, scenes and Resources workflow, features ported one by one with teaching, new test suite, tools reused, a retrospective and a skill set; the fresh-project preparation docs are `docs/research/nativize/fresh/` (assets-inventory, new-project-start, state-and-coop) | maintenance/131 (`needs-info`), 149, 150, Q2143 | asked; this session prepares only | the designer's grilling | new |
| P91 | A skill set (and a written retrospective) for moving another code-built project the same way | maintenance/139 (`needs-info`), Q2143 comment | asked | P90 | new |
| P92 | Starter kit 7: carry the new tools (png_strip, agent_start/finish, suites, shot sets, agent_cost), agent safety brief, ticket board mod, graybox kit as an optional zoo part | maintenance/147 (`needs-info`), Q2058 | asked; "not now" | P90 | new |
| P93 | The zoo's playground: a plain walk-through level beside the house with stalls (Cabinet with Socks, washer, pairing machine, vacuum, Hamper, cat, rigs, effects), mannequins in Trails | maintenance/114 (`needs-info`, next), Q1713-Q1716 | parked: the F1 menu covers the quick needs (Q1961) | the move (zoo comes new) | new |
| P94 | Leave debug code out of release exports (title reaches debug by path or registry; export excludes `game/debug/**`) | maintenance/118 (`ready-for-agent`, later), Q1747 | asked | none | change |
| P95 | `tools/run.py` forwards `--reverse`; `code_map.py --check` crashes on `game/dungeon` | maintenance/133 (`ready-for-agent`), 138 follow-up | asked | none | fix |
| P96 | Typed Resources for tuning (steps T1-T6) | maintenance/116 (`wontfix`: folded into 131), `docs/research/nativize/tuning-resources.md` | closed; folded into P90 | P90 | change |

### 2.8 Closed (wontfix) tickets, listed so they are not rebuilt by mistake

dungeon/01 (the UV-lantern dungeon prototype) and dungeon/03 (water drum prototype): superseded by the drum finale. flat/12 (art touch-ups), house/13 (bike remodel, "no longer wanted", Q1146), maintenance/27 ("Buffer argument is not a valid buffer"; never reproduced; reopen if seen), maintenance/116 (typed tuning, folded into 131), physics/15, 16 (snapshot stream and Guest prediction, replaced by the event design, Q1034), physics/34 (what Jolt limits cost), progression/30 (one click opens a floor; superseded by progression/37), progression/35 (duplicate designs), progression/62 (choose Cabinet draw by hand; "the per-room pools are enough", Q1623), questions/04 (MVP Collections, superseded by 17 Collections), rogue-machine/02 (stronger rogue sequence; the old choreography was removed, Q1470).

### 2.9 Open follow-ups in done tickets that describe a feature or a change of play, look or sound (not already listed above)

These sit in the `## Open follow-ups` sections of done tickets (1,084 lines read; counts in Part 6). Most are "keep or change?" questions on a built placeholder. They are grouped here by theme, each pointing at the source ticket; a one-line summary only.

| Id | Theme | Items (source ticket) |
|---|---|---|
| P100 | Held items and Hands feel | wheel and turn resets (flat/65), turn shown to a teammate or mirror (flat/53, 65), held info follow point and wording (flat/21, 71), drop crosshair colours while charging (flat/66), Throw hold feedback in the first 0.25 s, lob rule (flat/36), Radio hand-over by Throw (flat/50), Radio capacity cost (flat/68), Guide card spare rules (flat/70, 81) |
| P101 | X-ray and effects feel | Show pair edge cases (flat/67), Cabinet X-ray slot, naming, sounds (flat/75, 84), ready sound (xray_ready), outline tint (flat/85), pairing pop, sparkles colour, teammate hears the pop (flat/43, 69), Collection-complete banner readability (flat/69, 77), "+N" overlap |
| P102 | House and lighting | day/night lamp times and fades (flat/28), HDRI picks and dusk blend (flat/30), basement dim levels, Medium/Low wall light leaks (house/27), warm fill tint (house/29, 30), stairwell shadow cost (house/31), garage ramp slope, hall plant (house/19), roomier house roof pitch (house/37), mirror paleness (house/15) |
| P103 | Elevator and Doors | hatch click rules, rope creak, call sounds (house/17, 26), Doors swing sides, push directions, leak of unshadowed light (house/21), rider climb numbers and letters (house/35) |
| P104 | Mess and Socks | Sock rest rules and stairs (house/16), rare mates share (house/20), pushed-up items pop (house/18), heap look and washer fan heap (physics/11), spill counts at 10,000 Socks, Socks standing on end (physics/07), Sock glow, print atlas size, motif list review, Design readability (progression/50) |
| P105 | Knockdown and avatar | getting up facing, bounce, knocked view lock (knockdown/01), struggle count display (knockdown/02), washed again at once (knockdown/03), look bend while crouched (multiplayer/21), name tag height, trim darkness, squash scope |
| P106 | Stages and gifts | Rows and Pairs numbers, the Stage bar look, locked-Drawer refusal, hold-the-door remnants, gift box look, carry and drop rules, gift label, pile layout (progression/02-27) |
| P107 | Upgrades | Quick Grab prices, Double Glow prerequisite, Wide Funnel meaning, Long Hose, Roomy Car look, Hamper rules (pairs, Drawer pour), "new object that sells Upgrades" (progression/48, 57-64) |
| P108 | Menus, Lobby, Options | slider ranges, bus choice, cursor size, text box cursor (flat/46, 49), loading screen content, fixed seed and pre-baked Mess (maintenance/16), lobby places and pedestals wording (lobby/05-07) |
| P109 | Sound and voice | clip peak levels (-5.9 dBFS comments), voice wording placeholders (Old Tree, washer), TV channel names, Radio track set, jazz placeholders (flat/47, 58) |
| P110 | Code and test follow-ups (counted, not listed) | typed event classes instead of string-keyed Dictionaries (maintenance/58, 80), Game/Main reading by property name, `Game.decide` carry checks, DropView rule bookkeeping, 32 thin forwards in Game, test fixtures and flake lists, static-state resets, memory use of bakes (about 1.1 GB per first bake), `Tuning.load_default` cache, `.uid` housekeeping, large files to split (sock_layout, physics_stress, sock_vacuum_view, room, cat) |

---

## Part 3. Waiting on the designer

Everything below blocks or decides queued work. "Verbatim" means the follow-up line is copied from the ticket
unchanged (long answers shortened only by joining wrapped lines). Source is the ticket id; the vault is not
carried over, so the Q numbers are the way back into the designer's history.

### 3.1 Every `[blocking]` open follow-up (60 lines, 22 tickets)

Notes: W01-W04 are in done tickets (dungeon/07 and the like) but still open. W05-W10 (maintenance/116) belong to a
ticket closed as `wontfix` and folded into maintenance/131: they are the typed-tuning split questions T1-T6 and
come back inside the move grilling. W47-W60 (tools/16, 19, 21, 22, 23) are questions on graybox stands that stay
parked on branches (Q2112); most are moot unless a stand is revived. progression/81: the designer answered
Q1688-Q1699 (scope: system only; rewards: some pieces; credit per achievement; milestones replaced; hidden ones
shown "???"; page on the title and pause menu; toast card; debug builds count; the word is Achievement; text
placeholder icons), so the blocking items on those topics are answered in the ticket's Answers although the lines
still read as open; still open there are the co-op-only question (6), Achievements and Secrets (7), wording (16) and
the later items (10, 13, 14, 15, 18, 19, 20).

**dungeon/05-drum-shuffle-spin** (needs-info): The drum's shuffle spin
- W01 [blocking] When it spins: a timer with a warning, reacting to the players, both, or at progress steps (Q1881 left open).
**dungeon/07-handed-out-pairs-after-the-drum** (done): What happens to the handed-out Pairs after the drum
- W02 [blocking] When the pile goes: at the spit-out itself, a few seconds after, or while players are still inside (e.g. each Pair fades some time after landing)?
- W03 [blocking] How it goes: a plain fade, a poof with sparkles, shrinking away, or something tied to the story (the machine or the Old Tree takes them, they go into the Laundry bins)?
- W04 [blocking] Is it seen? Whether the players should watch it happen (from inside through the glass, or after landing outside) or it happens off-screen.
**graphics/05-lowest-preset** (needs-info): A fourth graphics preset: Lowest
- W05 [blocking] The low-end PC's extra bench runs (maintenance/134).
**maintenance/108-physics-tick-spikes** (ready-for-agent): Physics tick spikes in the bench
- W06 [blocking] The aim chain is the biggest single cost (about 40% of a tick's script time). Built as a tuning number in maintenance/110 (review builds at every 2nd and every 3rd tick); the designer picks the rate there.
**maintenance/110-aim-rate** (ready-for-human): Aim chain at a lower rate
- W07 [blocking] Which rate: 1, 2 or 3? Play `builds/review-aim-rate/every-2-ticks` and `every-3-ticks` and watch the outline and the prompts while turning fast. Then set `players.aim_every_ticks` in `data/tuning/players.json`.
**maintenance/114-zoo-playground** (needs-info): The zoo's playground: a plain walk-through area beside the house
- W08 [blocking] Which stalls come first? (a) Socks heap and floor Pairs, pairing machine, vacuum, Hamper, mannequins, then Cabinet, then the house-only pads (recommended: it follows the cost and gives a usable playground after phases 1 to 4); (b) Cabinet with Socks first, as the designer's first example; (c) mannequins first.
- W09 [blocking] The washer stall: (a) a sign and a pad to the real washer in the house, plus a look-only washer with its face (recommended: S); (b) the sign and pad only; (c) a second working washer that takes loads and washes (L, 3+ days, touches lost items, the wash, the cat's load and the Final wash).
- W10 [blocking] The cat stall: (a) a sign and a pad to wherever the cat is in the house (recommended); (b) a fenced pen where the cat sits, naps and can be petted, picked up and thrown, but never walks out (M); (c) a pen it roams (L).
- W11 [blocking] Mannequins walk: (a) a short pace back and forth on their spot so the Trail marks spread out (recommended: no game change); (b) truly in place, marks piling on one spot (a small Avatar change).
- W12 [blocking] How many mannequins: (a) one per Trail (17) plus 3 hat-and-clothes sets, in two rows (recommended); (b) one per Trail only; (c) a few (4 to 6) the panel re-dresses.
**maintenance/116-typed-tuning-resources** (wontfix): Move game-only tuning from JSON to typed Resources
- W13 [blocking] T1 Split: C2 root GameTuning + a .tres per section (recommended) / A class per section / B 12 feature bundles / C1 one big file.
- W14 [blocking] T2 `_note` text (54 KB): `##` doc comments as Inspector tooltips (recommended) / a note field per section / a NOTES.md.
- W15 [blocking] T3 Colours: real Color fields with a picker (recommended) / keep html strings.
- W16 [blocking] T4 Class defaults: zero defaults so each number lives in one place (recommended) / today's numbers as defaults.
- W17 [blocking] T5 Inspector ranges: guides with or_greater/or_less (recommended) / hard limits / none.
- W18 [blocking] T6 players.json and gifts.json: keep whole as JSON (recommended) / split the Blender-read part out.
**maintenance/131-scenes-and-resources-plan** (needs-info): Move the game to scenes and Resources
- W19 [blocking] Do the scenes replace the JSON (read at load into the same data; recommended) or write JSON on save?
- W20 [blocking] Tuning: all 62 sections as typed `.tres`, only the often-tuned ones (drum, cat, stages, upgrades), a generic `TuningSection`, or leave it JSON?
- W21 [blocking] Do the Blender generators keep running for the house shell, furniture and avatar (meshes only), or stop entirely?
- W22 [blocking] One house scene, or one per floor?
**maintenance/150-target-code-shape** (done): The shape of the code after the move: classes, one standard interface, a class diagram
- W23 [blocking] The 15 designer questions (report section 9; S1 to S15 on the page) go into the maintenance/131 grilling. S1 (where a Door's "is it open" lives: shape A, B, or after the Radio spike) is the big one.
**maintenance/74-zoo-update** (done): Update the zoo and clean up its panel
- W24 [blocking] Check the renamed labels in the review build (list in the Built log).
**multiplayer/37-guest-fps-investigation** (ready-for-human): Low FPS on the Guest over the internet: find the cause
- W25 [blocking] Which of the report's findings become fix tickets (Q1814)? The report ranks them: `docs/perf/guest-fps-report.md`.
- W26 [blocking] When the Guest's frame rate looked low over the internet, was the camera itself smooth while teammates and thrown Socks stuttered, or did the whole picture slow down (F3 shows the number)? The first is the report's finding 1; the second was not reproduced here and needs the three checks under "To confirm on the designer's PC".
- W27 [blocking] Was the Guest on the same PC as in the local test, or on another one?
**progression/72-completion-rewards** (needs-info): Rethink Drawer and Cabinet completion rewards
- W28 [blocking] The grilling: what each completion gives (currency, gift, celebration), the order, and how a growing Cabinet's partial completion is rewarded.
**progression/73-wash-cycles** (needs-info): Wash cycles: replayable game modes
- W29 [blocking] The grilling after the prototypes: unlock order, which cycles stay, each cycle's rules and numbers.
**progression/81-achievements** (needs-info): Achievements: a local store now, Steam as a drop-in later
- W30 [blocking] **How many achievements, and which scope at first?** (a) about 30-45 across all five groups, cut from the DRAFT (Recommended: enough variety, well under Steam's 100 first limit); (b) a small set of about 15-20, progress and completion only; (c) the full DRAFT and more.
- W31 [blocking] **Achievements and the Wardrobe milestones** (the milestone table is empty today, Q308; Gifts are the only source of pieces since progression/79). (a) Side by side: achievements read the same Lifetime tallies, milestones stay a separate (empty) table for the balance round (Recommended: no rework, both independent); (b) achievements replace milestones: a milestone piece becomes an achievement's reward and `"unlocks"` goes away; (c) drop milestones entirely and keep achievements as badges only.
- W32 [blocking] **Rewards.** (a) None: a badge and a toast only (Recommended: keeps Gifts as the one source of Wardrobe pieces and keeps balance out of it); (b) some achievements give a Wardrobe piece; (c) Coins or Drawers.
- W33 [blocking] **Who gets credit for team events** (today's tallies count every player's Pairs, Collections, floors and games for everyone, but only your own Coins). (a) Per achievement: team for Stage, Collection, Final wash and the big Pair counts; own for skill, Hand-off and prank ones (Recommended: matches today's tallies, co-op stays friendly); (b) always own (only who shelved or did it); (c) always team.
- W34 [blocking] **Hidden achievements.** (a) A few hidden (the prank and Secret-like ones), shown as "???" until earned (Recommended: surprise without frustration); (b) none hidden; (c) all funny ones hidden.
- W35 [blocking] **Co-op-only achievements** (Hand-offs, Knockdowns, Washes, a full Session). (a) Include them, marked "co-op" on the page (Recommended: co-op is the game's heart); (b) only ones a solo player can also earn, so solo can reach 100 %; (c) include them but give each a solo alternative. Also: should team ones like "Gentle Cycle" count solo, where they are trivial?
- W36 [blocking] **Achievements and Secrets** (the glossary says a Secret is not an achievement). (a) Keep Secrets as they are; a couple of achievements count Secrets found ("Not So Secret", "Sock Sleuth") (Recommended); (b) no achievement mentions Secrets, so they stay a pure surprise; (c) one achievement per Secret.
- W37 [blocking] **Where the Achievements page lives.** (a) On the title screen beside the Sock encyclopedia, plus a pause-menu entry (Recommended: easy to find, readable in a game); (b) a tab or back pages in the Sock encyclopedia book; (c) an in-world object (say a corkboard of badges in the basement laundry) plus the title screen.
- W38 [blocking] **Toast style.** (a) A small card sliding in at the top-right with icon, title and a soft chime, about 4 s (Recommended); (b) a Whiteboard-style marker scribble; (c) the existing HUD message line only. And in Steam builds: (a) only Steam's overlay pop-up (Recommended: no double toast) or (b) both.
- W39 [blocking] **Icon art.** (a) Flat 2D hand-drawn icons in the Whiteboard's marker style, one per achievement, with a shared greyed sock-ball for locked (Recommended: cheap, on-tone); (b) rendered 3D sock-ball badges from Blender; (c) text-only placeholders until a later art pass. Steam will want a locked and an unlocked image per achievement (size to confirm, believed 256x256).
- W40 [blocking] **Debug builds and cheats.** (a) Count in every build, except in a Run where a debug cheat (e.g. cheat Coins) was used (Recommended); (b) never count in debug builds; (c) count always.
- W41 [blocking] **Wording.** (a) Punny titles, a plain one-line description of the condition (Recommended: fun to read, clear to chase); (b) punny both; (c) plain both. And: the DRAFT titles are placeholders to rename.
- W42 [blocking] **The word.** Add **Achievement** to the glossary as "a named badge a player earns in their own Profile when a condition is met; never a Wardrobe piece, not a Secret" (Recommended), or another name (e.g. Badge, Merit Sock); keep the "Avoid: achievement" lines on Lifetime tallies and Secret.
**progression/84-gifts-when-all-owned** (needs-info): Gifts when the player already owns the pieces
- W43 [blocking] Options asked in Q1834: a piece from any Collection, give it to a Teammate who lacks it, a colour variant, or keep Coins.
**secrets/05-polish-secrets** (needs-info): Polish the Secrets
- W44 [blocking] What to polish (asked in Q1837): discovery (hints, a list), the moment of finding, Secrets that don't trigger, the pieces' models.
**story/01-plot-npc** (needs-info): A talking NPC that tells the plot
- W45 [blocking] Who the NPC is (Q1838 offered a new character or the Old Tree).
- W46 [blocking] The plot text (the designer's, Q1840).
**tools/16-back-devices-ideas** (needs-info): Back-mounted collecting devices: idea sheet
- W47 [blocking] Which idea to build, and the ten questions at the end of `docs/llm/tools/back-devices-ideas.md` (Q1829: relation to the standing vacuum and the Hampers). Note: the Hampers are `enabled: false` (progression/78).
**tools/19-sorting-vacuum-grayboxes** (ready-for-human): Sorting vacuum: graybox every variant
- W48 [blocking] Thrown sacks: an unclipped sack is the game's Hamper, which cannot be thrown (only the Radio, the Sock detector and the cat are); a throw needs a carried "sack" kind with its own flight and landing. Should sacks be thrown at all, and what happens when one lands (stays shut, spills)?
- W49 [blocking] A Sock whose sack is full or unclipped is left lying (placeholder). Should it go to the rest sack instead, or the vacuum stop sucking (as a full plain vacuum does)?
- W50 [blocking] What a dial position means: placeholder positions are the stand's pile Collections shifted by one per click (sacks get Collections n, n+1, n+2), the last position the three Sizes.
- W51 [blocking] Cartridges: placeholder is one click-to-swap slot per sack cycling the pile's Collections, then the Sizes, then empty. Real cartridges (a rack to take them from, one per Collection in the house) are a look and play choice.
**tools/21-launcher-and-size-grate-grayboxes** (ready-for-human): Sock launcher and Size grate: grayboxes
- W52 [blocking] Should launched Socks and Pairs knock players down? The kit's ejected Socks use the "spit" flight that hits no player, and that is what the launcher uses; a launched Pair thrown at a team-mate is only catchable, never a hit.
**tools/22-machines-review** (ready-for-human): Machines review: tickets 19, 20 and 21 in one build
- W53 Collected verbatim from tickets 19, 20 and 21 ([blocking] first), then this ticket's own.
- W54 [blocking] (19) Thrown sacks: an unclipped sack is the game's Hamper, which cannot be thrown (only the Radio, the Sock detector and the cat are); a throw needs a carried "sack" kind with its own flight and landing. Should sacks be thrown at all, and what happens when one lands (stays shut, spills)?
- W55 [blocking] (19) A Sock whose sack is full or unclipped is left lying (placeholder). Should it go to the rest sack instead, or the vacuum stop sucking (as a full plain vacuum does)?
- W56 [blocking] (19) What a dial position means: placeholder positions are the stand's pile Collections shifted by one per click (sacks get Collections n, n+1, n+2), the last position the three Sizes.
- W57 [blocking] (19) Cartridges: placeholder is one click-to-swap slot per sack cycling the pile's Collections, then the Sizes, then empty. Real cartridges (a rack to take them from, one per Collection in the house) are a look and play choice.
- W58 [blocking] (21) Should launched Socks and Pairs knock players down? The kit's ejected Socks use the "spit" flight that hits no player, and that is what the launcher uses; a launched Pair thrown at a team-mate is only catchable, never a hit.
**tools/23-nozzle-filter-variants** (ready-for-human): Nozzle filter: three more graybox variants (stands 10-12)
- W59 [blocking] Stand 12, which filter the wheel steps: placeholder is wheel up (pad LB) steps filter A, wheel down (pad RB) steps filter B, each only forward through no sample, the pile's Collections, then the Sizes (wrapping). The ticket says "the nozzle holder changes a filter with the mouse wheel" but not how one wheel picks between two filters.
- W60 [blocking] Where the pour lands: "straight down in front of the container" read as the container's side away from the carrier (placeholder `pour_at` z -0.35), because carried its window faces the carrier and Socks poured on the window side fall on the carrier's own feet, hidden under the container. Setting `pour_at` z to 0.3 flips it. Even so, the carrier cannot see the pour in first person (the carried container hides the floor in front of it); a teammate sees it.

### 3.2 Tickets in `ready-for-human` (nine) and what each waits for

| Ticket | Waits for |
|---|---|
| cat/11 litterbox | the designer's play check of the placeholders: spot beside the toilet, the Cat's visit every about 240 s, hide chance 1 in 3, scratch 6 s, flap sound (placeholder cupboard sound); `builds/review-litterbox/` |
| maintenance/110 aim rate | pick 1, 2 or 3 ticks (`players.aim_every_ticks`) after playing `builds/review-aim-rate/every-2-ticks` and `every-3-ticks` (Q1963: keep waiting) |
| multiplayer/37 guest FPS | which findings of `docs/perf/guest-fps-report.md` become fix tickets; was the whole picture slow or only teammates; was the Guest on another PC |
| questions/06 balance and feel round | a full playtest, then every placeholder value set or kept (Q1111) |
| tools/19, 20, 21, 22, 23 | the grayboxes were played (review build `builds/review-machines/`); the designer liked stand 5 (nozzle filter) and moved on to tools/24; the rest stay parked on branches (Q2112); nothing was merged before the pick |

### 3.3 Review material waiting or parked (in `builds/`)

`builds/` holds 81 folders. Those tied to an undecided pick or a parked branch:

| Folder | Waits for | Branch |
|---|---|---|
| `builds/review-sock-glow/` | the stills pick ("idk yet", Q2061); the branch stays unmerged | `graphics/06-sock-glow` |
| `builds/review-aim-rate/` | the rate pick (above) | `maintenance/110-aim-rate` |
| `builds/review-machines/`, `review-tools12/` | played; only the parked-branch decision remains | `tools/machines-review`, `tools/23-nozzle-filter-variants` |
| `builds/review-vacuum-devices/` | model picks made (Q2171-Q2174); models to be built | `tools/30-vacuum-device-models(-final)` |
| `builds/review-back-devices/` | "back devices - park for now" (Q2060) | `tools/16-back-devices` |
| `builds/review-litterbox/` | the litterbox play check | merged |
| `builds/review-wash-cabinets/`, `review-wash-movement/`, `review-wash-rules-area/` | the wash-cycles grilling (progression/73) | `proto/73-*` |
| `builds/review-controller/` | the controller polish list (maintenance/107) | `proto/103-controller-feel` |
| `builds/review-water-drum/`, `review-dungeon/` | none: superseded by the drum finale | branches deleted |
| `builds/review-zoo-panel/`, `review-zoo74/` | maintenance/74: "Check the renamed labels in the review build" (W in 3.1) | merged |

I did not open the builds; their status above is read from tickets, not from the folders' contents.

### 3.4 Tickets in `needs-info` with no `[blocking]` line (22 `needs-info` in all)

dungeon/02 (mechanics and layout trials: the carried questions in Part 2 P30), graphics/05 (lowest preset: waits
for the low-end bench), maintenance/107 (controller polish: "the designer adds to it as they play"), maintenance/72
(occlusion culling: parked), maintenance/131 and 139 and 147 (the move, its skill set, starter kit 7),
multiplayer/12 (Steam, on hold Q1957), physics/29 (collider budget: parked until the low-end bench), progression/94,
95, 96 (polish lists), tools/16 (parked). The designer's open design decisions that no ticket carries are the
unpicked graphics fidelity choices (P58) and the unpicked sound candidates (P85).

---

## Part 4. Known bugs still open

Tickets of kind `bug` that are not `done` (of 40 bug tickets, 3 are open and 1 closed):

| Id | Bug | Source | State |
|---|---|---|---|
| X01 | The long soak finds the Cat off the stairs' steps: `cat:lost_soak_long` (stress case, `"stress": true`, not in the normal run) fails "only Grotto parks (1 of 26 finds): off the stairs' steps (stairs_ground) at (4.5, 0.0, 5.6) after a pet, seed 8, 1638 s". Not known since when, or whether a player sees it | cat/16 | `ready-for-agent` |
| X02 | `bench_lowend.cmd`: the 720p and 540p runs ran at the saved fullscreen size (2560x1440), so those rows are not at the asked size; `machine.cmdline` is empty | maintenance/136 | `ready-for-agent` |
| X03 | Jolt's contact buffers: lowered limits are applied (`max_contact_constraints=65536`); the measured proof that the 5,000-Sock rain loses no Socks and the memory cost is missing | physics/30 | `ready-for-agent` |
| X04 | "Buffer argument is not a valid buffer of any type" (rendering_device.cpp:1177) during the release stress S2 pick storm; never reproduced in the sandbox | maintenance/27 | `wontfix`: reopen if seen (Q1960) |

Failing, skipped or fragile test cases and behaviours mentioned in tickets (do not port as behaviour):

| Id | Item | Source |
|---|---|---|
| X10 | `upgrades:menu` failed 3 checks headless ("hovering lights a button", "focusing lights a button like hovering does", "a lit button...") on `progression/70` before that work | progression/74 follow-up |
| X11 | `mess:rest_fit` floats one house Sock over 1 cm in seeds 2 (bathroom) and 10 (laundry) after the catalogue grew | house/38 |
| X12 | `piano:rest` raised a SCRIPT ERROR (`sock_ids().max()` of an empty list, `tests/piano_test.gd:176`) | maintenance/77 |
| X13 | `tests/layers_test.gd` lists known layer violations in `KNOWN_VIEW_NAMES` and `KNOWN_NET_NAMES` (a rules file naming a view class, a file outside `game/net/` naming a net class) that "shrink as they are fixed" | maintenance/101 |
| X14 | `tools/run.py --here` has no override.cfg, so the `typed` suite fails there; run through the mirror | maintenance/101 |
| X15 | Several suites fail only in one `--only=` process with many suites (`parts:world`, `locks:leaf_sweep` fixed in 29d/29f); the known-flake ledger is `flaky-ledger.md` in the runner's shared folder | maintenance/39, 29a, 126 |
| X16 | Socks stand on their cuff in a Heap (a rigid Sock balances within 7 degrees; the bake lays them flat, a live rest does not) | physics/07, pipeline/03 |
| X17 | A thrown Sock dips 1 to 1.7 cm under the floor on a bounce and at the start of the landing glide; the drop's flick through a table top for about 4 frames when crouched beside it | maintenance/05, physics/35 |
| X18 | Loose Socks on a picked floor Pair float; gift boxes, Parts and the bin on a picked Pair float; Players' feet do not push resting Socks | physics/38 |
| X19 | Ragdolls do not lie on Resting Socks; players walk through Heaps (only stress walkers stand on `SOCK_REST`) | physics/22 |
| X20 | A player joining mid-drag is not told of the drag; a Gift box, Radio or Cat spinning in the drum lies by the door for a joiner | maintenance/49 |
| X21 | A Command the Host drops is never undone on the Guest (N6); a Guest's drops can fly to the wrong place and hop on | deep review, multiplayer/15 |
| X22 | A teammate's Throw on a Guest stops at the release point for about 50 ms | multiplayer/35 |
| X23 | The tick is 60 Hz, not 30 as tickets 25 and 108 and `settings.gd` said (the project sets no rate); a measuring column `physics_ms` was bogus | `docs/research/deep-review.md`, maintenance/108 |
| X24 | Teardown error "BUG, indexing did not unpair geometries from light" (58 lines, 29 lights), suspected engine side | maintenance/25 |
| X25 | A first Mess bake costs about 1.1 GB resident and is never given back; every suite with a world case sits at 1.5-1.8 GB | maintenance/57, 77, physics/32 |
| X26 | A floor's Socks still hitch the game at the Fix (100-290 ms before the research; partly fixed) | maintenance/109, `docs/research/spawn-lag.md` |
| X27 | The hose limit holds the holder in a straight line from the container through walls and floors | tools/01 |
| X28 | Door sounds: the flap plays the cupboard pool's full clip (not shorter) | cat/15 |
| X29 | The rogue sequence's wide shot looks through the decorative Sock heap and a standing player | rogue-machine/04 |
| X30 | Pad buttons: A is both `pad_primary` and `ui_accept`, B both `pad_secondary` and `pad_back`, Start both pause and skip_cutscene, split only by context | maintenance/115 |
| X31 | Stale doc and name drift: GLOSSARY "Cabinet" entry, "flat" vs "house", `FlatLayout` | progression/13, house/07 |

---

## Part 5. For the new project: one list to mark

Fill the last column with `port early` / `port later` / `redesign first` / `drop`. Only obvious notes are
filled in. The milestone is my suggestion: M1 assets, M2 the house, M3 first co-op slice, M4 core loop (the Mess,
Hands, Throws, Pairs, Cabinets), M5 the frame of a run (Stages, Laundry day, menus, saves, lobby), M6 features by need.

### 5.1 Built features

| Id | Feature | Suggested milestone | Note | Verdict |
|---|---|---|---|---|
| B01 | Hands, pick, drop, Throw, Hand-off | M4 | the core verbs; one hold system | |
| B02 | The Mess: SockWorld | M4 | ADR-0001, 0005, 0008; biggest file group (7,727 lines) | |
| B03 | Pairing and the paired moment | M4 | | |
| B04 | Cabinets, Drawers, Rows, payout | M4 | | |
| B05 | Catalogue of Designs (data) | M1 data, M4 use | 1,005 Design entries, 17 Collections | |
| B06 | Held info, hints, prompts, Highlight | M4 | | |
| B07 | Player movement, stacking | M3 | | |
| B10 | The house | M2 | a rename to "house" from the start (P82) | |
| B11 | Doors and openables | M2 | | |
| B12 | Elevator | M2 | one of the four parts of the house; owner rule | |
| B13 | Piano | M6 | | |
| B14 | TV and Radio (Radio is the music source) | M6 | | |
| B15 | Grotto, lantern | M6 | switched off by the designer since dungeon/04 (ADR-0012) | |
| B16 | Litterbox | M6 | numbers are placeholders | |
| B17 | Studio intro | M6 | | |
| B20 | Stages and floors, locks, Parts | M5 | | |
| B21 | First wash | M5 | | |
| B22 | Laundry day: bins and the Final wash | M5 | Dirty Socks switched off (ADR-0011) | |
| B23 | Final screen | M5 | | |
| B24 | The Drum finale | M5 | the last Stage | |
| B25 | Gifts and Stage presents | M5 | | |
| B26 | Guide card | M6 | | |
| B27 | Whiteboard | M5 | opens the Upgrade menu earlier; the Old Tree took over (B41) | |
| B28 | Hampers | M6 | switched off since 2026-11-10 by the designer | |
| B29 | Secrets | M6 | | |
| B30 | Sock vacuum | M6 | the planned rework is P01-P06 (redesign first?) | |
| B31 | Sock pairing machine | M6 | switched off since 2026-11-19 by the designer | |
| B32 | Sock detector | M6 | | |
| B33 | Laundry bin | M5 | with B22 | |
| B34 | Washing machine and the talking machine | M5 | | |
| B35 | Knockdown, drag, wash a player | M6 | | |
| B36 | Upgrades and the Upgrade menu | M5 | 33 nodes | |
| B37 | X-rays | M6 | | |
| B40 | The Cat | M6 | 3,434 lines, nav mesh | |
| B41 | The Old Tree | M5 | Upgrade station | |
| B42 | Avatar: the sock creature | M3 | | |
| B50 | Wardrobe, Trails | M5/M6 | 120 piece glbs | |
| B51 | Profile, tallies, encyclopedia | M5 | | |
| B60 | Main menu, Options, Licence, loading | M5 | | |
| B61 | Lobby | M5 | | |
| B62 | Worlds and Groups | M5 | ADR-0010 | |
| B63 | Saves | M5 | | |
| B64 | Co-op: Host, Guest, Commands, snapshot | M3 | ADR-0006 | |
| B65 | Pings and emoji wheel | M3 | | |
| B66 | Controller | M4 | pad polish is P70 | |
| B67 | Graphics presets and bench | M6 | | |
| B70 | Sfx bank and picks | M4 | | |
| B71 | Music and ducking | M6 | | |
| B72 | Voiceover and subtitles | M5 | | |
| B80 | Zoo | M3 | "tools stay in place" (Q2143); the new zoo comes with the move | |
| B81 | F1 debug menu | M6 | | |
| B82 | Bench, stress test, probes | M4 | | |
| B83 | Graybox kit and Machines row | M6 | | |
| B84 | Test harness and shot tools | M1 | reused, improved | |

### 5.2 Planned features and changes

| Id | Item | Suggested milestone | Note | Verdict |
|---|---|---|---|---|
| P01 | Three vacuum devices (Smart, Backpack, Splitter) | M6 | asked by the designer 2026-11-19; spec in tools/24 | |
| P02 | Shared piece: pour, spit-out, filter | M6 | one owner; built on a branch | |
| P03 | Backpack vacuum | M6 | | |
| P04 | Splitter | M6 | | |
| P05 | Filter nozzle Upgrade | M6 | | |
| P06 | Models for backpack, splitter, nozzle display | M1 or M6 | picks made (Q2171-Q2174) | |
| P07 | Glossary terms for the vacuum devices | M6 | | |
| P08 | Parked graybox machines (Sorter, chute, clothesline, launcher, Size grate) | M6 | parked on branches by the designer (Q2112) | |
| P09 | Chute and clothesline in the real house | M6 | | |
| P10 | Back devices | M6 | parked by the designer (Q2060) | |
| P11 | Pairing machine sounds | M6 | only if the machine returns | |
| P12 | Decide which switched-off features come back | M6 | Hampers, pairing machine, Dirty Socks, Grotto | |
| P20 | Achievements | M6 | Steam mirror depends on P40 | |
| P21 | Wash cycles | M6 | 13 prototyped twists, 8 ideas | |
| P22 | Completion rewards rethink | M5 | change of an existing feel | |
| P23 | Co-op variants of cosmetic pieces | M6 | content | |
| P24 | Gifts when all owned | M5 | | |
| P25 | Drawer drops in when first seen | M5 | | |
| P26 | Co-op-only Gifts | M6 | | |
| P27 | Stacking leftovers (solo high spots) | M6 | | |
| P28 | Drum finale leftovers (pile, art, name, lines) | M5 | | |
| P29 | Drum shuffle spin | M6 | "don't do it now" (Q1881) | |
| P30 | More mechanics and layouts for the drum | M6 | likely superseded | |
| P31 | Final-level idea notes | M6 | | |
| P32 | Talking NPC that tells the plot | M6 | designer writes the plot | |
| P33 | Polish rounds (Wardrobe pieces, Old Tree, presents, Secrets) | M6 | | |
| P34 | Balance and feel round | M6 | hundreds of placeholders | |
| P35 | Wardrobe progress hints, replacing milestones | M5/M6 | | |
| P36 | Final screen leftovers | M5 | | |
| P40 | Steam peer, lobbies, Cloud, presence | M6 | on hold (Q1957) | |
| P41 | Proximity voice chat | M6 | built last | |
| P42 | Profile secret against a hostile Guest | M3/M5 | | |
| P43 | Guest FPS over the internet | M3 | measure on the new netcode | |
| P44 | Net stream rework (deep review) | M3 | | |
| P45 | Stress verdicts S4, S5, S8, N1, N2 | M4 | | |
| P46 | Spawn spots clear of Heaps | M4 | | |
| P47 | Collider budget and Jolt buffers | M2/M4 | | |
| P48 | Multiplayer zoo | M6 | parked (Q1961) | |
| P50 | Compile shaders before play | M2/M5 | | |
| P51 | Lowest graphics preset | M6 | waits for low-end bench | |
| P52 | Socks glow in dim rooms | M4 | | |
| P53 | Physics tick spikes | M4 | | |
| P54 | Aim chain rate | M4 | | |
| P55 | Bench window size bug | M1 | tooling | |
| P56 | Day-cycle writes, interpolated transforms, tick cost cuts | M6 | | |
| P57 | Occlusion culling | M2 | may come with the move | |
| P58 | Graphics fidelity choices | M2 | | |
| P59 | Mirror MSAA | M2 | | |
| P60 | Floor Socks hitch | M5 | | |
| P70 | Controller and controls polish, rebinding | M6 | | |
| P71 | Rebinding screen | M6 | | |
| P72 | Localisation (`tr()`) | M1 | cheap early, expensive late | |
| P73 | Lobby leftovers | M5 | | |
| P74 | Game icon, Licence wording | M5 | | |
| P75 | Invite friends | M6 | needs P40 | |
| P76 | Options leftovers | M5 | | |
| P80 | Cat leftovers | M6 | | |
| P81 | Litterbox play check | M6 | | |
| P82 | Rename flat to house | M1 | free in a fresh project | |
| P83 | Drying rack, bikes, armchair | M2 | | |
| P84 | Sound hunt 2 | M6 | | |
| P85 | Outstanding sound picks | M4/M6 | | |
| P86 | Ideas in the move plan (SoftBody3D, AnimationPlayer cutscenes, crouch animation) | M6 | | |
| P87 | Studio intro leftovers | M6 | | |
| P88 | Ambient effects scope | M6 | | |
| P90 | The move itself | M1 | | |
| P91 | Skill set and retrospective | all | | |
| P92 | Starter kit 7 | M1 | | |
| P93 | Zoo playground | M3 | comes new with the move | |
| P94 | Debug code out of release | M3 | a registry or path seam from the start | |
| P95 | run.py --reverse, code_map crash | M1 | | |
| P96 | Typed Resources for tuning | M1/M4 | folded into P90 | |
| P100-P109 | The follow-up themes of 2.9 | with the feature each belongs to | | |
| P110 | Code and test follow-ups | n/a | "Every line of code has to fight for its life" (Q2143) | |

---

## Part 6. Counts and what I could not determine

### 6.1 Tickets by status and feature folder (578 tickets in 19 feature folders; one `issues/*.md` per ticket)

| feature | done | ready-for-agent | ready-for-human | needs-info | needs-triage | in-progress | wontfix | total |
|---|---|---|---|---|---|---|---|---|
| cat | 14 | 1 | 1 | 0 | 0 | 0 | 0 | 16 |
| dungeon | 3 | 0 | 0 | 2 | 0 | 0 | 2 | 7 |
| flat | 83 | 1 | 0 | 0 | 0 | 0 | 1 | 85 |
| graphics | 3 | 2 | 0 | 1 | 0 | 0 | 0 | 6 |
| house | 44 | 1 | 0 | 0 | 0 | 0 | 1 | 46 |
| intro | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| knockdown | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| lobby | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 8 |
| maintenance | 141 | 6 | 1 | 7 | 0 | 0 | 2 | 157 |
| multiplayer | 33 | 2 | 1 | 1 | 0 | 0 | 0 | 37 |
| mvp | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 13 |
| physics | 32 | 3 | 0 | 1 | 0 | 0 | 3 | 39 |
| pipeline | 15 | 0 | 0 | 0 | 0 | 0 | 0 | 15 |
| progression | 83 | 2 | 0 | 7 | 0 | 0 | 3 | 95 |
| questions | 4 | 0 | 1 | 0 | 0 | 0 | 1 | 6 |
| rogue-machine | 5 | 0 | 0 | 0 | 0 | 0 | 1 | 6 |
| secrets | 4 | 0 | 0 | 1 | 0 | 0 | 0 | 5 |
| story | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| tools | 17 | 6 | 5 | 1 | 0 | 1 | 0 | 30 |
| **all** | **508** | **24** | **9** | **22** | **0** | **1** | **14** | **578** |

By kind (frontmatter, spelled as written): build 365, polish 45, bug 40, research 19, feature 17, decision 17, task 14, docs 12, content 10, maintenance 7, prototype 6, tooling 5, design 4, refactor 3, perf 1, and 13 older tickets with no `kind`.

### 6.2 Follow-ups read

- `## Open follow-ups` in the 300 done tickets that have any: **1,084 lines** (5 `[blocking]`, 540 `[later]`, 539 untagged: older tickets' numbered or plain questions).
- Open (not done) tickets: **173 lines** (55 `[blocking]`, 98 `[later]`, 20 untagged). Across all tickets **60 `[blocking]` lines in 22 tickets** (Part 3.1; the sweep of 2026-11-12 counted 34 then).
- By my keyword count of the 1,084 done-ticket lines (a rough count, one line can match several): about 165 mention a placeholder number to tune, about 172 ask "keep or change?" or give lettered options, about 55 are code or test cleanups, about 81 concern sounds. The cleanup ones are counted in P110 and not listed.
- Not read: the `## Built log` sections of done tickets (only the litterbox's was read); the `spec.md` files and proposals were only grepped. `docs/llm/questions/live.md` (223 lines, a 2026-10-31 snapshot of open questions) and `docs/llm/maintenance/128-sweep-summary.md` were read in part; their open items are almost all the same questions as the tickets' follow-ups.

### 6.3 Rows per table

Part 1: 56 rows (B01-B84; the asset families are one paragraph). Part 2: 83 rows (P01-P110, including 10 theme rows for the follow-ups of done tickets) plus the one-paragraph closed list of 14 `wontfix` tickets. Part 3: 60 blocking lines, 9 `ready-for-human` tickets, 10 review-material rows. Part 4: 4 bug tickets and 22 behaviour or test notes. Part 5: 54 built rows and 74 planned rows (the planned ids are grouped, e.g. P100-P109 is one row).

### 6.4 Branches (93 refs in `git branch -a`)

45 `worktree-agent-*` branches and 2 `integrate/*` branches are 0 commits ahead of `main` (merged or empty). Of the other 43 local branches, 15 are 0 ahead (merged) and **28 are ahead of `main`**; Appendix B lists the 28. Branches ahead that hold a feature or a prototype rather than docs: `proto/*` (5: 4 throwaway wash-cycle and controller prototypes, 1 early Old Tree), `tools/19`, `20`, `21`, `23`, `25`, `30(-final)`, `machines-review`, `graphics/06-sock-glow`, `maintenance/110-aim-rate` (the tuning number for P54). `proto/77-old-tree-alive` has 6,555 lines of an early placeholder-voice Old Tree; main has the finished one.

### 6.5 What I could not determine

- Whether a done ticket's `[later]` follow-up was built later by another ticket without being closed under Answers. The sweep (maintenance/128) closed 3 and dropped 17; I did not re-verify the other 1,000 against the code.
- Test suites per feature are matched by name, not by reading the suites; suite counts, pass state and run time are unknown (no test was run). Suites not mapped above: harness, statics, typed, uid, tuning, runner (cross-cutting).
- Line counts of tests per feature were not measured (only the total, 44,048).
- Whether the switched-off features (Hampers, pairing machine, Dirty Socks, Grotto) still pass their suites: `hampers_off`, `pairing_off` and `grotto` suites exist and are named in tickets as green at the time.
- What the 81 `builds/` folders contain; their status is read from tickets only.
- Dates: tickets without `done:` (older style) show no completion date; I did not date them from git.
- The 17 Collections and 1,005 Design entries: the tickets quote 555, 605 and "about 500"; the data file is the authority (counted above), including the Dirty and Lost Socks sets.
- Which designer notes exist outside this repo (the Obsidian vault's own notes, `notes:` frontmatter names): not visible from here.
- The phrase "Laundry day" is not a glossary term; I read it as the Final wash with the Laundry bins (B22) and the First wash (B21).

---

## Appendix A. All 578 tickets

`feature/NN` : status : kind : title. Sorted by folder and number; the `done` date is in each ticket, not copied here.


**cat**
- cat/01 : done : build : A black cat in the house
- cat/02 : done : build : The cat starts on the couch
- cat/03 : done : build : The cat swats Socks
- cat/04 : done : build : A real cat hiss
- cat/05 : done : build : A washed Cat comes out in a new coat
- cat/06 : done : build : The Cat's poses as real animations
- cat/07 : done : build : A petted Cat brings Socks
- cat/08 : done : build : The Cat navigates the house
- cat/09 : done : bug : The Cat cannot leave the attic loft
- cat/10 : done : bug : The Cat gets lost
- cat/11 : ready-for-human : build : A litterbox for the Cat
- cat/12 : done : polish : The Cat brings Socks more often
- cat/13 : done : feature : The Cat naps in the Elevator
- cat/14 : done : polish : Cat follow-ups: Elevator naps and the litterbox
- cat/15 : done : bug : Door sounds are weird since the Cat merges
- cat/16 : ready-for-agent : bug : The long soak finds the Cat off the stairs' steps

**dungeon**
- dungeon/01 : wontfix : build : The Lost Socks dungeon: the grand finale (prototype)
- dungeon/02 : needs-info : design : The Lost Socks dungeon: try several mechanics and layouts
- dungeon/03 : wontfix : build : The water drum: a prototype on today's game code
- dungeon/04 : done : build : The drum finale: the last Stage inside the washing machine
- dungeon/05 : needs-info : build : The drum's shuffle spin
- dungeon/06 : done : build : The Drum hatch as a hole in the door glass (was: a mini porthole)
- dungeon/07 : done : build : What happens to the handed-out Pairs after the drum

**flat**
- flat/01 : done : build : The flat model
- flat/02 : done : build : Eight themed Cabinets
- flat/03 : done : build : Four Sock shapes and the sock balls
- flat/04 : done : build : Print atlas for the picture Collections
- flat/05 : done : content : Eight Collections and 500 Designs
- flat/06 : done : build : Soft cloth, sock balls and the active item
- flat/07 : done : build : Throw (Q) Upgrade
- flat/08 : done : build : Size, Collection and Held X-rays
- flat/09 : done : build : Icons, labels and the interaction highlight
- flat/10 : done : build : Physics heaps and hiding spots
- flat/11 : done : build : Flat integration and performance
- flat/12 : wontfix : polish : Art touch-ups from the review
- flat/13 : done : polish : Code polish from the review
- flat/14 : done : polish : A held Sock stays calm when the view turns
- flat/15 : done : polish : Pick any Sock the crosshair reaches
- flat/16 : done : polish : Under the crosshair only the Size; no floating station text
- flat/17 : done : polish : A dropped Sock keeps its size in flight
- flat/18 : done : polish : Right mouse button zooms; G drops
- flat/19 : done : polish : Cheap render polish
- flat/20 : done : polish : A key hint for every action; mouse icons match the keycaps
- flat/21 : done : polish : Held info sits beside the held item: Size, Sock or ball icon, N/capacity, wheel
- flat/22 : done : build : Sound bench: candidates for every event, the designer picks
- flat/23 : done : polish : Held items keep their size while zoomed
- flat/24 : done : polish : No crouch rule; the coffee table hides Socks
- flat/25 : done : build : The sun follows an in-game day, night included
- flat/26 : done : polish : Coin rewards fly to the bank
- flat/27 : done : build : Integrate polish tickets 20, 21, 23, 24, 25, 26
- flat/28 : done : polish : Polish follow-ups from tickets 21–27
- flat/29 : done : polish : The Upgrade menu matches the keycaps and icons
- flat/30 : done : build : HDRI sky outside the windows and for reflections
- flat/31 : done : build : Integrate tickets 28, 29, 30
- flat/32 : done : polish : Dropped Socks appear only once they land, and land on what is under them
- flat/33 : done : polish : G zooms, right click drops
- flat/34 : done : polish : Short, current hint messages with inline key icons
- flat/35 : done : polish : The oven is hollow
- flat/36 : done : polish : Hold right click to throw; Q is gone
- flat/37 : done : build : Two matching Pairs wait on the washer
- flat/38 : done : polish : Pairs go into the drawer you aim at
- flat/39 : done : build : Integrate tickets 30–38
- flat/40 : done : bug : Socks lying on a Station can be picked
- flat/41 : done : build : Debug money cheat
- flat/42 : done : build : Windows build with the debug cheats
- flat/43 : done : build : The paired moment
- flat/44 : done : build : Real Sock shapes, better sock balls and cloth detail
- flat/45 : done : build : A modelled outside seen through the windows
- flat/46 : done : build : Main menu, Coop flow, Options, Licence and UI sounds
- flat/47 : done : build : A TV and a radio in the flat
- flat/48 : done : build : Wardrobe doors, hollow laundry basket and bathroom mirror
- flat/49 : done : build : Free mouse on the title, the game's own cursor, ping in a lone co-op session
- flat/50 : done : build : The Radio is the music source, and it can be carried
- flat/51 : done : build : One Ping key hint
- flat/52 : done : build : Red ways out, a white cursor
- flat/53 : done : build : Turn the held item
- flat/54 : done : build : The Licence in the corner, icons on the main menu
- flat/55 : done : polish : Turn the held item round its long axis only
- flat/56 : done : build : Calmer window ambience
- flat/57 : done : build : Sound bench: every event, and picks that stick
- flat/58 : done : content : CC0 sound hunt: real candidates for the newer events
- flat/59 : done : build : A pressed keycap's label goes down with it
- flat/60 : done : content : The ping is the bubble alone
- flat/61 : done : build : The radio music much louder
- flat/62 : done : build : Widescreen TV shows with the retro filter
- flat/63 : done : build : Drop the jazz placeholder tunes
- flat/64 : ready-for-agent : content : Sound hunt 2: knockdown, TV static, lids and car doors
- flat/65 : done : polish : The turned item stays where R left it
- flat/66 : done : build : A drop lands where the crosshair is, or is refused
- flat/67 : done : build : X-ray rework: only the Show pair ability stays
- flat/68 : done : polish : Held fixes: Radio size, Pair tumble, held info toggle
- flat/69 : done : build : Bigger pairing pop and house-wide Collection-complete moment
- flat/70 : done : build : Guide card
- flat/71 : done : - : Held info shows the Design name and Collection icon
- flat/72 : done : - : Hints, spell corner, zoo effects, stair light flicker
- flat/73 : done : - : Slower walking and sprint
- flat/74 : done : - : X-ray glow: more visible, pulsing outline
- flat/75 : done : - : Cabinet X-ray: second ability (key 2)
- flat/76 : done : - : Base speed back, Upgrades half as strong
- flat/77 : done : - : Collection complete: matching confetti, icon, bouncing text
- flat/78 : done : build : UI panels and keycaps get a 3D right edge too
- flat/79 : done : build : Held info is always on
- flat/80 : done : build : Fix the perspective of the 3D UI edge
- flat/81 : done : build : The Guide card, updated
- flat/82 : done : build : Pings shown at the screen's edge
- flat/83 : done : decision : Sock X-ray and Cabinet X-ray: own colours, better effects, clear readiness
- flat/84 : done : build : Sock X-ray and Cabinet X-ray: own colours, clear readiness
- flat/85 : done : polish : X-ray: real outlines, one shared outline shader, icons back left, pressed when on

**graphics**
- graphics/01 : done : build : Ambient effects
- graphics/02 : done : bug : Mirrors cost too many frames
- graphics/03 : ready-for-agent : build : Compile shaders before play
- graphics/04 : done : polish : A cheaper Low preset
- graphics/05 : needs-info : build : A fourth graphics preset: Lowest
- graphics/06 : ready-for-agent : polish : Socks glow in dim rooms

**house**
- house/01 : done : decision : Floor plan proposal for the house
- house/02 : done : decision : Art style trial: sofa, bed and plant three ways
- house/03 : done : build : The house shell, playable
- house/04 : done : build : Stylised furniture for every room
- house/05 : done : build : Swap in the stylised furniture everywhere, every piece openable
- house/06 : done : build : The Mess across four levels: an even spread, walking Mate distance
- house/07 : ready-for-agent : build : Rename the flat to the house
- house/08 : done : build : The outside around the house
- house/09 : done : build : Restyle the washer, Wardrobe Station, radio and clock
- house/10 : done : build : A stylised car for the garage
- house/11 : done : build : Plan revisions: no WC, a garage, the stair glass
- house/12 : done : build : Furniture fixes: wardrobe, trunks, sink, ironing board, dining table, overlaps
- house/13 : wontfix : build : Bike remodel
- house/14 : done : build : Socks in an openable ride with it
- house/15 : done : build : Bathroom mirror reflects
- house/16 : done : build : Socks rest exactly on furniture
- house/17 : done : build : The dumbwaiter
- house/18 : done : build : Sock balls ride drawers, stuck items push up
- house/19 : done : build : Garage door and ramp, car moved, hall plant, grates, plinth
- house/20 : done : build : Rare mates on other floors
- house/21 : done : build : Interactive room doors
- house/22 : done : build : Baked Socks rest on what is drawn, whatever the layout
- house/23 : done : build : One call button per Dumbwaiter hatch
- house/25 : done : build : Split the house into shell, furniture, exterior and Elevator
- house/26 : done : build : Elevator rework: rename, hatch click, items carried as data
- house/27 : done : polish : Basement light and night lighting glitches
- house/28 : done : build : Playable piano
- house/29 : done : polish : Warm basement fill
- house/30 : done : - : house/30: Basement lamps on by day
- house/31 : done : - : Stairwell shadows stay; zoo time-of-day slider
- house/32 : done : - : Piano behind the sofa
- house/33 : done : - : Piano: all keys playable, music and top clutter removed
- house/34 : done : - : Remove the drying rack from the basement
- house/35 : done : build : Creatures travel through the Elevator
- house/36 : done : build : Move the attic door off the rails
- house/36 : done : build : The Newel's collider matches its drawn cap
- house/37 : done : build : The house 10% roomier
- house/38 : done : build : The Lost Sock Grotto under the basement
- house/39 : done : build : The car's doors open separately
- house/40 : done : build : Grotto fixes: only Lost Socks, crates face the walkway, the hatch is used with E
- house/41 : done : build : The lantern is an item like any other, and it swings
- house/42 : done : build : A climbing pose on the ladder, and falling drips
- house/43 : done : build : Remove the leftover door on the attic stairs' U landing
- house/44 : done : build : A third Cabinet spot on the ground floor
- house/45 : done : feature : The Old Tree in the garage, and the garage relaid out around it
- house/46 : done : bug : The Elevator's letters can't be pressed with two riders

**intro**
- intro/01 : done : build : Hudry Games studio intro
- intro/02 : done : build : The studio intro: a purple turkey, falling letters and GAMES slammed down

**knockdown**
- knockdown/01 : done : build : Ragdoll for knocked-down Avatars
- knockdown/02 : done : build : Drag knocked-down players
- knockdown/03 : done : build : Wash a dragged player in the washing machine
- knockdown/04 : done : build : Knock players down with anything thrown

**lobby**
- lobby/01 : done : build : Worlds: the Solo World, five co-op slots and a fixed Group
- lobby/02 : done : build : The Lobby: a greyboxed giant sock drawer where everyone gets ready
- lobby/03 : done : build : The main menu and the flow into a game
- lobby/04 : done : build : Lobby fixes after the first play-test
- lobby/05 : done : build : The Lobby as a screen
- lobby/06 : done : build : The Lobby on pedestals
- lobby/07 : done : build : The Host's World settings in a Lobby sidebar
- lobby/08 : done : build : The World settings sidebar as an overlay drawer

**maintenance**
- maintenance/01 : done : docs : Project setup from the starter kit
- maintenance/02 : done : docs : Sock physics and performance research
- maintenance/03 : done : build : Sock collision, pick hitch and loading screen
- maintenance/04 : done : build : Graphics presets and benchmark
- maintenance/05 : done : build : A dropped Sock never dips through what it lands on
- maintenance/06 : done : build : A Sock or Pair that leaves the flat comes back in front of the washing machine
- maintenance/07 : done : build : The zoo: a test scene with every mechanic and stress tools
- maintenance/08 : done : build : High shadows only from lights near you
- maintenance/09 : done : build : Net tests that never flake
- maintenance/10 : done : build : Close answered follow-ups across all tickets
- maintenance/100 : done : build : The folder move to game/
- maintenance/101 : done : build : Guard rails for the layout
- maintenance/102 : done : build : Session in parts
- maintenance/103 : done : research : Research: controller (gamepad) support
- maintenance/104 : done : bug : A "gone" vacuum_suck event crashes `SockVacuums._apply_suck()`
- maintenance/105 : done : build : A SCRIPT ERROR inside a case fails the run
- maintenance/106 : done : bug : Hot-fix: the pad drives only the focused window; keyboard or mouse drops the pad focus
- maintenance/107 : needs-info : feature : Polish the controls (pad, keyboard and mouse)
- maintenance/108 : ready-for-agent : build : Physics tick spikes in the bench
- maintenance/109 : done : perf : A new floor's Socks hitch the game for 100 to 290 ms at the Fix
- maintenance/11 : done : build : Faster tests, shots and imports
- maintenance/110 : ready-for-human : build : Aim chain at a lower rate
- maintenance/111 : done : build : Why a tick frame costs 3 ms more than a plain one, and the plain-frame spikes
- maintenance/112 : done : build : Read the game's data files once: Tuning, FlatLayout, SockCatalogue, CabinetPools
- maintenance/113 : done : build : Code map: a zoomable treemap of game/**/*.gd
- maintenance/114 : needs-info : research : The zoo's playground: a plain walk-through area beside the house
- maintenance/115 : done : build : Every action in the project's Input Map
- maintenance/116 : wontfix : refactor : Move game-only tuning from JSON to typed Resources
- maintenance/117 : done : build : Constants and duplicate small functions: merge the real duplicates, share the menu sizes, move play-feel numbers to tuning
- maintenance/118 : ready-for-agent : refactor : Leave the debug code out of release exports
- maintenance/119 : needs-info : build : A multiplayer zoo
- maintenance/12 : done : build : The bed and nightstand are not drawn
- maintenance/120 : done : bug : Two controls bugs from the controls report
- maintenance/121 : done : refactor : SockWorld and Flight constants to tuning (maintenance/117 leftover)
- maintenance/122 : done : bug : net_devices:ride "full size again" flake
- maintenance/123 : done : build : Wardrobe focus: arrows and colours only
- maintenance/124 : done : build : Profily replaces the frame overlay
- maintenance/125 : done : build : Starter kit 6: the designer's answers on kit 5
- maintenance/126 : done : build : Known flakes, integrate state file and merge hashes
- maintenance/127 : done : build : Housekeeping check and stranded docs
- maintenance/128 : done : build : Doc drift and the follow-up sweep
- maintenance/129 : done : build : Wardrobe focus only with a controller
- maintenance/13 : done : docs : Close the answered follow-ups
- maintenance/130 : done : polish : Held Sock: turn from its top, Zoom, and only the controls that apply
- maintenance/131 : needs-info : research : Move the game to scenes and Resources
- maintenance/132 : done : build : A basic debug menu in the game
- maintenance/133 : ready-for-agent : build : Forward --reverse through tools/run.py
- maintenance/134 : done : build : The bench records the machine, and a low-end bench script
- maintenance/135 : done : research : Where the tick's script time goes
- maintenance/136 : ready-for-agent : bug : bench_lowend.cmd: the 720p and 540p runs ran at the saved fullscreen size
- maintenance/137 : done : build : Agent safety: rules in the repo, destructive git blocked, git repair in one script
- maintenance/138 : done : research : Research for the move to native Godot
- maintenance/139 : needs-info : docs : A skill of its own: "nativize godot project"
- maintenance/14 : done : docs : Question cleanup after the Q437-Q508 round
- maintenance/140 : done : tooling : Reusable development tools, so agents stop rewriting one-off scripts
- maintenance/141 : done : tooling : Agent start and finish scripts, and a suite runner
- maintenance/142 : done : tooling : Shot sets: named shot recipes, with before/after from an older commit
- maintenance/143 : done : tooling : House layout queries
- maintenance/144 : done : tooling : Agent cost report, shown on the ticket board
- maintenance/145 : done : polish : Zoo panel: quick polish, focused on features
- maintenance/146 : done : docs : Docs and skills for the new workflow tools
- maintenance/147 : needs-info : build : Starter kit 7: carry over the workflow improvements
- maintenance/148 : done : research : How much code would unification and a rewrite really remove?
- maintenance/149 : done : research : The move to native Godot: a plan, core first, one feature at a time, tests written separately
- maintenance/15 : done : build : Stairwell shadows; parallel screenshots share the machine
- maintenance/150 : done : research : The shape of the code after the move: classes, one standard interface, a class diagram
- maintenance/16 : done : build : Responsive loading screen
- maintenance/17 : done : docs : Graphics fidelity research
- maintenance/18 : done : bug : Load-flaky tests
- maintenance/21 : done : research : Profile the Mess physics
- maintenance/22 : done : bug : Flaky tests under load
- maintenance/23 : done : build : Fade into the game after loading
- maintenance/24 : done : bug : Socks can't be placed in the Elevator's second row
- maintenance/25 : done : research : Rendering and performance audit for old PCs
- maintenance/26 : done : build : Retro process fixes
- maintenance/27 : wontfix : bug : "Buffer argument is not a valid buffer" during picks
- maintenance/28 : done : docs : Compact the workflow guides into the kit's skill shape
- maintenance/29 : done : task : Code cleanup and refactor
- maintenance/29a : done : task : Shared test fixtures
- maintenance/29b : done : task : Screenshot actions as a table
- maintenance/29c : done : task : Dead-code sweep
- maintenance/29d : done : task : One record per item in SockWorld
- maintenance/29e : done : task : The crosshair pick lives on SockWorld
- maintenance/29f : done : task : One World encoding for stream, join and save
- maintenance/29g : done : task : The Flight and the Hands
- maintenance/29h : done : task : The Command seam
- maintenance/29i : done : task : Split main.gd's setup
- maintenance/29j : done : task : Split game.gd
- maintenance/30 : done : task : Small cleanups after 29c and the vacuum remodel
- maintenance/31 : done : build : The zoo tries every feature
- maintenance/32 : done : task : Update the documentation and clean up
- maintenance/33 : done : task : Fewer merge conflicts and quicker review builds
- maintenance/34 : done : docs : Stale ticket audit
- maintenance/35 : done : bug : Zoo panel overflow
- maintenance/36 : done : bug : Held items and HUD fixes from the playtest
- maintenance/37 : done : bug : The Radio pushes you back; the body glitches looking down
- maintenance/38 : done : build : One hold system for everything in the Hands
- maintenance/39 : done : build : One "what is held" record
- maintenance/40 : done : build : Carriable: one save and guest-quit path for carried things
- maintenance/41 : done : build : One floor-unlocked query (and the cat's bug)
- maintenance/42 : done : build : One Openable base, with its sound
- maintenance/43 : done : build : Small dedupes: reward recipient, tuning sections, test helpers
- maintenance/44 : done : decision : Duplicated logic audit (2026-11-06)
- maintenance/45 : done : bug : PairingView._process errors on machines a load swapped
- maintenance/46 : done : bug : Throwing a Dirty Sock into the laundry bin throws an error
- maintenance/47 : done : build : Every held thing goes down with the crouch
- maintenance/48 : done : build : One prompt record
- maintenance/49 : done : build : Every carried thing survives a save, a guest quitting and a player joining
- maintenance/50 : done : build : Finish the shared landing
- maintenance/52 : done : decision : Audit: hand-rolled code with a native Godot replacement
- maintenance/53 : done : build : Use Godot's smoothstep, ease and Performance monitors
- maintenance/54 : done : build : The complete banner and coin flights as Tweens
- maintenance/55 : done : build : Hand-counted delays as Timers
- maintenance/56 : done : build : Every key as an InputMap action
- maintenance/57 : done : build : A test runner that shares the machine: memory-aware, machine-wide, in Python
- maintenance/58 : done : research : Audit: the architecture against Godot's best practices and the skills' gotchas
- maintenance/59 : done : build : A finished Game is freed: break the Game and parts reference cycles
- maintenance/60 : done : build : Godot stops importing the documentation's preview images
- maintenance/61 : done : build : Every static knob is reset between test cases, and shared statics are looked at
- maintenance/62 : done : build : Tests wait on state, not on a count of frames (the 123 long waits)
- maintenance/63 : done : build : Main and its Rigs have the same process priority: trace and pin the tick order; view clocks follow the game's time
- maintenance/64 : done : build : Dependencies are injected and typed, not reached by method name; nodes are configured before add_child
- maintenance/65 : done : build : The save file is written without losing the old one, and its errors are seen
- maintenance/66 : done : build : The menus and the HUD share one Theme instead of 194 per-control overrides
- maintenance/67 : done : build : Faster, leaner tests
- maintenance/68 : done : research : Hot paths and suggested optimizations
- maintenance/69 : done : build : The Upgrade menu and the HUD refresh only when shown and changed
- maintenance/70 : ready-for-agent : build : The day cycle writes the lights only when they change
- maintenance/71 : done : build : No pass over the whole Mess on every pick and drop
- maintenance/72 : needs-info : build : Occlusion culling for the house
- maintenance/73 : done : build : The Sfx ear works only when something changed
- maintenance/74 : done : build : Update the zoo and clean up its panel
- maintenance/75 : done : build : Split docs/architecture.md by subsystem
- maintenance/76 : done : bug : Co-op cases and perf budgets that fail only under load
- maintenance/77 : done : build : Test runs use too much memory
- maintenance/78 : done : bug : Three small bugs found at the 2026-11-10 merge
- maintenance/79 : done : polish : The UI looks and is styled the same everywhere
- maintenance/80 : done : research : Audit: does the code use anything Godot's documentation forbids?
- maintenance/81 : done : maintenance : Every space query runs in the physics tick (widen physics/33)
- maintenance/82 : done : maintenance : The ragdoll sets no property Jolt ignores
- maintenance/83 : done : maintenance : Nodes in the tree are freed with queue_free
- maintenance/84 : done : maintenance : A co-op session shuts down cleanly
- maintenance/85 : done : maintenance : The Godot rules are checked at every merge
- maintenance/86 : done : maintenance : One helper reads JSON files
- maintenance/87 : ready-for-agent : maintenance : Measure interpolated transforms and the MultiMesh AABB
- maintenance/88 : done : research : Proposal: a feature-folder layout and the refactors that cut merge conflicts
- maintenance/89 : done : polish : Back buttons are white with a black outline; the Licence screen is two links
- maintenance/90 : done : research : Proposal: the net-code layout, before the maintenance starts
- maintenance/91 : done : build : Every script has its .uid and every .uid its script
- maintenance/92 : done : build : Tuning in one file per section
- maintenance/93 : done : build : Test knobs declared by their class
- maintenance/94 : done : build : net_test.gd split by feature
- maintenance/95 : done : build : Game parts register their own Commands
- maintenance/96 : done : build : Main installs features
- maintenance/97 : done : build : Shot actions and zoo sections per feature
- maintenance/98 : done : build : Rig in parts
- maintenance/99 : done : build : SockWorld in parts

**multiplayer**
- multiplayer/01 : done : build : Split Game into a shared World and per-player state
- multiplayer/02 : done : build : Command layer: serialisable commands and host-assigned ids
- multiplayer/03 : done : build : Split Main into a world view and a local-player rig
- multiplayer/04 : done : build : ENet listen server: Host/Join and join snapshot
- multiplayer/05 : done : build : Sync picks, re-settles, throws and Openables
- multiplayer/06 : done : build : Avatars: simple body, colour, name tag, visible held items
- multiplayer/07 : done : build : Co-op interactions: hand-offs, X-ray mates, messages and sounds
- multiplayer/08 : done : build : Ping on middle mouse
- multiplayer/09 : done : build : Saves: host save with guests' Upgrades and positions by player id
- multiplayer/10 : done : build : Mess scales with player count
- multiplayer/11 : done : build : End summary: team totals and a line per player
- multiplayer/12 : needs-info : build : Steam peer (GodotSteam)
- multiplayer/13 : ready-for-agent : build : Proximity 3D voice chat
- multiplayer/14 : done : build : Session menus: Play, straight-in Join, Leave and End session, host-only F9
- multiplayer/15 : done : build : Guests predict the wheel and drops
- multiplayer/16 : done : build : Saves drop guests' Hands, a loaded game resumes in place, Host picks the player count
- multiplayer/17 : done : content : Sock creature avatar and its first wardrobe
- multiplayer/18 : done : build : Singleplayer and Multiplayer screens, refusal messages, hand-off outline, glossary
- multiplayer/19 : done : build : Ping emoji wheel and highlight
- multiplayer/20 : done : build : Sock-creature avatar in game and the Wardrobe
- multiplayer/21 : done : build : The sock creature bends with its player's look
- multiplayer/22 : done : build : A full-charge Throw knocks a teammate down
- multiplayer/23 : done : build : Knockdown: a wonky physics fall, and who did it
- multiplayer/24 : done : build : A knocked-down body collides
- multiplayer/25 : done : build : A lying body blocks; a fall by a wall slides down
- multiplayer/26 : done : build : Teammate throws from the hand, darker trim, teammates block Stations
- multiplayer/27 : done : build : Keycap end summary, join/leave messages, solo ESC exits
- multiplayer/28 : done : bug : The waddle stopped
- multiplayer/29 : done : polish : Crouch Highlight, bigger Pings and emoji bubble
- multiplayer/30 : done : - : multiplayer/30: Highlight on a primitive mesh
- multiplayer/31 : done : build : Squash and stretch on the Avatar's jump
- multiplayer/32 : done : bug : A riding player's look direction glitches in the Elevator
- multiplayer/33 : done : build : The Host checks what a Guest's RPC carries before using it
- multiplayer/34 : done : bug : A Guest's pick can hit an out-of-bounds save row on the Host
- multiplayer/35 : done : bug : On a Guest the Throw feels wrong and laggy
- multiplayer/36 : ready-for-agent : build : A per-player secret so a Guest cannot take another player's Upgrades
- multiplayer/37 : ready-for-human : research : Low FPS on the Guest over the internet: find the cause

**mvp**
- mvp/01 : done : build : First-person room and player
- mvp/02 : done : build : Sock design catalogue (about 200 Designs, 3 Collections)
- mvp/03 : done : build : The Mess: visible mass, live nearby Socks
- mvp/04 : done : build : Hands: picking up, pairing and dropping
- mvp/05 : done : build : The Drawer, payout and the Collection bonus
- mvp/06 : done : build : Upgrade station and the two Upgrades
- mvp/07 : done : build : Autosave and the ending
- mvp/08 : done : build : Soft sound cues
- mvp/10 : done : build : Sprint Upgrade
- mvp/11 : done : build : Cabinets of drawers
- mvp/12 : done : build : Bedroom, washing machine and room models
- mvp/13 : done : build : Four rigged Sock shapes, one per Collection
- mvp/14 : done : build : Cloth motion for held and dropped Socks

**physics**
- physics/00 : done : docs : Research and a proposed architecture for Sock physics and networking
- physics/01 : done : build : Stress-test scene with our own measurement monitors and an exe for the designer's PC
- physics/02 : done : decision : The designer runs the baseline stress test on their PC
- physics/03 : done : build : Engine settings: 30 and 60 Hz modes, physics interpolation, Jolt limits and tuning
- physics/04 : done : docs : ADR-0008: two-tier Socks, and the ADR amendments
- physics/05 : done : build : SockWorld core: Sock records, states, static rest colliders, drawing and ray picking
- physics/06 : done : build : Waking and resting: the Active budget, impacts, movers and the Elevator
- physics/07 : done : build : Sock and Pair colliders: two boxes versus three; the Pair sphere
- physics/08 : done : build : Authored collision for the house shell and layout
- physics/09 : done : build : Authored collision for every furniture piece
- physics/10 : done : build : Authored collision for the Elevator
- physics/11 : done : build : A seeded Sock layout per game in under 5 seconds
- physics/12 : done : build : Picks, drops and Throws on SockWorld
- physics/13 : done : build : Sock vacuum and pairing machine on SockWorld
- physics/14 : done : build : The rogue machine's decorative Socks on scripted arcs
- physics/15 : wontfix : build : Sock replication: the snapshot stream, priority, interest and rest events
- physics/16 : wontfix : build : Guest prediction of their own Throws and drops; Host checks of Guest picks
- physics/17 : done : build : One compact encoding for late join and saves
- physics/18 : done : build : Ragdolls on the new collision layers
- physics/19 : done : build : Network stress through a lossy relay
- physics/20 : done : build : Drawing 10,000 Socks on integrated graphics
- physics/21 : done : bug : Socks fall through the floor in the stress test
- physics/22 : done : build : Switch the game from the old Mess to SockWorld
- physics/23 : done : build : The Elevator car's contents: physics at a stop, data while riding
- physics/24 : done : build : Socks meet an unlocked floor's door leaf as it swings
- physics/25 : done : build : Cap and cheapen the cloth animation
- physics/26 : done : build : The game's Jolt limits, thicker floors, and CCD only for fast Socks
- physics/27 : done : bug : The game freezes briefly when a Sock is picked from a big Heap
- physics/28 : ready-for-agent : polish : Keep the players' spawn spots clear of Heaps
- physics/29 : needs-info : decision : The house's collider budget
- physics/30 : ready-for-agent : bug : Jolt's contact buffers in the game
- physics/31 : ready-for-agent : build : The SockWorld stress verdicts that are still missing
- physics/32 : done : build : The Mess bake's tile spaces in a pool
- physics/33 : done : build : Physics space queries run in the physics tick, not in the render frame
- physics/34 : wontfix : research : What the raised Jolt limits cost each step
- physics/35 : done : research : A dropped or thrown item moves as one motion
- physics/36 : done : build : Two release systems: physical (Socks, Pairs) and items
- physics/37 : done : build : The pairing machine's rolled Pairs as Jolt bodies
- physics/38 : done : build : Resting Pairs fall when what holds them up goes

**pipeline**
- pipeline/01 : done : build : Blender MCP and the asset pipeline
- pipeline/02 : done : build : The washing machine through the Blender MCP pipeline
- pipeline/03 : done : build : Sock and Pair-ball meshes with LODs, through the Blender MCP pipeline
- pipeline/04 : done : build : Remodel the Cabinets through Blender MCP
- pipeline/05 : done : build : Remodel the Wardrobe through Blender MCP
- pipeline/06 : done : build : Remodel the radio through Blender MCP
- pipeline/07 : done : build : Remodel the wall clock through Blender MCP
- pipeline/08 : done : build : Remodel the TV through Blender MCP
- pipeline/09 : done : build : Remodel the Collection board through Blender MCP
- pipeline/10 : done : build : Remodel the pairing machine through Blender MCP
- pipeline/11 : done : build : Remodel the sock vacuum through Blender MCP
- pipeline/12 : done : build : The Avatar's leg Socks: a Socks piece goes on the feet, not the body
- pipeline/13 : done : build : Leg Socks that show: a flared cuff, and your own feet
- pipeline/14 : done : polish : Socks flying into the vacuum use a low-LOD Sock with its Design
- pipeline/15 : done : polish : The Socks inside both machines' windows show as low-LOD Socks with their Designs

**progression**
- progression/01 : done : build : Collection whiteboard
- progression/02 : done : build : Stage engine
- progression/03 : done : build : Locked doors and reveals
- progression/04 : done : build : Stage spawning
- progression/05 : done : build : Stage HUD bar
- progression/06 : done : content : New Designs
- progression/07 : done : build : Gifts
- progression/08 : done : build : Wardrobe slots
- progression/09 : done : content : Cosmetic pieces
- progression/10 : done : build : Player stacking
- progression/11 : done : build : Restricted Hand-off
- progression/12 : done : build : Door hold: everyone
- progression/13 : done : docs : Glossary and ADR for progression
- progression/15 : done : build : Debug Drawer size slider
- progression/16 : done : build : Door hold: together-click on the lock, Coins and Rows wait
- progression/17 : done : build : Gifts: one box per player, pick up and unwrap
- progression/18 : done : build : Re-UV the avatar so Sock patterns show
- progression/19 : done : build : Stacking: jump onto a teammate, rider stands lower
- progression/20 : done : build : Stage bar: cream keycap panel, drop the old counter
- progression/21 : done : build : Sport nook dust sheet and Elevator padlock sign
- progression/22 : done : build : Wardrobe: one "< NAME >" selector per slot, everything starts locked
- progression/23 : done : build : Cabinets show only the Drawers they need and grow one per floor
- progression/24 : done : bug : The Stage bar reads one short with every Pair shelved
- progression/25 : done : bug : Gifts: a pile beside the completed Cabinet, and the Sparkle crash
- progression/26 : done : bug : Wardrobe: no silhouette for locked pieces, and a one-time profile reset
- progression/27 : done : build : Gifts: click to pick up, click to open, preview of the piece
- progression/28 : done : build : Remove the Sport Cabinet's nook
- progression/29 : done : bug : The Cabinet under the dust sheet cannot be used
- progression/30 : wontfix : build : One click on the padlock opens the next floor
- progression/31 : ready-for-agent : build : A new Drawer drops in only when a player first sees it
- progression/32 : done : build : Unlocks from a player's lifetime progress across all games
- progression/33 : done : build : The gift reveal: it shakes, then shows the real piece
- progression/34 : ready-for-agent : content : Co-op variants of the cosmetic pieces
- progression/35 : wontfix : content : The Collections' new Sock Designs
- progression/36 : done : build : The Wardrobe shows only unlocked pieces
- progression/37 : done : build : Floors open by fixing the washing machine
- progression/38 : done : build : Dirty Socks, the laundry bin and the final wash
- progression/39 : done : build : Sock Sense
- progression/40 : done : content : Models for the washing machine's Parts and the laundry bin
- progression/41 : done : polish : Collection complete: ribbon and rosette
- progression/42 : done : build : Controls for the laundry bin
- progression/43 : done : build : Tab and the Whiteboard show what each player collected
- progression/44 : done : build : Put the laundry bin down the way it is held
- progression/45 : done : build : Bin carrier hand-off refused; the Dirty Collection's colour
- progression/46 : done : decision : What the HUD shows once the machine is fixed
- progression/47 : done : build : Sole Mates: the teammate match cue becomes an Upgrade
- progression/48 : done : decision : Upgrades rethink
- progression/49 : done : build : The Wardrobe preview spins all the way round
- progression/50 : done : build : Eight new Collections
- progression/51 : done : build : Themed Cabinets for the eight new Collections
- progression/52 : done : build : Variable Cabinets: each run draws its Collections
- progression/53 : done : build : The Sock encyclopedia in the Profile
- progression/54 : done : build : The encyclopedia book in the house
- progression/55 : done : bug : The Collection-complete moment is missing in real play
- progression/56 : done : build : Two currencies: personal Coins and team Drawers
- progression/57 : done : build : Upgrade trees: data and rules
- progression/58 : done : build : The Upgrade menu at the Whiteboard
- progression/59 : done : build : New personal Upgrade effects
- progression/60 : done : build : Team Upgrade effects: vacuum, pairing machine, Elevator, teamwork
- progression/61 : done : build : Wardrobe pieces for the new Collections
- progression/62 : wontfix : build : Choose by hand how new Cabinets come into a game
- progression/63 : done : build : Upgrade set v2: the designer's list, Personal and House
- progression/64 : done : build : The Hamper: a bought carrier for many Socks
- progression/65 : done : build : Auto Pair: the pairing machine's Auto mode
- progression/66 : done : build : Elevator Repair: the Elevator starts locked
- progression/67 : done : build : Sole Mates and Sole Hands
- progression/68 : done : build : Drawer flight
- progression/69 : done : build : Hamper fixes after the first play
- progression/70 : done : build : Upgrade menu polish
- progression/71 : done : design : Cabinet pools per room, and Collections that unlock over games
- progression/72 : needs-info : design : Rethink Drawer and Cabinet completion rewards
- progression/73 : needs-info : build : Wash cycles: replayable game modes
- progression/74 : done : build : Small follow-ups
- progression/75 : done : feature : The Old Tree is the Upgrade station
- progression/76 : done : feature : A small arrow at the screen edge points to a hint's target when it is off screen
- progression/77 : done : feature : The Old Tree comes alive: it moves and talks when it has something to say
- progression/78 : done : feature : Hampers off for now
- progression/79 : done : feature : Stage presents under the Old Tree, and the tree as the helpful protagonist
- progression/80 : done : feature : The tree says when a Stage's presents are ready
- progression/81 : needs-info : design : Achievements: a local store now, Steam as a drop-in later
- progression/82 : done : bug : The Lost Sock Grotto's Stage won't complete
- progression/83 : done : build : The ending: wash the prefilled laundry bins
- progression/84 : needs-info : decision : Gifts when the player already owns the pieces
- progression/85 : done : build : The final screen: every Pair and piece, animated
- progression/86 : done : build : The first wash: the machine breaks and spits out the Socks
- progression/87 : done : build : Washing sounds, and music ducked in cutscenes
- progression/88 : done : build : The Old Tree calls the players at the start
- progression/89 : done : polish : Upgrade tree: an icon per effect, and the lock in front of the icon
- progression/90 : done : build : The end screen shows the unlocked Collection's icon
- progression/91 : done : build : The laundry bins load the washing machine
- progression/92 : done : build : The washing machine spits Socks after every Stage
- progression/93 : done : build : A gift for each Collection completed
- progression/94 : needs-info : polish : Polish the Wardrobe pieces of the new Collections
- progression/95 : needs-info : polish : Polish the living Old Tree
- progression/96 : needs-info : polish : Polish the Stage presents and the tree's hints

**questions**
- questions/01 : done : decision : The core loop
- questions/02 : done : decision : Starting numbers and curves
- questions/03 : done : decision : How rare Designs are found later
- questions/04 : wontfix : decision : The three MVP Collections
- questions/05 : done : decision : Where the sound cues come from
- questions/06 : ready-for-human : decision : Balance and feel round

**rogue-machine**
- rogue-machine/01 : done : build : Rogue washing machine sequence: floor unlocks and the New Game intro
- rogue-machine/02 : wontfix : build : A stronger rogue washing machine sequence
- rogue-machine/03 : done : bug : Socks on top ride the washing machine
- rogue-machine/04 : done : build : The talking washing machine
- rogue-machine/05 : done : build : Talking washing machine: cutscene polish
- rogue-machine/06 : done : feature : The talking voices are louder, and their subtitles show only while you can hear them

**secrets**
- secrets/01 : done : build : Secrets
- secrets/02 : done : build : The washing machine's drum takes the Cat and the Radio
- secrets/03 : done : build : Models for the 8 Secret pieces and the Elevator car's lamp
- secrets/04 : done : bug : The Elevator car's lamp leaves a static collider at the car's home stop
- secrets/05 : needs-info : polish : Polish the Secrets

**story**
- story/01 : needs-info : decision : A talking NPC that tells the plot

**tools**
- tools/01 : done : build : Sock vacuum: nozzle, hose and container
- tools/02 : done : build : Sock pairing machine: hopper, timer, Pairs out
- tools/03 : done : build : Synergy: the container spits into the pairing machine
- tools/04 : done : build : Sock vacuum rework: dropped nozzle, button, timed rear spit
- tools/05 : done : build : Pairing machine rework: start button, rolled Pairs
- tools/06 : ready-for-agent : build : Sounds for the Sock vacuum and the pairing machine
- tools/07 : done : build : The Sock vacuum and the pairing machine in the house
- tools/08 : done : build : The vacuum's hose wraps around geometry
- tools/09 : done : build : The vacuum's hose is pushed by doors and drawers
- tools/10 : done : build : One player carries the vacuum while another holds its hose
- tools/11 : done : build : The vacuum shows and sounds its suck
- tools/12 : done : build : The vacuum view costs only while a vacuum is in use
- tools/13 : done : build : Copy the Debugger's errors
- tools/14 : done : bug : The vacuum's spit is a gentle dribble and never goes through a wall
- tools/15 : done : build : The Sock detector: a handheld finder
- tools/16 : needs-info : research : Back-mounted collecting devices: idea sheet
- tools/17 : done : bug : The held Sock detector pushes its carrier back
- tools/18 : done : prototype : Graybox kit and a Machines row in the zoo
- tools/19 : ready-for-human : prototype : Sorting vacuum: graybox every variant
- tools/20 : ready-for-human : prototype : Laundry chute and clothesline: grayboxes
- tools/21 : ready-for-human : prototype : Sock launcher and Size grate: grayboxes
- tools/22 : ready-for-human : prototype : Machines review: tickets 19, 20 and 21 in one build
- tools/23 : ready-for-human : prototype : Nozzle filter: three more graybox variants (stands 10-12)
- tools/24 : in-progress : feature : Vacuum devices for the game: Smart Sock vacuum, backpack vacuum, splitter
- tools/25 : ready-for-agent : feature : Vacuum: pour, nozzle spit-out and the filter (the shared piece)
- tools/26 : done : feature : Pairing machine switched off
- tools/27 : ready-for-agent : feature : Backpack vacuum
- tools/28 : ready-for-agent : feature : Splitter
- tools/29 : ready-for-agent : feature : The filter nozzle Upgrade
- tools/30 : ready-for-agent : feature : Models: backpack vacuum, splitter, the nozzle's display

## Appendix B. Branches ahead of main (read-only `git rev-list --count main..<branch>`)

| Branch | Commits ahead | What it holds | Ticket | State |
|---|---|---|---|---|
| `graphics/06-sock-glow` | 1 | Sock rim, rim tint and sheen multipliers as tuning keys (defaults unchanged); stills in builds/review-sock-glow | graphics/06 | waiting for the designer ("idk yet", Q2061) |
| `maintenance/110-aim-rate` | 1 | tuning number `players.aim_every_ticks` (default 1), 6 files, +133 | maintenance/110 | waiting for the rate pick (P54) |
| `maintenance/114-zoo-playground` | 1 | zoo playground scoping (docs, 239 lines) | maintenance/114 | parked (Q1961) |
| `progression/58-upgrade-tree-menu` | 1 | phase 1 layout mocks of the Upgrade tree menu (docs) | progression/58 | copied to main; branch stale |
| `progression/71-fixed-cabinet-spots` | 1 | proposal of fixed Cabinet spots (docs) | progression/71 | ticket done; docs on main |
| `progression/81-achievements` | 2 | achievements design ticket and ADR-0009 (proposed), Q1688-Q1699 answers | progression/81 | docs only; main is source of truth |
| `proto/103-controller-feel` | 2 | controller feel prototype: focus lift, pad mapping (A primary, B secondary, RT sprint, LT crouch), 27 files | maintenance/103 | throwaway prototype; the main game took a pad mapping later |
| `proto/73-wash-cabinets` | 1 | Cabinet wash cycles: Shuffle, Basic Everywhere, Blank Labels, Picky Drawers | progression/73 | parked, throwaway |
| `proto/73-wash-movement` | 2 | movement wash cycles: Tumble Dry, Static Cling, Rinse, Heavy Duty | progression/73 | parked, throwaway |
| `proto/73-wash-rules-area` | 1 | Hand Wash, Mixed Load, Darks, Rising Foam, Pre-wash | progression/73 | parked, throwaway |
| `proto/77-old-tree-alive` | 2 | Old Tree breathes, flickers, talks (placeholder voice), 67 files, 6,555 lines | progression/77 | superseded: the finished tree is on main |
| `research/code-split` | 1 | code split proposal (docs, 1,646 lines) | maintenance/138 | docs only |
| `research/code-structure-review` | 1 | code structure review (docs) | maintenance/138 | docs only |
| `research/controls-map` | 1 | controls map research | maintenance/115 | docs only |
| `research/deep-review` | 1 | deep review: hot-spots, netcode, scaling | maintenance/111 | docs only |
| `research/spawn-lag` | 1 | spawn lag research | maintenance/109 | docs only |
| `research/steam-integration` | 1 | Steam integration research | multiplayer/12 | docs only |
| `research/steam-verify` | 1 | Steam research verification | multiplayer/12 | docs only |
| `research/tuning-resources` | 1 | typed tuning Resources proposal (docs, 7,211 lines) | maintenance/116 | docs only |
| `tools/16-back-devices` | 1 | back devices idea sheet with greybox stills | tools/16 | parked (Q2060) |
| `tools/19-sorting-vacuum-grayboxes` | 1 | graybox stands for every sorting vacuum variant (24 files, +1,047) | tools/19 | parked (Q2112) |
| `tools/20-chute-and-clothesline-grayboxes` | 1 | laundry chute and clothesline grayboxes (17 files) | tools/20 | parked (Q2112) |
| `tools/21-launcher-and-size-grate-grayboxes` | 1 | Sock launcher and Size grate grayboxes (16 files) | tools/21 | parked (Q2112) |
| `tools/23-nozzle-filter-variants` | 10 | stands 10-12: pour on E, two filters, filters on the nozzle (55 files, +3,612); the code P02 lifts from | tools/23 | parked; source for tools/25 |
| `tools/25-vacuum-pour-spit-and-filter` | 1 | vacuum spit-out, pour and the nozzle filter (23 files, +1,144 -618) | tools/25 | started, unmerged |
| `tools/30-vacuum-device-models` | 1 | line-ups of backpack vacuum, splitter and nozzle display (three variants each) | tools/30 | picks made |
| `tools/30-vacuum-device-models-final` | 2 | same, with a merge of main | tools/30 | picks made |
| `tools/machines-review` | 8 | tools/19, 20, 21 combined for one review build (48 files, +2,593) | tools/22 | played; parked |

Merged (0 commits ahead): `dungeon/04-drum-finale`, `fix/grotto-merge`, `fix/p37-h37-merge`, `house/44-third-ground-floor-cabinet`, `lobby/01-worlds-and-groups`, `lobby/02-sock-drawer-lobby`, `lobby/05-lobby-screen`, `maintenance/57b-run-py`, `maintenance/100-folder-move`, `maintenance/122-ride-flake`, `physics/35-drop-throw-one-motion`, `progression/06-fix-net-lost`, `progression/06-new-designs`, `progression/37-fix-the-washing-machine`, `progression/46-after-fix-hud`, 45 `worktree-agent-*` and 2 `integrate/*`.
