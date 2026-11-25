# Migration journal

Kept from the first day; the retrospective and the reusable skills are written from it at the end. Never summarised
in place. The agent drafts its entry in its report; the lead copies it in at merge and adds the cost from
`python3 kit/tools/agent_cost.py --by ticket --json` (never from memory). A merge without its journal line is incomplete.

## Entry format (per merged ticket)
| Field | Content |
|---|---|
| Ticket | id, piece or family, milestone, state (planned, design agreed, built, approved) |
| Planned vs actual | tickets planned for the piece, tickets actual (a rework is a new ticket tagged `redo-of`) |
| Redo count | how often the piece came back after the designer's review |
| Corrections | one line of what the designer changed and why, quoted (feeds the skills) |
| Cost | tokens and tool calls and the model |
| Time | one approval timed, design and walkthrough apart, in minutes (rough) |
| Surprises | where the docs said one thing and the file another; a tool that failed; a wrong rule |
| Stop rules | rule number from `risks-and-slices.md` part A that fired, and what was done |
| Looks | whether the baseline views were compared, and the result |
| Decisions | each Q number answered or changed during the ticket, one line each |
Plus: a half-page summary at each milestone end (planned vs actual totals, the top three surprises);
a rule that turned out wrong is marked `rule change`; the drift list (changes to the old game after the port began).

## 2026-11-19: the preparation day (facts only)
- Researched, read-only, by agents from the old project's ticket vault, tests and code: five design digests
  (`digests/`), the core-loop behaviour list (107 when-then lines, 15 invariants), the feature catalogue (56 built,
  83 planned things), the asset inventory (241 glb models), the preparation plan, the risk register (22 risks) with
  four slice proposals, and the chapter "State and co-op". Earlier the same day: four netcode, rigging, authoring and
  constants reports, a code-unification estimate (four numbers), a move plan with a graph, and a code-shape report
  (113 classes, shapes A and B), all kept in the reference clone under `docs/research/nativize/`.
- A throwaway Host + Guest + late Guest slice ran in Godot 4.7.1 over ENet: 19 of 19 checks (`state-slice-run.log`).
- The designer's answers Q2143-Q2170 and Q2175-Q2181 were given in the grilling that day (`decisions.md`).
- What went wrong, as reported by the lead at the end of the day (the details are not in the research files):
  the test runner's `--import` call hung with no timeout; two branches clashed at merge; the git glitch ("unable to
  read tree") hit on the mounted drive and was repaired by the lead (the count was not recorded).
- What the old project's process digest says cost the most rework (so the same traps are avoided): test
  reliability, memory and speed (about 17 tickets in 18 days); code structure refactored again and again (about 45
  tickets); performance measured on the wrong machine; the zoo and debug UI; docs and vault drift; git and merge
  friction; decisions reversed after play (`digests/digest-maintenance-and-process.md` parts 3 and 4).
- Later that day and night: the old game's last features merged (five merges, four needing a fix in the merge
  worktree); frozen and tagged `v0.1`; the capture tour added and the 70-view looks baseline taken; tagged `v0.1.1`.
- The first hand-off (its own scaffold, 57 files) was dropped when the designer pointed at the game starter kit;
  starter kit 7 and 7.1 were built instead (Python runner, commit and merge tools, asset lint, the zoo skill and
  template, scene parts with a packet guard, avatars, a gate at connect, a carried thing's motion) and this pack
  was rebuilt on top. Cost of the misreading: four agent runs stopped and discarded.
- Three research rounds after the freeze: ids, roster and guards; Godot's own multiplayer nodes, tested; the
  official demo projects. Their result is the co-op structure in `decisions.md`.
- The designer's answers Q2188-Q2226 (`decisions.md`).
- No asset ported and no game code of the new project written by 2026-11-19.

## 2026-11-20: M0, setup (new session)
- The kit arrived as kit 8.0, a Claude Code plugin in the `kit/` submodule, not the zipped kit 7.1 START-HERE names.
  Setup followed `kit/docs/SETUP.md` section 1; the pack's kit-7 paths were repointed to `kit/tools/...`, and kit 8's
  extra example ticket (`mvp/issues/02-walking-skeleton.md`) was deleted with the other two.
- Project values: Q2227-Q2230 (`decisions.md`). Engine 4.7.2 (the 4.7 minor's newest patch; the old game ran 4.7.1).
- Checks: `run.sh` PASS 303 checks, 74 cases; shot, grep_rules, asset_lint, `setup.py --check`, 168 kit unit tests,
  `check_pack.py` (115 files) all pass. First commit e7d6f228, `git_check` PASS.
- What went wrong: the sandbox lacked git-lfs, xvfb and Pillow (installed); the private reference repository
  cannot be cloned without a GitHub token in the sandbox (open); the first commit hit the drive's "invalid object"
  glitch twice: four index entries pointed at blobs missing from the object store, and `git_repair.sh` cannot help
  before the first commit (no HEAD). Re-hashing the four files (`git hash-object -w`, re-add) fixed it.
- Not done: the reference clone, the push (no remote yet, Q2230).
- Later the same day: the designer added the old game as a submodule at `prototype/` (at its `main`, behind
  `v0.1.1`). The kit's tools skip only `reference/`, so `run.sh` failed on the old scripts; moved to
  `reference/it-socks` and pinned at `v0.1.1` (Q2231). Lesson for the reusable skill set: the reference goes under
  `reference/`, whether a plain clone or a submodule, and is pinned at the tag.
- M0 done: the designer made the remote `Griperis/it-socks-to-be-a-washing-machine` and pushed `3e8b31e` from the host; the sandbox has read access but no push token.

## core/01 zoo movement (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/01, the game's Player and the movement station, M0.5, approved and merged (4a1444f) |
| Planned vs actual | 1 ticket planned, 1 actual |
| Redo count | 0 after the designer's review; 1 lead review round before it (camera interpolation, placeholder marks, header) |
| Corrections | none to the behaviour list or the design; scope moved: sprint to M4 (Q2233), zoom to core/02 (Q2234), pad look tuning later (Q2235) |
| Cost | 3,045,492 tokens, 34 tool calls, 6 min, Sonnet, 2 runs (`kit/tools/agent_cost.py --by ticket`) |
| Time | behaviour list and design: about one hour of lead reading; designer approvals: two dialogs |
| Surprises | the agent left Godot's own interpolation on the top-level camera (headless tests cannot see it: a lead read caught it); the new `tests/hooks.gd` was committed without its `.uid`, so `integrate.sh` stopped once; the designer's editor re-saved `project.godot` and `.mcp.json` and imported the baseline PNGs in `docs/migration/` (now `.gdignore`d) |
| Stop rules | none fired |
| Looks | not compared (the zoo is new; nothing of the 70 baseline views changed) |
| Decisions | Q2232-Q2240 |

## core/02 handling Socks (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/02, the Mess and Hands Parts, pick, hold, drop, zoom, turn; M0.5; approved and merged (9e18ccf) |
| Planned vs actual | 1 planned; the Throw split off into core/08 before building (Q2250) |
| Redo count | 0 |
| Corrections | behaviour list unchanged; design choices Q2244-Q2249; the crate retired after (Q2258) |
| Cost | core/02 1 20,490,929 123 22m55s (Opus) |
| Time | the agent ran about 23 min; lead review with a before/after still |
| Surprises | the agent left two Q2245 pad bindings because removing events needs `--allow-project`; the kit crate lost its put-down when the kit hands went; a commit hit missing git objects once (fsck clean after); the code-shape questions (Q2251-Q2253) were asked late, mid-build |
| Stop rules | none fired |
| Looks | held-sock.png compared by eye: same place and size; crew model and plain Size letter differ (expected) |
| Decisions | Q2243-Q2250, Q2257, Q2258 |

## core/08 the Throw (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/08, charge, ring, lob, Throw speeds, the wake, out of bounds; M0.5; approved and merged (99f7ed3) |
| Planned vs actual | 1 (split from core/02, Q2250) |
| Redo count | 0 |
| Corrections | none; one approved test retired with the designer's OK (Q2267) |
| Cost | core/08 1 9,796,855 89 13m03s (Opus) |
| Time | the agent ran about 13 min |
| Surprises | a commit hit the missing-object glitch (re-hashed); the agent's new `tools/shot_hooks.gd` came without its `.uid` and stopped `integrate.sh` (second time: core/01 too); the designer's editor re-saved four files again |
| Stop rules | none fired |
| Looks | the ring compared with the old `power_ring.gd` numbers; stills in `builds/review-core-08/` |
| Decisions | Q2259-Q2261, Q2267 |

## core/03 pairing (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/03, two mates fuse in the Hands into a Pair (sock ball), the pairing moment, falling Pairs; M0.5; approved and merged (a786dc9, main fa4dab1) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Cost | core/03 1 15,803,409 96 16m54s (Opus) |
| Time | the agent ran about 17 min |
| Surprises | the designer's editor re-indented `.mcp.json`, which stopped `integrate.sh` (committed as editor format); the new scenes carry hand-written uids |
| Stop rules | none fired |
| Looks | the moment as a strip in `builds/review-core-03/`; the glow of the grey Simple Collection reads near white |
| Decisions | Q2254, Q2255, Q2262, Q2263, Q2269-Q2271 |

## core/04 one Cabinet (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/04, the Cabinet with Drawers and a Door, shelving by click and by Throw; M0.5; approved and merged (15b469e, main 7a563a8) |
| Planned vs actual | 1 planned, 1 actual; follow-ups core/09 (D11, D12) and core/10 (one Mess for the zoo) |
| Redo count | 0 |
| Cost | core/04 1 20,736,753 126 19m23s (Opus) |
| Time | the agent ran about 19 min |
| Surprises | the first report under Q2277 listed seven old details not built, each asked about before the merge; the agent gave each station its own Hands, which the designer did not want (Q2284); no still was made, so the lead took one; the station signs ran off the screen (all four now wrap at 3 m) |
| Stop rules | none fired |
| Looks | `builds/review-core-04/cabinet-station.png` |
| Decisions | Q2256, Q2264-Q2266, Q2282-Q2285 |

## core/10 one Mess for the zoo (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/10, the zoo owns one Mess, Hands and Coins; stations join it and still run alone; M0.5; approved and merged (0a93587, main 11b5cf6) |
| Planned vs actual | 0 planned (came from core/04's review, Q2284), 1 actual |
| Redo count | 0 |
| Cost | see `agent_cost.py --by ticket` core/10 (Opus), about 8 min |
| Surprises | Designs repeat across stations once there is one Mess (Q2290) |
| Stop rules | none fired |
| Looks | none |
| Decisions | Q2284, Q2289-Q2291 |

## core/12 every-Sock station (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/12, both Socks of every Design laid out by Collection with their info, real Mess Socks; M0.5; approved and merged (d2eb6d3, main 0632b04) |
| Planned vs actual | 1 planned, 1 actual; follow-up: the two-tier Mess (Q2301) |
| Redo count | 0 |
| Cost | core/12 1 6,427,237 62 9m13s (Sonnet) |
| Time | the agent ran about 9 min |
| Surprises | about 2,000 lying Socks as full Looks scenes cost a 40 ms physics tick (was 3 ms): the two-tier Mess is needed now; the agent's test came without its `.uid` (third time: core/01, core/08, core/12); PROTOCOL bumped to 6 at merge (Sock ids shift) |
| Stop rules | the same failure three times (a missing `.uid`): retro question |
| Looks | `builds/review-core-12/overview.png`, `row.png` |
| Decisions | Q2290, Q2294, Q2295, Q2301 |

## core/09 hand details (M0.5, batch 1), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/09, cloth (spring bones), glide, pick fly-up, pairing fly-in, shelving flight, drawer shut; M0.5; approved and merged (173a44e, main cab8f01) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Cost | core/09 2 25,136,212 162 34m32s (Opus) |
| Time | the agent ran about 28 min |
| Surprises | the go commit hit the missing-object glitch (repaired); the agent edited the shared `openable.gd` for the `shut` animation (kept) |
| Stop rules | none fired |
| Looks | six strips in `builds/review-core-09/` |
| Decisions | Q2272-Q2276, Q2283, Q2286-Q2288, Q2313-Q2316 |

## core/13 two-tier Mess (M0.5, batch 2), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/13, lying Socks as server bodies and MultiMesh instances, the moving budget, wakes and pushes, the old physics numbers; M0.5; approved and merged (94a445c, main c97c54c) |
| Planned vs actual | 0 planned (came from core/12's cost, Q2301), 1 actual |
| Redo count | 0 |
| Cost | core/13 1 36,370,272 165 39m29s (Opus) |
| Time | the agent ran about 40 min |
| Surprises | with the every-Sock station: process frame 16 ms to 0.9 ms, nodes 48,060 to 3,407; core/12's "39 ms" was Godot's physics monitor, which does not measure the tick; a hit woke lying Pairs against the old Q1742 (fixed, Q2330); PROTOCOL 7 |
| Stop rules | none fired |
| Looks | none (no change meant) |
| Decisions | Q2168, Q2301, Q2305-Q2312, Q2330 |

## core/19 batch 1 fixes (M0.5), merged 2026-11-20
| Field | Content |
|---|---|
| Ticket | core/19, the Throw leaves from the hand, the pairing ring around the ball, readable station signs; approved and merged (735996b, main c97c54c) |
| Planned vs actual | 0 planned (from the designer's play of batch 1), 1 actual |
| Redo count | 1 (core/09's throw and ring came back after play) |
| Cost | core/19 1 9,173,197 95 15m18s (Opus) |
| Time | the agent ran about 15 min |
| Surprises | the ring ignored the moment's scale; the signs' wrap (the lead's fast fix at core/04) had made them cover the view |
| Stop rules | none fired |
| Looks | `builds/review-core-19/` before and after |
| Decisions | Q2329, Q2332 |

| Field | Content |
|---|---|
| Ticket | core/14, the rules back to the old game (free mouse, nearer aim, woken pick, Pair last, drop on a Pair, drawer-front shelve, mid-air pick); approved and merged (557a5e3, main f1a126c) |
| Planned vs actual | 1 planned, 1 actual (widened once, Q2339) |
| Redo count | 0 |
| Corrections | the designer chose the old mid-air pick: "As the old game" (Q2339) |
| Cost | core/14 1 10,669,558 75 14m54s (Sonnet) |
| Time | the agent ran about 15 min |
| Surprises | core/18's look:v06 real path pressed pick with a free mouse; it failed after the merge until it captured the mouse (R01) |
| Stop rules | none fired |
| Looks | none (rules only) |
| Decisions | Q2297, Q2303, Q2304, Q2312, Q2338, Q2339 |

---

| Field | Content |
|---|---|
| Ticket | core/17, the sound system (SoundEvent Resources, the old buses and mix, footsteps by surface, muffle, ambience, Settings and Sounds); built ahead of batch 6 and merged (99dec60) |
| Planned vs actual | 1 planned, 1 actual; the call sites wait for batch 6 |
| Redo count | 0 |
| Corrections | "Sound a different M1.X milestone, sounds made nicely plug-and-play" (Q2278); then built early as long parallel work (Q2317) |
| Cost | core/17 1 8,690,877 73 11m33s (Opus) |
| Time | the agent ran about 12 min |
| Surprises | its .tres files lacked `uid=` headers (the editor re-save is committed as editor format when it comes); a missing .uid stopped the merge |
| Stop rules | none fired |
| Looks | none (sound) |
| Decisions | Q2278, Q2317-Q2321, Q2333 |

---

| Field | Content |
|---|---|
| Ticket | core/18, the picture and theme (old noon HDRI, AgX, grade, vignette, SSAO, glow, AA, presets, old crosshair); built ahead of batch 7, approved and merged (1d94605) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | the HUD keeps the default font: Patrick Hand was only on the old whiteboard (Q2331; the lead's premise in Q2324 was wrong); noon ambient 0.75, not the ticket's 0.7 |
| Cost | core/18 1 8,774,745 84 4h04m (Opus; the wall time includes waiting for the designer's go) |
| Time | the agent's work about 20 min; the rest waited on the still |
| Surprises | its real-path case pressed pick with a free mouse and broke when core/14 (R01) merged |
| Stop rules | stopped at the first still (Q2333 go) |
| Looks | `builds/review-core-18/` |
| Decisions | Q2299, Q2300, Q2317, Q2322-Q2324, Q2331, Q2333 |

---

| Field | Content |
|---|---|
| Ticket | house/01, the house kit (walls, corners, Ts, floor and ceiling tiles, door and window walls, a straight stair with a landing, the kit station); merged as a first step (ef17dba, main 1269185) |
| Planned vs actual | 1 planned, 1 actual; widened by house/02 and house/03 |
| Redo count | 0 |
| Corrections | the designer wants the kit to build the old house nearly identically, the old house re-gridded to 0.5 m (Q2343-Q2346); the agent had nudged 2.9 m storeys to 3.0 m and left out windows, frames, skirting, railings, roof |
| Cost | house/01 1 15,172,921 100 22m27s (Opus) |
| Time | the agent ran about 22 min |
| Surprises | 5 staged blobs went missing from the object store at the agent's finish (rewritten); the kit station stood in sounds:s07's walking path, fixed at the merge |
| Stop rules | stopped at its stills |
| Looks | `builds/review-house-01/` |
| Decisions | Q2325-Q2328, Q2343-Q2346 |

---

| Field | Content |
|---|---|
| Ticket | core/22, the Sounds station built from the sound catalogue with small buttons; approved and merged (c06911e) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (overlapping labels and the sign over the buttons, Q2340) |
| Corrections | "Fix both, then merge" (Q2340) |
| Cost | core/22 1 3,133,847 37 9m44s (Sonnet) |
| Time | the agent ran about 10 min |
| Surprises | its first commit left out two script .uid files (the agent added them) |
| Stop rules | stopped at its first still |
| Looks | `builds/review-core-22/` |
| Decisions | Q2337, Q2340 |

---

| Field | Content |
|---|---|
| Ticket | core/20, the heap station (a spout pours real Socks in waves, More and Respill, counters, walls, a table and a slope); approved and merged (main 52fd2f5) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (moved off the house kit station's spot, Q2347) |
| Corrections | "Move it, then merge"; nothing pours at start (Q2347, Q2348) |
| Cost | core/20 1 16,864,657 107 25m56s (Opus) |
| Time | the agent ran about 23 min |
| Surprises | the agent placed it on the spot house/01 took in parallel; a FLAKY heap:h04 once, reworked, 4 runs clean; 500 Socks: 3 ms a tick pouring, 0.6 ms at rest |
| Stop rules | stopped at its still |
| Looks | `builds/review-core-20/` |
| Decisions | Q2334-Q2336, Q2347, Q2348 |

---

| Field | Content |
|---|---|
| Ticket | core/26, the stations instanced by hand in zoo.tscn (the folder collector and grid placement gone); merged (main ee21292) |
| Planned vs actual | 0 planned (the designer's ask, Q2359), 1 actual |
| Redo count | 0 |
| Corrections | "why the stations are placed by code and not directly in the scene, so I can move them around?" (Q2359) |
| Cost | core/26 1 536,695 8 1m59s (Sonnet) |
| Time | the agent ran about 2 min |
| Surprises | a kit rule reversed for this game; the kit's zoo-design skill still describes the folder collector |
| Stop rules | none fired |
| Looks | none |
| Decisions | Q2359 |

---

| Field | Content |
|---|---|
| Ticket | core/11, the reusable outline (Outline component, OutlineStyle, the old stencil shells) on Socks, drawers, the Door and the cupboard, red full; approved and merged (main 59bf018) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (made stronger for the graybox, Q2374) |
| Corrections | "Stronger for now" (Q2374) |
| Cost | core/11 1 19,300,891 131 26m35s (Opus) |
| Time | the agent ran about 25 min |
| Surprises | the old numbers barely read on the bright graybox; the outline station had to be placed in zoo.tscn at the merge (core/26); a damaged commit at the merge (git_repair) |
| Stop rules | stopped at its first still |
| Looks | `builds/review-core-11/` |
| Decisions | Q2292-Q2293, Q2341, Q2374 |

---

| Field | Content |
|---|---|
| Ticket | core/23, Socks no longer flip (rigid-board spin fixed: turn_weight 3, pours fall as woken Socks, flights use the lying boxes, CCD as the old); the Throw and the drop leave from the hand; approved and merged (main 92ab47e) |
| Planned vs actual | 1 planned, 1 actual (widened by the drop, Q2367) |
| Redo count | 0 |
| Corrections | "Real body from the hand" (Q2356); "Drop from the hand too" (Q2367); the thrown Sock keeps the hand's pose (Q2383) |
| Cost | core/23 1 46,243,751 202 44m47s (Opus) |
| Time | see cost |
| Surprises | the flips were physics, not the rest switch (core/21 had cleared it); the every-Sock flip was not reproduced |
| Stop rules | stopped at its strips |
| Looks | `builds/review-core-23/` |
| Decisions | Q2356, Q2357, Q2367, Q2382, Q2383 |

---

| Field | Content |
|---|---|
| Ticket | house/02, the kit for the old house: the re-gridded plan, two-face walls, skirting, every window (both sets), door frames, the U stair, roof, dormer, attic, no z-fighting; approved and merged (main 92ab47e) |
| Planned vs actual | 1 planned, 1 actual (two stops) |
| Redo count | 0 |
| Corrections | re-grid the old house (Q2343); a 0.9 m landing, off-centre doors, 10.5 m, old clear heights, roof 40 (Q2350-Q2354); "try multiple things" for windows (Q2355, Q2381); no z-fighting (Q2358) |
| Cost | house/02 1 48,669,950 190 16h46m (Opus; the wall time includes the waits for the designer) |
| Time | see cost |
| Surprises | the old house is off any grid (10.1 x 8.34 m, 13 window sizes); the ticket's 40 degree roof was the lead's misreading (old 37.4), kept on the designer's word |
| Stop rules | stopped at the plan and at the pieces |
| Looks | `builds/review-house-02/` |
| Decisions | Q2343-Q2346, Q2350-Q2358, Q2380, Q2381 |

---

| Field | Content |
|---|---|
| Ticket | assets/01, the Sock models, balls, pattern shader and prints; the Sock entity, flights and the lying tier swapped to them; approved and merged (main e2ce243) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | "Go, we will figure the updates to socks looks afterwards" (Q2384); the wool look is assets/05 |
| Cost | assets/01 1 45,805,928 232 1h27m (Opus) |
| Time | see cost |
| Surprises | the shape follows the Collection, not the Size (the ticket's premise); the cloth on the ankle shape dips 3.9 mm |
| Stop rules | stopped at its first still |
| Looks | `builds/review-assets-01/` |
| Decisions | Q2378, Q2384 |

---

| Field | Content |
|---|---|
| Ticket | assets/02, the 17 Collection Cabinets as Looks of the one Cabinet, all at the Cabinet station; approved and merged (main e2ce243) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | 3 drawers now, growing by Stage in M4 (Q2385) |
| Cost | assets/02 1 17,846,338 137 1h22m (Opus) |
| Time | see cost |
| Surprises | its grown pad overlapped the Sock looks station at the merge (moved); asset_lint cannot read inherited scenes (kit) |
| Stop rules | stopped at its first still |
| Looks | `builds/review-assets-02/` |
| Decisions | Q2378, Q2385 |

---

| Field | Content |
|---|---|
| Ticket | assets/03, the 111 old icons and the keycap lookup, an icons station; approved and merged (main e2ce243) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | assets/03 1 5,906,121 59 1h22m (Sonnet) |
| Time | see cost |
| Surprises | the .uid and .import files needed a headless --import; zoo.tscn conflicted with assets/01 (both added a station) |
| Stop rules | stopped at its first still |
| Looks | `builds/review-ui-art/` |
| Decisions | Q2378, Q2385 |

---

| Field | Content |
|---|---|
| Ticket | core/25, every core sound and rumble wired (bounce by hit speed, a min gap per sound, shelve at the click, rumble a setting, land after every jump); merged (main c68636d) |
| Planned vs actual | 1 planned, 1 actual (W15 moved to core/16) |
| Redo count | 0 |
| Corrections | bounce follows the hit speed (Q2371); a gap per sound (Q2372); shelve at the click (Q2373) |
| Cost | core/25 1 7,621,525 58 9m34s (Sonnet) |
| Time | the agent ran about 10 min |
| Surprises | a missing git blob at the agent's finish again (rewritten) |
| Stop rules | none fired |
| Looks | none (sound) |
| Decisions | Q2371-Q2377 |

---

| Field | Content |
|---|---|
| Ticket | core/15, aiming and screen: the old prompts, corner hints, keycaps, the aimed and held readouts with Sock Smarts and Sense flags, the old openable names; approved and merged (main c8aa2fd) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (the openable wording back to the old names, Q2388) |
| Corrections | "This worked different by upgrades. Explore more." (Q2360); the Throw hint was never gated (Q2365, the draft's premise was wrong); old names on openables (Q2388) |
| Cost | core/15 2 32,520,955 197 29m29s (Opus) |
| Time | the agent ran about 25 min |
| Surprises | a "nonexistent object" at the agent's finish again (committed by hand, read back) |
| Stop rules | stopped at its first still |
| Looks | `builds/review-core-15/` |
| Decisions | Q2360-Q2365, Q2387, Q2388 |

---

| Field | Content |
|---|---|
| Ticket | house/03, the old house rebuilt twice from the kit (A old-width windows, B rounded), beside the zoo, walkable front door to attic; approved and merged (main 6d88764) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | "A, but also do B for the building ... Goal is to rebuild the old house with this technique" (Q2381); beside the zoo (Q2386) |
| Cost | house/03 1 35,514,822 147 44m02s (Opus) |
| Time | the agent ran about 45 min |
| Surprises | each house is about 2,050 nodes, over the zoo's node budget; the test now counts only the Mess (Q2392); two kit pieces added and two 1 cm fixes (Q2393); missing blobs again at commit |
| Stop rules | stopped at its stills |
| Looks | `builds/review-house-03/` |
| Decisions | Q2345, Q2381, Q2386, Q2391-Q2393 |

---

| Field | Content |
|---|---|
| Ticket | core/16, feedback and motion polish part 1: the cloth tuned to flap less, the refusal wobble, the "Paired!" pop, the ball's squash, hop and roll, the lost Sock's return scatter and pop; merged (main b58290b) |
| Planned vs actual | 1 planned, 2 actual (the rest split into core/27, Q2398) |
| Redo count | 0 |
| Corrections | "Keep the node, tune it, so it doesn't flap as so much" (Q2366); "Rest can come as a separate ticket, merge this now" (Q2398) |
| Cost | core/16 1 27,878,079 139 28m59s (Opus) |
| Time | the agent ran about 30 min |
| Surprises | FLAKY sound_wiring:w10_gap again at the merge (core/27 F1 fixes it) |
| Stop rules | stopped at its review sheet |
| Looks | `builds/review-core-16/` |
| Decisions | Q2366-Q2370, Q2398 |

---

| Field | Content |
|---|---|
| Ticket | assets/04, the shared material library (24 groups, most-used variant kept) and the 67 furniture pieces as scenes with opening parts, Sock spots, collision and the old coarse player boxes; the Sock area widened over the furniture and houses; approved and merged (main ecf16e6) |
| Planned vs actual | 1 planned, 1 actual (device details split into assets/07; sheen into assets/06) |
| Redo count | 0 |
| Corrections | most-used per group (Q2389); fabrics without sheen for now (Q2390); Socks on furniture (Q2396); old player boxes (Q2397) |
| Cost | assets/04 1 58,511,473 256 1h03m (Opus) |
| Time | the agent ran about 1 h |
| Surprises | ids in zoo.tscn clashed with other branches twice; the Furniture station had to move east of house B |
| Stop rules | stopped at the material strips and the furniture line-up |
| Looks | `builds/review-furniture/` |
| Decisions | Q2177, Q2378, Q2389, Q2390, Q2394-Q2397 |

---

| Field | Content |
|---|---|
| Ticket | assets/08, the model sources: .blend files in assets_src/blender/, the Blender scripts in assets_src/generate/, both rebuilding all 97 ported .glb exactly; docs/human updated; merged (main 5b44d4f) |
| Planned vs actual | 0 planned (found writing docs/human), 1 actual |
| Redo count | 0 |
| Corrections | "assets_src/blender and the tools also into assets_src/generate if possible" (Q2400) |
| Cost | assets/08 1 12,820,822 116 14m37s (Opus) |
| Time | the agent ran about 15 min |
| Surprises | the pinned Blender download was blocked by the sandbox firewall (pip bpy 5.3.0 used instead); kit export.sh reads its manifest inside kit/ and lacks sock budgets (kit faults) |
| Stop rules | none fired |
| Looks | none (sources) |
| Decisions | Q2152, Q2400 |

---

| Field | Content |
|---|---|
| Ticket | core/27, the rest of the motion polish: the held box rides the sway, the throw keeps its hand bend, the shelved ball's landing, a thrown shelve flies on to its slot, the fold's curl, the Door and cupboard swings; the FLAKY w10_gap fixed; merged (main 45a6890) |
| Planned vs actual | 0 planned (split from core/16, Q2398), 1 actual |
| Redo count | 0 |
| Corrections | the designer asked for a complexity report before the merge ("I would like to have a report of how much complexity this added"); a drop keeps no bend (Q2401); the swing ease is the designer's to tune in the editor (Q2403) |
| Cost | core/27 1 28,528,469 165 42m28s (Opus) |
| Time | the agent ran about 40 min |
| Surprises | w10_gap's race: the runner reset sounds while the last case's Sock still bounced |
| Stop rules | stopped at its review sheet |
| Looks | `builds/review-core-27/` |
| Decisions | Q2281, Q2315, Q2316, Q2368, Q2398, Q2401-Q2403 |

---

| Field | Content |
|---|---|
| Ticket | core/28, the code review's correctness fixes: drawer locks held by the Host, no swing replay, the pad keycap, the heap pour cannot hang, line-up labels, the ball's physics stops, the catalogue index, the Cabinet caches, the shut Door's own sound, the outline re-enter; merged (main 955ce95) |
| Planned vs actual | 0 planned (from the M0.5 code review, Q2404), 1 actual |
| Redo count | 0 |
| Corrections | none; R8(b) (other bodies' footsteps) left for M0.6 |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 11 min |
| Surprises | the commit came out damaged again; repaired with git_repair.sh |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2404 |

---

| Field | Content |
|---|---|
| Ticket | core/29, the code review's per-frame cost outside the Mess: one aim search per held tick, reused probe shapes, the sway's cloth found once, HeldView's one `_forget`, PairMoment's cache, missing icons cached; merged (main 955ce95) |
| Planned vs actual | 0 planned (from the M0.5 code review, Q2404), 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 4 min |
| Surprises | none |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2404 |

---

| Field | Content |
|---|---|
| Ticket | core/33, the zoo's station names near the ground: at each station's front edge, eye height, one shared look, wrapped, Y-billboard; merged (main 4c48e54) |
| Planned vs actual | 0 planned (designer's note, Q2408), 1 actual |
| Redo count | 0 |
| Corrections | none; the Cabinet's long name overlaps its gallery from 3 m (noted) |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 15 min |
| Surprises | two commit attempts lost a git object; finished with `--no-test` after a passing `--touched` run |
| Stop rules | stopped at its stills for the designer's go |
| Looks | `builds/review-core-33/` |
| Decisions | Q2408, Q2411 |

---

| Field | Content |
|---|---|
| Ticket | core/34, what only the zoo needs into `game/zoo/`, per station (upgrade switch, sound buttons, kit line-up and sample rooms, zoo flags); the two generators to `tools/`; prompts ask `Part.prompt_title()`; merged (main 486431f) |
| Planned vs actual | 0 planned (designer's note, Q2409; no guard check, Q2410), 1 actual |
| Redo count | 0 |
| Corrections | the designer dropped the guard check (Q2410) |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 6 min |
| Surprises | a staged blob went missing again; rewritten with `git hash-object -w` |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2409, Q2410 |

---

| Field | Content |
|---|---|
| Ticket | core/31, the Mess benchmark (`tools/mess_bench.sh`/`.cmd`, nine scenarios as data, a fault watch) and the settle teleport: the Mess's MultiMeshes were physics-interpolated, so a settling Sock was undrawn for a tick and flying rows smeared; plus the review's Mess speed-ups; merged (main e89ce65) |
| Planned vs actual | 0 planned (designer's report, Q2405-Q2407), 1 actual |
| Redo count | 0 |
| Corrections | the designer pinned the glitch to the settle moment (Q2407); asked how the code grew before the go; sunk Socks left (Q2412), flips accepted (Q2413); core/21 closed (Q2415) |
| Cost | see `agent_cost.py --by ticket` (Fable) |
| Time | the agent ran about 40 min, most of it benchmark runs |
| Surprises | core/21 had found the switch pixel-identical in a still: the fault was a whole missing tick, visible only in motion; the lead's Euler suspect measured harmless |
| Stop rules | none needed (no look change) |
| Looks | `builds/review-core-31/` (two strips, the benchmark report) |
| Decisions | Q2405-Q2407, Q2412-Q2415 |

---

| Field | Content |
|---|---|
| Ticket | core/30, the code review's tidy-up: felt numbers into tuning Resources and the Theme, zoo labels/buttons/swatches as scenes, duplication and unused code out; merged (main 8909c25) |
| Planned vs actual | 0 planned (from the M0.5 code review, Q2404), 1 actual |
| Redo count | 0 |
| Corrections | three items kept as they were (Arc's fallback, LAYER_HOUSE in the generators, two Cabinet helpers the tests use) |
| Cost | see `agent_cost.py --by ticket` (Opus) |
| Time | the agent ran about 37 min |
| Surprises | the net saving was small (about 50 game lines): much had gone in core/28-34, and the replacements (label scenes, theme entries, asserts) cost lines |
| Stop rules | before/after stills of every station: 28 of 33 identical, 5 differ only in the heap counter's live digits |
| Looks | `builds/review-core-30/` |
| Decisions | Q2404 |

---

| Field | Content |
|---|---|
| Ticket | core/35, the game's command line (`--help`, `--bench=mess`, `--scene=`) in debug builds; the bench scripts as thin wrappers; merged (main 8909c25) |
| Planned vs actual | 0 planned (designer's request, Q2416), 1 actual |
| Redo count | 1 (sent back for the zoo-first ERROR and the pacing) |
| Corrections | an exe run needs the engine flag `--fixed-fps 10` before `--` (Godot cannot fix its step at runtime); the bench refuses to run without it |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 1 h 45 min, 83 min of it one unpaced run the lead stopped |
| Surprises | a headless run without a fixed step paces in real time and runs for hours |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2416 |

---

| Field | Content |
|---|---|
| Ticket | core/36, the held Sock's cloth swings: drag 0.25 in the tuning and the four Looks scenes; merged (main 8909c25) |
| Planned vs actual | 0 planned (designer's report, Q2417), 1 actual |
| Redo count | 0 |
| Corrections | the designer picked drag 0.25 from the sheet (Q2420); the swing test was removed: no tests for visual tweaks (Q2421) |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 18 min |
| Surprises | drag 1.0 was the old game's "fully damped": no momentum at all |
| Stop rules | stopped at its sheet for the designer's pick |
| Looks | `builds/review-core-36/` |
| Decisions | Q2417, Q2420, Q2421 |

---

| Field | Content |
|---|---|
| Ticket | core/39, a Sock caught by a shutting Door or drawer is pushed out to the open side, no pop; merged (main 9033b77) |
| Planned vs actual | 0 planned (core/31 follow-up, Q2428), 1 actual |
| Redo count | 0 |
| Corrections | the agent also kept a Sock pressed a few mm into a floor where it lies, as the old `flat_layout.gd` `sunk_floor()` (9 of 10 pops after a Door shut on main were that, not the leaf) |
| Cost | see `agent_cost.py --by ticket` (Opus) |
| Time | the agent ran about 16 min |
| Surprises | the bench never showed `lost` on this machine, on main either; the station's own pops were the floor rule |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2428 |

---

| Field | Content |
|---|---|
| Ticket | core/40, the tests that only check a look or feel number are removed (23 cases, about 900 lines); merged (main 9033b77) |
| Planned vs actual | 0 planned (Q2421, Q2429), 1 actual |
| Redo count | 0 |
| Corrections | 19 doubtful cases kept and listed in its Built log; the look-only cases in the Cabinet and Mess suites were left for a later sweep (core/39 owned those files) |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 4 min |
| Surprises | none |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2421, Q2429 |

---

| Field | Content |
|---|---|
| Ticket | core/38, jointed flying Socks (three bodies, two hinges): an experiment on core/37's branch, never merged; closed wontfix (Q2423) |
| Planned vs actual | 0 planned (Q2422), 1 actual, plus a "really flappy" build (Q2424) |
| Redo count | 0 |
| Corrections | the lead stopped its long budget sweep; the first review build would not load: a preload loop through SockCloth and HeldView, also on main, fixed there (9b829af) |
| Cost | see `agent_cost.py --by ticket` (Opus) |
| Time | the agent ran about 1 h 30 min, most of it benchmark runs |
| Surprises | joints cost about 1.5x a one-body pour, not 3-4x; spin, not joints, flips Socks; taken to main: `--tune=` and shared flight materials (cd3d60d); the contact switch tried after it made main slower and was taken back |
| Stop rules | the lead's wrap-up message |
| Looks | `builds/review-core-38/`, `builds/review-core-38-flappy/` |
| Decisions | Q2422, Q2423, Q2424 |

---

| Field | Content |
|---|---|
| Ticket | core/46, a Throw wakes the lying Socks it is about to hit, so it shoves them (the old look-ahead); merged (main e9a3f94) |
| Planned vs actual | 0 planned (core/08 T11 follow-up, Q2431), 1 actual |
| Redo count | 0 |
| Corrections | the agent stopped at needs-info: burst_16 p95 1.0 to 1.8 ms, moving peak 52 to 124; the designer accepted it (Q2435) |
| Cost | see `agent_cost.py --by ticket` (Opus) |
| Time | the agent ran about 12 min |
| Surprises | the shove shows little: a Throw lands steeply on flat Socks and friction stops them within mm |
| Stop rules | stopped at the cost question |
| Looks | none |
| Decisions | Q2431, Q2435 |

---

| Field | Content |
|---|---|
| Ticket | core/47, the room is silent: `amb_room` has no clip, an event with no clip plays nothing and logs nothing; merged (main e9a3f94) |
| Planned vs actual | 0 planned (Q2432), 1 actual |
| Redo count | 0 |
| Corrections | clashed with core/48 in `Sounds._asked`; the lead kept core/47's silent rule |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 3 min |
| Surprises | none |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2432 |

---

| Field | Content |
|---|---|
| Ticket | core/48, the game's one log: the kit's `log` template as the autoload `Log`, first; a file per run under `user://logs/` starting with the build; the game's warnings and errors moved onto it; merged (main e9a3f94) |
| Planned vs actual | 0 planned (the designer asked, 2026-11-22), 1 actual |
| Redo count | 0 |
| Corrections | went wider than named (Parts, Avatars, ZooNet, the heap spout, the bench report onto Log); the Settings and Sounds tests now read the log line, since `Log.error` raises no engine error |
| Cost | see `agent_cost.py --by ticket` (Sonnet) |
| Time | the agent ran about 6 min |
| Surprises | the kit's rule had been skipped since M0.5 began |
| Stop rules | none needed |
| Looks | none |
| Decisions | none |

---

| Field | Content |
|---|---|
| Ticket | coop/01, spike: thrown Socks carried to a Guest by Godot's spawner and one synchronizer per body (the Throw's Option A), M0.6 batch 0; merged (main 953eaf7) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none; the test suite stays (small-zoo cases stable three runs; two stress cases record numbers only) |
| Cost | 6,132,717 tokens, 50 tool calls, 17m43s (Opus) |
| Time | the agent ran about 18 min |
| Surprises | ENet's packet throttle drops 31 of 32 unreliable packets at 60 fps (any stream, avatars too); Mess answers carry the whole poses array (about 100 KB at 2,038 Socks) and back up the reliable channel; `MessMoving._launch` sets the pose after `add_child` |
| Stop rules | none needed |
| Looks | none |
| Decisions | Option A with three conditions (`docs/research/coop-flight-sync.md`) |

---

| Field | Content |
|---|---|
| Ticket | coop/02, spike: Godot's PhysicalBone3D ragdoll on Jolt for the 4-bone avatar and its pose reaching a Guest, M0.6 batch 0; merged (main 953eaf7) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none; the spike suite stays until the knockdown's own tests replace it |
| Cost | 2,977,019 tokens, 33 tool calls, 9m56s (Opus) |
| Time | the agent ran about 10 min |
| Surprises | a synchronizer on bone poses works with no code but steps 4 to 6 times the Host's motion; a direct `--import` rewrites about 300 `assets/*.res` files |
| Stop rules | none needed |
| Looks | none |
| Decisions | the stamped pose eased at 12/s (`docs/research/coop-ragdoll-sync.md`); the lag (100 to 155 ms) is judged at the knockdown |

---

| Field | Content |
|---|---|
| Ticket | coop/03, host, join and roster behind a transport seam ready for Steam (NetTransport/EnetTransport, PlayerProfile with the long id, the gate with protocol, layout hash, id and name, the Roster Part, refusals, toasts, leaver's drop, 10 s join timeout, throttle at full), M0.6 batch 1; merged (main a3457f7) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | went outside its Owns list where the acceptance needed it (`Hands.left()`, `hearing.gd` drop once, `Player.announce()`/`notice()`); with coop/04 the new avatar test shared one profile on both zoos and the gate refused it: the lead gave each zoo its own profile at integration |
| Cost | 20,832,512 tokens, 122 tool calls, 20m42s (Opus) |
| Time | the agent ran about 21 min |
| Surprises | none |
| Stop rules | none needed |
| Looks | none |
| Decisions | Q2440-Q2449, Q2456-Q2460 |

---

| Field | Content |
|---|---|
| Ticket | coop/04, the avatar model ported as is (4 bones, the Looks scene and contract, the capsule replaced), M0.6 batch 2, an asset piece; approved (Q2465); merged (main a3457f7) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | 9,919,850 tokens, 91 tool calls, 19m14s (Opus) |
| Time | the agent ran about 19 min |
| Surprises | the import's bone rests carry a 0.6 to 1.2 degree lean the coop/02 stand-in lacks (noted for the knockdown) |
| Stop rules | none needed |
| Looks | the before and after strip: no pixel differs in six views |
| Decisions | Q2438, Q2465 |

---

| Field | Content |
|---|---|
| Ticket | coop/05, Teammates seen and heard (pose every frame with pitch and crouch, 12/s follow and 1 m snap, every old motion in AvatarLooks, colour, "Player" tag, worn held view, 3D Teammate sounds and steps, Throw from their hand, Pair sparkle, the avatar zoo station), M0.6 batch 2; strip approved (Q2469); merged (main 7387b32) |
| Planned vs actual | 1 planned, 1 actual (stopped at its first strip, then finished) |
| Redo count | 0 |
| Corrections | the avatar station was added mid-ticket (Q2468); its stand-in walks only when the camera is near, or other stations' tests waited for its held Sock; the last commit came back damaged and the lead repaired it (git_repair.sh) |
| Cost | 44,333,070 tokens, 192 tool calls, 55m01s (Opus) |
| Time | the agent ran about 54 min in two parts |
| Surprises | a Guest's pick capacity on the Host comes from the Hands' own tuning, not the Guest's Upgrade |
| Stop rules | the look round stopped it at the first strip, as meant |
| Looks | the Teammates strip in builds/review-teammates/ |
| Decisions | Q2439, Q2450-Q2455, Q2461-Q2464, Q2468, Q2469 |

---

| Field | Content |
|---|---|
| Ticket | coop/06, the own body in first person (the avatar's belly cut at 0.8 m and closed, set back 0.22 m, outside only, no eyes or shadow, the feet; the capsule mesh gone), M0.6 batch 2, a gap the lists left out (Q2466); stills approved (Q2471); merged (main 92e1676) |
| Planned vs actual | 0 planned (raised by the designer), 1 actual |
| Redo count | 0 |
| Corrections | the lead's done commit came back damaged and was repaired; the designer's editor had reassigned the uid of avatar_tuning.tres with no clash found: put back (the designer's call) |
| Cost | 5,492,913 tokens, 51 tool calls, 9m04s (Opus) |
| Time | the agent ran about 9 min |
| Surprises | no old picture exists of the first-person views to compare with |
| Stop rules | stopped at its first stills, as meant |
| Looks | builds/review-own-body/ |
| Decisions | Q2466, Q2467, Q2471 |

---

| Ticket | coop/07, the Guest's respill disconnect (a bug): Mess answers carry only changed rows; rests batched a tick; a Guest's spawned flight copy frozen (stops the Jolt overflow); PROTOCOL 11; M0.6 batch 3, plan `coop-mess-sync.md` (Q2472); merged (main 61ccc8e) |
| Planned vs actual | 1 planned, 1 actual (redirected mid-run to the plan's record format) |
| Redo count | 0 |
| Corrections | the disconnect itself never reproduced in one process; the reproduced faults were the Guest falling minutes behind and Jolt overflow from heaped flight copies |
| Cost | 20,245,190 tokens, 133 tool calls, 52m47s (Opus) |
| Time | the agent ran about 53 min |
| Surprises | reliable bytes in a 2,000-Sock pour: 1.33 MB/s average (16 MB worst second) before, about 59 KB/s (90 KB worst) after; game code +256 −121 |
| Stop rules | the frozen flight copies changed a Guest's looks against the ticket; flagged `[later]`, told to the designer as a stopgap until coop/08 |
| Looks | none |
| Decisions | Q2472 |

---

| Ticket | coop/08, the Mess's local bodies: every machine starts its own body for a woken, falling, poured, swept or dropped Sock, a Guest's looks only and snapped to the rest batch; Doors and drawers sweep on every machine; the join packed and compressed with flying Socks' motion; only Throws on the spawner; M0.6 batch 3, plan `coop-mess-sync.md` (Q2472); merged (main 4bc92fc) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | the commit came back damaged and was repaired; `agent_finish.sh` took the second `-m` as the subject, so the branch commit's first line is its body (left as is; the merge commit names it) |
| Cost | 18,662,509 tokens, 100 tool calls, 29m38s (Opus) |
| Time | the agent ran about 30 min |
| Surprises | join of the zoo's 2,039 Socks 132 KB to 19.7 KB; mid-pour 256 KB to 90 KB; a rested 4,039-Sock join 110 KB (over the 100 KB placeholder); pour bytes kept at about 60 KB/s; game code +257 −36 |
| Stop rules | none hit |
| Looks | none (a Guest now sees moving Socks, as the plan says) |
| Decisions | Q2472 |

---

| Ticket | coop/09, the Hands and Throw in co-op: a Guest's pick, drop and Throw ghosts (Q2220, Q2221, Q2473), wheel at once, refusals and the 2 s timeout, Throws on the stamped stream seen by all, Hands keyed by player id, each Guest's own HandsTuning clamped on the Host, the ghost's cloth flat before rest; PROTOCOL 12; M0.6 batch 3; merged (main 44e2537) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (sent back by the lead: Z1, D13 and G08/G09 were in the Design but left as `[later]`) |
| Corrections | the agent's interim "a Teammate uses the Host player's tuning" contradicted D13; replaced |
| Cost | 47,139,201 tokens, 194 tool calls, 55m25s (Opus) |
| Time | the agent ran about 55 min over two rounds |
| Surprises | one Throw about 5.6 KB/s, four 22 KB/s; the 2,000 pour 54.9 KB/s reliable at 50 ms; in-process tests had hidden a Guest's capacity of 1; game code +1348 −69 |
| Stop rules | two looks and wording questions came back (Q2481, Q2482) |
| Looks | none |
| Decisions | Q2473-Q2482 |

---

| Ticket | coop/10, knockdown and drag with Godot's own ragdoll: full-charge Sock and Pair Throws knock down, the 4-bone PhysicalBone3D ragdoll on the Host with a stamped pose eased at 12/s elsewhere, the Hands dropped as a leaver's, the head camera with the vignette and the own body, getting up, drag and struggle, the body outline, message, sound and rumble, a knockdown station; PROTOCOL 13; M0.6 batch 4 (Q2437, Q2483-Q2498); merged (main f618311) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (the outline, Q2498, and a clearer drag still) |
| Corrections | stopped by the weekly usage limit mid-build and resumed; each commit came back damaged on the mounted drive and was repaired |
| Cost | 50,972,998 tokens, 175 tool calls, 2h20m (Opus) |
| Time | about 2 h 20 min over three rounds |
| Surprises | a latent Mess-settle fault (two Socks resting inside each other with 1 or 3 extra Socks in the zoo): core/49; pose stream about 2.0 kB/s per knocked player; game code about +1,770 |
| Stop rules | stopped at the vignette's first still (approved Q2497) |
| Looks | builds/review-knockdown/ |
| Decisions | Q2483-Q2498 |

---

| Ticket | core/49, a pour left two Socks inside each other: the spout now checks its own wave's earlier picks; the test counts Socks pressed within Jolt's slop (Q2499) and fails a Sock made inside another; merged (main d2b9087) |
| Planned vs actual | 0 planned (found by coop/10), 1 actual |
| Redo count | 1 (sent back after the designer's Q2499) |
| Corrections | the extra-record count was a red herring: it changed the ids and Jolt's order, not the pour |
| Cost | 11,450,421 tokens, 93 tool calls, 45m48s (Opus) |
| Time | about 46 min over two rounds |
| Surprises | about 200 of 500 Socks rest pressed into another (deepest about 21 mm), 0-6 a run measured past 22 mm by sharp boxes; a rarer fault (a Sock 116 mm under the floor) went to core/50; game code +115 −31 |
| Stop rules | the slop question went to the designer (Q2499) |
| Looks | none |
| Decisions | Q2499 |

---

| Ticket | core/50, a heap Sock sank 116 mm under the floor: Jolt's position solve pushed a Sock touching the 0.2 m floor past its middle in one step; a falling Sock moved farther than its motion explains into a floor or wall is put back 1 cm higher with its fall stopped; a pressure rest never moves a Sock; a new `under` watch fault; merged (main bcacadf) |
| Planned vs actual | 0 planned (found by core/49), 1 actual |
| Redo count | 0 |
| Corrections | the mounted-drive repair folded the agent's first commit onto main's tip in its worktree; the agent reset its own branch and recommitted; main was untouched. The designer's uncommitted editor edits blocked the merge and were discarded on the designer's word |
| Cost | 36,713,733 tokens, 180 tool calls, 1h22m (Opus) |
| Time | about 1 h 22 min |
| Surprises | never seen with floors 0.4 m thick or with Jolt's speculative contacts off; game code +100 −9 |
| Stop rules | none hit |
| Looks | none |
| Decisions | none |

---

| Ticket | coop/11, a Guest's own Throw looked weaker and jumped (from the designer's play): the ghost aimed from the first-person hand, its body had no physics material (died on the first touch), and the Host's flight time read a step ahead; merged (main 70c6eb5) |
| Planned vs actual | 0 planned (from play), 1 actual |
| Redo count | 0 |
| Corrections | stopped when the session ended and resumed from its worktree |
| Cost | 8,268,483, 64 tool calls, 11h11m (Opus) |
| Time | see cost |
| Surprises | ghost 0.50 m off the Host's flight before, 0.0000 m after; the two-window check is the designer's |
| Stop rules | none hit |
| Looks | none |
| Decisions | Q2221, Q2481 |

---

| Ticket | assets/05, Socks look like knitted wool: one seamless knit tile (normal, roughness, cavity) from Blender, tiled by the sock shader under every Design, faded with distance; merged (main 4a86d7a) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | see the agent's report (Opus) |
| Time | see cost |
| Surprises | game code +186 −27 |
| Stop rules | none hit (Q2504: built to the end, reviewed in the batch strip) |
| Looks | builds/review-assets-05/sock-wool-before-after.png |
| Decisions | Q2500, Q2504 |

---

| Ticket | assets/06, fabrics get a soft rim sheen: StandardMaterial3D rim 0.35, tint 0 on the 14 fab_* materials; merged (main 4a86d7a) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | see the agent's report (Opus) |
| Time | see cost |
| Surprises | game code +44; the rim is per material, no shared value |
| Stop rules | none hit |
| Looks | builds/review-assets-06/strip.png |
| Decisions | Q2501, Q2504 |

---

| Ticket | assets/07, furniture devices: opening sounds for 19 openables, the piano's 88 sampled keys, a real planar wall mirror with the own body in it, the dust sheet on a locked Cabinet (not aimable while sheeted); merged (main 4a86d7a) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (Q2513: the sheeted Cabinet made unaimable, as old) |
| Corrections | stopped at the 5-hour limit and resumed |
| Cost | about 850k subagent tokens (Opus) |
| Time | see cost |
| Surprises | game code +4169 −10; a second player body for the mirror; docs/architecture.md clash with house/04, resolved |
| Stop rules | none hit |
| Looks | builds/review-furniture-devices/furniture-devices-strip.png |
| Decisions | Q2502, Q2505-Q2508, Q2513 |

---

| Ticket | house/04, the house is the main scene (F5): built from the kit, furnished as the old house, noon light plus the old lamps, the wainscot, the shaft walls, the roof marks fixed, the outside doors shut; old houses A and B gone from the zoo; merged (main 4a86d7a) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (Q2514: the outside doors shut) |
| Corrections | stopped at the 5-hour limit and resumed; a damaged commit on the mounted drive, its branch soft-reset and recommitted |
| Cost | about 830k subagent tokens (Opus) |
| Time | see cost |
| Surprises | game code +5424 −6238; LevelNet added (the house may not use the zoo's ZooNet); no Socks in the house yet (house/05) |
| Stop rules | none hit |
| Looks | builds/review-house-04/ |
| Decisions | Q2503, Q2509-Q2512, Q2514, Q2515 |

---

| Ticket | core/51, the level runtime scene: the player, co-op and Mess nodes in one sealed `level_runtime.tscn` that the house, the zoo and a one-box example level each instance (Q2517, by composition); ZooNet folded into LevelNet; merged (main 3607fed) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | 224k subagent tokens, 109 tool calls, 25 min (Opus) |
| Time | see cost |
| Surprises | about 280 test path lookups changed to LevelRuntime.of(); Part ids now Runtime/Socks/...; ReturnSpot stays in each level |
| Stop rules | none hit |
| Looks | builds/review-level-runtime/level-runtime-before-after.png (0 px differ) |
| Decisions | Q2517 |

---

| Ticket | core/52, the Sock generator: one SockArea box finds landing places (floor, tops, insides, under-gaps) and previews them as dots in the editor; Socks laid at rest from the level's seed by the Host; heaps, exclusions, hidden share 0.3, straight-line mates, under-edge strips, washer thinning, stair trail; a zoo station; merged (main baaf279) |
| Planned vs actual | 1 planned (two steps: list, then build), 1 actual |
| Redo count | 0 |
| Corrections | none |
| Cost | about 640k subagent tokens (Opus) |
| Time | about 42 min for step 2 |
| Surprises | game code +1762 −13, tests +450; the stills draw the preview in game (the editor run headless drew the same 110 dots); the kit's stairs collide as a ramp (Q2530) |
| Stop rules | the behaviour list stopped for the designer, as planned |
| Looks | builds/review-sock-generator/ |
| Decisions | Q2518-Q2530 |

---

| Ticket | assets/09, model fixes from the designer's walk: a body-coloured sill closes the car's window slit, the car's two doors open separately ("Car Door"), the whiteboard's pens lie apart; merged (main 88a5ac5) |
| Planned vs actual | 0 planned (from play), 1 actual |
| Redo count | 0 |
| Corrections | the merge's suite hit an ENet port taken by a parallel test run; rerun green; free ports added to coop/12 |
| Cost | about 263k subagent tokens, 154 tool calls, 26 min (Opus) |
| Time | see cost |
| Surprises | fkit.py's mesh names doubled on import (car_car_Body) and were fixed; 29 furniture openings now |
| Stop rules | none hit |
| Looks | builds/review-assets-09/ |
| Decisions | Q2536 |

---

| Ticket | house/05, the Mess in the house: Sock areas per floor at the old stage counts (990 Socks), all eight Cabinets, stair Socks flat on the treads; F5 plays pick, pair, shelve and Coins, a Guest sees the same Mess; merged (main f3b6de4) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | the merge stopped on 250 mesh files re-imported by the suite run (churn, restored in the integration worktree) |
| Cost | about 296k subagent tokens, 156 tool calls, 31 min (Opus) |
| Time | see cost |
| Surprises | laying takes 1.7 s in one frame (house/09); the attic trunk's inside is 10 cm too high (house/09); the full suite now takes 282 s |
| Stop rules | none hit |
| Looks | builds/review-house-05/house-05-old-beside-new.png |
| Decisions | Q2530, Q2541-Q2544 |

---

| Ticket | core/55, reseeded and starting Heap Socks hung frozen in the air: the Heap stacked on the biggest Sock's box (15-20% of the station's Socks up to 0.36 m up), nothing woke them; now stacked on the real Socks, and a laid Sock with nothing within 1 cm under it wakes and falls (Q2531); merged (main 6341cfc) |
| Planned vs actual | 0 planned (from play), 1 actual |
| Redo count | 0 |
| Corrections | the lead's guess (old Socks in the rays) was wrong; a damaged commit, the branch soft-reset and recommitted |
| Cost | about 237k subagent tokens (Opus) |
| Time | about 38 min |
| Surprises | game code +136 −4; a reseed keeps clear of a standing player |
| Stop rules | none hit |
| Looks | none |
| Decisions | Q2531 |

---

| Ticket | coop/12, the M0.6 close-out: co-op cases at 0 and 50 ms, guard tests, a leaver's looks-only bodies, free test ports, the co-op cost, code map and review guide; merged (main 20696e9) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | free ports added mid-run (an ENet port clash broke a merge) |
| Cost | about 304k subagent tokens (Opus) |
| Time | about 28 min |
| Surprises | the smooth knocked fall (E62/F72) cannot be checked headless: in the designer's run |
| Stop rules | none hit |
| Looks | none |
| Decisions | Q2534 |

---

| Ticket | house/07, from the designer's walk: 7 outer-wall pieces crossing room lines cut there (no stray strip of the next room's colour), the basement hatch closed, the bathroom trim a raised strip; merged (main 16c3c78) |
| Planned vs actual | 0 planned (from play), 1 actual |
| Redo count | 0 |
| Corrections | the raised trim (Q2538) added mid-run; the first merge refused while the lead edited decisions.md |
| Cost | about 205k subagent tokens (Sonnet) |
| Time | about 50 min |
| Surprises | the partitions were already right; the fault was outer walls |
| Stop rules | none hit |
| Looks | builds/review-house-07/ |
| Decisions | Q2538, Q2563 |

---

| Ticket | house/06, the old lamp rules: by day only the basement's lamps lit, each lamp lights only its own floor (light layers), a night switch for a later day cycle; merged (main e370c34) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 0 |
| Corrections | the merge refused twice on the designer's editor re-saves (committed as editor format) |
| Cost | about 158k subagent tokens (Sonnet) |
| Time | about 12 min |
| Surprises | the old basement's warm daytime fill not ported (house/10, Q2572) |
| Stop rules | none hit |
| Looks | builds/review-house-06/ |
| Decisions | Q2515, Q2572 |

---

| Ticket | coop/13, from the designer's M0.6 run: the Host let a Guest's Throw and drop go from the avatar's hand 0.6 m under the Guest's view (no arc, a slide down); now every Throw and drop leaves the thrower's own hand (within 2 mm of the Host's flight), the Guest's drops keep core/50's floor guard, settling heaps glide 0.2 s onto the Host's rest (Q2577); merged (main 682f8f6) |
| Planned vs actual | 0 planned (from play), 1 actual |
| Redo count | 1 (Q2577: the glide) |
| Corrections | none |
| Cost | about 565k subagent tokens (Opus) |
| Time | about 35 min |
| Surprises | equal heaps at rest were already met: the difference was mid-settle; Host 63.9 KB/s and 17.7 ms mean during a 2,000-Sock pour |
| Stop rules | none hit |
| Looks | none |
| Decisions | Q2573, Q2577 |

---

| Ticket | house/09, laying without a freeze: the house's Socks are laid in timed slices behind the loading card (`SliceClock`, longest slice 11.1 ms of 14), stair-trail Socks stay on their treads (a tread counts as support), trunks hold 6 and 5 (Socks stack inside any piece, Q2581); merged (main d6810de) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 1 (the review's fixes: flaky slice timing, trail Socks falling, trunks) |
| Corrections | none |
| Cost | about 500k subagent tokens (Opus), fixes round |
| Time | about 95 min, fixes round |
| Surprises | the kitchen real-path case's Heap pick never reached the Hands (core/60); tread layer 128 shared with the Mate capsule |
| Stop rules | none hit |
| Looks | builds/review-house-09/ |
| Decisions | Q2576, Q2581 |

---

| Ticket | core/58, M4's first build: title (Solo, Multiplayer, Options, Quit; Zoo in debug builds, Q2580), Options, Licence, ESC menu, one loading screen ("Loading the house...", Q2579; "Joining..." for a Guest) driven by house/09's laying, saves through the `SaveStore` seam (local file and memory backends, Steam Auto-Cloud ready), autosave; Solo/Host go straight into the house until the Lobby (Q2561); merged (main 67c76a3) |
| Planned vs actual | 1 planned, 1 actual |
| Redo count | 2 (Q2579: the loading text always; the ESC still retaken after the laying) |
| Corrections | none |
| Cost | about 577k subagent tokens |
| Time | about 3 h with the waits on house/09 |
| Surprises | S01 aimed at the wrong kitchen Sock after house/09 (see core/60) |
| Stop rules | none hit |
| Looks | builds/review-menus/ |
| Decisions | Q2540, Q2553-Q2563, Q2575, Q2579, Q2580 |

---

| Ticket | core/59, the ESC close key at the top right of every dialogue (Options, Licence, ESC menu, Multiplayer, Join) replacing the bottom-left Back; the End-session question's Cancel removed (Q2578); merged (main c86b0e5) |
| Cost | about 104k subagent tokens |
| Surprises | a lead mistake: the first merge's worktree was removed while it still ran; rerun clean |
| Looks | builds/review-esc-close/ |

---

| Ticket | core/61, the Lobby design: 74 old details (`m4-lists/02-lobby.md`), `docs/architecture/lobby.md`, build tickets core/62-67 (Q2582-Q2587); merged (main 7961957) |
| Cost | about 234k subagent tokens |

---

| Ticket | core/60, the Heap's top Sock "never reached the Hands": the pick was fine; the tests' open-Sock probe started inside the Sock above; the kitchen real path aims at a Heap top again; merged (main bfb77e6) |
| Cost | about 97k subagent tokens (Opus) |

---

| Ticket | core/62, the game link: Session and Roster moved out of the level to a `GameLink` beside the current scene (Q2582), save ids kept (`Runtime/Session/Roster`), Guests spawned after their house handshake, synchronizers filtered for a loading Guest, PROTOCOL 14; merged (main ed98062) |
| Cost | about 312k subagent tokens (Opus) |
| Surprises | a title-started Host cannot reach an F5 `--join=` Guest (different Session paths); 3+ players: a loading Guest still gets another Guest's avatar spawn (both [later], for core/63) |

---

| Ticket | core/63, the Lobby scene and `LobbyState`: Solo (one place, Back / Continue / New Game, Q2583), Host and Join through the Lobby, Ready and Start, Start loads the house for all, the shared ESC key on Solo's question; stand-in view (the look is core/66); merged (main bf6c265) |
| Cost | about 266k subagent tokens (Opus) |
| Surprises | core/62's two gaps and a Lobby Guest's Hands numbers left over (core/68) |
| Looks | builds/review-lobby/ |
| Decisions | Q2582-Q2587 |

---

| Ticket | core/64, the name field on the Multiplayer page for Host and Join, cut at 16, ready for a Steam name (Q2585); merged (main 98b1500) |
| Cost | about 105k subagent tokens |

---

| Ticket | core/42, the Hand-off: right-click Hand-off with the pairing rule, "Not their mate" / "Hands full", the flight into the receiver's Hands with a sparkle, the catch by Throw (Q2588), a knocked-down Teammate refused (Q2589), Guest timeout 2 s, PROTOCOL 16; merged (main a6e1955) |
| Cost | about 444k subagent tokens (Opus) |
| Surprises | the Host's reach guard (new, technical); lines needing later pieces logged [later], none dropped |
| Looks | builds/review-hand-off/ |

---

| Ticket | core/41, Player stacking: a Sock stands on a Teammate's back disc (a plain collider, Q2591), inside any piece (Q2581), riding offset in the synced pose so others draw the rider glued on (Q2592), reach 2.5 m, the land sound on every machine and a silent jump (Q2593, Q2594), PROTOCOL 17; merged (main 1b83da9) |
| Surprises | the plain collider drew the rider behind on other screens, fixed by the riding offset; the merge stopped twice on editor uid re-saves |
| Looks | builds/review-player-stacking/ |
| Decisions | Q2581, Q2591-Q2594 |

---

| Ticket | core/54, the heap's flaky Sock: an asleep-while-tipping Sock woken, `pressure_spin` 1.5 rad/s, `push_slack` 0.02, "jumped" measured from the rest tick, jitter counted only for a wake that moves the Sock (5 mm / 3 degrees); 0 faults in 1350 pours; merged (main e7615b9) |
| Cost | about 246k subagent tokens (Opus) |
| Surprises | `flight_start:t01_heap` began failing in the full suite after this merge (core/69) |

---

| Ticket | core/68, the game link's gaps: a third player's spawn reaches only Guests in the house (a Host-owned Gate synchronizer), the F5 `--join=` path, a Lobby Guest's Hands numbers in `house_ready`, PROTOCOL 18; merged (main 83dd055) |
| Cost | about 224k subagent tokens (Opus) |
| Surprises | `session.gd` at 842 lines, a split left [later] |

---

| Ticket | house/08, the room Doors: leaves swing on the hinge, the laundry Door in the house, the Door's sound 1 m up (Q2595); merged (main 9752669) |
| Cost | about 432k subagent tokens |
| Surprises | 31 typed uids fixed with the new uid check; no Sock behind an open leaf and the leaf bevel stay [later] |
| Looks | builds/review-house-08/ |
| Decisions | Q2595 |

---

| Ticket | core/65, the World drawer and its pages in the Lobby, the Host's World list to Guests (`LobbyState.worlds`), a damaged World kept in place, PROTOCOL 19; merged (main becc751) |
| Cost | about 157k subagent tokens |
| Surprises | its merge of main was blocked by the moved kit pin; commit.sh now lets main's pin ride along |

---

| Ticket | core/43, hint arrows and pings: the ping wheel, ping marks seen by every player, the hint arrows at the screen edge, PROTOCOL 20; merged (main 725052d) |
| Cost | about 460k subagent tokens |
| Surprises | its merge of main met two clashes (sound catalogue, PROTOCOL), both resolved; `git merge` twice failed reading a tree it had just written, a retry went through; the X-ray, Mate Radar and Laundry bin arrow sources stay [later] for M4/M5 |

---

| Ticket | core/69, the flight_start heap flake: earlier cases change Jolt's body order and one poured Sock is pushed under the floor for a step before the Mess puts it back; the case now reads heights after the put-back; no game number changed; merged (main 0783a6a) |
| Cost | about 121k subagent tokens |
| Surprises | follow-up core/70: whether that Sock can be drawn under the floor for one frame (designer, 2026-11-24) |

---

| Ticket | maintenance/02, the suite's time: coop_knockdown and room_doors run the game clock at 2x (knockdown about 77 s to 35 s); merged on the designer's word with the rest in maintenance/03 (main 87c1c85) |
| Cost | about 86k subagent tokens |
| Surprises | the full run was 146-149 s after it (235-258 s before, partly other agents' runs sharing the 8 slots); coop_hands and coop_hand_off fail at 2x |

---

| Ticket | core/66, the Lobby look: players on plinths with their names, the World card at the top, the World settings drawer, World rows named by members (Q2596-Q2598); merged (main d506f7f) |
| Cost | about 174k subagent tokens |
| Surprises | the "Ada," cut and the drawer row's tiny details line stay [later] (Q2598) |
| Looks | builds/review-lobby/ |
| Decisions | Q2596-Q2598 |

---

| Ticket | core/67, the Lobby details: captions under Ready and Start, the pad route, UI hover sound, an invite hook on the transport, the Lobby's words in one place; merged (main 9be8097) |
| Cost | about 168k subagent tokens |
| Surprises | the pad's focus ring does not show (core/75, later, Q2645); captions stay 11 px (Q2644) |
| Looks | builds/review-lobby-details/ |
| Decisions | Q2644-Q2646 |

---

| Ticket | maintenance/04, session.gd split before batch A: Session keeps every RPC and PROTOCOL (20); the work moves to SessionPeer, SessionGate, SessionHouse, SessionGuard, SessionRelay; `coop.md` "Adding a verb"; no behaviour change |
| Cost | about 133k subagent tokens |
| Surprises | session.gd 842 to 337 lines; helpers resuming after an await now check the Session still exists |

---

| Ticket | core/70, a Sock pushed under the floor drawn for a frame: not seen (0 of 306 drawn frames with 4 pushes; the push lands at the next tick's start and the Mess puts it back in that tick); a drawn-frame floor watch added to mess_settle; no game change |
| Cost | about 125k subagent tokens |
| Surprises | t01_heap no longer gets a push on main; reproduced on the thin-floor pour |

---

| Ticket | core/75, pad focus: the old lit look ported (the selected control lifts 5 px, grows to 1.08 over 0.1 s, a gold glow fades in; only pad or keyboard selection lights it); UiSounds drives it for every control, opt-out by the meta `own_lit`; numbers in pad_focus_tuning.tres (Q2647-Q2650); merged (main 2ec8f85) |
| Cost | not recorded |
| Surprises | the first build invented a ring instead of the old look; an editor re-save dropped credits.tres's covers lists on main (restored, 1877358) |

---

| Ticket | core/100, a Sock drawn under the floor: bound to suite order, not load; a Sock pressed 13-18 mm into the floor under one Jolt pushed through is now put back; the drawn-frame watch counts only a push (Jolt's 0.02 m slop kept, the old game's, Q2604; 0.005 m a [later] question); merged (main bb48b63) |
| Cost | about 336k subagent tokens |
| Surprises | the ticket's guess (several steps a frame) was wrong; 10 full runs in a row passed |

---

| Ticket | core/76, Stages: the run's state and Rows; a New Game starts at Stage 1; the Stages station; the Run in house.tscn (no play change yet); debug --pairs-per-drawer; PROTOCOL 21; merged (main 987dd2b) |
| Cost | about 283k subagent tokens |
| Surprises | a dust_sheet timer fired on a freed Cabinet (fixed); cabinet.gd 641 lines |

---

| Ticket | core/78, carried things in the Hands: a Part and a bin take the whole Hands, go down at the crosshair, `handable` switch for Hand-off (on, the old way); merged (main 987dd2b) |
| Cost | about 275k subagent tokens |
| Surprises | Hands.loaded() crashed on a number key (fixed); hands.gd and player.gd over 600 lines |

---

| Ticket | core/84, voice lines as one JSON per speaker and the bake by command; VoiceMood, marks, optional per-recording timing; the washer's 21 lines carry the old times; merged (main 032e49e) |
| Cost | about 258k subagent tokens |
| Surprises | untagged old comments given all four triggers, as the old picker did |

---

| Ticket | core/89, the spray of Socks out of the washer's door; the Laundry station (moved to x 60, z 7 at merge, clear of Stages); merged (main 032e49e) |
| Cost | about 154k subagent tokens |
| Surprises | none |

---

| Ticket | assets/11, the 17 Collection Cabinets to six Drawers, pixel-identical to the old stack at 2 and 6 Rows; Segments 4-6 hidden until core/81; merged (main 032e49e) |
| Cost | about 157k subagent tokens |
| Looks | builds/review-assets-11/ |
| Surprises | a missing blob in the git store on first commit, rewritten; shot_hooks.gd 1160 lines |

---

| Ticket | core/82, the Stage bar and its phases: provider words and icons from Stages, the fold with its pop, the group `stage_bar_goal` for the First wash; merged (main b17c17c) |
| Cost | about 167k subagent tokens |
| Surprises | one bar for every phase (the old had two boxes) |

---

| Ticket | core/85, Voices and Subtitles: the Voices autoload, VoiceChannel, SubtitleRow, the picker, the muffle and the music duck; the Voice station at x 78; merged (main b17c17c) |
| Cost | about 263k subagent tokens |
| Surprises | none |

---

| Ticket | core/90, the Laundry bin entity: graybox heap scaled by fill, the tip, `handable` on (the old way), hooks for core/86, core/88, core/93; merged (main b17c17c) |
| Cost | about 153k subagent tokens |
| Surprises | none |

---

| Ticket | core/77, a Stage's Socks: only open floors hold Socks, even shares after each Fix, a high-spot pass with two players; Stage 1 laid behind the loading screen; held records until the First wash; merged (main 8f19925) |
| Cost | about 279k subagent tokens |
| Surprises | the high-spot pass never placed a Sock in a station (no top over 1.7 m), left to core/91's house case |

---

| Ticket | core/81, the Cabinets grow: the new Drawers drop in at once with a thunk and dust (Q2620); only the current Rows' Drawers shown; CabinetGrowth split out of cabinet.gd; merged (main 74260a4) |
| Cost | about 161k subagent tokens |
| Surprises | coop_knockdown:real_path went FLAKY in a run (core/101) |

---

| Ticket | core/79, Machine Parts: the Part pops from the Cabinet that took the last Pair, lies turning and bobbing in its Looks (assets/12's contract, graybox until the designer's yes), fits in the washer's slot; "Fit the new filter"; merged (main f9d5177) |
| Cost | about 264k subagent tokens |
| Surprises | the old bob rate is 2.2 rad/s, not Hz; the pop spot kept clear of gift boxes waits for batch B's Gifts |

---

| Ticket | core/86, the washing machine entity and its comments: it replaces the house marker, stare comments silent before the First wash (Q2636), comment sets by Stage; the Washer station at x 98; merged (main f528b6b) |
| Cost | about 319k subagent tokens |
| Surprises | its looks contract broke the asset lint's shape and its station lay outside the zoo's Mess bounds (both fixed at merge); the disk filled with test mirrors mid-merge |

---

| Ticket | core/83, run tallies, record, Whiteboard and Tab: Pairs shelved, Socks picked, Coins earned per player; a Tab overlay key; merged (main 3d99183) |
| Cost | about 190k subagent tokens |
| Surprises | the disk filled mid-finish (test mirrors in /tmp); a Guest's counting tested by snapshot, not two machines |

---

| Ticket | core/101, coop_knockdown:real_path flaky: the click came before the Host heard the Guest's new place; the test now waits for it; no game change; merged (main 3d99183) |
| Cost | about 154k subagent tokens |
| Surprises | coop_hands, coop_carry, coop_pings may share the race (core/103); a run.py hung 25 min holding perf.lock |

---

| Ticket | core/80, floor locks: the door and the gate, the padlock hint, the pop, the chain, the one-way swing, the lamps; graybox Looks keyed as assets/10's models; merged (main 3c1fc28) |
| Cost | about 257k subagent tokens |
| Surprises | assets/10's Looks need `leaf` as an AnimatableBody3D |

---

| Ticket | core/87, the broken washer's looks: sparks, smoke, buzz, rumble, flash and the drum light's flicker by mood, calmer each Fix; `set_cutscene` for core/88; merged (main 3c1fc28) |
| Cost | about 160k subagent tokens |
| Surprises | the old room-lamp flicker belongs to the washes (carried into core/94, core/96) |

---

| Ticket | core/88, the cutscene frame: shots, cuts, fades, only the washer drawn, the Host's skip (Space, pad Start), the respawn; the washer station's Play pillars; merged (main 3c1fc28) |
| Cost | about 263k subagent tokens |
| Surprises | the knockdown wash's respawn and the First wash's bob carried into core/98, core/94 |

---

| Ticket | core/102, house:h09 flaky: the laying behind the loading screen outlasted a fixed frame wait on a busy machine; the test waits for the screen to lift (20 s floor); no game change; merged (main 3c1fc28) |
| Cost | about 126k subagent tokens |
| Surprises | the same race in case_real_path_loading_screen, fixed too |

---

| Ticket | core/95, the Final screen: a column per player, the Pairs popping in, the totals, the skip; FinalSummary for core/96; stills in builds/review-final-screen/; merged (main 917166b) |
| Cost | about 261k subagent tokens |
| Surprises | its station at x 116 took the zoo's Mess bounds to x 160 at merge; SOURCES rows moved back into the table |

---

| Ticket | core/98, the knockdown wash: drag a knocked Teammate to the door, the spin, the burst out, ending at the respawn; the dragger let through the tumbling body; merged (main 2d30223) |
| Cost | about 283k subagent tokens |
| Surprises | without letting the dragger through, the ragdoll flew off at ~20 m/s |

---

| Ticket | core/91, the house's run: Stage by Stage in the house, the Cabinets' unlock Stages, the floor locks placed, the Stage 1 laying and high-spot cases, the New Game page with the debug Pairs per Drawer slider; merged (main beee71a) |
| Cost | about 313k subagent tokens |
| Surprises | the lock door swings the other way and the gate's hinge moved, to keep the old swing with the chain on the players' side |
