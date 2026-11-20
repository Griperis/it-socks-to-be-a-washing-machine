# Architecture decision records

One file per decision that is hard to reverse or that a newcomer would otherwise question:
`NNNN-<slug>.md`, numbered from `0001`, never renumbered. The lead writes one
when a decision is actually made (the `designer-grilling` skill, rule 7); don't create them upfront.

## Format

```md
# NNNN: <Decision, as a short statement>

Status: accepted | superseded by NNNN | deprecated
Date: 2026-01-01

## Context
<The forces at play: what problem, what constraints, what was true at the time.>

## Decision
<What was decided, in GLOSSARY.md vocabulary.>

## Consequences
<What gets easier, what gets harder, what is now ruled out.>

## Alternatives considered
<Each option that lost, and why, in a line or two.>
```

## Rules

- An ADR is never edited to change its decision. A new ADR supersedes it, and the old one's
  `Status:` line points at the new one.
- Tickets and code comments may cite an ADR as `ADR-NNNN`.
- If a piece of work contradicts an ADR, say so explicitly (`kit/docs/agents/issue-tracker.md` "The glossary and decision records") and let the
  designer decide whether to reopen it.
