---
type: ticket
status: needs-info
kind: content
area: content
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[145-achievements-system]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, later row (after the answer)", "suggested model: sonnet"]
terms: [Achievement, Lifetime tallies]
suites: [game_link]
---

# Batch B's Achievements list

The Achievement files batch B ships, dropped into `game/profile/achievements/` (core/145's system). The proposal's ten
(core/122 W1 (a)) each gave a basic piece; the designer chose instead to own the basic pieces from the start (Q2679),
which leaves the list itself unanswered. The old game's draft of 46 is a draft only (Q1688, Q1699); every batch B
condition can only be a Lifetime tally reaching a number (`docs/architecture/wardrobe.md` "Achievements").

The proposal's ten, as plain badges (team credit, none hidden, numbers the draft's placeholders):

| id | Title | Condition |
|---|---|---|
| `first_pair` | Two of a Kind | 1 Pair shelved |
| `pairs_100` | Sock Drawer Regular | 100 Pairs shelved |
| `pairs_1000` | The Thousand Pair Club | 1,000 Pairs shelved |
| `coins_1000` | Pocket Lint Fortune | 1,000 Coins earned |
| `coins_10000` | Sock Market Tycoon | 10,000 Coins earned |
| `first_collection` | The Full Set | 1 Collection completed |
| `basement_done` | Spin Cycle One | 1 floor completed |
| `floors_10` | Floor Show | 10 floors completed |
| `first_wash` | Fresh and Clean | 1 game finished |
| `games_5` | Repeat Cycle | 5 games finished |

## Acceptance
- One `.tres` per chosen Achievement in `game/profile/achievements/`; each shows in the Achievements station and on the
  Profile page; the id test passes.
- Real path: on the Stages station's mini run with a fresh zoo profile the player shelves a Pair by a left click and the
  first chosen tally Achievement's toast slides in.
- `kit/tools/run.sh --touched` ends PASS.

## Answers
- The ten basic Wardrobe pieces are owned from the start (Q2679, 2026-11-25).

## Open follow-ups
- [blocking] Which Achievements does batch B ship? (a) the ten above as plain badges, no piece (recommended: the
  Profile page has something to show and every tally has a first goal); (b) a cut of the old draft of 46 that the
  designer picks (only tally conditions work in batch B); (c) none in batch B: the system waits for a content round.
