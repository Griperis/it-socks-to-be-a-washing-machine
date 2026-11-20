---
name: migration-port
description: Port one piece (an entity, a prop, a class, a feature) from the reference clone of the old game into this project. Use when a ticket is a piece of the port, when starting a zoo station or a milestone ticket, and when closing one with its walkthrough and journal line.
---

# Porting one piece

Nothing is carried over unexamined: read the reference, explain it, then write it fresh. "Every line of code has
to fight for its life" (Q2143): before adding a line, ask whether an existing piece or a Godot node already does
the job. The designer approves each stage. The kit's skills own the mechanics (tickets and branches:
`ticket-agents`; asking: `designer-grilling`; merging: `lead-integrator`; stills: `review-material`).

1. **Behaviour list.** Read the reference (`reference/it-socks/`, and in `docs/migration/`:
   `behaviour-core-loop.md`, the digests, `feature-catalogue.md`) and write the ticket's `## Behaviour list`:
   when-then lines in plain words and glossary terms, plus the invariants. The lead asks the designer to approve
   or change it. Mark every line that the designer's later answers changed (`decisions.md`; for co-op,
   Q2220-Q2226). `since-the-research.md` lists what the research does not know.
2. **Design and grilling, before any code.** In `## Design`: the entities and Parts, their state fields, the
   Commands, what Looks must provide (node and animation names for `looks_contract.json`), a code sketch, what
   is shared with other pieces and who owns it. For each piece of state, say which kind it is
   (`coop-structure-for-the-port.md`): decided state (a Part, written by the Host's answer), continuous state one
   machine owns (a synchronizer), a thing created during play (the spawner), or part of the Mess. The lead asks
   the open questions in one dialog. A sketch is for deciding, not for merging.
3. **A zoo station first.** The piece is built as a real entity and placed at its own station in the zoo scene
   (`zoo-design`): graybox Looks until the model is ported. Never a second, zoo-only version of it.
4. **Build with tests from the behaviour list.** One test per behaviour line, named after it; tests drive the
   game's features, never a zoo or debug button. From M0.6 on, shared state gets cases for the Host, a Guest, a
   race and a late joiner (`multiplayer-game-dev`, `headless-harness`). Numbers are typed Resources, each marked
   decided or placeholder. Run the touched suites only.
5. **An asset piece** follows the port rules instead of steps 1 to 4: technical improvements only (origins,
   scale, names, collision, shared materials, file size), its Looks scene passes `kit/tools/asset_lint.py`, and a
   before and after strip goes in `builds/review-<family>/`. Assets are approved a family at a time (Q2216).
6. **Walkthrough.** Add a section for the piece to the planning page (URL and how to republish:
   `docs/migration/README.md`): purpose, a diagram, the real code with plain notes, how to try it in the zoo,
   open questions. The designer approves by answering the dialog.
7. **Merge** on the designer's OK, in a batch, pushed. Keep the process light (Q2200).
8. **Journal line** in `docs/migration/journal.md` (format at its top), with the cost from
   `kit/tools/agent_cost.py`; a rule that proved wrong is marked `rule change`.
9. **Looks.** When a piece changes what the 70 baseline views show, capture them again and compare
   (`docs/migration/milestones.md`, "The looks baseline"). A difference is a question for the designer.
