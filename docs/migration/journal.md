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
| Ticket | core/01, the game's Player and the movement station, M0.5, approved and merged (dd134fc) |
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
| Ticket | core/02, the Mess and Hands Parts, pick, hold, drop, zoom, turn; M0.5; approved and merged (e035aa2) |
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
| Ticket | core/08, charge, ring, lob, Throw speeds, the wake, out of bounds; M0.5; approved and merged (49f22f4) |
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
| Ticket | core/03, two mates fuse in the Hands into a Pair (sock ball), the pairing moment, falling Pairs; M0.5; approved and merged (55ead41, main a60e724) |
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
| Ticket | core/04, the Cabinet with Drawers and a Door, shelving by click and by Throw; M0.5; approved and merged (dc4a350, main 703620a) |
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
| Ticket | core/10, the zoo owns one Mess, Hands and Coins; stations join it and still run alone; M0.5; approved and merged (6f07aa6, main c42ca7d) |
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
| Ticket | core/12, both Socks of every Design laid out by Collection with their info, real Mess Socks; M0.5; approved and merged (8c30aaa, main 9a6e58c) |
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
| Ticket | core/09, cloth (spring bones), glide, pick fly-up, pairing fly-in, shelving flight, drawer shut; M0.5; approved and merged (31e8061, main d961c2c) |
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
| Ticket | core/13, lying Socks as server bodies and MultiMesh instances, the moving budget, wakes and pushes, the old physics numbers; M0.5; approved and merged (753ab66, main c111ee1) |
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
| Ticket | core/19, the Throw leaves from the hand, the pairing ring around the ball, readable station signs; approved and merged (976f3aa, main c111ee1) |
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
| Ticket | core/14, the rules back to the old game (free mouse, nearer aim, woken pick, Pair last, drop on a Pair, drawer-front shelve, mid-air pick); approved and merged (c747e6a, main af34977) |
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
| Ticket | core/17, the sound system (SoundEvent Resources, the old buses and mix, footsteps by surface, muffle, ambience, Settings and Sounds); built ahead of batch 6 and merged (f79dfa2) |
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
| Ticket | core/18, the picture and theme (old noon HDRI, AgX, grade, vignette, SSAO, glow, AA, presets, old crosshair); built ahead of batch 7, approved and merged (f9dadaf) |
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
