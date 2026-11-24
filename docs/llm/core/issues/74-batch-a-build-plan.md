---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-24
blocked_by: []
notes: ["suggested model: opus", "batch A (Q2606, Q2614); answers Q2617-Q2643"]
terms: [Stage, Laundry day, Final wash, Voice line]
---

# Batch A: the answers folded in, the build tickets filed

The three batch A designs (core/71 Stages, core/72 First wash and Laundry day, core/73 washer and voices) were
answered in one sitting: Q2617-Q2643 in `docs/migration/decisions.md`. Several answers differ from the
recommendations the proposals were written for (S1, S4, S6, S7, R7, W2, W3, W6, W7, W8, and Q2640: voice lines as one
JSON per speaker instead of a Resource per line). Batch A is then built unattended (Q2603).

## Do
1. Update `docs/architecture/stages.md`, `run-ends.md`, `voice.md` and `washer.md` to the answers (no recommendation
   text left that an answer replaced); `GLOSSARY.md` per Q2643.
2. In each of core/71, core/72, core/73: move every `[blocking]` choice under `## Answers` with its Q, set `status: done`.
3. File batch A's build tickets as `docs/llm/<area>/issues/NN-*.md` (core from 75 on; assets tickets in
   `docs/llm/assets/issues/` from 10), `ready-for-agent`, from the three proposals' drafts, deduplicated: one Cutscene
   frame ticket, one carrying seam (`Carriable`, `Hands.carries()`) for the Laundry bin and the Machine Parts. Each
   ticket: one mergeable piece, its behaviour lines (from the m4-lists, every old detail, Q2277), acceptance, its
   real-path case, `blocked_by`, a suggested model, and how it is authored (Q2607). Look-only work (the washer's drawn
   icon, Q2641; the later pour, Q2627) is its own ticket; the pour is `priority: later`.
4. Write the build order in `docs/migration/milestones.md` as a "Batch A" table (waves of tickets that can run side by
   side, at most 5 agents, files that clash kept apart), and correct the milestone table: M1 mostly done (the families
   built; the exterior and the dusk and night skies left), M3 merged, M4 started (menus, Lobby), the batches A-D
   (Q2614).
5. A review sheet stub `docs/migration/batch-a-review.md`: what the designer plays at the end, by ticket, and the
   place where agents list an open choice they settled by the old game (Q2604).

## Acceptance
- No game code changed; docs only.
- Every Q2617-Q2643 lands in the doc it changes; every proposal draft is a filed ticket or named as merged into one.

## Open follow-ups
- [later] For the lead: assets/11 (Cabinets to six Drawers) is written not to stop at its strip (a port of the old
  segments, no look change intended) because core/81 waits on it; give its agent a `Look work:` line if you want it to
  stop.
- [later] For the lead: the review sheet lists three readings to confirm in play: voice at 0 dB with no game gain
  (Q2638), the Laundry day's bar text "Wash clothes n/m" (Q2621's example), the Part taking core/42's Hand-off.

## Built log
- 2026-11-24
  - Changed: the four architecture files made build plans to Q2617-Q2643 (stages: even shares, drop at once, old floor
    names, the attic's own Cabinets, `StageBarPhase`s; run-ends: the answers R1-R9, the one Cutscene frame merged from
    core/72 and core/73; voice: lines as one JSON per speaker, the bake a command, no gain; washer: the answers W1-W10);
    `GLOSSARY.md` per Q2643 (Laundry day added); core/71-73 answers moved under `## Answers`, `done`; 24 core tickets
    (core/76-99; core/75 is taken on main) and 6 assets tickets (assets/10-15) filed from the drafts, the carrying seam
    (core/78) and the Cutscene frame (core/88) deduplicated, the run record merged into the tallies (core/83), a Fix
    scene ticket (core/92) added for the seam no draft owned, the pour `priority: later`, `needs-info`; to avoid file
    clashes the Fix and First-wash waits are derived from data (no `house.tscn` switch) and only three tickets edit the
    Stages station; `milestones.md` corrected (M1, M3, M4, M5) with the batches A-D and the Batch A waves; the review
    sheet stub; `docs/architecture.md` rows; the m4-lists' headers note the answers.
  - Files: docs/architecture/stages.md, run-ends.md, voice.md, washer.md, docs/architecture.md, GLOSSARY.md,
    docs/llm/core/issues/71-*, 72-*, 73-*, 74-*, 76-* .. 99-*, docs/llm/assets/issues/10-* .. 15-*,
    docs/migration/milestones.md, docs/migration/batch-a-review.md, docs/migration/m4-lists/03-*, 04-*, 05-*
  - Verified: docs only, no game code (`agent_finish.sh --no-test`)
- Merged: a1631b9c (2026-11-24, branch core/74-batch-a-build-plan)
