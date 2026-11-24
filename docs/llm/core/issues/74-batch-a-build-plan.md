---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: now
created: 2026-11-24
done:
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

## Built log
