Next free Q number: Q2574 (update this line whenever a round of questions is asked)

# Decisions for the move to a fresh project

Binding answers of the designer, all 2026-11-19, copied from `reference/it-socks/docs/llm/maintenance/issues/131-scenes-and-resources-plan.md`
(section "Answers"). Quotes are the designer's words. A number marked "reading" is the lead's reading, not an answer.
Q2171-Q2174 and Q2182-Q2187 belong to the old game's vacuum devices and Sock looks, not to the move. **Where a later answer changed an earlier one, the earlier line says so; the later one binds.** The old answers
Q1-Q2142 sit in the reference clone's tickets; cite them by path.

## Shape of the move
- Q2143 Fresh project, not a rebuild: "Fresh project, features ported based on the most neccessary ones - core, new scenes and resources workflow. Ideally going one by one and teaching and explaining how the code works and asking a lot about the structure. With whole architecture planned before. New test suite written up - similar rules, different fields. Tools, benches, ... stay in place, as a baseline for the new project - every tooling reused, improved. Every line of code has to fight for it's life whether it can be unified or not. A new set of skills (cleaned up) to work on. A lot of authorship and decisions on my side."
- Q2144 Switched-off features (Hampers, the Grotto, Dirty Socks, the pairing machine): "We will start from fresh project." Reading: nothing is deleted from today's game; a feature exists in the new project once ported, each port the designer's call.
- Q2145 Order: "Core loop first ported."
- Q2148 Today's game: finish the vacuum device set (tools/24-30) and play it there, then freeze: bug fixes only; it stays the playable baseline.
- Q2149 "New repository will be the thing. First we will port all the props and stuff that's plugged into the game and ideally improve it, so we have the assets ready, then we start plugging it together in the project." Reading: assets, then the core loop, then features by need.
- Q2158 "I will create it and add to sandbox." The lead creates nothing.
- Q2179 The 237 commits on main not on GitHub: "I will push."
- Q2180 Today's game goes into the new repository as a plain clone in an ignored folder `reference/it-socks/`.
- Q2181 The new repository lives on the mounted drive next to it-socks; every merge is pushed; the check and repair tools come along.
- Scope of the first session: "Let's not start doing any migration work - only preparations right now. The migration itself will happen in another session. We will also get a fresh tickets and issues board if you think it makes sense." Later: "The game will be frozen, once the vacuum reworks finish. Meanwhile I think we can start on scaffolding some of the stuff."
- Preparations asked: "Definitely 1, then 3. Ideally before building everything, we could get a glimpse at some vertical slices for the hand-authoring." (1 = a plain-words record of what the game does; 3 = the risky bets with proofs and stop rules.)
- "Also the whole process should result in a retrospective + a skill sets so other project can be transferred in a similar way." A migration journal is kept from the start.
- "Also consider planned features in this project into the planning for the nativization, so something isn't left over." (`feature-catalogue.md`)
- Planning page: Q2150 "One artifact, the one we already had, cleaned up once we know how everything should be laid out, a new step tracking page." Q2170: milestones with pieces, each piece planned, design agreed, built, approved.

## Authorship and tests
- Q2159 Agents write, the designer approves each piece. Before a piece: its design (classes, fields, a code sketch) and a grilling. After: a plain walkthrough of the real code; it merges only on the designer's OK.
- Q2169 Walkthrough: a page per piece on the artifact (purpose, diagram, the real code with plain notes, how to try it, open questions); approving is answering the dialog.
- Q2165 The designer approves a plain-words behaviour list before a feature is ported; tests are written from it; a test changes later only with the designer's OK.
- Q2160 Co-op from the first game code: the first slice (one Door, one carried thing) runs with a Host, a Guest and a late joiner in tests. **Reworded by Q2209 and Q2212:** M0.5 is single-player but co-op-ready, M0.6 adds the other players.
- Q2166 Carried over besides assets and tools: the glossary; the skills, agent brief and CLAUDE.md rewritten short and clean. Not carried: the ADRs (new decisions get new records) and the ticket vault (a fresh tracker that points to the old one).

## Code and data
- Q2146/Q2147 State lives on the scene part (shape B of `code-shape.md`): a field of the part, visible in the inspector; only the Host's answer to a Command writes it; one generic piece handles saves, late join and sync; the Mess stays its own data. To be proven with a Guest and a late joiner in the first slice; ADR-0006 gets amended for the new project. (Asked back: "What's the best for godot authoring co-op stuff?"; `code-shape.md` chose shape A, the designer's answer chose B.)
- Q2163 Screens are scenes on one Theme; code fills in data and reacts to clicks (reverses the old Q1192).
- Q2164 Numbers: typed Resources per feature, edited in the inspector; a number of one placed prop is a field on that prop; each number comes over only with its feature.
- Q2167 Folders: "Game and assets apart": `game/` code and scenes by area, `assets/` models by family, `data/` settings.
- Q2168 The Mess: the two-tier design stays, the code is rewritten clean with its shape explained first; the bench proves it is no slower than today.
- Q1200 (old, still binding): use Jolt wherever it can; custom physics only with a reason.

## Assets
- Q2151 A ported prop is "1 + models." Reading: the cleaned model files, and per prop a scene without behaviour: the model, its collision, named moving pieces, Sock spots and hold points, shared materials. No game code.
- Q2152 Blender scripts stay and build meshes only (`.glb`); placement, collision, Sock spots and settings move into Godot scenes edited by hand.
- Q2153 "Improve" while porting means technical only, looks unchanged: origins, scale, names, collision, shared materials, file sizes; a before and after strip proves it. Remodels are separate tickets.
- Q2162 "Everything before any scene work": all models, sounds and UI art are ported and cleaned before the house is assembled. **Replaced by Q2213 and Q2214:** assets and the house run beside the zoo; an entity starts with graybox looks.
- Q2176 Sock spots: a bake button on the furniture piece computes them from its surfaces and saves them with the scene; dots in the editor, single ones added or deleted by hand.
- Q2177 One shared material library for all models; where variants differ (oak: 9 in 39 models) the designer picks the one that stays from a strip.
- Q2178 Things built by code today (the Drum interior and water, Guide cards, gift boxes, the padlock sign, the dust sheet, the Sock detector's screen) become models or scenes in the asset port.

## The house
- Q2154 Built by hand in Godot, walls and floors too: "2. so it's easy to author the house - ideally should be modular, so I can place stuff around, assign materials, ... First iteration should be the house created out of the props - without functionality." Reading: a kit of wall, floor, door and stair pieces; the layout file and `make_house.py`'s whole-house build go.
- Q2155 "1. In future 3." Today's floors, rooms and sizes rebuilt from the kit, furniture where it stands today as a start; a new house design later, as its own task.
- Q2156 Kit pieces are scenes that snap to a grid, dragged from the file dock; each placed piece can get its own material and settings. Not GridMap.
- Q2157 The first house milestone: editable in the editor, and Play walks through it in first person with a throwaway walker.
- Q2175 Half-metre grid: walls in fixed lengths (0.5, 1, 2 m); every room nudged to the nearest half metre (up to 25 cm), furniture re-placed; the house is no longer an exact copy.
- Q1954 The home is called "the house", no longer "the flat". Collections renamed on 2026-11-19: Basic is Simple, Casual is Patterns.

## The core loop (first playable)
- Q2161 The Mess, Hands and Throws; Pairs and Cabinets (with Doors and Drawers). Not in it: Stages and the Laundry day; menus, saves and the lobby. Reading: co-op tests need a plain way to host and join without the lobby.

## Standing rules from the old project (still binding)
- Q1795 No save compatibility until the first outside play-test. Q2056 Tests use the game's features, never zoo buttons. Tests: "They can pin layout, but it shouldn't be the THING that's important." The core loop is tested most.
- Commit messages carry no `Co-Authored-By` line for Claude or any AI assistant, for the lead and for ticket
  agents, whatever the assistant's defaults say (designer, 2026-11-20). The kit's `tools/commit.sh` refuses one.

## The kit and the order (2026-11-19, evening)
The hand-off was first built as its own scaffold; the designer pointed at the game starter kit instead. The move
sits on **starter kit 7.1** plus this small port pack.
- Q2196 Board: the starter kit's vault `docs/llm/`.
- Q2197 Q numbers continue the It Socks sequence here; the starter kit keeps Q1 for new games.
- Q2198 Delivery: two zips, the starter kit, then the port pack over it.
- Q2199 The starter kit ships the Python test runner.
- Q2200 Merging: "My OK per piece, merged in batches. Ideally don't have too much additional process in integrating the branches, we should move quickly."
- Q2201 The git check and repair tools are always in the kit; `tools/commit.sh` is the one way to commit.
- Q2202 Proof of the kit: "I will prove it myself on a prototype of a game." No fresh-agent dry run was made.
- Q2203 The looks baseline at `v0.1` is captured before the port (done: `docs/migration/baseline/`).
- Q2204 Required steps in the kit: the parse check before suites, a conflict preview before a batch, the asset lint in the merge, a session ledger line at session end. Other tools are used when they help.
- Q2205 The kit ships two co-op shapes; this project uses **scene parts**.
- Q2206 The reference clone holds the tagged commit only.
- Q2207 M0.5 is a zoo: "grayboxed zoo for testing systems (creating a new zoo) - the zoo should be a playground for the individual features, grayboxed flat area, not neccessarily for testing the real level. Can be played in coop."
- Q2208 It replaces the four slices: "Zoo slice of one cabinet, pairing, handling socks, movement, the CORE!"
- Q2209 "M0.5 singleplayer M0.6 co-op zoo base."
- Q2210, Q2215 The zoo in the starter kit: "Should be a skill for designing a good zoo. Not neccessary for every game, but optional. Should be generic." The skill plus a small template scene.
- Q2211 Zoo objects: "Real entities from the game - so we are not testing / implementing two different systems at once. Zoo should be always a scene, that can be easily edited in editor."
- Q2212 M0.5's code is co-op-ready from line one with one player: every change goes through the shared-state path, the player a Host of one.
- Q2213 Entity looks: a graybox mesh inside the real entity, the model swapped in later. "I would like to consider animationplayers for the animations, not directly code animations." Reading: an entity is behaviour plus a swappable Looks child scene whose node and animation names are checked (`looks_contract.json`, `tools/asset_lint.py`); state plays an AnimationPlayer in Looks.
- Q2214 Order: M0 setup; M0.5 the core in a single-player zoo; M0.6 the co-op zoo base; M1 assets (the core's models first) and M2 the house, both alongside; M3 the core loop in the house; M4 the frame of a run; M5 features by need, each first a zoo station.
- Q2216 Approvals: assets in family batches, code per piece.

## The capture tour (old game, 2026-11-19)
- Q2217 The tour is a tooling-only change to the frozen game, tagged `v0.1.1`.
- Q2218 The views are a file; the It Socks file holds the baseline views (`docs/migration/baseline/views_baseline.json`).
- Q2219 Views that need a state (a full Cabinet, the wardrobe, the encyclopedia, settings, the ending) are in the same run, each state set up once and reset.
- The baseline is the sandbox tour set; the designer will not run the tour on their PC ("no point of me running it then"). The rebuild is captured the same way, in the sandbox.

## Co-op structure (2026-11-19, night)
From `coop-structure-for-the-port.md`, `hl-multiplayer-report.md` and `ids-roster-guards.md`. The structure: decided
state is Parts and Commands (the Host decides); a player's body and things in the air are Godot synchronizers,
owned by one machine; things created during play use Godot's spawner; the Mess is one bulk system that is one
Part; a gate at connect; authority follows decided state; prediction is looks only.
- Q2220 A Guest's pick is looks only: the Sock flies to the Hands at once; the Hands and the count change on the Host's answer.
- Q2221 A Guest's Throw: the Host owns the body; the thrower sees an instant ghost that cannot touch the Mess and blends onto the Host's flight over 0.2 s.
- Q2222 Moving Socks stay as in the old game: each machine simulates them for looks and snaps to the Host's rest.
- Q2223 Other players' avatars update every frame with light easing, not 20 a second: an intended difference from the old game's look.
- Q2224 A long random player id in the profile from M0.6 on, everything saved keyed by it; the proving token comes with the lobby (M4).
- Q2225 M0.6 includes the full knockdown: "Ragdoll should be also handled natively the godot way." Confirmed the same night ("Ideally yes, instead of another handrolled code that could be godot native"): Godot's own physical-bone ragdoll on the avatar's skeleton; how its pose reaches other players is tested before it is built; the avatar's rig moves to the front of the asset port.
- Q2226 A Teammate's Throw keeps the old look, the short pause at release included.

## Kept as tickets, not built (the designer's calls)
- Stable ids for placed things (so a renamed or moved node keeps its saved state): planned for starter kit 7.2; until then a thing is found by its node path from the level. Do not rename or re-parent a placed entity once saves exist without saying so.
- A roster Part (who is in the session, by player id): "Let's not overcoplicate this, but keep it as ticket."

## The lead's readings (not decided by the designer)
- Proven code (the Mess's design, Sock drawing, placement maths) is carried over after examination, not rewritten on principle. The designer asked for this recommendation and did not contradict it; no answer recorded.
- The Mess as one Part with its own bulk snapshot is the lead's mapping (`coop-structure-for-the-port.md`); its design is grilled in M3.

## Superseded text in the copied research
- Everything about **M0.5 as four slices with a review gate** (`risks-and-slices.md` part B, `new-project-start.md`): replaced by the zoo. The risks of part A and their stop rules still stand.
- Everything about the **board in `docs/tickets/`**, copied skills, a hand-built scaffold and tools copied from the reference (`new-project-start.md` parts B to D): replaced by the starter kit.
- Milestone numbers: `milestones.md` governs; it has the mapping.
- `state-and-coop.md`: its classes are the kit's scene parts now (`game/parts/`, the `multiplayer-game-dev` skill); its "our own messages for everything" is replaced by the co-op structure above. Its ten questions: see `open-questions.md` B1.
- `code-shape.md` picked shape A; Q2147 chose shape B. Its test method is superseded by Q2165.
- `coop-structure-for-the-port.md` asks its own questions at the end; Q2220-Q2226 answered them.
- Clone depth, "next Q is Q2179 / Q2196": the clone is the tag only; the next Q is line 1 of this file.

## Glossary names at the freeze (old session, 2026-11-19)
Q2188-Q2195: Sock vacuum, Backpack vacuum, Splitter, Filter nozzle and Nozzle display, Spit and Pour, Tank (Big Bag keeps its name), Hopper / Output / Pile / Reject, Filter. Entries are in `GLOSSARY.md` (and in the reference clone at `v0.1.1`). The old code and UI text were not renamed.

## Project setup (new session, 2026-11-20)
- Q2227: the project values as this pack set them (It Socks; co-op yes, scene-parts; zoo, Blender, Profily yes; the old models rule; saves compatible from the first outside play-test), renderer Forward+.
- Q2228: at most 5 parallel agents.
- Q2229: platforms Windows and Linux desktop.
- Q2230: no GitHub remote for now; commits stay local.
- Q2231: the old game is the git submodule `reference/it-socks`, pinned at `v0.1.1` (the designer added it as `prototype/`; moved so the kit skips it).

## M0.5, core/01 zoo movement (2026-11-20)
- Q2232: the movement behaviour list approved as written (`docs/llm/core/issues/01-zoo-movement.md`).
- Q2233: no sprint in M0.5; sprint and Footwork come with the Upgrades (M4).
- Q2234: zoom is ported with handling Socks (core/02).
- Q2235: pad bindings for movement now; the stick look's deadzone, curve and speed-up in a later ticket.
- Q2236: the core/01 design approved: the kit's graybox player becomes the game's `Player` in `game/player/`, with `MoveTuning`.
- Q2237: the movement station: wall, ramp, ledge, low beam, 0.5 m box.
- Q2238: mouse sensitivity and Invert Y are `MoveTuning` fields until the Options screen (M4).
- Q2239: core/01 merged on the designer's OK.
- Q2240: editor re-saves in the designer's working copy (`project.godot` reordered, `.mcp.json` tabs) are discarded, not committed.
- Q2241: no play session now; go on with core/02.
- Q2242: kit noise is fixed locally, not upstream: "what shouldn't be in godot should be gdignored". `docs/.gdignore`; the game's git ignores untracked files in `kit/`.

## M0.5, core/02 handling Socks (2026-11-20)
- Q2243: the handling behaviour list approved as written.
- Q2244: carry capacity is a player tuning field (1); the zoo's player instance overrides it in the editor.
- Q2245: pad buttons as the old game: A pick, B drop/Throw, Y interact, X jump, LB/RB the wheel.
- Q2246: the held items keep the old layout, compared with the baseline still `held-sock.png`.
- Q2247: loose Socks live in a small `Mess` Part from M0.5 (records; one mesh each); M3 adds the bulk parts. Socks are placed as `SockSpot` markers.
- Q2248: the 605 Designs become a typed `DesignCatalogue` Resource.
- Q2249: the graybox Sock is the old `crew.glb`, tinted, unported, until M1.
- Q2250: the Throw is split into core/08, after core/02.

## Code shape (2026-11-20; open-questions B1 7-9)
- Q2251: inheritance one step: Part, then Openable; nothing extends Openable.
- Q2252: one class per file, named alike.
- Q2253: a thing gets a script only when no Part can do the job.

## M0.5, core/03 pairing (2026-11-20)
- Q2254: the pairing behaviour list approved as written (the survey's Pairs questions answered "keep").
- Q2255: the pairing moment stays as it was; AnimationPlayer in the Looks and a particle burst; a strip before merging.

## M0.5, core/04 one Cabinet (2026-11-20)
- Q2256: the Cabinet behaviour list approved; a drawer's capacity is a configurable field (25 today), the model keeps 25 slots.
- Q2257: core/02 merged; the held Sock matches the old layout.
- Q2258: the kit's example crate and the Carriables station are retired.

## M0.5, core/08 the Throw (2026-11-20)
- Q2259: the Throw design approved (the drop path with a speed; wake; bounds and return spot).
- Q2260: the charge ring keeps the old look.
- Q2261: the zoo's return spot is on the handling station's pad.
- Q2262: the pairing design approved (Pairs are linked Sock records in the Mess, named by the lead Sock).
- Q2263: the sock ball stand-in is the old ball_crew_plain.glb, tinted.
- Q2264: the Cabinet design approved (drawer entities with Openable; Cabinet Part; shelve Command; Coins Part).
- Q2265: the Cabinet stand-in is the old simple.glb, unported.
- Q2266: the zoo Cabinet is the Simple Collection.
- Q2267: core/08 merged; the stand-in check "a long press does not drop" is retired (a long press throws).
- Q2268: files are kept in the Godot editor's format; editor re-saves are committed, not discarded (replaces Q2240).
- Q2269: core/03 merged as built (the Collection colours, two mate Socks in the handling station and the shot set kept).
- Q2270: the pairing moment's Sock keeps the fixed fly-in path, as the old game's.
- Q2271: the moment's Socks keep their sizes in the animation keys; ball_scale does not resize them.
- Q2272: the old hand motions are ported: cloth Socks (held and thrown), the glide on switching, the pick fly-up (core/09).
- Q2273: core/09 is built right after core/04, before M0.5 closes; each detail stops at its first still.
- Q2274: the pairing moment's second Sock flies in from where it lay, like a pick (replaces Q2270).
- Q2275: what else looks different about the Throw: asked again after the cloth is in.
- Q2276: core/09's behaviour list approved as written.
- Q2277: the small details (motions, glides, flies, sways, pops, sounds) of every piece are always explored and listed; only the designer drops one, and a left-out detail is asked about at once, never parked as [later].
- Q2278: sound is its own milestone, M1.1, made plug-and-play; every old sound and rumble goes there (old-details-backlog.md).
- Q2279: the old screen text (prompt and key hints, aimed Size, "Paired!", boxed held Size) is ported in a polish pass.
- Q2280: the old soft outline and the refusal wobble are ported in the polish pass.
- Q2281: the ball's landing squash, hop and roll, the cloth curl in the pairing fold and the smooth flick ease are ported in the polish pass.
- Q2282: core/04 merged as built; a left click uses anything that is not a Sock, as the old game's click did.
- Q2283: the Cabinet's shelving flight and the old drawer slide ease (out both ways) go into core/09.
- Q2284: the zoo has one Mess and one Hands for all stations (core/10).
- Q2285: the Cabinet's refusal order is the old game's: "Wrong Cabinet" before "Cabinet locked".
- Q2286: core/09's cloth bends with the Sock's speed, as the spring-bone node does by itself; the old bend-on-a-change-of-speed waits in the polish backlog.
- Q2287: core/09's cloth uses the node's own ground plane (may crumple at the contact); the old straightening waits in the polish backlog.
- Q2288: core/09's design is approved; it builds after core/10.
- Q2289: core/10 merged: one Mess, Hands and Coins for the zoo.
- Q2290: Designs may repeat across zoo stations; the zoo gets a station of every Sock in the game laid out on the ground, at the end.
- Q2291: the return scatter and pop and the unsinking of a sunk Sock wait for the polish pass.
- Q2292: the outline is one reusable component (Outline plus an OutlineStyle resource) on every interactable, ported from the old highlight; plan approved (core/11).
- Q2293: core/11 is built in the polish pass.
- Q2294: the every-Sock zoo station lays the Socks out in rows by Collection, with the Collection's name, in Design order, each Sock beside its mate.
- Q2295: its Socks are real Mess Socks you can play with; the zoo is never saved and always starts fresh; each Sock has its info as text in front of it.
- Q2296: M0.5 is a true vertical slice of the core: the core's sounds and rumble (a plug-and-play sound system) and its polish details (old-details-backlog.md, core/11 outline) are built in M0.5; a deeper audit lists every other difference from the old game's core.
- Q2297: the rules audit's differences are decided one by one; the mouse-capture click is a bug against L03, fixed.
- Q2298: the Cabinet's drawers are outlined too (core/11), unlike the old game.
- Q2299: the zoo gets the old picture (AgX, grade, vignette, SSAO, glow, MSAA 4x + FXAA, HDRI sky, the tuned sun) at a fixed noon; the 20-minute day comes with the house and the run.
- Q2300: into M0.5: the old font and theme, and the old crosshair (two bars, 18 x 2 px); the Coins and Pairs counter and the ESC menu and Options stay out.
- Q2301: core/12 merged as built (one label per pair); the two-tier Mess (MultiMesh drawing, static colliders) is next, and the designer is asked what to remove or change in the rewrite.
- Q2302: the pad differences (full-speed stick, the old look stick, the crouch trigger, pad zoom and turn) wait for later.
- Q2303: back to the old: the nearer of a Sock and a ball under the crosshair wins, and a sliding Sock can be picked; kept: no 3 cm forgiveness, our zoom slow-down curve.
- Q2304: back to the old: a new Pair goes to the end of the Hands and becomes active, and a drop onto a lying Sock or Pair is allowed; kept: a drop lands square to the dropper (no R turn).
- Q2305: the two-tier Mess: a lying Sock is a static collider made in the physics server plus a MultiMesh instance, no node; a Looks scene only for the aimed, held and nearby flying Socks; records, Commands and co-op unchanged.
- Q2306: the old moving budget is ported whole: 512 with 32 reserved for Throws, a queue nearest-first, per-tick start and stop caps, the pressure rules (numbers placeholders until a stress test).
- Q2307: no stored support links: a pick asks the physics which lying Socks sit just above the picked one.
- Q2308: built with the rewrite: a pick wakes up to 40 Socks lying on it (Socks too); a body at 1.5 m/s or more wakes the Sock it hits and up to 8 touching; Doors and drawers wake and push Socks, and Socks ride out in a drawer; a flight rests after it has stopped moving for a short time, never forced by its total time (designer's correction).
- Q2309: a lying Sock collides as two boxes (leg and foot), a Pair as a sphere.
- Q2310: lying Socks are drawn in MultiMeshes grouped by an 8 m floor grid (placeholder), with Godot's automatic LOD and visibility ranges.
- Q2311: back to the old: thrown and dropped bodies bounce 0.35 and slide at friction 0.6; the old damping (woken 0.6 / 3.0, dropped 0.05 / 0.8); kept: the same spin each Throw, a thrown Pair's drag all the way.
- Q2312: back to the old: a thrown Pair shelves only on a drawer front; only a drawer takes a shelve by click.
- Q2313: core/09 merged; the cloth numbers set by eye stand until tuned in play.
- Q2314: the pairing moment's fly-in keeps 0.2 s; the moment stays 0.5 s.
- Q2315: a thrown Sock carries its held bend into the throw: polish batch 5.
- Q2316: a shelved ball's landing squash, hop and roll and a thrown-shelve's flight to its slot: polish batch 5; a teammate's shelving flight and sparkle burst: M0.6.
- Q2317: the sound system (core/17) and the picture and theme (core/18) start now in their own worktrees and wait ready for batches 6 and 7; the Sock models (M1) do not start yet.
- Q2318: the sound catalogue is typed Resources in the inspector: one SoundEvent per named event (clips, volume, bus, flat or 3D) holding an AudioStreamRandomizer for variations and pitch; buses in the editor's bus layout.
- Q2319: the clips are the old game's picks for each core event, with their volumes; the other candidates stay in the reference.
- Q2320: a 'Sounds' station in the zoo plays every event, flat or from a spot.
- Q2321: built with the system: muffling behind a shut Door (-9 dB, 900 Hz low-pass), footsteps by surface (1.4 m, wood or tile) and the landing sound, volume per bus as settings, a quiet zoo ambience.
- Q2322: the zoo's sky is the old day HDRI at noon: sky ambient 0.7, sky reflections, the warm sun (1.0, 0.93, 0.82) at 2.4 with soft shadows.
- Q2323: the old graphics presets (low, medium, high) are ported now as a setting, chosen by a project setting until the Options menu exists.
- Q2324: the old Patrick Hand theme on all 2D screen text; the zoo's 3D station signs keep a plain readable font.
- Q2325: the house kit's wall heights and thickness are the old house's, per floor where they differed, nudged to the grid.
- Q2326: the first kit has walls and corners (0.5, 1, 2 m; outer, inner, T), floor and ceiling tiles (0.5, 1, 2 m), door and window walls sized as the old house's, and a straight stair with a landing.
- Q2327: kit pieces snap by Godot's own 0.5 m grid: each piece's origin on a grid corner; no plugin.
- Q2328: each kit piece has a simple box collider and one material slot overridden per placed piece, from a shared library of the old house's materials.
- Q2329: core/13 (the two-tier Mess) and core/19 (batch 1 fixes) merged.
- Q2330: a fast hit never wakes a lying Pair, as the old game's Q1742; lying Socks only (fixed on main, case t11_pair_stays).
- Q2331: the HUD and messages keep Godot's default font, as the old game; Patrick Hand waits for the whiteboard and the screens that used it (replaces Q2324).
- Q2332: the Sock held stiff during a throw's catch-up: polish batch 5.
- Q2333: core/17 (sound system) and core/18 (picture and theme) merged ahead of their batches.
- Q2334: the heap station spawns Socks by a click, about 500 a batch (a tuning number).
- Q2335: the heap is spilled live from a spout above the pad in waves, settling under the moving budget.
- Q2336: the heap station has a respill button, live counters (moving, waiting, resting, physics time), low walls round the pad, and a slope or table.
- Q2337: a zoo station that shows game data is built from that data at load (a new Design, sound or other entry appears with no other change); the Sounds station is rebuilt from the sound catalogue with smaller boxes (designer, 2026-11-20).
- Q2338: core/14 (the rules back to the old game) merged.
- Q2339: any moving Sock can be aimed and picked, a dropped or thrown one in the air too (as the old Q783); changes core/02's H10.
- Q2340: core/22's still: the overlapping labels and the sign over the buttons are fixed, then it merges without another still.
- Q2341: a woken, sliding (or flying) Sock under the crosshair gets the outline in core/11, not before.
- Q2342: only a click captures the mouse; a wheel notch while it is free does nothing (kept as built).
- Q2343: the house kit must build the old house nearly identically; the old house is re-gridded to the kit's 0.5 m grid (about 10 x 8.5 m, rooms and windows move up to 0.25 m), not sized pieces nor a fine grid (designer, 2026-11-20; widens Q2325-Q2326).
- Q2344: the kit also covers every old window (frames, sills, casings, glass, frosted) and door frames, skirting and the U stair's newel wall and railings, the pitched roof, knee walls, gables, dormer and attic, and wall openings for the entities (elevator shaft, garage door, front door, basement window wells).
- Q2345: the proof is the whole old house (4 floors) rebuilt from kit pieces only, stills from the old looks-baseline views beside the old game's.
- Q2346: house/01 merges as a first step; house/02 widens it.
- Q2347: core/20's heap station moves clear of every pad (it stood on the house kit's spot), then merges with no new still.
- Q2348: the heap station pours nothing at start; the first batch waits for More.
- Q2349: measure frozen full Socks against the two-tier Mess at 500, 2,000 and 10,000 before deciding whether the rest swap stays (docs/research/frozen-socks-vs-two-tier.md).
- Q2350: house plan: the U stair gets a 0.9 m half landing, 33.3 degrees (old 31.3).
- Q2351: house plan: the laundry and bedroom doorways keep their old places through an off-centre door piece.
- Q2352: house plan: outer wall centre lines 10.5 m apart (inside 10.3 m, 0.2 m wider than the old house).
- Q2353: house plan: storeys 3.0 m with the old clear heights kept (2.7, 2.7, 2.6 m) through thicker ceiling tiles.
- Q2354: house plan: the roof at 40 degrees (ridge 3.88 m over the attic floor; the old house was 37.4).
- Q2355: house plan: openings, "We can try multiple things here": the kit gets both the old-width window pieces and grid-rounded ones, compared side by side on a still before one is chosen (the lead's reading).
- Q2356: the Throw's real body leaves from the hand on an arc aimed at the crosshair's point; the eye-line start and the hand catch-up go (changes the old Q483 and core/19's F1).
- Q2357: the flipping Socks are seen in the heap pour, on settling, in drops and throws, and at the every-Sock station (core/23).
- Q2358: house kit pieces never z-fight: no coplanar overlapping faces between pieces placed by the grid convention (floors against walls on upper floors seen in house/01); a convention and a test (house/02 K14).
- Q2359: the zoo's stations are instanced by hand in zoo.tscn so the designer moves them in the editor; the folder collector and grid placement go (core/26). Branches adding stations will meet in zoo.tscn (accepted).
- Q2360: the Sock prompt as the old by upgrade: the base (pick key and boxed Size; the held Size letter), Sock Smarts' held readout and Sock Sense's aimed readout are all built in core/15, each upgrade a flag the player has, both on in the zoo with a toggle at a station; M4 wires buying.
- Q2361: the corner shows all the old hints: Jump and Crouch always, Drop/Throw, Zoom, Turn, Cycle when they apply.
- Q2362: the prompt keys are the old keycap pictures (1.5x the font), the art ported.
- Q2363: the prompt rows at the old places and sizes (58 %, 63 %, 70 % of the height; 32, 28, 24 pt).
- Q2364: an openable's prompt shows the old key (E, or LMB for a click-only one).
- Q2365: "Drop / hold: Throw" always shows: the old game never gated it by an Upgrade (the draft's premise was wrong).
- Q2366: the Sock cloth keeps Godot's spring-bone node, tuned so it does not flap so much (the old springs felt "kinda sticky"); the old ports of Q2286/Q2287 are dropped.
- Q2367: the drop also leaves from the hand: the body is let go at the hand and falls to the spot; the drawn flick and the 3 cm hold go (core/23; changes core/08 H10's flick).
- Q2368: the Door swings 0.6 s eased in and out, the cupboard 0.35 s eased out (the old timings).
- Q2369: lost and sunk Socks: the old numbers at the zoo's return spot, plus a station button that loses and sinks a Sock.
- Q2370: "Paired!" gets a short pop of the text (a look change; built in core/16 with its own still).
- Q2371: the bounce sound follows the hit speed: soft hits quiet, hard ones louder and higher (a sound change from the old one level).
- Q2372: each sound event has a minimum gap (e.g. 0.05 s for bounce), set in its SoundEvent, so a heap does not fill every voice.
- Q2373: the shelve sound plays at the click, as the old game.
- Q2374: the outline is made a little stronger for the graybox (inner shells' opacity and width up, old shape kept), rechecked on the M1 models.
- Q2375: pad rumble always on, kept as a setting (pad/rumble, default on) for the menu later.
- Q2376: a teammate's own sounds and the knockdown rumble come in M0.6 with co-op.
- Q2377: every jump lands with the "land" sound, as the old game (the 3 m/s gate stays).
- Q2378: four M1 asset families start now beside M0.5: the Sock models and prints, the 17 Cabinets, the UI art and keycaps, the house furniture with the shared material library (assets/01-04).
- Q2379: after the old Sock look is ported, Socks get a wool look (knit texture and normal mapping); a follow-up ticket (assets/05, priority later).
- Q2380: house/02's kit pieces are approved and merge.
- Q2381: both window sets stay: the old widths (A) and the rounded ones (B); house/03 builds the house with each to compare; the goal is the old house rebuilt with this kit.
- Q2382: core/23 merges on the strips; the designer tries it in play and its numbers (turn_weight) are tuned from that.
- Q2383: a thrown Sock keeps the hand's pose in the air (it lands as it flies, often on its end), not turned flat as the drop.
- Q2384: the ported Sock models, balls, pattern shader and prints are approved; the shape follows the Collection as the old game; look updates come later (assets/05).
- Q2385: the 17 Cabinets and the 111 icons are approved; Cabinets keep 3 drawers now, growing by Stage comes with Stages (M4).
- Q2386: the two rebuilt houses (A, old-width windows; B, rounded) stand beside the zoo, walked into from the zoo floor, as stations.
- Q2387: core/15's screen (prompts, hints, keycaps, readouts at the old places) is approved.
- Q2388: openable prompts use the old wording: drawers and cupboards show the thing's own name ("[E] Simple Cabinet Drawer"); the Door keeps "Open the Door".
- Q2389: in the material library, each group keeps the variant the most old pieces used (a tie: nearest the median roughness); any group can be overridden later by name.
- Q2390: fabrics are ported without the old glTF sheen; a look-change ticket gives them a soft sheen later (assets/06).
- Q2391: house/03's two rebuilt houses (A, B) are approved and merge; the missing shell pieces and furniture come in later tickets.
- Q2392: the zoo's node budget test (mess:m04) counts only the Mess's nodes; a house's static pieces may be merged into fewer nodes later if play needs it.
- Q2393: house/03's two 1 cm kit fixes and its two new pieces (an open exterior corner, an offset door with the elevator hatch) stay in the kit.
- Q2394: the 67 furniture pieces on the shared material library are approved and merge.
- Q2395: the furniture devices are ported now, in their own ticket (assets/07): opening sounds by container kind, the mirror's reflection, the piano's playable keys, the dust sheet and the Old Tree's shader.
- Q2396: the zoo's Sock area widens to cover the furniture station and the old houses, so Socks lie on furniture.
- Q2397: players collide with the old coarse boxes per piece on their own layer; Socks keep the detailed shapes.
- Q2398: core/16's five looks merge as built; the rest of the motion polish (P03, P08, P10, P11, P14, P15) is its own ticket, core/27.
- Q2399: human documentation starts in docs/human/: how to update models, the model pipeline, the sound pipeline and the house kit (for the designer, plain words).
- Q2400: the model sources come into the project: the .blend files into assets_src/blender/ and the Blender scripts into assets_src/generate/ where possible (assets/08; changes Q2152's tools/blender/ place).
- Q2401: a dropped Sock keeps no bend from the hand; only a Throw carries it.
- Q2402: core/27 merges after its complexity report (about 300 lines of game code); the designer reviews the code once M0.5 is complete.
- Q2403: the Door and cupboard swing ease stays as built; the designer tunes the AnimationPlayer keys' curve in the editor.
- Q2404: the code review's findings are fixed (designer: "Yes. Fix those."): correctness (core/28), per-frame cost outside the Mess (core/29), tidy-up with felt numbers moved into tuning Resources and the zoo's labels, buttons and swatches as small scenes (core/30); the whole-array Mess patches become sparse in M0.6 (core/32).
- Q2405: the Mess still settles wrongly, some Socks glitch out and it is laggier than before: one Fable agent reproduces it and builds a Mess performance benchmark (core/31).
- Q2406: the benchmark takes the old game's way (tools/stress.sh, game/debug/physics_stress.gd, docs/perf/tools.md) as its model, kept well structured (designer: "Inspire from the old game, how it's done. But try to keep the code well structured.").
- Q2407: the Mess glitch is at the moment Socks settle: "they teleport and there is a visible glitch" (designer, 2026-11-21); core/31 starts from it (it reopens core/21's rest blip, which a still had found pixel-identical).
- Q2408: the zoo's station names and the houses' names stand near the ground where the player reads them easily, not floating high over the station (designer: "they should be near on the ground, so I can read them easily"; core/33).
- Q2409: what only the zoo needs (switches, sound buttons, line-ups, sample rooms, zoo-only data) lives under game/zoo/, grouped per station; the game never refers to game/zoo/; the build-time generators move to tools/ (designer: "the switches, texts, ... that are used in the zoo should only be in the zoo"; core/34). Real entities that only the zoo uses today (the Cabinet, the cupboard, the Player, the kit pieces) stay in game/: they are the game's.
- Q2410: core/34 adds no guard check for references into game/zoo/ (designer: "We don't need the guard check for this.").
- Q2411: core/33's station names near the ground are approved from the stills and merge (designer: "OK, stations looking good.").
- Q2412: Socks resting up to 20 mm into the floor (Jolt's penetration slop) are left as they are (designer: "Leave it").
- Q2413: the few Socks that still spin over 25 rad/s on an edge-first hit (7 of 500 poured) are accepted for now; turn_weight stays 3 and the benchmark keeps counting them.
- Q2414: core/31 merges as built (the settle teleport fixed by turning physics interpolation off on the Mess's MultiMeshes, the review's Mess speed-ups, the benchmark), after its complexity report.
- Q2415: core/21 (the rest blip) is closed: core/31 found and fixed the cause.
- Q2416: the benchmarks run from the game itself in debug builds, by a command line (designer: "could we have the benchmarks in the game debug builds? So it's easy to run it anywhere - have a CLI for the game?"; core/35).
- Q2417: the held Sock's cloth should swing more: it snaps when the view turns, with no inertia (designer: "Could you figure out settings for the socks in hand that make it look more swinging?"); candidates are shown side by side before any value changes (core/36).
- Q2418: an experiment: lying Mess Socks get two bends (heel and ankle) decided as they come to rest (draped over what is under them), drawn by the sock shader and followed by their boxes; flights stay one body (core/37, option A of the lead's estimate).
- Q2419: core/37 is not merged into main: the designer tests it from a review build of the zoo; no strip needed (designer: "give me a review build with zoo scene to test this on (not merge into a main). No need for a strip.").
- Q2420: the held cloth takes drag 0.25 (stiffness 5, gravity 3 kept): 13 degrees past rest, one swing, settled in 0.13 s after a quick turn; thrown Socks ring a little more too (core/36).
- Q2421: a visual tweak (a look or feel number: cloth, ease, colour, timing) gets no test; its stills or strip and the designer's eye judge it (designer: "I think it doesn't make sense to do tests just for visual tweaks like this."). core/36's swing test is removed.
- Q2422: on top of the core/37 experiment, try the full bend simulation: flying Socks as jointed bodies (three segments, two hinges), as optimised as possible; only on the experiment branch, never main (designer: "For 37 could we try the full bend sim? Ideally super optimized. But only for 37."; core/38).
- Q2423: jointed flying Socks (core/38) are not worth it: not merged (designer: "No it's not worth it"); taken to main from it: the bench's `--tune=` and shared flight materials (designer: "1, 2, yes"); Jolt penetration slop left as is.
- Q2424: core/38 also gets a "really flappy" review build on its branch, with no tests run on it (designer: "just make the socks really flappy", "No need for running tests, this is just experiment").
- Q2425: M0.5 close-out: the lead triages the core `[later]` follow-ups and does the paperwork; no walkthrough page; the designer does the full zoo run alone; the code map is updated and a system-by-system baseline is made for the designer's code review (designer, 2026-11-21).
- Q2426: core/37 (bent lying Socks) is parked: not merged, its branch and review build kept (designer: "core/37 park").
- Q2427: a pour stirs the heap as it does now, jitter included; no change (designer: "it's ok as is").
- Q2428: a Sock left inside a Door or drawer leaf when it shuts is pushed out of the leaf, not sent to the return spot with a pop (designer: "pushed out").
- Q2429: tests that only check a look or feel number go, the old cloth tests hand_details d02 and d03 first (Q2421; designer: "yes").
- Q2430: the old features with no milestone (stacking, hand-off, hint arrows and pings, the F1 debug menu, the studio intro) are tracked as tickets, not planned yet (designer: "track them").
- Q2431: a Throw wakes the lying Socks it is about to hit just before contact, as the old game, so the thrown Sock shoves them (core/08 T11 follow-up; core/46).
- Q2432: the room ambience `amb_room` is silent, as the old game (the placeholder clip goes; core/47).
- Q2433: a Throw that cannot reach the crosshair (a light charge to the far floor, a charge-0 lob) lands short, as the old game; no change.
- Q2434: the old sound events and modes left out of core/17 all stay for M1.1 (which ports every old sound); none dropped.
- Q2435: core/46's cost is accepted (a Throw into a heap wakes about twice as many Socks; burst_16 p95 1.0 to 1.8 ms, under the 8 ms budget) and it merges as is; the push is small (friction stops hit Socks within mm) and the designer judges it by playing (designer: "Merge as is, I'll play it").

## M0.6 planning (2026-11-22)
- Q2436: the M0.6 plan goes as proposed: batch 0 two spikes (flight bodies on a synchronizer, a ragdoll pose to a Guest), 1 host/join/roster, 2 the avatar model and Teammates seen, 3 the Mess and Throw in co-op, 4 knockdown, 5 close-out (`milestones.md`).
- Q2437: M0.6's knockdown is the knockdown and the drag (with the struggle); the wash waits for the washing machine (M5). Refines Q2225's "full knockdown".
- Q2438: the avatar is ported as is, 4 bones (Root, Spine0-2): the ragdoll folds at the spine only, as the old game. A limbed rig would be its own look ticket.
- Q2439: a Teammate's Throw leaves the hand at once, with only the network's 0.1 s delay; the old pause at release is not recreated (it came from the hand-to-eyes blend that Q2356 and Q2367 removed). Changes Q2226.
- Q2440: every player is named "Player" until the lobby (M4); no name flag.
- Q2441: a player's colour is the next free one in the old order, automatic (the Host first).
- Q2442: the join and leave toasts as the old game, 2 s in the player's colour, under the crosshair; the joiner sees "Joined <Host>'s zoo".
- Q2443: 4 players at most; the fifth is refused with "The game is full (4 players)".
- Q2444: the old refusal texts stay ("The game is full", "You are already in this game", "Another version of the game", "The Host ended the session"), with "Host" capitalised.
- Q2445: the join gate also checks the scene layout; a mismatch is refused with the "Another version of the game" text.
- Q2446: a leaver's held things drop where they last stood, as the old game (Q248).
- Q2447: a join with nobody there gives up after 10 s with "Could not reach <ip>" and stays single-player.
- Q2448: a new joiner appears 0.6 m beside the Host, facing the same way; a returning player id where they left.
- Q2449: no proving token until the lobby (M4); a copied profile joining as its owner is accepted for M0.6 playtests (confirms Q2224).
- Q2450: a Teammate's body eases at 12 per second (crouch 6), as the old game; judged on a strip.
- Q2451: a Teammate who moves over 1 m in one update snaps; smaller moves ease.
- Q2452: a Teammate's steps and landing use the local player's clips in 3D at their body, full level up close, fading from 3 m to 20 m, a step every 1.4 m (new in M0.6, Q2376).
- Q2453: a Teammate's pick, pair, drop, shelve and throw sounds play as loud as the local player's, in 3D at 1.2 m over their feet, as the old game.
- Q2454: others do not see a Teammate's held turn (R) or zoom (G), as the old game.
- Q2455: the avatar's pupils follow the nearest player, as the old game.
- Q2456: the lobby and the multiplayer system should be ready for Steam (designer, 2026-11-22).
- Q2457: M0.6 builds on ENet behind a swappable seam: the transport, the player identity and the join gate assume no IP address, so Steam's peer, lobby and ids come in with the lobby (M4) without rework. Steam is not run in M0.6.
- Q2458: the player id is one field: the Steam ID on Steam, proven by Steam's auth ticket (which replaces the proving token planned for M4); off Steam (LAN, IP) the long random id of Q2224. Saves are keyed by that one field.
- Q2459: the add-ons YARD (1.3.2, resource registries with a table view in the editor; switched on) and GodotSteam (4.24 GDExtension, Windows and Linux x86_64 only; its updater plugin switched off) are added now so the build continues with them in the editor (designer, 2026-11-22). Steam is not initialised until the lobby (Q2457).
- Q2460: the behaviour lists for M0.6 batches 1 and 2 (`m06-lists/01-host-join-roster.md`, `02-teammates-seen.md`) are approved as drafted, with Q2437-Q2458 applied (designer, 2026-11-22: "Yes, let's go").
- Q2461: a Teammate's body moves as the old game, every motion with the old numbers (waddle, bob, sway, the look bend, jump and land squash, feet rocking, crouch to 1 m), derived from their motion on each machine; judged on a strip of two players (coop/05).
- Q2462: a Teammate's name tag shows "Player" in their colour at the cuff top, as the old game; the lift over a tall hat comes with the Wardrobe.
- Q2463: a far or hidden Teammate is not marked, as the old game, until Mate Radar and the X-ray (M4).
- Q2464: a Teammate's held things as the old game: at their HoldPoint at true size, several clustered in small steps, a held Pair as the ball.
- Q2465: the avatar family (coop/04) is approved: the port's import matches the old game in all six views (designer, 2026-11-22).
- Q2466: the player's own body in first person is ported as the old game in M0.6, as its own ticket after coop/05 (coop/06): the belly of the new avatar below the cut, set back, outside only, edge closed, no eyes, name, hat or clothes, no shadow, the feet; it bends and crouches with the player; the capsule goes (old Q310, Q329; a gap the M0.6 lists left out, raised 2026-11-22).
- Q2467: "camera clipping of the body" means only that: looking down shows the belly under you, never the inside of your own body (the old cut and closed edge, maintenance/37).
- Q2468: the avatar gets a zoo station in coop/05: the real Avatar standing, and a stand-in Teammate walking a loop, crouching, looking up and down and holding a Sock, driven only through the pose properties a real Teammate sends, so it shows when playing alone (designer, 2026-11-22).
- Q2469: the Teammates strip of coop/05 is approved (how a Teammate moves, is coloured, tagged and holds); the sounds, the Throw from the hand and the Pair sparkle are finished on the branch before the merge (designer, 2026-11-22).
- Q2470: a Teammate's shelve sound plays at the drawer, as the old game (refines Q2453, which grouped it with the cues over their feet).
- Q2471: coop/06's own body in first person is approved from its two stills and merges; judged further in the zoo (designer, 2026-11-22).
- Q2472: the Mess in co-op is to be well optimised, inspired by the old game, differences flagged, then improved (designer, 2026-11-22). The plan: `coop-mess-sync.md` (changed records only; one rest batch a tick; woken, falling, poured and swept Socks simulated on every machine and snapped at rest, Q2222; Throws alone on a stamped stream; Doors and drawers swept on every machine; a compact compressed join). Sections A to C of `m06-lists/03-mess-throw-coop.md` are approved with it; a Sock mid-flight at a join flies on from where it is (list question 8, as the old game).
- Q2473: a Guest's drop falls at once on a looks-only body that blends to the Host's result, as the Throw (Q2221) and the old game (list 03 question 1; designer, 2026-11-22).
- Q2474: a Guest's second pick before the first is answered waits until the first is answered; no second ghost (list 03 question 2; designer, 2026-11-22).
- Q2475: a Guest's wheel turns at once and is turned back silently on a refusal, as the old game (list 03 question 3; designer, 2026-11-22).
- Q2476: a refused Guest Throw or drop removes the ghost and puts the item back in the Hands at once, as the old game; no fly-back (list 03 question 4; designer, 2026-11-22).
- Q2477: a Guest's pick, drop or Throw with no answer after 2 s goes back to the Hands with the refusal look and sound (list 03 question 5; designer, 2026-11-22).
- Q2478: a Guest hears its own pick at the click, with the ghost (list 03 question 7; changes the old game, which played it at the answer; designer, 2026-11-22).
- Q2479: a Guest's pairing moment starts only on the Host's answer, never at the click; no Pair splits back (list 03 question 9; designer, 2026-11-22).
- Q2480: sections D to M of `m06-lists/03-mess-throw-coop.md`, with Q2473-Q2479 folded in, are approved; coop/09 is built from them (designer, 2026-11-22).
- Q2481: a Guest's own Throw ghost leaves its first-person hand and eases onto the Host's flight (from the avatar's hand, about 0.3 m away) over 0.2 s, as coop/09 built it (designer, 2026-11-22).
- Q2482: a Guest's pick, drop or Throw timed out after 2 s (Q2477) plays "refuse" only, with no text (designer, 2026-11-22).
- Q2483: in M0.6 only full-charge Throws of Socks and Pairs knock down; the lantern, Radio, Beeper, Guide card and Cat get their knock at their own milestone (list 04 question 2; designer, 2026-11-22).
- Q2484: the old exemptions stay: the thrower, someone already down, someone in the drum, an Elevator rider are never knocked (list 04 question 3; designer, 2026-11-22).
- Q2485: a knocked-down player drops everything in the Hands (changes the old game, which kept them) (list 04 question 4; designer, 2026-11-22).
- Q2486: the knocked player's items drop as a leaver's do (D14 of list 03): where they stood, a Pair as a ball, lying in the Mess for anyone (designer, 2026-11-22).
- Q2487: no immunity after getting up, as the old game (list 04 question 5; designer, 2026-11-22).
- Q2488: getting up as the old game: a 0.6 s smoothstep blend, the same facing, no hop or bounce (list 04 question 6; designer, 2026-11-22).
- Q2489: the struggle shows only the hint "Mash: Struggle [Space]" for now, as the old game; a better struggle display is tracked to improve later (list 04 question 7; designer, 2026-11-22: "1, but track to improve").
- Q2490: the knocked player's view gets a vignette while down (changes the old game, which added nothing); its look stops at its first still (list 04 question 8; designer, 2026-11-22).
- Q2491: the knockdown sound is the first placeholder candidate until M1.1 (list 04 question 10; designer, 2026-11-22).
- Q2492: only the knocked (and the dragged) player's pad rumbles; the thrower gets none (list 04 question 11; designer, 2026-11-22).
- Q2493: a lying body under the crosshair wins the left click over a Sock or a station, as the old game (list 04 question 12; designer, 2026-11-22).
- Q2494: the knocked player sees "<Name> knocked you down", as the old game (list 04 question 13; designer, 2026-11-22).
- Q2495: the knocked player sees their own body in the ragdoll pose under the head camera, as the old game (list 04 question 14; designer, 2026-11-22).
- Q2496: list 04 (`m06-lists/04-knockdown.md`) is approved with Q2437, Q2438 and Q2483-Q2495 folded in; batch 4 is built from it (designer, 2026-11-22).
- Q2497: coop/10's knockdown vignette is approved as its first still shows (black edges, `vignette_dark` 0.7 from `vignette_start` 0.45); judged further in the zoo (designer, 2026-11-22).
- Q2498: a knocked body under the crosshair gets the outline (list 04 H91) in coop/10, before the merge (designer, 2026-11-22).
- Q2499: Socks pressed under a heap may rest up to 20 mm into each other (Jolt's default penetration slop); accepted and only counted in the test; the spout's own overlap is fixed (core/49; designer, 2026-11-22).
- Q2500: assets/05's wool is one tiling knit normal and roughness texture over every Sock shape in the Sock shader, under the Design's colours, pattern and print, faded with distance so it does not shimmer (designer, 2026-11-23).
- Q2501: assets/06's fabric sheen is StandardMaterial3D rim and rim tint on every `fab_*` material of the shared library; no custom shader (designer, 2026-11-23).
- Q2502: assets/07 builds all five furniture devices as the old game (open and shut sounds per container kind, the wall mirror, the piano's 88 keys, the dust sheet, the Old Tree's shader), its behaviour list written in full from the old code (designer, 2026-11-23).
- Q2503: house/04: the house only, no exterior (no fences, trees, street or light wells). Keep house B (windows on the 0.5 m grid) and remove house A. The house becomes a main scene launched from the game, built from the kit pieces (designer, 2026-11-23: "Look what's currently built in the game. I want the house to be a main scene, launched from the game, built from the kit pieces we have").
- Q2504: M1 and M2 run on their own: agents build each ticket to the end with no stop at the first still, matching the old game and the designer's answers, and leave a before and after strip in `builds/review-<family>/`; the designer reviews the batch before it merges, and a change is a follow-up. Relaxes, for M1 and M2, the first-still stop and the family-batch approval before building (Q2216) (designer, 2026-11-23).
- Q2505: the wall mirrors draw a real planar reflection as the old game (a second camera behind the glass, 256 px, every 3rd frame, within 4.5 m, off on Low; teammates and the player's own full body, no Mess Socks) (assets/07; designer, 2026-11-23).
- Q2506: the Old Tree stays as it is (the model with its glowing bulbs); its motion, flicker and voice are not ported now because it will be reworked; tracked (assets/07; designer, 2026-11-23).
- Q2507: the dust sheet is built now as the old one: draped over a locked Cabinet, pulled off (slides forward, spills and fades in 0.5 s) on the unlock, triggered by a switch at the furniture station until Cabinet locks exist; the sheeted sofa stays a model (assets/07; designer, 2026-11-23).
- Q2508: the piano as the old game: 88 keys, each its sampled note, dip 0.04 s, rise 0.16 s, 12 voices, the lid with its sound; anyone plays it and every player hears it (assets/07; designer, 2026-11-23).
- Q2509: the house is the game level and the project's main scene (F5 starts it) until there are menus (house/04; designer, 2026-11-23).
- Q2510: the old furniture is placed as the old house had it, moved with the rooms to the 0.5 m grid (house/04; designer, 2026-11-23).
- Q2511: nothing outside the house: no lawn, plinth, step or ramp; the player starts inside, at the old spawn (house/04; designer, 2026-11-23).
- Q2512: the house is lit by the zoo's noon light plus each old room lamp's light as the old house had it (house/04; designer, 2026-11-23).
- Q2513: a Cabinet under its dust sheet cannot be aimed at, as the old game (no outline, no prompt, no click), built in assets/07 before its merge (designer, 2026-11-23).
- Q2514: until the exterior ticket the house's front and garage doors stay shut (cannot be opened), so no one walks out into nothing (house/04; designer, 2026-11-23).
- Q2515: the old house's lamp rules (all but the basement's off by day; each floor lit only by its own lights) are ported in a follow-up ticket; house/04 merges with every lamp lit (designer, 2026-11-23).
- Q2516: the Mess comes into the house in its own ticket, so the main scene (F5) plays the core loop with Socks at the old game's places (designer, 2026-11-23).
- Q2517: the full game setup (player, co-op and Mess nodes) is one runtime scene that every level instances as a child (composition, not an inherited scene); a level holds only its own geometry, look (environment, sun) and a Spawn marker, so a new level is authored by adding its content and one instance (designer, 2026-11-23).
- Q2518: the Sock generator's area is one `SockArea` box dropped over a room or a floor; it finds every landing place under it by itself (open floor, furniture tops, insides, under-gaps), tints them by kind in the viewport, and furniture inside it joins automatically (core/52; designer, 2026-11-23).
- Q2519: furniture pieces bring their own landing places, their insides (hiding spots) and under-gaps included, so moving a piece moves its Socks (core/52; designer, 2026-11-23).
- Q2520: an area has one Pair count, split by each place's size times a weight per kind (open floor, top, inside, under) set on the area; a furniture piece may override its own weight; no exact pinned counts for now (core/52; designer, 2026-11-23).
- Q2521: rarity no longer decides hiding; every Design hides alike, and the hidden share (inside and under furniture) is one number on the area, 0.3 by default (core/52; designer, 2026-11-23).
- Q2522: the viewport preview shows the landing points as dots, tinted by kind (core/52; designer, 2026-11-23).
- Q2523: generated Socks appear already lying where the preview showed, all at once, with no fall and no sound, as the old game (core/52; designer, 2026-11-23).
- Q2524: the level's seed by default (the same Mess each start, as the preview shows), with a switch for a new seed each New Game saved with the game (core/52; designer, 2026-11-23).
- Q2525: a Pair's mates lie the old 0.4 m to 6 m apart, measured in a straight line; improving it (walked distance or better) is its own ticket (core/52; designer, 2026-11-23).
- Q2526: Heaps are an area option: an area flagged "heap" piles its floor Socks into mounds by the old roll-down rule; otherwise Socks lie flat, spaced, never overlapping (core/52; designer, 2026-11-23).
- Q2527: exclusions are the old rules as numbers on the area (0.28 m from walls, off furniture footprints, not where a crouching player cannot reach, not in stair holes, clear in front of Cabinets) plus `SockExclusion` boxes placed by hand (core/52; designer, 2026-11-23).
- Q2528: core/52 brings these old details now: the under-furniture edge strips, the thinning away from the washer (from a marker until the machine exists), the stair trail, and about a third of the room doors shut at a New Game (once the house has room doors); the rest wait for their feature, none dropped (core/52; designer, 2026-11-23).
- Q2529: core/52 merges as its stills show (designer, 2026-11-23).
- Q2530: the stair trail's Socks lie flat on each tread: house/05 gives the stair pieces step-shaped landing places; the player still walks the ramp collision (designer, 2026-11-23).
- Q2531: generated Socks are never frozen in the air: a laid Sock with nothing under it wakes and falls (or lands on the heap); a reseed lays the new Mess only onto the world without the old one (designer, 2026-11-23).
- Q2532: the room Doors come now, as M3's next ticket after house/05 (swing, push Socks, sounds, the co-op sweep, about a third shut at a New Game, Q2528) (designer, 2026-11-23).
- Q2533: triage: player stacking (core/41), hand-off (core/42) and pings and hint arrows (core/43) go to M3, soon; the F1 debug menu (core/44), the studio intro (core/45) and the walked mate distance (core/53) go to M5, by need (designer, 2026-11-23).
- Q2534: M0.6 batch 5, the close-out, starts now (designer, 2026-11-23).
- Q2535: after M3, M4 (the run's frame), M1.1 (sound) and M5 (features) run in parallel wherever they can; the architecture and the authoring of voicelines (the washer's, the Old Tree's, cutscenes) are designed first, before their features (designer, 2026-11-23).
- Q2536: assets/09 approved as its stills show: the body-coloured sill closes the car's window slit, the doors open separately as "Car Door", the pens lie apart (designer, 2026-11-23).
- Q2537: the attic balustrade's cut-back rail stays as it is, ending with no post (house/04; designer, 2026-11-23).
- Q2538: the bathroom wainscot is kept (tiles to 1.2 m) with its trim made a real raised strip, as the skirting (house/07; designer, 2026-11-23).
- Q2539: the rim sheen is 0.25 on the cream fabrics (linen, sheet, sofa), 0.35 on the others (assets/06; designer, 2026-11-23).
- Q2540: M4 starts with the main menu and saves, the save format chosen first (designer, 2026-11-23).
- Q2541: the house's Mess uses the old stage counts per floor (basement 50, ground 160, first 150, attic 130 Pairs; 990 Socks), not the whole catalogue (house/05; designer, 2026-11-23).
- Q2542: the house's Socks are laid a slice per frame behind a short loading screen ("The washer bursts open...", as the old), so nothing freezes; they still appear all at once (Q2523) (designer, 2026-11-23).
- Q2543: all eight Cabinets stay open until Stages (M4) lock them (house/05; designer, 2026-11-23).
- Q2544: house/05 merges as its strip shows; the attic trunk's inside is fixed in its own ticket (designer, 2026-11-23).
- Q2545: the Host decides every speaker's lines in co-op (the washer, the Old Tree, cutscenes); everyone hears the same line (V1, core/56; designer, 2026-11-23).
- Q2546: the bake writes an Animation per line (mouth, brows, moods), played by the speaker's Looks AnimationPlayer with the audio (V2; designer, 2026-11-23).
- Q2547: a line may have several takes, one picked at random each time it plays (V3; designer, 2026-11-23).
- Q2548: two speakers at once: fixed priority cutscene > washer > Old Tree; the higher cuts the lower; lower lines are dropped, except story beats that wait (V4; designer, 2026-11-23).
- Q2549: voices get their own Voice bus with a volume slider; the music ducks only in cutscenes, as the old (V5; designer, 2026-11-23).
- Q2550: subtitles in the old look (cream, black outline, bottom centre, on the Theme), one row per speaker, with the speaker's icon and no name (V6; designer, 2026-11-23).
- Q2551: a line's text comes from transcribing its recording and is corrected in the string table (V7; designer, 2026-11-23).
- Q2552: a subtitle shows while the line is within earshot, through a shut Door too (V8; designer, 2026-11-23).
- Q2553: the save file is the kit's save template, one JSON file per World with the World's record and every Part's state (M1, core/57; designer, 2026-11-23).
- Q2554: Worlds as the old slots (one Solo, five co-op) without the Group lock: anyone may join a co-op World (M2; designer, 2026-11-23).
- Q2555: autosave within 2 s of any change and at once on every way out, on a worker thread, as the old (M3; designer, 2026-11-23).
- Q2556: a save that cannot be written keeps the old file, logs why, and the HUD says "Could not save the game" (placeholder) once until a save works (M4; designer, 2026-11-23).
- Q2557: old saves always load: each Part's saved state carries a version, a migration chain steps old saves to the current shape, new fields take defaults, and sample saves of each version are loaded by the suite; built now with menus and saves, enforced from the first outside play-test (before it a change may say "breaks saves") (M5; designer, 2026-11-23).
- Q2558: stable ids are node paths now, checked by a committed id list in a test; an editor tool fills ids before the first outside play-test (M6; designer, 2026-11-23).
- Q2559: a load resets as the old: Doors, drawers and lids shut (what rode out slides back), the TV off, the Radio keeps its channel, lost things back by the washer, absent players' Socks dropped, nobody knocked down (M7; designer, 2026-11-23).
- Q2560: things in the air when the game saves are laid where they would land, as the old (M8; designer, 2026-11-23).
- Q2561: until the Lobby piece, Solo continues or starts the Solo World and Host the last co-op World, straight into the house; the World list, Continue/New Game and Delete come with the Lobby (M9; designer, 2026-11-23).
- Q2562: the first menus-and-saves build holds the title, Options, Licence, loading screen, cursor, menu sounds, ESC menu and saves; the studio intro and the encyclopedia key come later (M10; designer, 2026-11-23).
- Q2563: house/07 merges as its strips show (designer, 2026-11-23).
- Q2564: saves sync by Steam Auto-Cloud (set on the Steamworks site, no Steam code), written through a small `SaveStore` layer with a local-file backend so another store or the Steam API can replace it (C1, docs/research/steam-cloud-saves.md; designer, 2026-11-23).
- Q2565: Worlds and the profile sync between PCs; settings (graphics, resolution and the like) stay on each PC (C2; designer, 2026-11-23).
- Q2566: each Steam account on a PC has its own Worlds, under `user://worlds/<player id>/` (C3; designer, 2026-11-23).
- Q2567: the save folder (`use_custom_user_dir`) is "It Socks", set now with menus and saves (C4; designer, 2026-11-23).
- Q2568: the 2 ground-floor doorways the old house left open stay without Doors (house/08; designer, 2026-11-23).
- Q2569: a swinging Door moves Socks by the physics sweep only, no click-time push (house/08; designer, 2026-11-23).
- Q2570: the Doors shut at a New Game are already shut when the house appears, silent (house/08; designer, 2026-11-23).
- Q2571: the room Door gets its real leaf in house/08, ported from the old house's own leaf geometry (`reference/it-socks/tools/blender/make_house.py`, Door_<doorway>), as a Looks scene; the front and garage doors' plain leaves (house/04) match it (designer, 2026-11-23).
- Q2572: house/06 merges as built; the old basement's warm daytime fill (0.35, #ffd4a0) is ported in its own ticket (house/10) (designer, 2026-11-23).
- Q2573: a Guest's own Throw is predicted on the Guest with full physics (the same Jolt body and numbers as the Host's, so it flies the real arc), the Host stays authoritative, and the Guest's body is corrected smoothly to the Host's stream when they part (designer's M0.6 run, 2026-11-23).
