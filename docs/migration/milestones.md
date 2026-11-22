# Milestones

The order the designer set on 2026-11-19 (Q2207-Q2209, Q2214). The lead writes state changes here when a
milestone's tickets are all approved. A piece inside a milestone moves planned, design agreed, built, approved.
M1 and M2 run beside M0.5 and M0.6, not after them.

| | Milestone | Done when | State |
|---|---|---|---|
| M0 | Setup | The repository is set up from starter kit 8.0 (was 7.1) with the port pack on top; the checks pass; the reference clone at `v0.1.1` is in place; the first commit is pushed | done 2026-11-20 (pushed to origin by the designer) |
| M0.5 | The core in a single-player zoo | In a flat graybox zoo scene (edited in the editor, one station per feature, the game's real entities): movement, handling Socks, pairing, one Cabinet. A true vertical slice of the core (Q2296): the core's sounds and rumble and its polish details are in it, as the old game has them. One player, but every change already goes through the shared-state path: the player is a Host of one (Q2207, Q2208, Q2211, Q2212) | built 2026-11-22; closing (Q2425): the designer's zoo run and code review are left |
| M0.6 | The co-op zoo base | The same zoo with a Host, a Guest and a late joiner: avatars seen by the others every frame (Q2223), a Guest's pick and Throw as decided (Q2220-Q2222, Q2226), a long random player id in the profile (Q2224), and the full knockdown with Godot's own physical-bone ragdoll (Q2225) | planned |
| M1 | Assets | Models and UI art ported by the port rules; the core's models and the avatar rig first; a shared material library; things built by code become models or scenes. Approved in family batches, each with a before and after strip (Q2151-Q2153, Q2177, Q2178, Q2216) | planned, beside the zoo |
| M1.1 | Sound | The sound system is built in M0.5 for the core (Q2296); M1.1 ports every other old sound and pad rumble, ported with the old clips and numbers, made plug-and-play: a sound is added or swapped by dropping in a file and naming it, with no code change. The list from the four merged pieces is in `old-details-backlog.md` (Q2278) | planned |
| Polish | The polish pass | The core's polish details are done in M0.5 (Q2296); this pass holds those of later pieces | planned |
| M2 | The house | Built by hand in the editor from a half-metre kit and the ported props; Play walks through it in first person (Q2154-Q2157, Q2175, Q2176) | planned, beside the zoo |
| M3 | The core loop in the house | The Mess, Hands, Throws, Pairs and Cabinets (with Doors and Drawers) play in co-op in the house; the Mess bench is no slower than the old game's (Q2161, Q2168) | planned |
| M4 | The frame of a run | Stages, the Laundry day, menus, saves and the lobby (with the proving token for the player id); screens are scenes on one Theme (Q2163) | planned |
| M5 | Features by need | Each switched-off or planned feature (the vacuum devices, Hampers, the Grotto, Dirty Socks, the Cat, cutscenes, ...) is ported when the designer calls it, each first as a zoo station (Q2144, Q2214) | planned |

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
