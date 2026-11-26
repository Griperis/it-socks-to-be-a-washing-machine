---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["suggested model: opus", "batch B (Q2614); answers Q2667-Q2683; the same job core/74 did for batch A"]
terms: [Coins, Drawer, Upgrade, Old Tree, Gift, Collection, Wardrobe, piece, Profile, Achievement]
suites: []
---

# Batch B: the answers folded in, the build tickets filed

The three batch B designs (core/120 economy, core/121 Gifts and Collections, core/122 Wardrobe and Profile) were
answered in one sitting: Q2667-Q2683 in `docs/migration/decisions.md`. Several answers differ from the
recommendations the proposals were written for, for example E1 (both old Coins bonuses), E2 (no "+N", the counter
counts up), G1 (a piece of another unlocked Collection), W1 (the ten basic pieces owned from the start), W2 (the
Trails remade as particle scenes authored in the editor, Q2658), W4 (no Secrets in batch B), W5 and G3 (the Lost
Socks hidden until the Drum). Read every Q in that range; do not trust this list to be complete. Batch B is then
built unattended (Q2603), the same way as batch A.

## Do
1. Update `docs/architecture/economy.md`, `gifts.md` and `wardrobe.md` to the answers: no recommendation text left
   that an answer replaced, and no draft ticket left that an answer removed (for example the Secrets work, W4).
   `GLOSSARY.md` gets any new word the answers settle.
2. In each of core/120, core/121 and core/122, move every `[blocking]` choice under `## Answers` with its Q, and set
   `status: done`.
3. File batch B's build tickets from the three proposals' drafts (120-A..F, 121-A..I, 122-A..H, AS-B1, AS-B2, AS-W1,
   AS-W2), deduplicated across the three pieces (for example one Profile file, one HUD toast seam if two drafts each
   make one).
   - Numbering: core tickets as `docs/llm/core/issues/NN-*.md` from 124 on; asset tickets in `docs/llm/assets/issues/`
     from 16 on. All `ready-for-agent`, except a ticket blocked by an open question, which is `needs-info` with the
     question as `[blocking]`.
   - Each ticket has:
     - one mergeable piece;
     - its behaviour lines from `docs/migration/m4-lists/06-08`, every old detail (Q2277);
     - acceptance with its real-path case;
     - `blocked_by` with `[[NN-slug]]` links;
     - `suites: [...]`, naming the other suites it can break (`kit/docs/TESTING.md` "--touched");
     - a suggested model;
     - how it is authored (Q2607, UI in nodes Q2658, particles in the editor Q2680).
   - Look-only work (the Trails' looks, piece Looks) stops at its first stills. The asset tickets stop at their first
     line-up (`ready-for-human`) and swap in on the designer's yes. Core tickets build on graybox, so none waits on an
     asset's go.
   - Carry in what batch A handed over: core/79's Machine Part pop spot kept clear of gift boxes goes into the Gift
     ticket (`docs/migration/batch-a-review.md`, question 4).
4. Write the build order in `docs/migration/milestones.md` as a "Batch B" table, in the same shape as the "Batch A"
   one.
   - Waves of tickets that can run side by side, at most 5 agents. A wave starts when the waves before it are merged.
   - Merge the three proposals' wave tables into one. Order every cross-piece clash they name: `player_profile.gd`,
     `run.tscn`, `house.tscn`, the HUD scene, `title.tscn`, `stages.gd`, `cabinet.gd`, `final_screen`,
     `old_tree.tscn`, and the S-122a..d seams 121-C and 121-D need.
   - Set batch B's row to "answered (Q2667-Q2683), filed (core/123): building".
   - Correct M0.6's row: done, with all 14 coop tickets merged (coop/14 on 2026-11-25).
5. Write a review sheet stub, `docs/migration/batch-b-review.md`, in the shape of `batch-a-review.md`: what the
   designer plays at the end, by ticket, and the place where agents list an open choice they settled by the old
   game's answer (Q2604).

## Acceptance
- No game code changed; docs only.
- Every one of Q2667-Q2683 lands in the doc it changes.
- Every proposal draft is either a filed ticket or named as merged into one, or as dropped by its Q.
- No two tickets in the same wave edit the same file the proposals list as a clash.
- `python3 kit/tools/kit_check.py` (or the parse and wiring checks of `run.sh --touched`) pass on the branch.

## Answers
- The rest of the port runs as batches A-D; each is designed, grilled in one sitting, built unattended and played in
  one session (Q2603-Q2605, Q2614).
- Batch B grilling: Q2667-Q2683 (designer, 2026-11-25).

## Open follow-ups
