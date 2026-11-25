---
type: ticket
status: ready-for-agent
kind: maintenance
area: tools
feature: maintenance
priority: later
created: 2026-11-25
done:
blocked_by: []
notes: ["kit change: the lead does it, in the main checkout (kit/CLAUDE.md)", "not before 2026-12-02: a clean week after core.createObject rename (Q2684 item 7)"]
terms: []
suites: []
---

# Retire the damaged-commit machinery after a clean week

On the Windows host mount (virtiofs) git's link-then-unlink left fresh objects unreadable for minutes, and 1-4%
of commits read back damaged. `core.createObject rename` (Q2660-Q2662, kit 10dd397, set on 2026-11-25) took that
to 0 in 5,500 test commits. The kit still carries the machinery built around the fault: commit retries, the
read-back after every commit (`commit_reads_back_soon`), `kit/tools/git_check.sh`, `kit/tools/git_repair.sh`, the
`COMMIT DAMAGED` line and its doc text, 250-700 lines with their tests (toolbox audit, item 7).

Wait one week of real agent work (to 2026-12-02) before removing it: until then those checks are what would show
that the rename fix covers only some cases.

## Acceptance
- Before starting: no `COMMIT DAMAGED`, `git_check` failure or `could not parse HEAD` line in any agent report or
  merge since 2026-11-25 (grep the transcripts and `docs/llm/CHANGELOG.md` merges). If there is one, stop and
  report it instead.
- Removed from the kit: commit retries and the read-back in `kit/tools/commit.sh`, `kit/tools/git_repair.sh`,
  the `COMMIT DAMAGED` handling in `kit/tools/agent_finish.sh` and `kit/agents/ticket-agent.md`, "The git glitch"
  in `kit/docs/agents/git.md`, the glitch patterns (`GLITCH_RE`) where only they used them, and their tests.
- Kept: `ensure_object_rename` (the fix itself) and its `setup.py --check` note; one cheap read-back of each
  branch in `kit/tools/integrate.sh` before it merges, as the safety net.
- `kit/tools/selftest.sh` green; a CHANGELOG entry with the lines removed.

## Answers
- Retire it after a clean week; keep the safety net at merge. (Q2684, 2026-11-25)

## Open follow-ups
