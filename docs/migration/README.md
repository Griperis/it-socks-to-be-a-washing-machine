# Migration: index

Reference commit (the old game, `reference/it-socks/`): _filled in at START-HERE step 5: hash, date_ (tag `v0.1.1`).
Planning page (private to the designer): https://claude.ai/artifact/5sjTiUUdoSFHDeEwtkMAe2 . Its source is
`page/native-godot-move.html`, unedited. To change the page: read it with the Artifact tool first, then republish to the
same URL. Its first tab, "The port", is the current plan; the other tabs are the older research and are marked so.

Research files are depth, not rules: read the head of one (`head -40`), then the section you need.

## Own files (the pack's)
| File | One line | Read when |
|---|---|---|
| `decisions.md` | Every decision Q2143-Q2226 by theme, the lead's readings, what is superseded in the copied research | before asking anything |
| `milestones.md` | M0 to M5 with done-when lines and state, what changed from the first plan, the looks baseline | planning, closing a milestone |
| `journal.md` | The journal format and the first entries | closing any ticket |
| `since-the-research.md` | What merged after the research was written (the vacuum devices, Simple and Patterns), the tags, the capture tour, open placeholders, six lessons, the looks baseline | first, before any research file |
| `claude-md-section.md` | The lines this project adds to the kit's `CLAUDE.md` | START-HERE step 4 |
| `baseline/` | The 70 baseline stills of the old game, the views file, the numbers | comparing looks |
| `open-questions.md` | Everything waiting on the designer, verbatim with its source, and the source conflicts | before a grilling |

## Copied research, unedited (written 2026-11-19 by agents; "judged" marks reasoning, not measurement)
| File | One line | Read when |
|---|---|---|
| `coop-structure-for-the-port.md` | **Current.** Every old co-op mechanism mapped onto Parts, synchronizers, the spawner and one bulk Mess, with risks | before any design in M0.5 and M0.6 |
| `hl-multiplayer-report.md`, `hl-multiplayer-run.log` | **Current.** Godot's own multiplayer nodes tested in 4.7.1: what a synchronizer and a spawner do and do not do, costs, limits | choosing how a piece of state travels |
| `ids-roster-guards.md` | **Current.** How Godot and other games identify things for saves and the network; roster; packet guards | ids, the roster, saves |
| `godot-demo-projects.md` | **Current.** Patterns from Godot's official demo projects that fit this structure | harness, settings, pause, scene changes |
| `new-project-start.md` | The first preparation plan | rarely: mostly superseded by the starter kit (`decisions.md`) |
| `risks-and-slices.md` | 22 risks with tests and stop rules (part A, still valid); four slices (part B, replaced by the zoo); the journal format | a stop rule; a risky bet |
| `state-and-coop.md` | The chapter "State and co-op": classes, full code, six forks, ten questions | background to the kit's scene parts; superseded where `coop-structure-for-the-port.md` differs |
| `state-slice-test.gd.txt`, `state-slice-run.log` | The throwaway Host + Guest + late Guest test and its 19 of 19 run | writing co-op tests |
| `assets-inventory.md` | Every asset family counted, how made, house-kit facts, 16 technical problems | M1, the port rules, the house kit |
| `behaviour-core-loop.md` | 107 when-then behaviours, invariants, controls, disagreements, questions | M0.5 and M3: the behaviour lists to approve |
| `feature-catalogue.md` | 56 built and 83 planned things, what waits on the designer, rows to mark | choosing a feature (M5, M6) |
| `godot-rules.md` | Godot rules audit | writing GDScript and scenes |
| `authoring-and-editor-wiring.md` | How hand authoring, editor wiring and instanced scenes behave | M1, M2 |
| `code-shape.md` | The old code-shape report (shape A picked; Q2147 chose shape B) | class design; read headings first, 125 KB |
| `digests/digest-core-and-coop.md` | Every designer answer on the core loop, physics, co-op, lobby, knockdown | porting those features |
| `digests/digest-house.md` | The house, rooms, furniture, Doors, Elevator, exterior, light, graphics | M1, M2 |
| `digests/digest-progression.md` | Stages, Upgrades, Collections, Coins, wardrobe, saves | M5, M6 |
| `digests/digest-devices-cat-story.md` | Devices, the Cat, the Grotto, rogue machine, secrets, intro, story | M6 |
| `digests/digest-maintenance-and-process.md` | Graphics and controls rules; "how we work", what went wrong, what cost rework | process questions; parts 2-4 |

## Not copied (in the reference clone)
The old docs (`reference/it-socks/docs/architecture.md` and `docs/architecture/`, `docs/TESTING.md`, `docs/perf/tools.md`,
`docs/art/`), the ticket vault `docs/llm/` (598 files; cite by path), the other research under `docs/research/nativize/`
(netcode, rigging, unify slices, move plan, the `hl-multiplayer/` test project), `data/`, `assets/`, `audio/`, `game/`, `tests/`, `tools/`. House questions:
`python3 reference/it-socks/tools/layout.py --help`.
