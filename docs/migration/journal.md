# Migration journal

Kept from the first day; the retrospective and the reusable skills are written from it at the end. Never summarised
in place. The agent drafts its entry in its report; the lead copies it in at merge and adds the cost from
`python3 tools/agent_cost.py --by ticket --json` (never from memory). A merge without its journal line is incomplete.

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
