# Where development time goes (20-25 Nov 2026)

Question (designer, 25 Nov): what would make the whole development cycle faster? Measured from the lead's
transcript and 180 agent transcripts of session `08fda595`, git history, and the background-task outputs still on
disk. Read-only analysis; the scripts that rebuild every table are listed at the end.

## Summary

- **Agents were active 84 h** (20-25 Nov, 180 runs, 150 tickets). 54% of that is testing: run.sh 23 h,
  poll loops and Monitor waits 10.6 h, agent_finish 6.8 h, reading test logs and ad hoc Godot runs 4 h. Reading and exploring code is 18%. **Writing game code,
  tests, scenes and resources together is 8% (6.7 h).** A typical ticket is 25 min of agent time (mean 33, p90 58).
- **The "26 h of generation" in the first pass was really 20 h of generation plus 14 h of agents sitting idle
  waiting for their own background runs** (since 11-23; 16 h over the whole period). Generation over the whole
  period is 35.5 h: about 8 h of it is the fixed cost of a round trip (1.8 s each, 15.7k model calls), the rest is
  output tokens, of which about two thirds are thinking.
- **`--touched` is no longer a narrow run.** It picks 78-91% of the suites (90 of 96 on 11-25), and in about a
  third of the runs "something cannot be placed, so every suite runs". Run alone, a passing --touched or
  agent_finish took 32 s on 11-21 and 156 s on 11-25; with other agents' runs going, 181 s. In the last two days,
  test runs plus waiting for them take **20 of a ticket's 31 active minutes**.
- **The test slot pool is shared and saturates.** A targeted run that starts while two or more other agents are
  testing takes 34-76 s instead of 10 s. Two of the four flaky-fix tickets were cases that failed only "under
  load".
- **Flaky tests cost 11% of all agent time** (4 tickets, 9.5 h). core/54 alone took 7.1 h, 6.4 h of it in repeat
  loops.
- **The wall clock is set by flow, not by agent speed.** Some agent was active during 38 h of the lead's 126 h
  session. Even in the 61 hours the lead was working, the mean was 1.3 agents active at once (the cap is 5). The
  unattended batch A morning (11-25 09-12 UTC) held 3.4-4.5. A ticket's life from filed to merged is 76% waiting to
  be spawned, 19% building, 5% waiting to merge.
- **The lead spent 22 h active.** For 12 h of that an AskUserQuestion was open with the designer answering. On
  146 occasions the lead was idle until the designer wrote (14.5 h with gaps capped at 1 h). For 8.9 h of that,
  no agent was working either.
- **Rework is mostly not send-backs.** 25% of agent time (21 h) came after a lead message into a running agent.
  By kind of message: designer answers on stills 5.4 h, restarts after the session stopped 4.2 h, new rules 4.1 h,
  "main changed, merge it, take the next PROTOCOL" 2.4 h, real fix-before-merge send-backs only 1.4 h. There were
  493 fail-fix test cycles (median 1.1 min each), 23 merge-conflict stops (1.0 h of the lead) and 444 calls refused
  by the worktree git guard.

### Ranked recommendations (hours saved per 20-ticket batch; the recent profile is 31 agent-min per ticket, about 10 agent-h per batch)

| # | Change | Saves per batch | Sure? | Cost |
|---|---|---|---|---|
| 1 | Make `--touched` pick only suites that really load a changed file (a per-suite map of the `res://` files it loads, written by the runner); "cannot be placed" only for project.godot, kit and autoload changes | 2-3 agent-h, plus less slot contention for everyone else | medium | 0.5-1 day of kit work |
| 2 | Keep the build lane full: spawn up to the cap from the ready queue before each designer conversation; ready tickets don't wait on another ticket's designer go; queue an unattended run overnight in batch A's style | about 2 h of wall clock (a 10 agent-h batch at 2.2 agents at once is 4.5 h, at 4 it is 2.5 h) | medium (needs #1 first) | process only |
| 3 | Stop polling for good: hook_guard refuses `sleep` over 5 s, `until`/`while` wait loops and Monitor on a test log in agent worktrees (the rule went into ticket-agent.md on 11-25 20:40) | 0.5-1.2 agent-h (up to 3.7 h of polling so far had nothing of the agent's own running) | medium | 1 h |
| 4 | Finish without running the suites again: the ticket and Built-log edits go in *before* the final green `--touched`, and pass_stamp's fingerprint ignores folders with a `.gdignore` (docs/) | 0.8-1 agent-h | medium-high | 1 h |
| 5 | Flaky work: `run.sh --repeat=N --only=<case>` (N copies spread over the slots, prints "k of N failed" and the failing seeds), a 60-min timebox for a flaky hunt, and a `--load` option that reproduces "under load" on purpose | 0.5-1.5 agent-h (heavy-tailed: one bad flake is 7 h) | low-medium | 0.5 day |
| 6 | Try sonnet on feature tickets that are now given opus: an A/B on 6 comparable tickets (single-model feature tickets: sonnet median 15 min, opus 35; the tickets were not assigned at random) | 0-1.7 agent-h | low | none |
| 7 | Fewer round trips while orienting: the ticket lists the files to read (game, tests, the old game's files and line ranges); ticket-agent.md says to issue independent reads in one message | 0.5-0.7 agent-h | low-medium | 1 h (template and instructions) |
| 8 | A computed `Session.PROTOCOL` (a hash of the RPC table checked by a test) instead of a hand-numbered one, so co-op tickets stop queueing on "take 16 after core/63" | 0.3-0.5 agent-h on co-op batches, plus fewer lead messages | low-medium | 0.5 day |
| 9 | Fewer merge conflicts: `merge=union` for append-only logs (`docs/migration/batch-a-review.md`, `journal.md`; **not** `decisions.md`, whose line 1 is the next free Q number); the lead copies changes to an open branch's ticket by message, never by committing the ticket on main | 0.2-0.3 h of the lead | medium | 30 min |
| 10 | One line in ticket-agent.md: run git plainly from the worktree (never `cd <path> && git ...`) | 0.1 agent-h, fewer wasted turns | high | 10 min |
| 11 | End a lead session only with no agent mid-run (or tell agents to commit a WIP first) | about 0.5 agent-h per stop | low | process only |

Done already (11-25 20:40, after these transcripts): tests in the foreground, no wait loops (ticket-agent.md), and
pass_stamp reuse in agent_finish.sh. On these transcripts pass_stamp would have caught 16 of 243 agent_finish calls
(0.5 h). Another 29 came right after a green run with only ticket or doc edits in between (0.7 h), and pass_stamp
misses those as it is now (#4).

## Method, and what the data can't show

- **Active time.** Each transcript is turned into events: an assistant line, a tool result, a task-notification,
  a prompt. Every gap between events goes to one state:
  - *generation*: the gap ends at an assistant line. It goes to the activity of that message's tool call (an
    edit among parallel calls wins). It is capped at 10 min.
  - *tool*: the gap ends at a tool result. It goes to that tool's activity. It is capped at 60 min (6 h dropped
    in total, mostly the suspended `python3 -` call).
  - *background wait*: the gap ends at a task-notification while the agent had stopped with nothing pending. It
    goes to the background command's activity.
  - Time between turns (an agent stopped, waiting for the lead) is not counted: 120 h.

  Background runs are timed from the call to the notification.
- **Activities.** Bash commands are put in a category from what the command invokes, not from what it mentions
  (heredoc bodies are stripped). `run.sh`, `check.sh` and `agent_finish.sh` count as tests. Shot tools and reading
  PNGs count as shots. Writes are put in a category by the target file's extension: Write/Edit, `cat >`,
  `sed -i`, and python `open(...,'w')`. Grep, find, cat and Read count as reading, except reads of `.log` and task
  outputs, which count as reading test logs.
- **Tickets.** The ticket comes from the prompt's `Ticket:` line. The type comes from its front matter `kind:`,
  `area:` and title: "flaky" in the title makes a flaky fix, `area: assets` makes an asset ticket.
- **What it can't show:**
  - *Thinking against writing time.* Thinking is redacted in the transcripts. It is estimated from tokens
    (output tokens against visible characters / 3.5).
  - *The designer's real availability.* Only their messages and answer times are seen.
  - *Why the lead didn't spawn.* Was it a designer gate, the lead's judgement, or no ready ticket?
  - *Whether opus or sonnet is faster on the same ticket.* The tickets were assigned by difficulty, not at random.
  - *Inside a test run.* Mirror sync, import and the suites can't be separated beyond what runs print. Slot
    waits are printed only in foreground output (0.6 h is a floor).
  - *Processes started with `&`/nohup.* They aren't tracked.
  - *Test verdicts.* 27% of test commands have no verdict in the transcript (debug runs piped through `grep DBG`).
- Numbers can move by a few percent with the category rules. The ranking held through every revision of the
  scripts.

## 1. Where agent time goes, by activity

84.3 h active = generation 35.5 h + inside tools 32.8 h + idle waiting for their own background run 16.0 h.

| Activity | gen h | tool h | bg-wait h | total h | share |
|---|---:|---:|---:|---:|---:|
| Tests: run.sh | 2.7 | 12.2 | 8.2 | 23.1 | 27% |
| Read/explore code | 14.1 | 1.1 | 0.0 | 15.2 | 18% |
| Wait/poll loops, Monitor | 0.8 | 6.9 | 2.9 | 10.6 | 13% |
| Tests: agent_finish | 0.5 | 3.7 | 2.6 | 6.8 | 8% |
| Shots and viewing stills | 1.2 | 3.8 | 1.2 | 6.1 | 7% |
| Write game GDScript | 3.2 | 0.2 | 0.0 | 3.4 | 4% |
| Write helper .sh/.py | 1.4 | 1.4 | 0.1 | 3.0 | 4% |
| Git and commits | 2.0 | 0.6 | 0.1 | 2.7 | 3% |
| Godot ad hoc runs | 1.4 | 0.7 | 0.0 | 2.1 | 2% |
| Tests: reading logs | 0.9 | 1.1 | 0.1 | 2.1 | 2% |
| Other shell | 0.8 | 0.4 | 0.7 | 1.9 | 2% |
| Write test GDScript | 1.9 | 0.0 | 0.0 | 1.9 | 2% |
| Write docs/tickets .md | 1.4 | 0.0 | 0.0 | 1.5 | 2% |
| Blender | 0.7 | 0.1 | 0.0 | 0.9 | 1% |
| Other edits (config, data) | 0.6 | 0.1 | 0.0 | 0.7 | 1% |
| Report text / turn end | 0.7 | 0.0 | 0.0 | 0.7 | 1% |
| Edit scene .tscn | 0.5 | 0.0 | 0.0 | 0.5 | 1% |
| Lint, tool search, check.sh, .tres | 0.7 | 0.5 | 0.0 | 1.2 | 1% |

Families: testing 45.3 h (54%), reading 15.2 h (18%), shots 6.1 h (7%), writing code, scenes and data 4.8 h
(6%), helper scripts 3.0 h, git 2.7 h, writing tests 1.9 h, docs and tickets 1.5 h, Blender 0.9 h.

Per ticket: mean 33 min, median 25, p10 9, p90 58, max 423 (core/54). Since 11-24 (63 tickets) the mean is
31 min: test runs 8.4, poll and Monitor waits 7.1, reading 4.2, agent_finish 3.7, shots 1.3, test logs 1.0,
git 1.0, writing game code 0.8, docs 0.6, writing tests 0.4.

**Generation.** It is driven by what the model had just read. 47% of all generation time follows a read result,
and half of that goes on into another read. A failed test result is followed by only 3% of it. A fit of
per-message generation time against output tokens gives these costs:

| Model | Fixed per round trip | Per output token | Median context |
|---|---:|---:|---:|
| opus | 2.0 s | 8.6 ms (116 tok/s) | 188k |
| sonnet | 1.4 s | 6.3 ms (159 tok/s) | 124k |

Over 15.7k model calls the fixed part is about 7.8 h. About 66% of output tokens are thinking (82% on
read/explore steps, about 45% on steps that write code). So the levers on generation are fewer round trips and
less re-thinking during exploration, not faster typing.

## 2. Tokens by activity

Output 12.3 M tokens; input 2,987 M tokens (almost all cache reads, since every call re-reads the context).

| Activity | model calls | out k | out share | thinking share (est.) | input M | time share |
|---|---:|---:|---:|---:|---:|---:|
| Read/explore code | 6665 | 4519 | 37% | 82% | 1096 | 18% |
| Write game GDScript | 788 | 1398 | 11% | 48% | 164 | 4% |
| Tests: run.sh | 1197 | 909 | 7% | 68% | 270 | 27% |
| Write test GDScript | 300 | 909 | 7% | 41% | 63 | 2% |
| Write helper .sh/.py | 329 | 610 | 5% | 46% | 73 | 4% |
| Write docs/tickets .md | 293 | 576 | 5% | 42% | 61 | 2% |
| Git and commits | 1314 | 541 | 4% | 71% | 266 | 3% |
| Godot ad hoc runs | 591 | 445 | 4% | 80% | 97 | 2% |
| Shots and viewing stills | 796 | 330 | 3% | 68% | 177 | 7% |
| Wait/poll loops, Monitor | 569 | 254 | 2% | 58% | 110 | 13% |
| Tests: agent_finish | 279 | 200 | 2% | 52% | 63 | 8% |

Cost and time point in different directions:
- **Testing** is 54% of the time but only about 12% of output tokens: it costs wall clock, not money.
- **Exploration** is 18% of the time but 37% of output tokens and 37% of input tokens: it is the main token cost.
- **Git** takes 1,314 model calls for 3% of the time. Each `git status` or `git log` is a full-context call.

## 3. Per ticket type

| Type | tickets | runs | active h | mean min | median min | p90 min | tests % | read % | write code+tests % | shots % | blender % | out tok k/ticket |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| feature | 92 | 94 | 46.9 | 31 | 24 | 54 | 48 | 21 | 11 | 9 | 1 | 88 |
| bug | 19 | 19 | 10.7 | 34 | 28 | 53 | 71 | 14 | 3 | 3 | 0 | 56 |
| flaky fix | 4 | 5 | 9.5 | 143 | 64 | 423 | 85 | 2 | 0 | 0 | 0 | 42 |
| asset/Blender | 16 | 18 | 8.9 | 33 | 29 | 59 | 45 | 15 | 7 | 17 | 6 | 77 |
| refactor/maintenance | 7 | 8 | 3.3 | 28 | 18 | 50 | 59 | 16 | 4 | 7 | 0 | 49 |
| design/research | 12 | 13 | 2.3 | 11 | 13 | 16 | 13 | 44 | 3 | 0 | 1 | 57 |
| no ticket (research, review) | 24 | 24 | 2.8 | 7 | 4 | 12 | 23 | 29 | 5 | 0 | 2 | 29 |

Bugs are 71% testing (reproduce, rerun). Even asset tickets spend more time in tests than in Blender: Blender is
6% of their time, shots are 17%.

The 10 most expensive tickets, and what made them so:

| Ticket | type | active h | wall h | what made it expensive |
|---|---|---:|---:|---|
| core/54 heap Sock comes out "hot" | flaky | 7.1 | 24 | 13 repeat loops (6.4 h, one of them 2 h) hunting a rare event; a helper harness (1.0 h) |
| core/42 hand-off between players | feature | 1.7 | 2 | shots and stills 0.9 h (co-op two-window shots) |
| core/41 player stacking | feature | 1.6 | 12 | spread over 12 h by lead messages (PROTOCOL renumbering, merges of main); tests and poll waits |
| house/9 Socks laid without a freeze | feature | 1.6 | 2 | 62 test commands, the most of any ticket |
| core/58 main menu and saves | feature | 1.5 | 2 | 15 fail-fix cycles; poll waits |
| core/38 jointed flying Socks (experiment) | feature | 1.5 | 2 | 20 fail-fix cycles; sweeps with helper scripts |
| core/50 heap Sock sinks 116 mm | bug | 1.4 | 1 | 21 fail-fix cycles (the most): physics repro by trial |
| core/110 fall out of the map | feature | 1.3 | 1 | 0.6 h of poll and Monitor waits on its own runs |
| core/112 Final screen sparkles | bug | 1.2 | 1 | 1.1 h of its 1.2 h was Monitor and poll waits |
| assets/14 washing machine model and rig | asset | 1.2 | 6 | tests and shots, two runs |

## 4. Rework

- **Fail-fix cycles.** A cycle is a failing run, then edits, then the next run. There were 493 cycles in 108
  tickets. A cycle takes a median 1.1 min (mean 2.0): 16.8 h in total, of which 5.9 h was the failing runs and
  5.5 h diagnosing and fixing (the rest is the next run). Cycles per ticket: none 41 tickets, 1-2 cycles
  42 tickets, 3-5 cycles 34 tickets, 6 or more 32 tickets. The most were core/50 (21), core/38 (20), core/23 (16),
  coop/5 and core/58 (15 each).
- **Runs repeated with no file change in between.** 214 of 1,641 test commands (13%) took 8.0 h. Of these, 93
  came after a PASS (re-checking, or a different selection on the same files) and 42 after a FAIL (checking for a
  flake).
- **Respawns.** Only 6 tickets got a second agent (2.2 h).
- **Messages from the lead into a running agent.** 91 messages went to 60 runs. Agent time after them:

  | Kind of message | messages | agent h after |
  |---|---:|---:|
  | designer answer, look feedback | 34 | 5.4 |
  | restart after an interruption (session stopped, runs killed) | 7 | 4.2 |
  | new rule or decision | 12 | 4.1 |
  | main changed: merge it in, renumber PROTOCOL | 15 | 2.4 |
  | real send-back: fix before merge | 10 | 1.4 |
  | tool or git damage repair (since fixed) | 5 | 1.4 |
  | other | 8 | 2.4 |

  The look-feedback time is the designed look gate and is wanted. Restarts, renumbering and the git damage are
  not wanted (8 h).
- **Merging.**
  - The lead made 176 integrate.sh calls. RESULT lines: 106 MERGED, 37 conflict stops (preview and merge), 13
    "tracked files modified", 12 suite failures.
  - There were 23 windows from a conflict to the next merge: 2.3 h wall, 1.0 h of the lead's active time.
  - The conflicting files were mostly shared docs: `docs/migration/batch-a-review.md`, ticket files edited on
    both main and the branch, `docs/architecture.md`, `tools/shot_hooks.gd`. Shared scenes and resources came
    up rarely: `player.tscn`, `theme.tres`, `sound_catalogue.tres`.
- **Refusals.** 444 calls were refused by the harness's worktree guard ("split it into plain, separate
  commands"), costing 0.73 h in round trips. The other 554 errors are mostly non-zero exits of ordinary commands.

## 5. Waiting, the critical path and parallelism

**A ticket's life**, for 131 merged tickets with an agent run (median, then mean):
- filed to spawned: 0.4 h (6.4 h)
- spawned to agent done: 31 min (96 min), of which active 26 min (34)
- agent done to merged: about 0 (0.5 h)

Waiting to be spawned is 76% of the average life. Once spawned, a ticket is done in about half an hour and
merged within the hour. The lead's integration is not the bottleneck.

**Parallelism.**
- Some agent was active 38.2 h of wall clock. In that time the mean was 2.2 agents at once. One agent was active
  47% of that time, two 19%, three 12%, four or more 22%.
- Over the whole 126 h session, agents were active 31% of the time.
- In the 61 hours with the lead working, the mean was 1.3 agents at once (81 agent-h).
- In hours without the lead, agents did only 3.4 agent-h: nothing runs overnight.

**Merge rounds** (merges less than 45 min apart):

| round (UTC) | tickets | first filed to last merged h | first spawn to last merged h | agent active h | longest ticket h | agent h per spawn-to-done h |
|---|---:|---:|---:|---:|---:|---:|
| 11-20 14:24 | 8 | 3.1 | 2.8 | 2.1 | 0.5 | 0.7 |
| 11-20 21:17 | 8 | 5.1 | 4.9 | 2.4 | 0.7 | 0.5 |
| 11-21 15:49 | 17 | 21.5 | 21.5 | 7.8 | 1.0 | 0.4 |
| 11-22 (8 small rounds) | 17 | 0.6-2.4 each | 0.6-2.4 each | 7.7 | 1.4 | 0.3-1.3 |
| 11-23 10:32 | 5 | 44.5 | 2.1 | 2.7 | 0.9 | 1.3 |
| 11-23 17:11 | 7 | 8.3 | 8.3 | 3.9 | 0.9 | 0.5 |
| 11-23 19:24 | 10 | 46.8 | 4.5 | 7.4 | 1.7 | 1.7 |
| 11-24 16:58 | 6 | 65.9 | 30.8 | 10.4 | 7.1 | 0.3 |
| 11-24 21:38 | 5 | 27.2 | 6.2 | 1.5 | 0.4 | 0.2 |
| 11-25 09:01 (batch A, unattended) | 29 | 16.5 | 6.8 | 16.3 | 1.1 | 2.4 |
| 11-25 17:37 | 12 | 21.0 | 9.7 | 7.6 | 1.3 | 0.8 |

Batch A is the model to copy. 16.3 agent-h became 6.8 h of wall clock from spawn to merge, at 2.4 agents at once
(3.4-4.5 in its first four hours). Its tail is where it lost time: 13-14 UTC ran 1-1.5 agents while the lead
waited. Every other round ran at 0.2-1.7.

**The critical path, in order:**
1. Tickets waiting for a spawn, behind designer answers and the lead's grilling. While the lead is idle waiting
   for the designer, no agent is working for 8.9 of those 14.5 h.
2. The long tail of a round: one flaky or slow ticket (core/54 was 7.1 h in a round whose other tickets took
   under 1 h).
3. Test time inside each ticket: 20 of 31 minutes recently, and it gets worse with more agents at once.

**The lead's time.**
- Active 22.3 h, of which 12.0 h had an AskUserQuestion open. The rest: talking to the designer 2.9 h, merges
  1.3 h, git 1.3 h, reading 1.3 h, tickets and docs 0.7 h.
- Idle until the designer wrote: 146 times, 14.5 h capped (36 h uncapped, including nights).
- Idle until an agent finished: 227 times, 15.7 h.
- Idle until a background command finished (mostly integrate runs): 4.5 h capped.

## 6. Test runs

- **Volume.** 1,641 test commands in 152 agent runs: 172 in the background (161 timed: median 160 s, 14.4 h) and
  1,467 in the foreground (median 17 s, 16.1 h). Per ticket: mean 11.0, median 9, p90 20, max 62 (house/9).

| Selection | runs | in bg | total h | median s | p90 s | failed | verdict not visible |
|---|---:|---:|---:|---:|---:|---:|---:|
| repeat loop (for/seq/several runs) | 123 | 31 | 8.6 | 42 | 387 | 27 | 55 |
| targeted (--only/--grep) | 874 | 29 | 8.1 | 13 | 96 | 348 | 266 |
| agent_finish | 243 | 53 | 6.9 | 57 | 203 | 15 | 72 |
| --touched | 256 | 55 | 6.3 | 55 | 181 | 83 | 74 |
| whole suite (by an agent) | 48 | 5 | 0.3 | - | 47 | 6 | 39 |
| check.sh alone | 56 | 0 | 0.2 | 9 | 30 | 15 | 42 |

- **The parse and wiring checks cost little.** Passing targeted runs took a median 13 s with the checks and
  10 s with `--no-check`, so about 3 s a run; check.sh alone takes a median 9 s. The time is in the suites
  `--touched` selects.
- **--touched and agent_finish by day** (passing runs; "alone" means no other agent's test run was going when
  it started):

  | day | median s alone | with 1 other going | with 2+ | --touched picked (median share of suites) | "every suite runs" |
  |---|---:|---:|---:|---:|---:|
  | 11-20 | 15 | 21 | - | 50% | 11 of 39 |
  | 11-21 | 32 | 36 | - | 78% | 10 of 35 |
  | 11-22 | 57 | 58 | - | 84% | 4 of 13 |
  | 11-23 | 99 | 130 | 159 | 88% | 3 of 18 |
  | 11-24 | 140 | 120 | 158 | (n=1) | 4 of 5 |
  | 11-25 | 156 | 181 | 181 | 91% | 3 of 13 |

  Targeted runs show contention more plainly: a median 10 s alone, 14 s with one other agent testing, 34 s with
  two, 76 s with three or more. The slot pool is half the 16 cores, at most 8 Godot processes for every
  checkout. A whole run uses 8 at a time over 93-101 processes, so two agents doing a --touched each already
  queue.
- **Whole suite** (SLOW lines from the background outputs on disk):

  | day | runs seen | median s | min s | max s | max cases |
  |---|---:|---:|---:|---:|---:|
  | 11-23 | 5 | 160 | 123 | 282 | 549 |
  | 11-24 | 13 | 228 | 140 | 258 | 601 |
  | 11-25 | 13 | 205 | 125 | 604 | 761 |

  Runs on 11-20 to 11-22 stayed under the 120 s SLOW threshold (166-371 cases). By 11-25 a single --touched,
  at 156-181 s, costs about as much as the whole suite.
- **agent_finish.** 243 calls ran the suites. Only 16 followed a green --touched with no edit at all. 29
  followed one with only ticket or doc edits. 46 re-ran right after another agent_finish with no edit (a
  commit-side refusal such as a staged but unnamed file or a missing uid, or a second commit). Since 11-25 pass_stamp covers the no-edit
  cases. Recommendation 4 covers the doc-edit ones.
- **Repeat loops** (8.6 h) are almost all core/54 (6.4 h).
- **Poll loops.**
  - 575 wait or poll calls, 155 of them Monitor. The foreground ones total 6.9 h, and 2.9 h more went waiting
    for Monitor events.
  - Up to 3.7 h of the foreground polling ran while the agent had no background run of its own going.
  - By day: 11-23 1.2 h, 11-25 4.9 h. It was getting worse until the rule changed tonight.

## 7. Recommendations in detail

Estimates use the recent profile (11-24 onwards, 31 agent-min per ticket) and a 20-ticket batch. A round of 29,
like batch A, scales by 1.5.

1. **A narrow --touched (2-3 agent-h per batch; medium; 0.5-1 day).**
   - *How.* Have the runner record, per suite, the `res://` files actually loaded. A `ResourceLoader` wrapper,
     or the list of loaded scripts and scenes at the end of each process, is written to the shared test folder.
     `--touched` then selects suites by that map. "Cannot be placed" stays only for project.godot, autoloads
     and the kit.
   - *Saving.* Today --touched plus agent_finish take 7.6 min per ticket at about 175 s a run. At about 40 s a
     run that would be 2 min. Waiting on those runs shrinks too, and so does the slowdown every other agent
     sees.
   - *Risk.* A failure found only by the lead's whole run at merge (12 "FAILED: suite" in this period). Keep
     the whole suite once per batch, as now.
   - *Uncertainty.* If the zoo and main-scene suites really do load nearly everything, the map gives less. Then
     the second-best fix is to move the few "loads everything" suites (zoo, wiring, main scene) out of
     --touched into the batch run.
2. **Keep the lane full (about 2 h of wall clock per batch; medium; process).**
   - *Why.* Spawn-queue time is 76% of a ticket's life. With the lead present only 1.3 agents run at once.
   - *How.* Before each designer conversation the lead fills the lane from `ready-for-agent`. Questions for
     the next batch are asked while the current one builds. A batch-A-style unattended run goes overnight.
   - *Do #1 first.* With today's --touched, five agents at once slow each other's runs about 3x.
3. **Enforce no-poll in hook_guard (0.5-1.2 agent-h; medium; 1 h).** The new ticket-agent.md rule may be enough.
   The history says agents drift (4.9 h of polling on 11-25 despite "do not poll" in every background-run
   result). A refusal costs one round trip; a poll loop costs minutes.
4. **Finish without a second run (0.8-1 agent-h; medium-high; 1 h).** Order in ticket-agent.md: ticket status,
   Built log and journal draft first, then the final `--touched`, then `agent_finish.sh` right away. pass_stamp's
   fingerprint skips paths under a `.gdignore` folder, which Godot and the suites can't read.
5. **Flaky tooling (0.5-1.5 agent-h; low-medium; 0.5 day).**
   - `run.sh --repeat=N` runs N copies of one case in parallel slots with different seeds and prints
     `k of N failed` and the seeds.
   - `--load=K` runs K busy processes beside it, to reproduce "under load" on purpose (core/101 and core/102 were
     load-dependent).
   - A 60-min timebox, after which the agent reports what it knows.
   - The best fix for load flakes is #1: fewer processes competing.
6. **Model A/B (0-1.7 agent-h; low; free).**
   - Single-model feature tickets took a median 15 min with sonnet and 35 min with opus. Sonnet generates
     faster (6.3 against 8.6 ms a token) and works with smaller contexts (124k against 188k median).
   - The choice was by difficulty, so this is not proof.
   - Give the next 6 feature tickets the lead would send to opus to sonnet, and compare redo counts and time.
7. **Fewer orientation round trips (0.5-0.7 agent-h; low-medium; 1 h).**
   - 46 read calls per ticket, almost one per model call; 76% of them in the first 15 min.
   - Reads by target: game/ 34%, the old game 17%, tests/ 17%, docs 12%, kit 9%.
   - *How.* The ticket names the files and the old game's files with line ranges. Agents batch independent
     reads in one message (each round trip has a 1.8-2 s fixed cost and re-thinks over 120-190k of context).
8. **Computed PROTOCOL (0.3-0.5 agent-h on co-op batches; low-medium; 0.5 day).** A hand-numbered PROTOCOL
   serialises co-op tickets: 15 "merge main, take N+1" messages and several merges of main into agent branches.
   A hash of the RPC and Command table, checked by a test, removes the order. This is a technical choice, not a
   game choice; the lead can decide it.
9. **Union merge for logs (0.2-0.3 h of the lead; medium; 30 min).** Covered in section 4. Do not union
   decisions.md.
10. **Plain git in the worktree (0.1 agent-h; high; 10 min).** 444 refused calls.
11. **No session stop with agents mid-run (about 0.5 agent-h per stop; low; process).** 7 restarts, 4.2 h of
    agent time after them, some of it re-running killed sweeps.

Not recommended: making the parse and wiring checks faster (about 3 s a run), or speeding up integrate.sh (merges
happen within the hour of an agent's report; the lead's merge time is 1.3 h over five days).

## 8. How to measure from now on

Most of these numbers can come for free with three small additions. A per-tool-call hook is not needed: the
transcripts already carry every tool call's timestamps. What they lack is inside the test runs, and a
per-ticket summary.

1. **run.py: one JSON line per run** to `$GAME_TEST_SHARED/runs.jsonl` (default
   `/tmp/game-tests-shared/runs.jsonl`, outside git). Fields:
   - start and end (epoch), checkout path, branch, argv, `selection`
   - `suites_selected` / `suites_total`, `cause` ("every suite runs": the file it couldn't place)
   - phase seconds: `mirror`, `import`, `check`, `wiring`, `suites`, `perf_lane`
   - `slot_wait_s` (summed over processes), `processes`, `jobs`, `peak_mem_mb`
   - `verdict`, `failed_cases`, `flaky_cases`, `concurrent_runs_at_start` (from the slot pool's state)

   About 30 lines in run.py. This gives the check/suite split, contention and the --touched breadth directly,
   for background runs too.
2. **agent_start.sh / agent_finish.sh: a per-ticket line.**
   - agent_start writes `<git dir>/kit-ticket-start` (epoch).
   - agent_finish appends to `$GAME_TEST_SHARED/tickets.jsonl`: ticket, branch, model (from an env var the
     lead's prompt sets, or `unknown`), wall seconds since start, the number of runs, failed runs and their
     total seconds from `runs.jsonl` for this checkout, `reused` (pass_stamp), commits on the branch.
   - It also prints one `CYCLE ...` line in its output so the lead can copy it into the journal.
3. **`kit/tools/dev_cycle.py`: these scripts made a kit tool.**
   - It takes a session id (or "the latest") and an optional `--since`.
   - It reads the lead and subagent transcripts plus the two JSONL files.
   - It writes `docs/research/cycle/<date>-<batch>.md` with sections 1-6 of this report and appends one CSV row
     per ticket to `docs/migration/cycle.csv`: ticket, type, model, active min, test min, poll min, read min,
     fail cycles, runs, messages from the lead, filed/spawned/done/merged times.
   - The lead runs it at the end of each batch (lead-integrator, before housekeeping) and puts five headline
     numbers in the journal's batch summary: agent min per ticket, test share, --touched median s and share of
     suites, mean agents active while the lead works, filed-to-merged hours.

With those in place, the next batch answers in minutes whether #1-#4 worked. The targets are: --touched under
60 s and under 30% of suites, test share under 35%, poll minutes near 0, mean agents active while the lead works
above 3.

## Scripts

All in `/tmp/claude-1000/-c-Users-Gripe-personal-repositories-it-socks-to-be-a-washing-machine/08fda595-82ec-42d1-a22f-67d094c58b5b/scratchpad/devcycle/`
(scratch space: copy them into `kit/tools/dev_cycle.py` for #8.3 before it is cleared).

- `run_all.sh` rebuilds everything in about 10 s.
- `parse_agents.py` and `parse_lead.py` turn the transcripts into pickles: intervals, tool calls, test
  outputs, notifications.
- The section scripts: `a1_activity.py` (sections 1-3), `a1b_latency.py` (cost per round trip), `a2_tests.py`
  (test runs, cycles, repeats), `a3_flow.py` (rework, lifecycle, merge rounds, parallelism, the lead's waits),
  `a4_suite_trend.py` (whole-suite trend from the task outputs on disk), `a5_misc.py` (reads, polls, refusals,
  models), `a6_recent.py` (the per-ticket profile since 11-24), `a7_hourly.py` (an hour-by-hour table) and
  `a8_contention.py` (--touched by day and by load).
