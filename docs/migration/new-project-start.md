# Starting the new It Socks project: the preparation plan

Plain words. Numbers marked "measured" were read from the repo today (2026-11-19). Numbers marked
"judged" are my reading and were not tested. Nothing was run, created or changed to write this.

This session only prepares. The migration happens in a later session. Preparation creates the
repository, the reference folder, an empty Godot skeleton, the handoff documents and a tools check.
It ports no asset and writes no game code.

## What I measured first

| Fact | Value |
|---|---|
| `.git` of today's repo | 1.4 GB (packs 818 MB, loose objects 136 MB, LFS store `.git/lfs` 364 MB) |
| Git LFS files | 1,448 (png, glb, blend, wav, ogg, hdr, ttf, zip, ...) |
| Tracked files / commits | 4,864 files, 2,133 commits |
| Working folders | assets 92 MB, audio 106 MB, assets_src 20 MB, docs 168 MB (docs/art 144 MB, docs/screens 19 MB is git-ignored), game 3.5 MB, tests 2.4 MB, tools 3.5 MB, data 1.3 MB. About 400 MB without `.git` |
| Not in git | `extras/` 1.8 GB (engine 140 MB, Blender tarball, zips), `builds/` 8.1 GB (84 review folders), `.claude/worktrees/` (many) |
| Remote | `origin` = `https://github.com/Griperis/sock-it.git` |
| Commits not on `origin/main` | 235 (measured: `git log origin/main..main`). So GitHub is behind your disk |
| Branches / worktrees | 92 branches (local and remote-tracking), 4 tags, many agent worktrees under `.claude/worktrees/` |
| Free space | sandbox `/` 3.9 GB free (tight); the mounted drive 217 GB free |
| The drive | virtiofs mount, `core.filemode=false`, git commit glitch known |
| Uncommitted today | `docs/llm/.obsidian/appearance.json` modified and about 140 untracked `.import` files. `project.godot` and `export_presets.cfg` show no diff right now (measured: `git status`); your brief said they carry edits, so check before you copy from them |

---

# A. Target layout and how the old repo sits inside it

## A1. Top level of the new repository

```
<new-repo>/
  CLAUDE.md                 the short rules every session reads first (draft in part D)
  README.md                 what this is, how to open it (draft in part D)
  GLOSSARY.md               the game's words, copied from the old repo (Q2166)
  project.godot             Godot 4.7.1 skeleton: no scenes, no autoloads (part B)
  .gitattributes            LF lines and Git LFS for binaries (copied as is)
  .gitignore                .godot/, extras/Godot_*, builds/, reference/, override.cfg, ...
  .editorconfig             tabs for code, spaces for md/json (copied as is)
  .claude/
    settings.json           the destructive-git deny list (copied as is)
    skills/                 4 short skills, written fresh (part C)
  game/                     code and scenes, one folder per area (Q2167) - empty, .gitkeep
  assets/                   models, sounds, UI art by family (Q2167) - empty, .gitkeep
  data/                     settings and typed Resources (Q2167) - empty, .gitkeep
  tests/                    the new test suite - empty until M0 task 3
  tools/                    only the tools that work on a new project (part C)
  extras/                   engine binary, git-ignored (copied from the reference, no download)
  builds/                   git-ignored. builds/review-<name>/ holds everything shown to you
  docs/
    migration/START-HERE.md the first page of the migration session
    migration/decisions.md  all Q2143-Q2178 answers, copied word for word
    tickets/                the new board (part C2)
    agents/                 agent-brief.md (one page), git.md (one page)
  reference/                git-ignored. The original game lives here (A2)
    .gdignore               tells Godot not to read the old project
    it-socks/               the baseline: the old game, runnable, tools usable
```

Why `reference/` is ignored by the new repo: the old repo has its own `.git`, 4,864 files and a second
`project.godot`. If the new repo tracked it, every commit and every test mirror would carry it.

Two cautions I found in the tools (measured by reading `tools/run.py` and `tools/_mirror.sh`): the test
mirror copies the repo with an exclude list (`.git .claude extras builds .godot docs/screens docs/art`).
`reference` is not on that list. Add `reference` to it in the first tools task, or every test run
copies 400 MB. Godot also scans every folder, so `reference/.gdignore` is needed (judged: a nested
`project.godot` is skipped by Godot anyway, but `.gdignore` makes it certain).

## A2. Three ways to put the old repo in a subfolder

| | 1. Plain `git clone` into an ignored folder | 2. Git submodule | 3. Subtree, or copy with history |
|---|---|---|---|
| What you run (host) | `git clone <old-folder> reference/it-socks` | `git submodule add <url> reference/it-socks` | `git subtree add --prefix=reference/it-socks <old-folder> main` (or a plain copy of the files) |
| Disk (measured/judged) | Full clone from the local folder: about 1.4 GB `.git` + 0.4 GB files = about 1.8 GB (judged). Shallow `--depth 1` from the local folder: about 0.4 to 0.5 GB (judged) | Same as 1, plus a copy of the `.git` inside the new repo's `.git/modules` | Biggest: 1.4 GB of history lands in the new repo's own `.git` for good |
| LFS files | Yes. The clone's own LFS hooks fetch them. A clone from a local folder takes them from that folder's `.git/lfs` (judged, not tested; if it fails, `git lfs fetch --all` against GitHub or copy `.git/lfs` over) | Yes, but each submodule needs `git lfs install` and the right URL | Subtree copies pointer files, and the 364 MB LFS objects must also be pushed to the new repo's LFS. The copy option puts 1,448 more LFS files into the new repo |
| Old game stays runnable | Yes. Run `bash tools/run.sh` inside `reference/it-socks`. It finds its own folder by itself (measured: `cd "$(dirname "$0")/.."`) | Yes, same | Only after you move it back out: paths inside it assume it is the repo root |
| Old tools usable | Yes, unchanged. Engine: set `GODOT=<new-repo>/extras/Godot_v4.7.1-stable_linux.x86_64` (`tools/_mirror.sh` honours `GODOT`) | Yes, same | Tools see the outer repo as root, so `git` commands in them hit the wrong repo |
| Update after an old-game bug fix | `cd reference/it-socks && git pull` from the old folder. Nothing in the new repo changes | `git submodule update --remote`, then a commit in the new repo that moves the pin | `git subtree pull`, a merge commit in the new repo. Conflicts are possible |
| Mounted-drive risk | Low for the new repo (it never tracks the reference). The old repo's glitch risk stays what it is today | High. A submodule keeps its git folder in `.git/modules`, and the glitch hits trees and objects; a broken pin blocks the whole new repo | Highest. 2,133 commits of old history written onto the glitchy drive, inside the new repo you want clean |
| Fits "fresh project" | Yes: no history carried | Half: the new repo points at the old one | No: carries the old history |
| Hand work | One command, one `.gdignore`, one ignore line | `.gitmodules`, URL must be reachable (235 commits are not on GitHub yet) | Long and slow on the drive |

**Recommendation: option 1, a plain clone into `reference/it-socks/`, ignored by the new repo.**
It is the only option where the new repository stays clean and small, the old game and its tools
run exactly as today, and an old-game fix is one `git pull`. A shallow clone is a good
variant if disk matters (judged: you lose old history in that folder, but the original folder still
has it). I would take the full clone because it is only 1.4 GB more and the drive has 217 GB free.

What goes wrong with it: the new repo does not record which old commit it points at. The fix is one line
in `docs/migration/START-HERE.md` ("reference = old repo at commit `<hash>` on `<date>`"), updated after each pull.

---

# B. The preparation: step list

The order is: designer on the host, then a session in the sandbox. Everything here is preparation. No
asset is ported and no game code is written.

## B1. The designer runs on the host (Windows)

Names in angle brackets are your choice.

1. On GitHub, create the empty repository `<new-repo-name>` (no README, no licence). Private is fine.
2. In your repositories folder (the one that holds `it-socks`), in Git Bash or a terminal:
```
cd C:\Users\Gripe\personal\repositories
git lfs install
git clone https://github.com/<you>/<new-repo-name>.git
```
3. Make the reference folder and clone the old game into it. Run this from the new repo's folder:
```
cd <new-repo-name>
mkdir reference
git clone ..\it-socks reference\it-socks
cd reference\it-socks
git lfs pull
cd ..\..
```
   If `git lfs pull` complains it cannot find objects, tell the session; it is the one thing in this plan I could not test.
4. Windows git settings on the mounted drive, in both repos:
```
git config core.filemode false
git -C reference\it-socks config core.filemode false
```
5. Tell the sandbox about the new folder (the way you added `it-socks`). Then start a Claude Code
   session with the new folder as its working directory.
6. Before step 3, if you want GitHub and your disk to agree, push the old repo first:
   `cd ..\it-socks && git push origin main` (235 commits, optional; question E3).

Do not run `git stash`, `reset` or `checkout` in the old `it-socks` folder: your uncommitted editor
files live there. The clone in step 3 only reads from it and is safe.

## B2. A session does in the sandbox (preparation, in this order)

| # | Step | Output | Check |
|---|---|---|---|
| P1 | `git lfs version`; `git status` in the new repo; `cat reference/it-socks/.git/HEAD`. Confirm `reference/it-socks` has real files, not LFS pointers: `file reference/it-socks/assets/house/house.glb` is not "ASCII text" | verdict line | pointers = run `git lfs pull` again |
| P2 | Write `.gitignore`, copy `.gitattributes` and `.editorconfig` and `.claude/settings.json` from the reference | 4 files | `git check-ignore reference/it-socks` prints it |
| P3 | Copy the engine: `cp reference/it-socks/extras/Godot_v4.7.1-stable_linux.x86_64 extras/` (if the reference has none, the designer copies it from the old folder's `extras/`). No download | engine in `extras/` | `extras/Godot_v4.7.1-stable_linux.x86_64 --version` prints 4.7.1.stable |
| P4 | Write the `project.godot` skeleton (B3) and empty `game/ assets/ data/ tests/` with `.gitkeep` | skeleton | `extras/Godot... --headless --path . --import --quit` exits 0 (this is a run of the engine, not of the game; it is the only run in preparation) |
| P5 | Copy `GLOSSARY.md`. Copy the Q2143-Q2178 answers word for word into `docs/migration/decisions.md`, and the asset inventory (`docs/research/nativize/fresh/assets-inventory.md`) into `docs/migration/assets-inventory.md` | 3 docs | `wc -l`; open one to see it reads alone |
| P6 | Write `CLAUDE.md`, `README.md`, `docs/migration/START-HERE.md` (drafts in part D) and the two agent pages | 5 docs | a fresh reader test: P9 |
| P7 | Create the board folders and the template, and the M0/M1 ticket files with titles only (C2) | `docs/tickets/` | filenames match the pattern |
| P8 | Tools check: copy only the "copy unchanged" tools (C3). Run `bash tools/git_check.sh main`, `bash tools/engine.sh`, `python3 tools/png_strip.py --help`, and in the reference `GODOT=<engine> bash tools/suites.sh <one small suite>` to prove the old game and its tools still run from the subfolder | one table | all print a verdict; "no verdict printed" is a failure |
| P9 | Cold-read test: a fresh sub-session reads only `CLAUDE.md` and `START-HERE.md` and answers "what are the first three tasks, and who decides?" without opening anything else | its answer | it names the three tasks and the dialog rule |
| P10 | Commit with exact paths (never `-a`), then `bash tools/git_check.sh` | commit `docs: migration start` | `PASS` |

Hard stops in preparation: no `.glb` copied, no `.gd` written, no `.tscn` made, no `tests/` file.

## B3. The Godot skeleton (what to copy from today's `project.godot`)

Godot 4.7.1-stable, renderer Forward Plus (what the old game uses). Minimal files: `project.godot`,
`.editorconfig`, `.gitattributes`, the empty folders. No `export_presets.cfg` (made on the first export).

| Setting in today's `project.godot` | Verdict |
|---|---|
| `config_version=5`, `config/features=("4.7","Forward Plus")` | copy |
| `config/name`, `config/version` | rewrite (new name, version 0.0.1) |
| `3d/physics_engine="Jolt Physics"` | copy (Q1200: Jolt wherever it can) |
| `common/physics_interpolation=true`, `max_physics_steps_per_frame=3`, `physics_jitter_fix=0.0` | copy |
| `jolt_physics_3d/limits/max_bodies=32768`, `max_contact_constraints=65536`, `temporary_memory_buffer_size=128` | leave for now; add at the core-loop milestone with the Mess (the Mess is what needs them, judged) |
| display 1920x1080, `canvas_items`, aspect `expand` | copy |
| `rendering_device/driver.windows="d3d12"` | copy |
| `anti_aliasing/quality/msaa_3d=2`, `screen_space_aa=1` | copy |
| `[editor_plugins]`: `copy_errors` | copy later with the addon, when the first script exists |
| `[autoload]`: Settings, UiSounds, Profily | leave: they belong to old code; Profily returns with the first bench |
| `run/main_scene` (`game/ui/title.tscn`) | leave (nothing to run) |
| `[input]` 47 actions | copy only `move_*`, `interact`, `jump`, `crouch`, `sprint`, `turn`/`look_*`, `ui_accept` when the M1 walker is built; the rest comes with the feature (debug, zoo, xray, wardrobe, stress actions never) |
| `export_presets.cfg` | leave in the reference |

---

# C. What carries over, and the new board

## C1. Every document, skill, data file and memory, one verdict each

Verdicts: COPY (as is), REWRITE (short, new), LINK (stays in the reference folder, the new docs name its path), DROP.

| Item | Size | Verdict | Reason |
|---|---|---|---|
| `GLOSSARY.md` | 384 lines | COPY | Q2166 says it comes over. It still holds words for switched-off features; keep them, mark none (the designer prunes while porting) |
| `CLAUDE.md` | 62 lines | REWRITE | Q2166. Most of it is a map to files that will not exist. New one is about 40 lines (D1) |
| `README.md` | 4 KB | REWRITE | Its file list describes the old tree |
| `docs/agents/agent-brief.md` | 83 | REWRITE to about 35 lines | Keep: start, commands, tests, finish, git glitch. Drop: house layout, `layout.py`, `game/<feature>` list, tuning JSON, lambda leak tip |
| `docs/agents/git.md` | 148 | REWRITE to about 40 lines | Keep: branches, no squash, designer's copy, glitch repair, never `-a`. Drop: playtest tags, `RESULT` line details, integrate rewrite rules that go with the tools you keep |
| `docs/agents/issue-tracker.md` | 115 | REWRITE as `docs/tickets/README.md` (C2) | New board, new format |
| `docs/agents/triage-labels.md` | 22 | DROP | New statuses (C2); mattpocock names not needed |
| `docs/agents/domain.md` | 51 | DROP | One line in `CLAUDE.md`: read `GLOSSARY.md` |
| `docs/agents/agent-cost.md` | 17 | LINK | `tools/agent_cost.py --help` explains itself |
| `.claude/skills/designer-grilling` | 30 | REWRITE (15 lines) | Keep: dialog only, at most 4 questions, recommended first, Q numbers. Rule is the designer's most repeated |
| `.claude/skills/ticket-agents` | 65 | REWRITE (20 lines) | Keep: one owner for shared pieces, pre-flight questions, Sonnet by default, no resume for new work. Drop: worktree and merge detail |
| `.claude/skills/token-budget` | 24 | REWRITE (10 lines) | Quiet tools, small images, targeted suites |
| `.claude/skills/review-material` | 31 | REWRITE (12 lines) | `builds/review-<name>/`, strips, no unprompted review build |
| `.claude/skills/headless-harness` | 89 | LINK, rewrite at M0 task 3 | Describes the old harness; the new suite has "similar rules, different fields" (Q2143) |
| User skills `godot-game-dev`, `multiplayer-game-dev`, `blender-3d-modelling` | | NOTHING TO DO | They live in `~/.claude/skills`, so they work in any folder |
| `.claude/settings.json` | 25 | COPY | Deny list for destructive git |
| `docs/TESTING.md` | 409 | LINK | Specific to old suites; the new one is written with the new suite |
| `docs/perf/tools.md` | 174 | LINK | Bench, stress, zoo: baselines for later. Reused in M3 |
| `docs/architecture.md` + `docs/architecture/*` | 169 KB | LINK | Describe the old code. A new architecture is planned first (Q2143) |
| `docs/adr/` | 13 files | DROP from the new repo (stay linkable) | Q2166. ADR-0006 gets a new record when shape B is proven |
| `docs/llm/` ticket vault | 598 md, 2.9 MB | LINK | Q2166. New tracker points to it by path when a ticket ports something |
| `docs/llm/.obsidian/`, `Home.md`, `Progress.base` | | REWRITE (small Base file, C2) | Keep the Obsidian idea, cut the columns |
| `docs/art/` | 144 MB | LINK | Pipeline docs and line-ups for the old assets. The asset inventory is copied instead |
| `docs/research/nativize/**` | 1.9 MB | LINK | Only `fresh/assets-inventory.md` is copied. `unify/code-shape.md` is read at M2 design time, then answered fresh |
| `docs/screens/`, `docs/ideas/` | 19 MB | DROP | Re-takeable shots; ideas stay in the reference |
| `data/*.json` (designs, sounds, credits) | 1.3 MB | LINK | Each number or table comes with its feature (Q2164) |
| `assets/`, `audio/`, `assets_src/` | 220 MB | LINK | Ported in M0, one piece at a time |
| `game/`, `tests/` | 6 MB | LINK | Read as the behaviour reference; nothing copied unexamined |
| `studio_intro/`, `studio_intro (2).zip`, `game/1` | 2 MB | DROP | Stray files (measured: untracked) |
| `export_presets.cfg` | 2.7 KB | LINK | Made again at first export |
| Memory folder (25 notes) | | REWRITE into `CLAUDE.md` (D4) | Memory is keyed to the folder path, so the new folder starts empty. These lessons must be written into repo files |

## C2. The new tickets and issues board

Short on purpose. A ticket is one markdown file. The designer opens `docs/tickets/` as an Obsidian vault.

**Folders**

```
docs/tickets/
  README.md                 the format below, one page
  Board.base                Obsidian table: milestone, status, title (30 lines)
  _template.md              the blank ticket
  M0-assets/       T001-....md
  M1-house/        T0xx-....md
  M2-first-slice/  M3-core-loop/  M4-stages/  M5-menus-saves/  M6-by-need/   (created when reached)
  decisions/                one file per open design question (kind: decision)
```
A ticket's number is global and never reused (T001, T002, ...). The folder is its milestone.

**Frontmatter** (from the old format I kept 5 keys and dropped 7)

```yaml
---
status: planned          # planned | design-agreed | building | built | approved | parked
kind: piece              # piece | task | bug | decision
milestone: M0
area: assets             # assets | house | co-op | core | ui | tools | docs
ported_from: assets/furniture/kitchen_cupboard.glb   # path in reference/it-socks, if any
blocked_by: []           # [[T004-...]]
---
```
Dropped from the old format and why: `type` (always ticket), `feature` (the folder says it), `created`/`done` (git
history holds the dates), `notes`, `terms`, `priority` (the board order is the priority, the designer sets it).

**Statuses** (Q2170 gave four; I added two, judged): `planned` nothing agreed. `design-agreed` the design and the
behaviour list are approved. `building` an agent holds it. `built` code is done and tested, waiting for the
walkthrough. `approved` the designer answered the dialog; only now may it merge. `parked` waiting on the designer
or on another ticket.

**Body** (headings in this order): `# Title`, one paragraph what and why; `## Design` (classes, fields, code
sketch; before building); `## Behaviour list` (plain words, the designer approves it; tests come from it, Q2165);
`## Acceptance`; `## Answers` (each ends `(Qnnn, date)`); `## Open follow-ups` (`[blocking]` or `[later]`);
`## Built log` (dated: changed, files, verified, commit); `## Walkthrough` (link to the artifact page, Q2169).

**How the milestones map to tickets.** One milestone is one folder. A piece (a prop, a kit part, the Door, the Hands)
is one ticket and moves through the four states of Q2170. A milestone is done when all its piece tickets are
`approved`. The tracking page on the artifact (Q2150, Q2170) is built from `Board.base` plus the tickets' status;
the files are the truth, the page is a view.

**Milestones M0-M6** (my reading of Q2145-Q2162, 2026-11-19; the designer's answers do not number them, so check this):

| | Milestone | Source |
|---|---|---|
| M0 | Assets ported and cleaned: models, sounds, UI art, shared materials. No scenes of the house | Q2149, Q2151-2153, Q2162, Q2177-2178 |
| M1 | The house, no game functions: half-metre kit, ported props placed, editor-editable, throwaway first-person walker | Q2154-2157, Q2175-2176 |
| M2 | First co-op slice: one Door, one carried thing, Host, Guest and late joiner in tests; proves state on the scene part | Q2147, Q2160 |
| M3 | Core loop: Mess, Hands, Throws, Pairs, Cabinets with Doors and Drawers; bench no slower than today | Q2161, Q2168 |
| M4 | Stages and Laundry day | Q2161 (named as "not in it") |
| M5 | Menus, saves, lobby (screens as scenes on one Theme) | Q2161, Q2163 |
| M6 | Features by need, each the designer's call: Hampers, Grotto, Dirty Socks, pairing machine, the Cat, cutscenes | Q2144 |

**First tickets, titles only** (created as files in P7, empty bodies, status `planned`)

M0: T001 Port rules: origin, scale, names, collision, file size (design, one page). T002 Shared material library
and the oak pick strip. T003 The new test harness (copy `tests/runner.gd`, `suite.gd`, `run.tscn` pattern, one empty
suite) and `reference` added to the mirror's exclude list. T004 Before-and-after strip tool for ported props
(reuse `png_strip.py`). T005 Port batch 1: five small props as the proof. T006 Port the furniture (67 pieces, in
batches). T007 Port Sock shapes, Avatar and Wardrobe. T008 Port the Cat, washer and cutscene characters. T009 Built-in-code things become models (Q2178:
Drum interior, Guide cards, gift boxes, padlock sign, dust sheet, detector screen). T010 Sounds, music and voice lines.
T011 UI art and fonts. T012 Decide: Blender scripts and the shell (open follow-up "do generators keep running").

M1: T020 Kit grid and piece list (design, half metre, wall lengths 0.5/1/2 m). T021 Wall pieces. T022 Floor pieces.
T023 Door and stair pieces. T024 Sock-spot bake button (Q2176). T025 Ground floor assembled. T026 First, basement, attic
floors assembled. T027 Furniture placed where it stands today. T028 Throwaway walker and the editor play-through.
T029 Decide: one house scene or one per floor (open follow-up).

**Does the Q-number sequence continue?** Recommended yes: the next is **Q2179** (measured: the highest Q in
`docs/llm` is Q2178). One global sequence means every old answer and every new answer has a unique number,
and the new tickets can cite old ones without confusion. The new repo's `decisions.md` keeps the counter.

## C3. Tools: what works as is, what needs edits, what waits

Hard-coded things were found by grepping `tools/` (measured).

| Tool | Verdict | Why |
|---|---|---|
| `engine.sh` | copy unchanged | Version 4.7.1 in two places (`engine.sh`, `_mirror.sh`). Uses `curl`; agents cannot, so copy the binary (P3) |
| `git_check.sh`, `git_repair.sh` | copy unchanged | Generic git. These are the answer to the drive glitch |
| `png_strip.py` | copy unchanged | Generic image strips for review material |
| `suites.sh` | copy unchanged | Calls `tools/run.sh --only=` |
| `agent_start.sh`, `agent_finish.sh`, `_agent_common.sh` | copy unchanged (judged) | Plain git; they refuse to run in the main checkout. Keep only if the branch flow stays (E4) |
| `integrate.sh`, `record_merges.py` | copy with edits, only if the flow stays | `integrate.sh` names `it-socks-integrate-tests` in a temp path; `record_merges.py` writes into old ticket paths (`docs/llm/<feature>/issues`) |
| `housekeeping.sh` | edit | Matches temp names `it-socks-*`; worktree and branch checks are generic |
| `agent_cost.py` | edit one line | `DEFAULT_DIR` hard-codes `-c-Users-Gripe-personal-repositories-it-socks` (the new folder has its own transcript folder) |
| `run.sh`, `run.py`, `_mirror.sh` | edit at M0 T003 | Look for `tests/run.tscn`, `tests/*_test.gd`, `.godot` signature; the exclude list needs `reference`; a new project has no tests until T003 |
| `shot.sh`, `shot.gd`, `shot_actions.gd`, `shot_set.sh` | edit later | `shot.gd` defaults to `res://game/core/main.tscn` and `res://tools/shots/`; wait until M1 has a scene to photograph |
| `export.sh` | later | Writes `builds/windows/ItSocks.exe`; needs `export_presets.cfg` |
| `layout.py`, `move_files.py`, `code_map.py`, `dup_scan.py`, `grep_rules.py`, `testgraph.py` | leave in reference | Read old `game/` and the house layout file |
| `bench.sh`, `stress.sh`, `*.cmd`, `guest_fps*`, `udp_lag.py`, `tools/perf/*` | leave in reference, reuse at M3 / M2 | Baselines: the new Mess bench is compared against the old one (Q2168) |
| `blender/*`, `gen_*.py`, `fetch_radio.py`, `guide_card.py`, `pack_prints.gd`, `voiceover/` | run from the reference during M0 | They make the files that M0 cleans; copying them early only duplicates them |
| `font_sheet`, `icon_sheet`, `print_sheet`, `sound_bench`, `write_licences.gd`, `shots_ui_*`, `drawn_*`, `net_shot*`, `house_mocks/` | leave in reference | Specific to old screens and features |

---

# D. The handoff documents (ready to paste)

## D1. `CLAUDE.md` (about 45 lines)

```markdown
# It Socks (new project)

A co-op first-person Godot 4.7.1 game, rebuilt fresh. The original game is the reference in
`reference/it-socks/` (read only; it is a separate git repo, ignored here). Read
`docs/migration/START-HERE.md` first.

## The designer decides
- The designer owns every choice of play, look, wording, sound, cost and structure. You build, verify, ask.
- Ask through the question dialog (AskUserQuestion), never as numbered text. At most 4 questions per call,
  recommended option first. If the dialog is rejected, wait for the designer's words and ask again in it.
- Q numbers are one global sequence. The next is Q2179. A new answer is written into its ticket as `(Qnnn, date)`.
- Before a piece: its design (classes, fields, a code sketch) and a short grilling. After: a plain walkthrough
  of the real code. A piece merges only after the designer says OK.
- A behaviour list in plain words is approved before a feature is ported; tests come from it and change only
  with the designer's OK. Tests check that things work (the core loop most), not where things stand.
- Every line of code must earn its place: ask whether it can be unified before adding it.

## Where things are
- `GLOSSARY.md` the words. Use them in tickets, docs and UI text.
- `docs/migration/` the start page and every decision. `docs/tickets/` the board.
- Folders: `game/` code and scenes by area, `assets/` models by family, `data/` settings and Resources.
- The old game: `reference/it-socks/` (its `GLOSSARY.md`, `docs/llm/` tickets, `game/`, `tools/`).
  Look things up with grep; do not read big files whole.

## How to work
- Agents: Sonnet by default. Opus only for Blender, hard netcode or debugging, big refactors; say why.
- Blender work and anything using the modelling skill goes to an Opus subagent. Blender previews: Workbench at
  half size while iterating, EEVEE only for the final set (no GPU here).
- Physics: use Jolt wherever it can do the job; custom physics only with a reason.
- Parallel work: one Agent per ticket, set the model. A new shared piece has one owner, who first collects what
  each user of it needs. Before a build agent starts, a cheap read-only pass lists the design questions.
- Resuming a finished agent carries its whole transcript: resume only for tiny follow-ups; start fresh otherwise.
- When told to stop agents, also stop the helpers they started, then check nothing still runs.
- Quiet tools: send logs to a file and print one line; `git -q`, `--stat`; capped searches.
- Tests: agents run only the suites they touch. Merging runs the full suite. Never merge a branch that has a
  review build, a blocking question or a pending pick before the designer says so.

## Git and files
- Plain commands only. No sudo, curl, wget, pkill, `rm -rf`, git plumbing. A host command for the designer goes in
  a double-click `.cmd` file or is given exactly; the designer cannot copy from the sandbox terminal.
- This drive loses git tree objects sometimes ("invalid object", "unable to read tree"). After every commit run
  `bash tools/git_check.sh <branch>`; it must print PASS. Only the lead repairs (`tools/git_repair.sh`).
- Never `git commit -a` in the designer's checkout. Never stash, reset or checkout files there. `project.godot`
  and files the designer edits through tools are checked with `git status` before a merge.
- Binaries go through Git LFS. Everything shown to the designer goes in `builds/review-<name>/`; never export a
  review build unprompted: ask first. The main branch is the single source of truth for docs and answers.
- Disk is tight (about 4 GB free in the sandbox). Check free space between big rounds.
```

## D2. `README.md` (first version)

```markdown
# It Socks

A co-op first-person game about tidying socks, rebuilt from scratch in Godot 4.7.1.

Status: preparation done, migration not started. See `docs/migration/START-HERE.md`.

## Open it
1. Install Git and Git LFS (`git lfs install`).
2. Clone this repository, then the old game into `reference/it-socks` (see START-HERE, "Setup").
3. Open `project.godot` with Godot 4.7.1.

## Folders
game/ assets/ data/ tests/ tools/ docs/ (see CLAUDE.md). reference/ is the old game, not tracked.
```

## D3. `docs/migration/START-HERE.md` (draft)

```markdown
# Start here (migration session)

You are continuing the rebuild of It Socks as a fresh Godot project. The designer decides; you build and ask.
The full answers are in `docs/migration/decisions.md` (copied from
`reference/it-socks/docs/llm/maintenance/issues/131-scenes-and-resources-plan.md`, section "Answers").

## Decisions (all 2026-11-19)
1. Fresh project, features ported by need, architecture planned before code; every line fights to stay. Q2143
2. Core loop first; switched-off features (Hampers, Grotto, Dirty Socks, pairing machine) start from nothing. Q2144-2145
3. State lives on the scene part: a field of the node, only the Host's answer to a Command writes it. One generic
   piece does saves, late join and sync. Proven first with a Host, a Guest and a late joiner. Q2146-2147, Q2160
4. Today's game is frozen after the vacuum device set: bug fixes only; it stays the playable baseline. Q2148
5. Order: all assets first (models, sounds, UI art), then the house, then the core loop. Q2149, Q2162
6. A ported prop is the cleaned model plus a scene with no behaviour: model, collision, named moving pieces,
   Sock spots, hold points, shared materials. Q2151
7. Blender scripts stay and build meshes only (.glb). Placement, collision, Sock spots, settings live in Godot
   scenes edited by hand. Q2152
8. "Improve" while porting is technical only (origins, scale, names, collision, materials, file size); looks stay
   the same, proved by a before/after strip. Q2153
9. The house is built by hand from a half-metre kit (walls 0.5/1/2 m, floors, doors, stairs) as scenes on a grid,
   not GridMap. Rooms are nudged to the half metre; furniture re-placed. Q2154-2156, Q2175
10. M1 ends with the house editable in the editor and a first-person walk through it. Q2157
11. Sock spots: a bake button on a furniture piece, saved with the scene, editable by hand. Q2176
12. One shared material library; where variants differ (oak: 9 in 39 models) the designer picks from a strip. Q2177
13. Things built by code today become models or scenes in the asset port. Q2178
14. Authorship: agents write, the designer approves each piece (design and grilling before, walkthrough after,
    merge only on OK). Walkthroughs are pages on the artifact. Q2159, Q2169
15. Core loop = the Mess, Hands, Throws, Pairs, Cabinets (Doors, Drawers). Not in it: Stages, Laundry day, menus,
    saves, lobby. Co-op tests need a plain host/join without the lobby. Q2161
16. Screens are scenes on one Theme. Numbers are typed Resources per feature; a placed prop's number is a field
    on it. Q2163-2164
17. Tests come from an approved plain-words behaviour list; a test changes later only with the designer's OK. Q2165
18. Carried over: glossary, tools as baseline. Rewritten short: skills, agent rules, CLAUDE.md. Not carried: ADRs,
    the old ticket vault (the new board points to it). Q2166
19. Folders: `game/`, `assets/`, `data/`. Q2167
20. The Mess keeps its two-tier design, rewritten clean with its shape explained first; the bench proves it is
    no slower. Q2168
21. Planning lives on one artifact page (https://claude.ai/artifact/5sjTiUUdoSFHDeEwtkMAe2) with a step-tracking
    tab: milestones, pieces, four states. Q2150, Q2170
22. The designer created this repository and added it to the sandbox. Q2158

## Milestones (state at the start)
| | | State |
|---|---|---|
| M0 | Assets ported and cleaned | planned |
| M1 | House from the kit, no game functions | planned |
| M2 | First co-op slice (one Door, one carried thing, Host + Guest + late joiner) | planned |
| M3 | Core loop | planned |
| M4 | Stages, Laundry day | planned |
| M5 | Menus, saves, lobby | planned |
| M6 | Features by need | planned |

## Where things are
- The old game: `reference/it-socks/`, at commit `<hash>` on `<date>` (update after each pull).
- Asset facts: `docs/migration/assets-inventory.md`. Old house questions: `python3 reference/it-socks/tools/layout.py --help`.
- Old code map: `reference/it-socks/docs/architecture.md`. Target-code research: `reference/it-socks/docs/research/nativize/unify/code-shape.md`
  (headings first; it was written before the "fresh project" answer).
- Run the old game's tools from inside `reference/it-socks/` with
  `GODOT=<this repo>/extras/Godot_v4.7.1-stable_linux.x86_64`.

## Working rules
Designer decides. Ask in the dialog. Behaviour list approved before a port. Design and grilling before; walkthrough
after. Nothing merges before the designer's OK. Details: `CLAUDE.md`.

## Your first three tasks
1. Read this page, `CLAUDE.md`, `docs/tickets/README.md`, `docs/migration/assets-inventory.md` (sections 1 and 5). Then
   grill the designer in the dialog on T001 (the port rules) and open follow-ups [blocking] from the inventory
   (do the Blender generators keep running; one house scene or one per floor).
2. T003: the new test harness (tests directory, one empty suite, `tools/run.sh` prints one verdict line;
   `reference` added to the mirror's exclude list). Check it prints PASS.
3. T005: port five small props as the proof of T001, each with a before/after strip in `builds/review-port-proof/`;
   the designer approves each piece in the dialog. Then ask whether to continue with the rest of M0.
```

## D4. Memory lessons worth carrying (cleaned; they are all in CLAUDE.md above)

| Lesson | Old specific removed |
|---|---|
| Designer questions go in the dialog, never numbered text | which round it was said |
| Agents run only plain commands; host commands go in `.cmd` files | the names of tickets |
| No `commit -a` in the designer's checkout; stash/reset/checkout are forbidden there | `project.godot` edits of a specific day |
| Check files the designer edits through tools before any merge | `data/sounds.json` as the example |
| Never merge before a review pick or an answer to a blocking question | "aim-rate" |
| Ask before a review build; one `builds/review-<name>/` folder | dates |
| One merge round for parallel work; agents test their area only, the merge runs everything | `integrate.sh --continue` quirks |
| Sonnet by default; Opus for Blender, hard debugging, big refactors | model version numbers |
| Blender: Workbench half size while iterating, EEVEE only for finals | the binary path |
| Do not use the Workflow tool; one Agent per ticket | |
| Resume costs 300-450k tokens: fresh agent for new work | |
| Stopping agents: also check the helpers they started | `ListAgents` as a tool name only if it exists |
| Jolt wherever it can; custom physics needs a reason | Q1200 detail |
| Pre-flight questions before a build; one owner for a new shared piece | the tools/19-21 story |
| Tests check behaviour (core loop most), not layout | |
| Binaries through Git LFS; install git-lfs again if missing | commit hashes |
| Main is the single truth for docs | stranded-branch list |
| Disk: transcript folder is its own 2 GB volume; check it in long sessions | `/dev/vde` |
| The git glitch on this drive and its tools | |

Not carried: `integrate-continue-quirks` (old tool detail), `native-move-fresh-project` (now START-HERE).

---

# E. Decide before starting

1. **Repository name?** Options: `it-socks` (clean but the same as the old folder name, confusing next to it), `it-socks-fresh`
   (recommended: clear in lists), `it-socks-2`.
2. **Reference: clone, submodule or subtree?** Options: plain clone in an ignored folder (recommended), submodule,
   subtree with history. Part A2.
3. **Push the old repo's 235 unpushed commits to GitHub first?** Options: yes (recommended: one more copy before it
   becomes a baseline), no, only the main branch.
4. **Full clone or shallow clone of the old game?** Options: full (about 1.8 GB, recommended; the old history stays searchable), shallow (about 0.4-0.5 GB).
5. **Does the Q-number sequence continue?** Options: continue at Q2179 (recommended), restart at Q1 with a prefix like `N1`.
6. **Own ticket board format?** Options: the short one in C2 (recommended), a copy of the old one, GitHub issues instead of files.
7. **Same branch-and-integrate flow for agents?** Options: yes with a simpler script (recommended: a ticket branch, `agent_finish.sh`, then merge on your OK), same as today incl. `integrate.sh` and worktrees,
   agents commit straight to a working branch and you merge.
8. **Where should the new repository live?** Options: next to `it-socks` on the mounted drive (recommended: your Windows
   editor can open it, and the glitch tools come along; push often), inside the sandbox only (no glitch, but no
   Windows editor and lost if the sandbox is removed), on the mounted drive with the reference clone inside the sandbox.
9. **Are M0-M6 as I named them in C2?** Options: yes (recommended), change the order, merge M4 into M3.
10. **Keep `studio_intro`, the stray zip and `game/1` in the old repo?** Options: leave them alone (recommended), delete them yourself.
11. **Does the old repo keep its tickets and skills for the freeze period?** Options: yes (recommended), freeze them read-only.
12. **Where is the Windows Godot editor?** Options: the same 4.7.1 you use now (recommended), a newer one.

---

# F. Risks and what I could not check

| Risk | Reading |
|---|---|
| Local clone and LFS: a clone from a local folder may not find the LFS objects, because they are in the old `.git/lfs` and the folder's LFS URL is derived from it | Not tested (no clone made). First check in P1 |
| Disk sizes of the clones | Full about 1.8 GB and shallow about 0.4-0.5 GB are judged from `.git` parts and folder sizes, not from a clone |
| Mounted-drive glitch: a 1.8 GB clone and many LFS files written onto the drive | The glitch hits commits (trees). Cloning writes objects, which is less often hit, but not tested. The sandbox `/` has only 3.9 GB, so do not clone there |
| The 235 old commits not on GitHub | The only copy is your disk. Push (E3) before relying on the old folder as a baseline |
| `project.godot` / `export_presets.cfg` uncommitted edits | `git status` shows no diff on them now. If they have edits you have not committed, the clone does not carry them. The reference will lack your latest editor settings: copy settings by hand |
| About 140 untracked `.import` files (120 wardrobe glbs and others) | Not in git, so not in a clone. Godot re-makes them on import. The reference's first `--import` takes time |
| Engine binary | Not in a clone (git-ignored). P3 copies it from the old folder; if missing, the designer downloads it (agents cannot use curl) |
| Tools that copy the repo into `/tmp` mirrors | They would copy `reference/` (400 MB) until `reference` is excluded; part A1 and T003 |
| Memory | The new folder gets a fresh memory folder; any lesson not written into `CLAUDE.md` is lost |
| Old tickets that said the old repo is the working copy | Ticket paths in the old docs (`docs/llm/...`) resolve only under `reference/it-socks/` |
| Not read in full | The 598 old tickets, `docs/art/*`, the 13 ADRs, `code-shape.md` (headings only), `TESTING.md` and `perf/tools.md` (heads only), most tool bodies (headers and greps only) |
| Not checked | That `run.py` honours `GODOT` for a repo with no `.godot` folder; that a nested `project.godot` is skipped by the editor without `.gdignore`; the real behaviour of `suites.sh` run from inside a subfolder of another repo |
| Judged, not given by the designer | Milestone names M0-M6; the extra statuses `building` and `parked`; the split of copy / edit / leave for each tool |
| A file I expected and did not find | `docs/research/nativize/unify/godot-rules.md` does not exist (the rules are in `docs/research/nativize/godot-rules.md`) |
