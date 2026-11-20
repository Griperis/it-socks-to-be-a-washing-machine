Next free Q number: Q2239 (update this line whenever a round of questions is asked)

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
