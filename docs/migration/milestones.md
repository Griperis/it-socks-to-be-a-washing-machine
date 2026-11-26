# Milestones

The order the designer set on 2026-11-19 (Q2207-Q2209, Q2214). The lead writes state changes here when a
milestone's tickets are all approved. A piece inside a milestone moves planned, design agreed, built, approved.
M1 and M2 run beside M0.5 and M0.6, not after them.

| | Milestone | Done when | State |
|---|---|---|---|
| M0 | Setup | The repository is set up from starter kit 8.0 (was 7.1) with the port pack on top; the checks pass; the reference clone at `v0.1.1` is in place; the first commit is pushed | done 2026-11-20 (pushed to origin by the designer) |
| M0.5 | The core in a single-player zoo | In a flat graybox zoo scene (edited in the editor, one station per feature, the game's real entities): movement, handling Socks, pairing, one Cabinet. A true vertical slice of the core (Q2296): the core's sounds and rumble and its polish details are in it, as the old game has them. One player, but every change already goes through the shared-state path: the player is a Host of one (Q2207, Q2208, Q2211, Q2212) | built 2026-11-22; closing (Q2425): the designer's zoo run and code review are left |
| M0.6 | The co-op zoo base | The same zoo with a Host, a Guest and a late joiner: avatars seen by the others every frame (Q2223), a Guest's pick and Throw as decided (Q2220-Q2222, Q2226), a long random player id in the profile (Q2224), and the full knockdown with Godot's own physical-bone ragdoll (Q2225) | done: all 14 coop tickets merged (coop/14, the Guest's flight, on 2026-11-25) |
| M1 | Assets | Models and UI art ported by the port rules; the core's models and the avatar rig first; a shared material library; things built by code become models or scenes. Approved in family batches, each with a before and after strip (Q2151-Q2153, Q2177, Q2178, Q2216) | mostly done: the families are built (assets/01-09); left: the exterior and the dusk and night skies; batch A adds its own models (assets/10-15) |
| M1.1 | Sound | The sound system is built in M0.5 for the core (Q2296); M1.1 ports every other old sound and pad rumble, ported with the old clips and numbers, made plug-and-play: a sound is added or swapped by dropping in a file and naming it, with no code change. The list from the four merged pieces is in `old-details-backlog.md` (Q2278) | planned |
| Polish | The polish pass | The core's polish details are done in M0.5 (Q2296); this pass holds those of later pieces | planned |
| M2 | The house | Built by hand in the editor from a half-metre kit and the ported props; Play walks through it in first person (Q2154-Q2157, Q2175, Q2176) | planned, beside the zoo |
| M3 | The core loop in the house | The Mess, Hands, Throws, Pairs and Cabinets (with Doors and Drawers) play in co-op in the house; the Mess bench is no slower than the old game's (Q2161, Q2168) | merged: house/05 (the Mess in the house), house/08 room Doors (Q2532), core/41 stacking, core/42 hand-off, core/43 pings (Q2533) |
| M4 | The frame of a run | Stages, the Laundry day, menus, saves and the lobby, on Steam (its lobby, invites, relay and Steam IDs proven by its auth ticket, Q2456-Q2458; off Steam the proving token for the random id); screens are scenes on one Theme (Q2163) | started: the menus, saves and the Lobby are merged (core/58-68); the rest is the batches A-D below (Q2614); Steam comes with batch D, co-op stays on ENet behind its seam until then (Q2616) |
| M5 | Features by need | Each switched-off or planned feature (the vacuum devices, Hampers, the Grotto, Dirty Socks, the Cat, cutscenes, ...) is ported when the designer calls it, each first as a zoo station (Q2144, Q2214) | folded into the batches B-D (Q2614); not ported: the splitter, the Grotto, Hampers, the pairing machine, the F1 menu (Q2599), Secrets (Q2600), the parked graybox machines, wash cycles, proximity chat (Q2602) |

After M3, M4, M1.1 and M5 run in parallel wherever they can; the voicelines' architecture and authoring are designed first (core/56, Q2535).

## The rest of the port: batches A-D (Q2603-Q2605, Q2614)
Each batch is a milestone of its own: the lead writes a proposal per piece, the designer is grilled on them in one
sitting, agents build it unattended in the order below, merged to `main` on full passing runs, and the designer reviews
the whole batch in one play session (its review sheet). An open choice an agent meets takes the old game's answer and
goes on the review sheet (Q2604).

| Batch | What | State |
|---|---|---|
| A | The run and the washer: Stages and floors, the First wash, the Laundry day (bins, Final wash), the Final screen, the voice system and the talking washing machine (Q2606); the run ends after the fourth Stage (Q2615) | designed (core/71-73), answered (Q2617-Q2643), filed (core/74): building |
| B | Progression: Coins and Drawers, the Old Tree and the Upgrade grid, Stage presents and Gifts, the Wardrobe, Collections unlocking, Profile and encyclopedia, Achievements | designed (core/120-122), answered (Q2667-Q2683), filed (core/123): building |
| C | The lived-in house: exterior, Elevator, Cat and litterbox, X-rays, the vacuums, the detector, TV and Radio, the guide card | planned |
| D | Finale and finish: the Drum finale, the other cutscenes, studio intro, M1.1's other sounds, controller, graphics presets, Steam | planned |

## Batch A
Filed by core/74 from the three designs (core/71 Stages `docs/architecture/stages.md`, core/72 run ends `run-ends.md`,
core/73 washer and voices `washer.md`, `voice.md`). Review sheet: `docs/migration/batch-a-review.md`.

Waves run side by side, at most 5 agents; a wave starts when the waves before it are merged. Within a wave no two
tickets edit the same station scene, `house.tscn`, `cabinet.gd` or the Hands. Core tickets build on graybox Looks, so
none waits for an asset's go; the asset tickets (except assets/11) stop at their first line-up, `ready-for-human`, and
their Looks swap in when the designer says yes.

| Wave | Tickets (suggested model) | Clash kept apart |
|---|---|---|
| 1 | core/76 Stages: the run's state and Rows (opus); core/78 Carried things in the Hands; core/84 Voice lines and the bake (opus); core/89 The spray; assets/11 Cabinets to six Drawers (opus) | core/76 makes the Stages station, core/89 the Laundry station |
| 2 | core/77 A Stage's Socks; core/82 The Stage bar and its phases; core/85 Voices, Subtitles and the Voice station; core/90 The Laundry bin; assets/12 Machine Part models | core/90 alone on the Laundry station; core/77 and core/82 make no station change |
| 3 | core/79 Machine Parts; core/81 The Cabinets grow; core/86 The washing machine entity and its comments; assets/10 Floor lock models (opus); assets/13 The Laundry bin model (opus) | core/79 alone on the Stages station; core/86 alone on `house.tscn` (the washer replaces the marker) |
| 4 | core/80 Floor locks; core/83 Tallies, record, Whiteboard and Tab; core/87 The broken washer's looks; core/88 The Cutscene frame (opus); assets/15 The washer's subtitle icon | core/80 alone on the Stages station; core/83 after core/81 on `cabinet.gd`; core/88 alone on the washer station |
| 5 | core/91 The house's run; core/95 The Final screen; core/98 The knockdown wash; assets/14 The washing machine's model (opus) | core/91 alone on `house.tscn` |
| 6 | core/92 The Fix scene; core/93 The Laundry day | core/93 alone on `house.tscn` (the bins); core/92 only the house plan `.tres` |
| 7 | core/94 The First wash (opus) | |
| 8 | core/96 The Final wash | |
| 9 | core/97 Back to the Lobby | |
| later | core/99 The visible pour (`needs-info`, after the review, Q2627) | |

The designer plays batch A after wave 9 (the asset tickets' line-ups may be judged at the same sitting). **Built and merged 2026-11-25 (main a541cde); waiting for the designer's play session and the questions in the review sheet.**

## Batch B
Filed by core/123 from the three designs (core/120 Coins, Drawers, the Old Tree and the Upgrade grid
`docs/architecture/economy.md`; core/121 presents, Gifts, Collections and the encyclopedia `gifts.md`; core/122 the
Wardrobe, the Profile and Achievements `wardrobe.md`), answered Q2667-Q2683. Review sheet:
`docs/migration/batch-b-review.md`.

Waves run side by side, at most 5 agents; a wave starts when the waves before it are merged. Core tickets build on
graybox Looks, so none waits for an asset's go; the asset tickets stop at their first line-up, `ready-for-human`, and
their Looks swap in when the designer says yes; core/144 (the Trails' looks) stops at its first strip.

| Wave | Tickets (suggested model) | Clash kept apart |
|---|---|---|
| 1 | core/124 Coins and Drawers (opus); core/125 Collections as data; core/126 Spawned Parts (opus); assets/16 The present box (opus); assets/18 The hats and clothes (opus) | core/124 alone on `cabinet.gd`, `stages.gd`, the HUD (`player.tscn`), `level_runtime.tscn`, `project.godot`, the Final screen station; core/126 alone on `run.tscn`, `parts.gd` |
| 2 | core/127 The Profile file and the Lifetime tallies; core/128 Wardrobe pieces and the dressed Avatar (opus); core/129 The Upgrades and the menu (opus); core/135 Cabinet pools and the draw; assets/17 The encyclopedia book | core/127 alone on `player_profile.gd` (the only ticket on it) and `run.tscn`; core/129 alone on `old_tree.tscn`, `level_runtime.tscn`, the Economy station; core/135 alone on `cabinet.gd`, `stages.gd`, `house.tscn`, the Stages station; core/128 alone on `avatar_looks.gd`, `player.tscn` |
| 3 | core/132 The Old Tree's voice (opus); core/134 The encyclopedia record and unlocks; core/141 Looks in co-op (opus); core/144 The Trails as particles (look work); assets/19 The Socks pieces and Trail meshes (opus) | core/132 alone on `old_tree.tscn`, the tree's Part and `house.tscn` (the Doors' start); core/134 alone on `run.tscn` and `final_screen`; core/141 alone on `roster.gd`, `session_gate.gd`, `avatar.gd`, `player.gd`, the Wardrobe station; core/144 only `game/wardrobe/trails/` |
| 4 | core/136 The encyclopedia pages; core/137 Presents under the Old Tree (opus); core/145 Achievements: the system (opus); assets/20 The Wardrobe station's model | core/137 alone on `stages.gd`, `run.tscn`, `house.tscn`, `carriable.gd`, `prompts.gd`, `tally_recorder.gd`, the Gifts and Stages stations; core/136 alone on `title.tscn`, the Collections station; core/145 alone on the HUD (`player.tscn`), `game_link.tscn`, `project.godot` |
| 5 | core/130 The Personal Upgrades (opus); core/138 Opening a present (opus); core/140 The Old Tree's present lines; core/142 The Wardrobe page and station (opus); core/147 The Profile page | core/130 alone on `player.gd`, `hands.gd`, `session_gate.gd`, `project.godot`, `prompts.gd`; core/138 alone on `final_screen`, the Gifts station; core/140 alone on the tree's Part; core/142 alone on `house.tscn`, `sock_places.gd`, the Wardrobe station; core/147 alone on `title.tscn`, `esc_menu.tscn` |
| 6 | core/131 The Sole cues (opus); core/133 The Old Tree's help; core/143 The Lobby's Wardrobe key | core/131 alone on the HUD (`player.tscn`); core/133 alone on `house.tscn`, `cabinet.gd`, the tree's Part |
| 7 | core/139 The encyclopedia book (opus) | alone on `house.tscn`, `carriable.gd`, `hands.gd`, `prompts.gd` |
| later | core/146 Batch B's Achievements list (`needs-info`: which ones ship); data files only, any wave after core/145 once answered | |

How the cross-piece clashes the designs named are ordered: `player_profile.gd` only core/127 (both profile drafts
merged); `run.tscn` core/126, 127, 134, 137 in waves 1-4; `house.tscn` core/135, 132, 137, 142, 133, 139 in waves 2-7;
the HUD scene (`player.tscn`) core/124, 128, 141, 145, 131 in waves 1, 2, 3, 4, 6; `title.tscn` core/136 then core/147;
`stages.gd` core/124, 135, 137; `cabinet.gd` core/124, 135, 133; `final_screen` core/124 (the station's rename), 134,
138; `old_tree.tscn` core/129 then 132, and the tree's Part `old_tree.gd` core/129, 132, 140, 133; the seams S-122a..d
come before the tickets that need them (core/128 and core/141 before core/137; core/127, 128 and 141 before core/138).

At the merge (not wave clashes; each change is a separate line the lead keeps from both sides): `zoo.tscn` (wave 1:
core/124, 125, 126 each add one station instance; later core/128, 145), `tests/saves/shape.json` (each ticket adding
saved State regenerates it: take both entries, or rerun `save` case s11's kept copy), the one Theme's variations and
`sound_catalogue.tres` (appended by several tickets per wave), `credits` entries.

The designer plays batch B after wave 7 (the line-ups and core/144's strip may be judged at the same sitting).

## M0.5 batches (Q2296)
Each batch is one theme, tested in one sitting at one or two stations, ending with a short play session and the
designer's go. Order: what the later batches show on comes first.

| Batch | What | Tickets | You test |
|---|---|---|---|
| 1 | Hand details | core/09 (building) | cloth held and thrown, glide, pick fly-up, pairing fly-in, shelving flight, drawer shut |
| 2 | The two-tier Mess | core/13 | the every-Sock station runs smoothly; Socks on top fall when one below is picked; a throw wakes Socks; Doors and drawers push Socks; bounce and skid |
| 3 | Rules back to the old | core/14 | the nearer of a Sock and a ball is aimed; a sliding Sock can be picked; a new Pair is active; drop onto Socks; Cabinet: drawer fronts and drawers only; the capturing click does nothing else |
| 4 | Aiming and screen | core/11 outline, core/15 | the outline on everything you can use (red on a full drawer); the prompt and key hints; the aimed Size; the old crosshair |
| 5 | Feedback and motion polish | core/16 | the refusal wobble, "Paired!", the boxed held Size, the ball's squash, hop and roll, the flick ease, the old cloth bend and ground, the lost Sock's scatter and pop |
| 6 | Sound | core/17 | the plug-and-play sound system and every core sound and rumble |
| 7 | The picture | core/18 | the old light at noon (AgX, grade, vignette, SSAO, glow, MSAA and FXAA, HDRI sky, the sun) and the old font and theme |
| 8 | Close-out | triage, paperwork, code review (Q2425) | the `[later]` follow-ups triaged (2026-11-21: 38 closed, 13 decided by the lead, 29 to `m06-backlog.md`, 7 asked); no walkthrough page; you play every station in one zoo run and review the code from the review guide and the code map |

What M0.5 left for later is in `m06-backlog.md`, by system; the old features with no milestone yet are tracked
as core/41-45 (Q2430). Parked experiments: core/37 bent lying Socks (Q2426); closed: core/38 jointed flights (Q2423).

Later, not in M0.5: the pad differences (Q2302), the Coins and Pairs counter and the ESC menu (Q2300), the 20-minute
day (Q2299).

## M0.6 batches (proposed 2026-11-22, for the designer's go)
The same shape as M0.5: each batch one theme, tested at one or two stations with a second window as the Guest,
ending with a short co-op play session and the designer's go. Each piece starts with its behaviour list from the
old game (drafts: the four co-op lists of 2026-11-22), approved by the designer before any design or code.

| Batch | What | You test |
|---|---|---|
| 0 | Two spikes, no game change: Jolt flight bodies on a synchronizer (the Throw's Option A, `coop-structure-for-the-port.md` 4), and a PhysicalBoneSimulator3D pose reaching a Guest (Q2225) | nothing to play; a short report decides the Throw path and the ragdoll's sync |
| 1 | Host, join and roster, ready for Steam (Q2456-Q2458): the transport, identity and gate behind a seam with ENet as its first transport; the gate with the player id (the long random id off Steam, Q2224; the Steam ID and its ticket come with the lobby, M4), the Roster Part (max players, colours, names, refusals), join and leave messages, a leaver's Hands dropped where they stood, the Host quitting | host in one window, join from another; join a full or a wrong build; leave and rejoin |
| 2 | The avatar model (asset piece: `avatar.glb` and feet, its rig, HoldPoint and HatPoint) and Teammates seen: the pose every frame with light easing (Q2223), head look, crouch, waddle and squash, the held item at the HoldPoint, colour, name tag, a teammate's sounds and footsteps at their body (Q2376) | walk, crouch, look, pick and hold beside each other and watch the other window |
| 3 | The Mess, Hands and Throw in co-op (the Mess half: coop/07, coop/08, plan `coop-mess-sync.md`, Q2472; the Hands and Throw half: coop/09): the late joiner's Mess, the settle stream, a Guest's Mess read-only, woken flights and sweeping Doors seen by a Guest, a Guest's pick (Q2220), drop, refusal, Throw ghost with its blend (Q2221), a Teammate's Throw with its pause (Q2226), catch, pairing, shelving and Coins from a Guest, two players on one Sock; the seven co-op lines of `m06-backlog.md` | the heap and cabinet stations as a Guest, a late joiner mid-pour, both players grabbing one Sock |
| 4 | Knockdown with Godot's own ragdoll (Q2225; coop/10, list approved Q2496): what knocks a player down, the ragdoll, the knocked view, getting up, the knock sound and rumble; drag and wash only as the designer scopes them | throw a full charge at the other player; get up; watch it from the third window |
| 5 | Close-out: tests at 0 and 50 ms one way, guard tests (bad shape, rate, a forged avatar write), the co-op cost measured with a Guest at 2,000 Socks, the zoo run in co-op, code map and review guide | one co-op zoo run of every station |

Batches 1 and 2 can run side by side (different files); 3 needs 1; 4 needs 2 and the ragdoll spike.

## What changed from the first plan
- M0.5 is a true vertical slice of the core: its sounds, rumble and polish details move into it from M1.1 and the polish pass (Q2296).
- Sound is its own milestone, M1.1, out of M1 (Q2278); the old game's small looks and screen details wait for a polish pass (Q2279-Q2281).
- The four hand-authoring slices and their review gate are gone; the zoo replaces them (Q2207, Q2208).
- "All assets before any scene work" (Q2162) is replaced: an entity is behaviour plus a swappable Looks child
  scene, so the zoo starts with graybox looks and the model is swapped in later (Q2213, Q2214).
- "The first slice runs with a Host, a Guest and a late joiner" (Q2160) keeps its intent and changes its wording:
  M0.5 is single-player but co-op-ready; M0.6 adds the other players (Q2209, Q2212).

## The looks baseline
70 fixed views of the old game at `v0.1`, captured by its capture tour in the sandbox (software renderer,
1280x720): `docs/migration/baseline/`. The rebuild is captured the same way, in the sandbox, with the same views
file, and compared with `kit/tools/baseline.py` (`kit/docs/agents/baseline.md`). 69 of the 70 are pixel-stable
between runs; `avatar-hat-clothes` is not (an unseeded idle animation).

## The end
A retrospective and a reusable set of skills for moving another project the same way, written from `journal.md`
(the old repository's ticket maintenance/139 tracks it).

Mapping from the research files' older numbering: their "assets" milestone is M1, "house" M2, "first co-op slice"
M0.6, "core loop" M3, "frame of a run" M4, "features" M5; their "M0.5 slices" no longer exist.
