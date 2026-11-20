# Risky bets, vertical slices, and a migration journal

For the designer. Plain words. Written 2026-11-19 from the documents only. Nothing was run, built or changed.

How to read "what we know today" in the tables:

- **run** = a test or measurement actually ran (the state-and-coop throwaway slice: 19 of 19 checks).
- **docs** = read in Godot's docs or in our research files, not tried.
- **judged** = my reasoning or arithmetic on numbers from the documents.
- **unknown** = nobody looked.

Milestone names M0-M6 are the ones in `new-project-start.md` (M0 assets, M1 house, M2 first co-op slice, M3 core loop, M4 Stages, M5 menus and saves, M6 by need). The feature catalogue part 5 numbers them differently (M1 assets, M2 house, ...). I use the first set. See part F.

---

## A. Risk register

Ranked by damage if wrong times how late we would find out. R1 is the worst. Cell text is short on purpose.

| # | The bet | Why it matters | What we know today | Cheapest test | Stop rule: if X, then Y instead | Answer by |
|---|---|---|---|---|---|---|
| R1 | A house built from hundreds of snapped kit pieces runs as well as today's one `house.glb`, on the low-end laptop too | It is the whole of M1 (Q2154-Q2157). Found late = the house is built twice. | **docs**: the low-end report says that laptop is limited by the graphics chip (per pixel), not by draw calls (353 draws, 115 k triangles), and by physics (4.0-6.7 ms a tick vs 0.8 ms on your PC). **judged**: a kit adds nodes, bodies and draw calls; today the shell is 90 drawn nodes plus 1,003 collision nodes. **unknown**: kit numbers. | Slice 2: one room from the kit, then the bench on your PC and on the laptop, beside today's same room. Count draws, bodies, load time, physics tick. | If the kit room is worse than today's by more than the margin you set (question E6), then we keep the kit for authoring but merge each room into one mesh and one collision body when the game loads (a build step), not drop the kit. If that still misses, then the house shell stays a Blender glb and the kit is for props only. | before M1 |
| R2 | Hand-made scene work (colliders, hinges, spots, markers) survives a re-export from Blender | Q2151/Q2152 move all of that out of Blender into scenes. If a re-export wipes it, 241 models lose their work. | **docs**: a wrapper scene (glb as child, our nodes beside it) should survive; renamed nodes break only the paths that point at them. The page on inherited scenes and "Editable Children" was not found. **unknown**: what the editor does on a rename. | Slice 1, last step: re-export the cupboard with a changed handle and one node deliberately renamed; open the wrapper. | If a rename silently breaks a wrapper, then node names in the glb are frozen by a test that checks every path in every wrapper (fails loudly). If even that cannot be done, then moving parts and markers go back into Blender as named empties and the scene only adds collision. | before M0 mass port (T005) |
| R3 | State lives on the scene part (Q2147) and stays stable when you rename or move a thing | The save, the network and late join all find a part by its id. The first sketch makes the id from the node path, so renaming a thing breaks saves. | **run**: Host, Guest and late Guest agree in a toy level (19 of 19). **docs/judged**: ids from paths are fine "until saves exist". **unknown**: a real scene from ported props, Jolt bodies, the crosshair, a whole-house snapshot size, and renames. | Slice 3: the real kitchen, two game windows. Rename a placed chair in the editor and run; a test lists every id and fails on a change. | If a rename or move changes an id and our test cannot catch it, then ids come from an editor tool that stamps a fixed id on each placed thing when you save (fork d, option 3), from the first slice. | before M2 design is agreed |
| R4 | Sock spots baked into the scene by a button (Q2176): 53,260 spots across 66 pieces | Today they are 1.16 MB in the manifest. As scene text they might make files huge, slow to load and unmergeable. | **docs**: the manifest has them; `tops.py` computes them. **unknown**: size and load time as scene data, whether a re-bake gives the same result twice (so git sees no noise), how the editor draws thousands of dots. | Slice 1: bake the cupboard, then a sofa and the car (car has the most collision shapes, 59). Measure file size, load time, and diff after a second bake. | If a baked piece makes the scene file bigger or slower than you accept, or a re-bake changes the file, then spots are saved in a separate binary file next to the scene (one per piece), still made by the same button. If spots are too many to show as dots, then the editor shows a count and a sample. | before M0 mass port |
| R5 | Rounding rooms to a half metre (Q2175) works for furniture, stairs, Elevator and doors | Q2175 says nudge up to 25 cm. My arithmetic below says some parts do not fit. Found at M1 = the layout is redone. | **judged** (arithmetic): kitchen 3.83 x 8.34 becomes 4.0 x 8.5 (both within 25 cm, fine). The 0.7 m Elevator shaft rounds to 0.5 (0.2 off) but its car is 0.58 m wide, so it no longer fits; to 1.0 is 0.3 off, over the limit. Stair half landing 1.1 m rounds to 1.0 or 1.5. First-floor depths 3.16 + 5.06 round to 3.0 + 5.0 = 8.0, but the house depth rounds to 8.5, so half a metre has to go somewhere. Doors 0.9 and 1.11 and 0.826 all become 1.0 (leaves are 0.866 wide). Stair width 2.33 to 2.5, length 3.19 to 3.0 shortens each tread. | A one-page rounding sheet for all 17 rooms, the stair, the shaft and 16 doorways (desk work), then slice 2 builds the kitchen's. | If more than a few rooms need a nudge over 25 cm, or the stair or shaft cannot round, then those parts (stair, Elevator, house depth) get their own fixed pieces off the grid, or the grid for that one part is 0.25 m. The furniture is moved before the house is bent. | before M1 (sheet now) |
| R6 | The Mess rewritten clean at 10,000 Socks is no slower than today (Q2168) | It is the largest code group today (7,727 lines) and the heart of the game. A slower Mess is a slower game. | **docs**: the bench and the two-tier design exist. **unknown**: the rewrite's speed. Not testable by a slice of hand authoring. | A spike, no designer hands: the two-tier shell with 10,000 dummy Socks on today's bench harness, before the M3 design is agreed. | If the spike is slower than today's bench by more than your margin after two tickets of effort, then we port today's core (the packed arrays and streams) nearly as is and rewrite only the edges. | before M3 design (spike in M2) |
| R7 | You can approve everything in time (design + walkthrough per piece, Q2159, Q2169) | You are the only approver. If the queue grows, agents idle or you rubber-stamp. | **judged** from the milestones, see the count under the table. | Count after slice 1-3: how long one approval took you, per kind. | If the queue holds more than you can review in a sitting (you pick the number, E4), then work is batched by family with one strip and one dialog per batch, and code pieces that follow an approved pattern get a lighter check. | before M0 mass port |
| R8 | One shared material library; 9 oaks become 1 (Q2177) | Looks change in 39 models. Also: how does a glb use a library material without editing each glb? | **docs**: oak has 9 variants in 39 glbs, brass 4 in 30, trim 18 in 22; 21 glbs are over the 8-material limit. **unknown**: the Godot step that swaps glb materials for library ones (an import script, or an override in each wrapper). | Slice 1: the cupboard's oak and one metal from a two-material library; before/after strip. Try the swap method on 3 more models. | If the swap needs hand work in every wrapper, then a one-time import script does it; if scripts cannot, then each family keeps a small material set and only the common ones (oak, brass, steel) are shared. If you dislike a merged look, that model keeps a named variant in the library. | before M0 mass port |
| R9 | The hand-authoring workflow in the editor works as hoped: drag a scene in, snap to half metre, edit children, Play | The whole plan is "you place things by hand". If the editor fights you, the plan fails quietly. | **docs**: dragging a scene into the 3D view, scene palette, snap settings, Editable Children and how a rename is stored were not confirmed (the pages were 404 or silent). Editor snap is a setting, not a rule, so pieces can land off the grid. | Slice 2 is exactly this; add a check that every kit piece sits on 0.5 m. | If dragging or snapping is too fiddly, then we add a tiny editor tool (a "place piece" dock with a snap) before M1, one ticket. If the editor cannot hold the house at all, then rooms become separate scenes. | before M1 |
| R10 | Text scenes under git on the mounted drive, and two agents editing one floor | The "unable to read tree" glitch is known; `.tscn` files conflict where binary-free text is edited by two. | **docs**: glitch repaired by the lead today. Q2181 puts the new repo on the same drive. **unknown**: scene merge behaviour for us. | Slice 2: two small edits to two rooms (separate files) and to one file; merge both. | If one conflict in one `.tscn` is not merged by git alone, then the rule is one agent per scene file and each room is its own scene (a floor scene only instances rooms). If the glitch hits scene commits more than today, then agents work in sandbox clones and push, as Q2181 says. | before M1 |
| R11 | You edit in the Windows editor while agents work on the same files | The editor rewrites `.import`, `.uid` and `project.godot`. Today these cost commits and one near-loss (sounds.json). | **docs**: the digest, part 3 and 4: `commit -a` swept in your edits; `.import` churn; 124 untracked imports today. **unknown**: with the new project, what the editor changes when you only open a scene. | Slice 1: open the cupboard in your editor while an agent re-imports headless; look at what git shows. | If an agent branch ever carries a change to `project.godot` or an editor-made file, then you work in your own clone and pull, and the tracked-or-ignored decision for `.import` and `.uid` is made once and tested. | before M0 mass port |
| R12 | Tests that load authored scenes stay fast and do not pin layout | A test that loads the real floor is slow and breaks when you move a chair. This was the biggest rework family before (about 17 tickets). | **docs**: digest part 4 item 1; Q2165; memory "tests assert behaviour, not layout". **unknown**: load time of a kit room headless. | Slice 3: time the kitchen load in the headless test. | If loading a room in a test takes noticeable seconds, then tests build a small room from the same kit pieces, never the real floor. If a layout move breaks a test, the test was wrong; it is rewritten to ask "can a Guest open the fridge". | before M2 |
| R13 | Typed Resources for tuning (Q2164) work with co-op | Does a Guest need the Host's numbers? If numbers differ between machines, play drifts. | **docs**: in the sketch both sides load the same `.tres` (swing time 0.35 s, today's number) and only the Host decides. **unknown**: a Guest on an old build; editing a `.tres` while the game runs. | Slice 4. | If a Guest's show depends on a number the Host changed, then the join message carries a hash of the data files and a mismatch refuses the join with a clear message; numbers are not sent. | before M2 |
| R14 | "Improve while porting" stays technical (Q2153) | It is where scope grows silently; 241 models are 241 chances. | **docs**: the rule exists, plus a before/after strip. Remodels are separate. | Every port ticket ships a strip. | If a strip differs from today's look, then the change is reverted and goes to you as a remodel question. | every ticket |
| R15 | The old game stands still while the new one is built (Q2148) | The vacuum devices (tools 24-30, models in P06) are still changing assets and numbers. | **docs**: catalogue part 2.1 lists them as in progress. | Write down the old commit the port starts from. | If the old game's assets change after M0 starts, then each change is a line in a "drift list" and re-ported, never silently mixed. If drift passes what you accept, then M0 waits for the freeze. | before M0 starts |
| R16 | Cost: agent tokens with no budget | A 241-model port can cost a lot unseen. | **docs**: `tools/agent_cost.py` reports tokens per ticket and model; no budget exists. | Slices 1-3 give a real cost per prop, room and code piece. | If the projection from the slices passes the budget you set (E3), then the scope is cut by family (wardrobe 120 pieces, Grotto, exterior later), not by quality. | after slice 3 |
| R17 | Hand-making 67 furniture wrappers (119 moving parts) is too much work | Pivots, axes, angles live only in the manifest, not in the glb. By hand that is a lot. | **docs**: assets-inventory section 2 and 5.9. **judged**: a script could write each wrapper's first draft from the manifest, you then edit. | Slice 1: time the cupboard by hand, then try the draft script on one more piece. | If a draft script cannot get a wrapper 80 percent right, then pieces are ported by hand in batches of one family, and the count drives the budget (R16). | before M0 mass port |
| R18 | Everything-before-scenes (Q2162) hides scene problems until late | Four milestones of assets before anyone tries a scene. | **docs**: Q2162. Slices exist to answer this. | The slices themselves. | If slice 1 or 2 changes the port rules, then rules (T001) are rewritten before the mass port; no ported model is redone for free. | slice review gate |
| R19 | A shared house kit plus per-piece material overrides do not blow up node count | Each kit piece with its own material is a unique resource. | **docs**: no node limit in the docs; judged 900 nodes for all furniture is small. **unknown**: kit count. | Slice 2 counts nodes. | If the editor slows, then rooms are split into scenes, one per room. | before M1 |
| R20 | The retrospective has no data | You asked for a retrospective and a skill set at the end. | **docs**: the old retro lessons were pulled from 598 tickets by hand. | The journal in part D, from the first ticket. | If the journal has gaps after M0, then the lead stops and fills it before the next ticket. | from day one |
| R21 | Whole-house snapshot for a late Guest and save | Not measured at all. | **docs**: the sketch's "not measured: bandwidth, latency, whole-house snapshot". | Slice 3: print the snapshot size of the kitchen, scale by placements (73). | If it is large, then snapshots send only parts that differ from the scene's start. | before M3 |
| R22 | Blender scripts that also wrote layout data stop writing it | `make_house.py` writes glb and layout; furniture builders write manifest entries. Handoff changes (Q2152). | **docs**: animation-rigging 4; also `make_flat.py` is imported by `make_house.py`. **unknown**: whether the scripts still run byte-for-byte. | Slice 1 runs the cupboard's builder only. | If a script cannot be reduced to meshes only, then that piece is re-exported once and the script is retired for it. | before M0 mass port |

### How many approvals is that? (judged, from the milestone lists)

| Milestone | Pieces needing you | Count |
|---|---|---|
| M0 assets | 241 models. One strip each, or one per batch of about 10 | 241, or about 25 |
| M0 plus M1 design tickets | Port rules, material library, oak pick, grid, bake button, stair, Elevator, walker | about 12 |
| M1 house | kit piece types (walls, floors, doors, stairs) and 5 floors | about 20 |
| M2 first slice | Command, Part, Openable, OpenFeel, Carriable, Parts, Session: design and walkthrough each | about 14 |
| M3 core loop | Mess, Hands, Throws, Pairs, Cabinets, Drawers, Prompt, movement, and more: two approvals each | about 20 to 30 |

So about 90 to 110 approvals before the core loop plays if assets are batched, or well over 300 if every model gets its own. Both are your time. This is the likeliest bottleneck; R7 is not about code.

---

## B. Vertical slices for hand-authoring

The idea: four small pilots in the new project, before the mass port, each one something you open, edit and play. They are the first things built in M0 and the first things done again properly after.

Common start: the new repository exists (Q2158) with an empty Godot project, the engine in `extras/`, and today's game cloned into `reference/it-socks/`. Each slice is a branch you can open in your Windows editor.

### Slice 1. One cupboard, every stage

**Piece:** `kitchen_cupboard` (0.6 x 0.64 x 1.09 m). It has one `Door` and one `Drawer_1`, so it covers both moving-part kinds (hinge and slide). Its materials come from the oak and a metal.

**What you do with your hands:**

1. Open `game/props/kitchen_cupboard/kitchen_cupboard.tscn` in the editor. In the scene tree you see `Model` (the glb), `Colliders`, `Door`, `Drawer_1`, `Spots`, and an `Openable` part on each moving piece.
2. Select `Door`'s part. In the inspector change `open_degrees` from today's value to another. Press Play (the throwaway test level, one cupboard in a room). Click the door with the middle-of-screen ray. See it open to your angle.
3. Select the root. Press the **Bake Sock spots** button in the inspector. Watch dots appear on the top and shelf. Delete one dot with the gizmo, add one by hand. Press Play and drop a loose Sock (a ball) onto it.
4. Open the material library (`assets/materials/`). Change `oak`'s colour. See the cupboard change. Open a second ported prop to see it change as well (this is why the library exists).
5. Ask the agent to re-export the glb from Blender with a changed handle shape and one node deliberately renamed. Reopen the scene. Your angle, dots and collider are still there. The renamed node is reported by a check, not silently lost.

**Built:** the port rules (T001, one page), the wrapper scene, the bake button (an `@tool` script), a two-material library, a one-shot script that drafts the wrapper from the manifest (R17), a before/after strip tool (T004). **Faked:** the Door and Drawer are driven by a plain test script, not the real `Openable` and not co-op; there is no Sock world.

**Names real assets:** the cupboard's builder in `tools/blender/house_furniture/`, its glb and manifest entry; the manifest's pivot, axis and `open_deg` for it.

**Proves:** R2, R4 (also a sofa and the car baked once for size), R8 (the swap method), R11 (open in your editor during a headless import), R17 (the draft script), R22. Also: does the glTF importer keep `extras` (the research could not check; the avatar relies on it).

**Cost:** 3 tickets (port rules and cupboard; bake button and size test; library, strip and re-export test). One more small one (the draft script) if it is not folded in.

**Kept or thrown away:** kept. The cupboard is the first ported prop and becomes the pattern. The rules page is the real T001. If R2 or R4 hits its stop rule, the rule changes first; the cupboard is redone once, on purpose.

### Slice 2. The kitchen from the kit, walkable

**Room:** the ground-floor kitchen (3.83 x 8.34 m today, 15 placements, 10 openables, one doorway to the hall, 3 window lights). It becomes 4.0 x 8.5 m. Alternative rooms are in question E1.

**What you do with your hands:**

1. Open `game/house/ground/kitchen.tscn`. The room is empty except a floor.
2. Drag wall pieces (0.5, 1, 2 m) from the file dock into the viewport. They snap to 0.5 m. Leave a 1.0 m gap for the hall doorway and drag the door-frame piece into it.
3. Drag the floor piece, set its material from the library (`kitchen_tile`) in the inspector. Give one wall a different material by hand and see it apply to that piece only.
4. Drag the ported furniture in: `fridge`, `kitchen_cupboard`, `kitchen_oven`, `kitchen_sink`, `kitchen_corner`, `kitchen_filler`, `kitchen_drawers`, `kitchen_wall_cupboard`, `kitchen_shelf`, `plant_trailing`, `dining_table`, four `dining_chair`. Rotate a chair, move the table half a metre. Delete one and put it back.
5. Press Play. The throwaway walker (first person) walks you in through the doorway. Walk between the table and the fridge. Check nothing floats and you cannot walk through the sink.
6. Try the rounding on purpose: shorten the room by 0.5 m and see what no longer fits. That is the real test of Q2175.

**Built:** the four kit pieces (wall in three lengths, floor, door frame, plus the half-metre check test), the kitchen's 12 furniture pieces ported by the slice-1 pattern (so this slice also is the "proof batch" T005), the walker (T028 in small), the rounding sheet from R5 (desk work). **Faked:** lights are two plain lights, no sun cycle; collision for Socks is placeholder boxes; no stairs.

**Proves:** R1 (bench kitchen vs today's kitchen on your PC and on the laptop), R5 (kitchen, doors, plus the sheet for stair and shaft), R9 (the editor workflow itself), R10 (two agents edit `kitchen.tscn` and a `ground_floor.tscn` stub, merge), R19, plus the first real timing for your approvals (R7).

**Cost:** 4 tickets (kit pieces and half-metre check; the 12 kitchen pieces in one or two batches counted as the T005 proof batch; kitchen assembly and walker; the bench strip and rounding sheet).

**Kept or thrown away:** the kit pieces, the pieces and the kitchen are kept (they are the first of M0 and M1). The walker is thrown away or reused as T028. If R1 hits its stop rule, the kit is redesigned before more rooms.

### Slice 3. Open one thing, carry one thing, two players

**Thing:** in the kitchen from slice 2: the fridge's top door (opens), and the Radio (carried; today's `assets/radio` model). One thing is opened and one is carried by two players.

**What you do with your hands:**

1. In the editor, open Project, Run Settings, "Customize Run Instances" and start two instances: one Host, one Guest (the state chapter lists this as unconfirmed; the agent checks it first).
2. Press Play. In the Host window click the fridge door: it opens in both windows. In the Guest window click it again: it closes in both.
3. In the Guest window pick up the Radio; the Host window shows the Guest holding it. The Host window tries to take it: refused.
4. Close the Guest window while it holds the Radio: the Radio drops where it stood in the Host window.
5. Start a third window, a late Guest: it sees the fridge door open and the Radio where it lies, with no swing.
6. Back in the editor, tick `locked` on the fridge's Openable and run again: a click shows "locked". Then rename `Chair2` in the scene and run; the test named in R3 fails and shows the old and new id.

**Built:** the chapter's classes as a pilot (Command, Part, Openable, Carriable, Parts, Session), a centre-of-screen click as the crosshair, the Radio as a rigid body under Jolt, the id-list test, a snapshot size print. **Faked:** no avatar, no Hands rules (one carried thing, no capacity), no prediction, no Mess, no lobby (two start arguments instead).

**Proves:** R3 (ids, real scene, physics), R12 (the load time in a headless test), R21 (snapshot size), and the open question of `Editable Children` for editing a part inside an instanced piece.

**Cost:** 2 tickets (kitchen wiring and carried-Radio physics; the id test, three-window test, snapshot print).

**Kept or thrown away:** the code is a pilot and **is not merged as the real M2**. Q2159 says each piece gets its own design, grilling, code and walkthrough before it counts; the pilot is the sketch you may use to decide the shape. The scene wiring (fridge with parts, Radio with its part) is kept. This is question E7.

### Slice 4. A tuning Resource in the inspector

**What you do with your hands:**

1. Open `data/house/open_feel.tres` in the inspector. Today's swing time is 0.35 s (from the chapter). Change it to something slow. Press Play with slice 3's two windows. See both windows swing slowly. (You choose the number; I invent none.)
2. Select one placed Door and change its own `open_degrees` (a number of one placed thing, Q2164). Only that door changes.
3. Edit the `.tres` on the Host machine only and start a Guest from the old file. The join is refused with a plain message (the version check from R13). Undo and it works again.

**Built:** the `OpenFeel` Resource, a data-hash in the join message, one test. **Faked:** nothing; this is real but small.

**Proves:** R13, and that "numbers are edited in the inspector" is as pleasant as hoped (Q2164).

**Cost:** 1 ticket, small. It can ride at the end of slice 3's second ticket.

**Kept or thrown away:** kept as the pattern for every later tuning Resource.

### Spikes (not slices: nothing for your hands)

| Spike | Answers | Cost |
|---|---|---|
| Mess spike: two-tier shell, 10,000 dummy Socks, today's bench harness | R6 | 1-2 tickets |
| Laptop run of slice 2's bench (you run `bench_lowend.cmd`) | R1 | your 10 minutes |

### Order, and what to skip

| Order | Slice | Why here | If time is short |
|---|---|---|---|
| 1 | Slice 1 (cupboard) | It tests the plan's most basic bet (R2, R4, R8) and costs the least. Its rules page is T001. | Never skip. |
| 2 | Slice 2 (kitchen) | The biggest bet (R1, R5). Doubles as the first proof batch T005. | Never skip. Cut the third wall length and the second-agent merge test if needed. |
| 3 | Slice 3 (open and carry) | The next biggest: R3. Q2160 wants co-op first anyway. | Skip only if you accept R3 at M2; then do slice 4 inside M2. |
| 4 | Slice 4 (tuning) | Tiny. | Skip first; fold into slice 3 or M2. |

---

## C. What the slices change in the plan

### Decisions they might overturn

| Q | Decision | What could overturn it | Slice |
|---|---|---|---|
| Q2162 | All assets before any scene work | Already bent: the plan asks for a pilot exception (about 13 pieces ported early). Could end up reversed to "port a family, then scenes" if rules change after slice 1. | 1, 2 |
| Q2175 | Half-metre rounding, nudge up to 25 cm | Elevator shaft, stair, house depth (R5). | 2 |
| Q2176 | Bake button saves spots in the scene | Spots may need a separate file (R4). Still the same button. | 1 |
| Q2177 | One shared material library | The swap method (R8), or some models keep variants. | 1 |
| Q2147 | State on the scene part | Ids (R3); stamping ids by a tool is a change to the sketch, not to Q2147. | 3 |
| Q2151, Q2152 | A prop = model plus a scene without behaviour; Blender builds meshes only | If re-export breaks wrappers (R2), moving parts go back to Blender. | 1 |
| Q2154, Q2156 | House built by hand from a snapping kit, not GridMap | If R1 or R9 fails: merged rooms at load, a small placing tool, or a glb shell. | 2 |
| Q2164 | Numbers as typed Resources | If Guests cannot share them (R13): hash check. | 4 |
| Q2159, Q2169 | Approval for each piece | The queue (R7): batch by family. | 1-3 |
| Q2168 | Clean rewrite of the Mess | The spike (R6): port core nearly as is. | spike |
| Q2160 | Co-op from the first game code | Held, and strengthened. | 3 |
| Q2165 | Tests from approved behaviour lists | Test of authored scenes (R12). | 3 |

### Where they sit in M0-M6

I do not renumber your milestones. I propose **M0.5 "slices"** inside M0 and a **gate** after it:

| Step | Contents | Note |
|---|---|---|
| M0 start | T001 port rules (draft), T002 material library (just the cupboard's materials), T003 test harness, T004 strip tool | as planned |
| M0.5a | Slice 1 | rules become final |
| M0.5b | Slice 2, using T005 as the kitchen's 12 pieces; rounding sheet; R6 spike in parallel | T005 changed from "five small props" |
| M0.5c | Slice 3, then slice 4 | the early part of M2, as a pilot |
| **Gate** | You review: risks R1-R6 answered or stop rules triggered; costs per prop, room, code piece; the approval time. Decide to continue, change rules, or cut scope | One short session |
| M0 rest | T006-T012 mass port, now with proven rules | |
| M1, M2 | as planned; M1 reuses slice 2's kit and kitchen; M2 redoes slice 3's code with full design and approval | |

If you refuse any exception to Q2162, then slice 1 and 2 use only 13 pieces, which is what the gate lets through; the other 228 models wait. That is the smallest exception.

---

## D. A migration journal

Where: `docs/migration/journal.md` in the new repository, one file, plus `docs/migration/costs.json` made by `tools/agent_cost.py --json`. Format and rules:

1. One entry per ticket, appended at merge. A table row per piece, a free-text "Surprises" line under it.
2. Fields: ticket id; piece or family; milestone; state (planned, design agreed, built, approved).
3. Planned vs actual: planned tickets for the piece, actual tickets (a rework is a new ticket tagged `redo-of`).
4. Redo count: how many times the piece came back after your review.
5. Corrections: one line of what you changed and why (quote you; it feeds the skill).
6. Cost: tokens and tool calls from `agent_cost.py --by ticket`, with the model; written by the lead, never typed from memory.
7. Time: you timed one approval (design and walkthrough separately), in minutes, as a rough number.
8. Surprises: what the docs said and the file did (mismatch), a tool that failed, a rule that was wrong.
9. Stop rules: if a rule of part A fired, write the rule number and what we did.
10. Decisions: any Q number answered or changed during the ticket, one line each.
11. Who writes: the agent drafts the entry in its ticket report; the lead copies it in at merge and adds the cost. You are asked only for corrections (item 5).
12. Gate review (after M0.5) and each milestone end get a half-page summary: planned vs actual totals and the top three surprises.
13. Rules that turned out wrong are marked "rule change" so the skill set can be written from those lines only.
14. The journal is never summarised in place; the retrospective is a separate document made from it at the end.
15. One check in the merge tool: no merge without a journal line (the same way the old tool checks stranded docs).

---

## E. Questions for the designer

Recommended first in each.

1. **Which room for slice 2?** (a) The ground-floor kitchen: 15 pieces, 10 openables, the most variety (recommended). (b) The first-floor office: fewer pieces and no cupboards, and the room can be smaller. (c) The bathroom: smallest, but few moving parts.
2. **Are the slices kept or thrown away?** (a) Kept after your approval: the cupboard, the kit and the kitchen become the real first pieces; slice 3's code is a sketch only (recommended). (b) Everything thrown away; slices only answer questions. (c) Kept as they are, merged without further review.
3. **A budget or stop point for the whole move?** (a) Run the slices first, then you set the budget from their measured cost per prop, room and code piece (recommended). (b) Set a number now. (c) No budget; look at costs at each milestone end.
4. **What is the largest queue of approvals you accept at once?** (a) Batch assets by family with one strip per batch, about 25 approvals for M0 (recommended). (b) Every model gets its own approval. (c) You approve designs only; walkthroughs only for risky code.
5. **May the plan break Q2162 for a pilot?** (a) Yes: about 13 pieces (the cupboard plus the kitchen's 12) are ported before the rest, to test scenes (recommended). (b) No: port everything first, then slices. (c) Only the cupboard before the rest.
6. **How do we judge the kit house against today's house (R1)?** (a) You decide from the bench strip and the laptop run; no fixed ratio (recommended). (b) A fixed limit you give now (a percent over today's). (c) The kit must be no worse than today at all.
7. **Does slice 3's co-op pilot skip Q2159's full approval?** (a) Yes: it is a pilot; the real M2 still gets full design, grilling and walkthrough (recommended). (b) No: full approval even for the pilot. (c) Skip slice 3 and do it only in M2.
8. **When a room does not fit the half-metre grid, what gives?** (a) The odd parts (stair, shaft, house depth) get a fixed piece off the grid; furniture moves before the house bends (recommended). (b) Rooms may be nudged more than 25 cm. (c) The grid becomes 0.25 m everywhere.
9. **Where does the gate review happen?** (a) One short session after slice 3 with a one-page result (recommended). (b) After each slice. (c) No gate; I decide as I go.

---

## F. What I could not check

- Nothing was run: no Godot, no Blender, no bench. Every "what we know" marked judged is arithmetic or reading.
- The rounding arithmetic (R5) uses sizes from `assets-inventory.md`: rooms, stair x 3.95..6.28 and z 5.15..8.34, shaft 0.7 x 0.7, car 0.58, doorways 0.9, 1.11, 0.826. I did not open the layout or test a nudge; the partition and wall thicknesses are not added.
- The editor questions: dragging scenes into the 3D view, Editable Children storage, "Customize Run Instances", snapping rules. Research files list them as unverified; slices 1-3 find out.
- Whether the glTF importer keeps `extras` as node metadata (the avatar relies on it) is open in `animation-rigging-blender.md`.
- The numbers 53,260 spots, 66 pieces with spots (telescope has 0) and 19 pieces with moving parts come from the inventory, not from my count.
- The kitchen's 12 furniture pieces: my list from `layout.py room kitchen`. The room has 10 openables on 6 pieces; I did not check which of these pieces are already well formed for a wrapper.
- Which materials the cupboard uses: not read. "Oak and a metal" is a guess to be confirmed in slice 1.
- The approval counts (part A) are my judgement. The milestone lists give tickets, not pieces.
- The low-end report says the laptop is limited by pixels and physics; I did not find a measurement of collision body count against physics tick, so how much a kit's extra bodies cost is unknown.
- The M0-M6 names in `new-project-start.md` differ from the feature catalogue's part 5 (it numbers the first slice M3 and the core loop M4). I used `new-project-start.md`'s. Marking those rows is the designer's job in any case.
- Q2171-Q2174 and the earlier `#` numbers beyond Q2183 were not read in full; I read the `## Answers` section to Q2181 as it stands in the file (the brief says up to Q2183; the file's last entry is Q2181).
- Slices 3 and 4 depend on the chapter's code being as described; I did not re-run it.
