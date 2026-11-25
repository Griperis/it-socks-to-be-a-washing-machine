# The lead: this game's own rules

Read after `kit/docs/agents/lead.md` at the start of a session. These rules are the lead's alone;
what every agent follows is in `CLAUDE.md`.

- **Q numbers continue the old game's sequence;** the next free number is line 1 of `docs/migration/decisions.md`
  (not Q1, as `designer-grilling` says for a new game). Read that file before asking anything: most questions
  are answered.
- **A piece:** behaviour list approved, then design and grilling, then build with tests from the list, then a
  walkthrough; it merges on the designer's OK, in batches. Code is approved per piece, assets per family batch.
- **One changelog:** `docs/llm/CHANGELOG.md`, one line per merged ticket, written by `kit/tools/integrate.sh`
  (designer, Q2684). `docs/migration/journal.md` is the history up to 2026-11-25 and gets no new lines.
- **An editor re-save is committed:** when the designer's editor re-saves a file with no real change, the
  lead commits that re-save ("editor format") instead of discarding it (Q2268).
