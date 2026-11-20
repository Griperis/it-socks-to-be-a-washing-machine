# Milestones

The order the designer set on 2026-11-19 (Q2207-Q2209, Q2214). The lead writes state changes here when a
milestone's tickets are all approved. A piece inside a milestone moves planned, design agreed, built, approved.
M1 and M2 run beside M0.5 and M0.6, not after them.

| | Milestone | Done when | State |
|---|---|---|---|
| M0 | Setup | The repository is set up from starter kit 8.0 (was 7.1) with the port pack on top; the checks pass; the reference clone at `v0.1.1` is in place; the first commit is pushed | done 2026-11-20 (pushed to origin by the designer) |
| M0.5 | The core in a single-player zoo | In a flat graybox zoo scene (edited in the editor, one station per feature, the game's real entities): movement, handling Socks, pairing, one Cabinet. One player, but every change already goes through the shared-state path: the player is a Host of one (Q2207, Q2208, Q2211, Q2212) | planned |
| M0.6 | The co-op zoo base | The same zoo with a Host, a Guest and a late joiner: avatars seen by the others every frame (Q2223), a Guest's pick and Throw as decided (Q2220-Q2222, Q2226), a long random player id in the profile (Q2224), and the full knockdown with Godot's own physical-bone ragdoll (Q2225) | planned |
| M1 | Assets | Models and UI art ported by the port rules; the core's models and the avatar rig first; a shared material library; things built by code become models or scenes. Approved in family batches, each with a before and after strip (Q2151-Q2153, Q2177, Q2178, Q2216) | planned, beside the zoo |
| M1.1 | Sound | Every old sound and pad rumble, ported with the old clips and numbers, made plug-and-play: a sound is added or swapped by dropping in a file and naming it, with no code change. The list from the four merged pieces is in `old-details-backlog.md` (Q2278) | planned |
| Polish | The polish pass | The old game's screen text, feedback looks and small motions left out of the zoo pieces, ported as they were: the list in `old-details-backlog.md` (Q2279-Q2281); placed in the order when the designer calls it | planned |
| M2 | The house | Built by hand in the editor from a half-metre kit and the ported props; Play walks through it in first person (Q2154-Q2157, Q2175, Q2176) | planned, beside the zoo |
| M3 | The core loop in the house | The Mess, Hands, Throws, Pairs and Cabinets (with Doors and Drawers) play in co-op in the house; the Mess bench is no slower than the old game's (Q2161, Q2168) | planned |
| M4 | The frame of a run | Stages, the Laundry day, menus, saves and the lobby (with the proving token for the player id); screens are scenes on one Theme (Q2163) | planned |
| M5 | Features by need | Each switched-off or planned feature (the vacuum devices, Hampers, the Grotto, Dirty Socks, the Cat, cutscenes, ...) is ported when the designer calls it, each first as a zoo station (Q2144, Q2214) | planned |

## What changed from the first plan
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
