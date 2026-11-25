---
type: ticket
status: done
kind: bug
area: coop
feature: net
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25: hosting in one window of the build, the second window cannot join: 'You are already in this game'"]
terms: [Host, Guest]
---

# A second copy of the game on one PC can join without a launch argument

The designer runs the Windows debug build twice to test co-op on one PC. One copy hosts. The other is refused with
"You are already in this game" (`game/parts/session.gd` `ALREADY`). Both copies read the same `user://profile.json`,
so they have the same player id (Q2458). The way round it today is `"It Socks.exe" -- --profile=2`. That isn't
visible in the build and is easy to miss: the hint is only on the zoo's title line.

## What it does
- In a debug build (`OS.is_debug_build()`), a second copy started while another copy holds the profile picks a
  profile of its own (`profile_2`, then `profile_3`, ...). It holds a lock file for as long as it runs (an exclusive
  `FileAccess` lock, or a lock file with the process id that a dead process doesn't keep). Its window title or
  title screen shows which profile it is ("Player 2").
- `--profile=<tag>` still wins when given.
- A release build never does this: one player is one profile, and a duplicate id is refused as today.
- Check what the old game did (`reference/it-socks`, read from the main checkout: grep `profile` and `instance`)
  and follow it if it had an answer. Record the answer in "Settled by the old game".

## Acceptance
- Two copies of the debug build on one PC, no arguments: the second joins the first's game as a Guest with its own
  name and id.
- Real-path case: two machines in one test run with the same user folder; the second gets `profile_2` and joins.
- A copy that crashed doesn't hold its profile forever: the next start takes it back.
- `--profile=` and the release build behave as before.
- The full suite passes, nothing flaky.

## Open follow-ups

## Built log

### 2026-11-25
Changed: new `ProfileLock` (port of the old game's lock): a debug build without `--profile=` takes the first free profile
("", 2, 3.. up to 8) by a `<profile>.lock` file (pid and stamp, renewed every 2 s, free after 30 s, removed on quit);
window title shows "(Player N)". `Worlds.profile()` uses it; `PlayerProfile.file_of`/`load_or_make` take a folder.
Case `second_copy_joins` in teammates_test (two Worlds on one folder, crash takes back, then Host/Guest join).
Files: game/net/profile_lock.gd(+.uid), game/net/player_profile.gd, game/save/worlds.gd, tests/teammates_test.gd,
docs/migration/batch-a-review.md.
Verified: PASS 23011 checks, 755 cases
- Merged: 69254346 (2026-11-25, branch core/114-second-copy-joins)
