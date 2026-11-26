---
type: ticket
status: done
kind: maintenance
area: maintenance
feature: profile
priority: next
created: 2026-11-26
done:
blocked_by: []
notes: ["suggested model: sonnet", "found by core/145's agent, 2026-11-26"]
terms: [Profile]
suites: [profile_tallies, coop_join, coop_wardrobe, coop_profile, encyclopedia_record, stages]
---

# One profile object per machine

Achievements (core/145) and the TallyRecorder read `Worlds.profile()`, while `level_net` can load a separate
profile object for `--profile=` (the co-op test machines and a second local window). On such a machine the
Lifetime tallies, the Achievements and the Wardrobe's owned pieces could land in a different object from the one
the session's welcome and saves use, so one machine would keep two profiles.

## Acceptance
- Every reader and writer of the local profile on a machine reaches one object, whether the profile came from
  `--profile=` or the default file (one owner, e.g. `Worlds.profile()` loading the `--profile=` path when given).
- Real path: two machines on `net_shot` or the co-op harness, the Guest started with `--profile=<file>`; the Guest
  shelves a Pair by a left click, and that file's Lifetime tally rises and its Wardrobe welcome shows its own pieces.
- No change for a single default-profile machine.

## Answers

## Open follow-ups
