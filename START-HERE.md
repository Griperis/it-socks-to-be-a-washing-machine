# Start here: It Socks, the port

You are the lead of a new Claude Code session in a new repository. Two zips were given to you: **starter kit 7.1**
(the project skeleton, tools, skills and the board) and this **port pack** (what is known about It Socks, what the
designer decided, and the first tickets). No memory of the old session exists. Read this file whole, then work
through it.

## What this is
- **It Socks** is a first-person co-op Godot 4.7.1 game about tidying socks (`GLOSSARY.md` defines every word).
  It exists as a running game in another repository, **the old game**, frozen at tag `v0.1.1` (bug fixes only).
- The designer is rebuilding it as a **fresh project** here. Nothing is copied over unexamined: each piece is read
  in the old game, explained, agreed with the designer, and written fresh (`docs/migration/decisions.md`, Q2143).
- **The starter kit owns how work is done** (tickets, branches, commits, merging, tests, review material, the
  designer's working copy): its `CLAUDE.md`, `docs/agents/` and `.claude/skills/`. **This pack owns what is built**
  and the designer's It Socks decisions. Where the two disagree on process, the kit wins, except for the lines in
  `docs/migration/claude-md-section.md`.
- The repository is on a Windows disk mounted into a Linux sandbox. The sandbox's own instructions are in the
  `CLAUDE.md` one level above this repository (network, GitHub authentication, publishing ports).

## The order of work (Q2214)
| | Milestone | In one line |
|---|---|---|
| M0 | Setup | This file: the kit set up, the pack on top, the reference clone, the first tickets |
| M0.5 | The core in a single-player zoo | Movement, handling Socks, pairing, one Cabinet, in a flat graybox zoo; co-op-ready as a Host of one |
| M0.6 | The co-op zoo base | The same zoo with a Guest and a late joiner; avatars; the full knockdown as a native ragdoll |
| M1, M2 | Assets, and the house | Alongside the zoo: the core's models and the avatar rig first; the house by hand from a half-metre kit |
| M3 | The core loop in the house | |
| M4 | The frame of a run | Stages, the Laundry day, menus, saves, the lobby |
| M5 | Features by need | Each first a zoo station |
Details and done-when lines: `docs/migration/milestones.md`.

## M0, step by step
Every step: do, check, expected. Commands run in the repository root. A step that fails twice: stop and tell the
designer what blocks it, in one line.

### 1. The environment
Do: `pwd; ls -A; git status -sb; git remote -v; git lfs version; git config core.filemode; df -h .`
Expected: the two zips (and perhaps `.git`); a remote `origin` naming the designer's GitHub repository; a Git LFS
version; `false` for filemode; at least 5 GB free.
Fails: no `.git`: `git init -b main`, ask the designer for the GitHub URL in the dialog, `git remote add origin <url>`.
filemode not `false`: `git config core.filemode false`. Then `git lfs install`.

### 2. The starter kit
Do: follow the kit's "First run" (its `README.md`): unzip `starter-kit-7.1.zip`, move the contents of its
`starter-kit/` folder into the repository root, `chmod +x tools/*.sh tools/*/*.sh .claude/statusline.sh`,
`tools/engine.sh --fetch`.
Then run the kit's `project-setup` skill. These values are already decided; show them to the designer in **one**
dialog question ("Set the project up with these values?", the values in the option's description) rather than
asking each:
| Value | Setting | From |
|---|---|---|
| Name | `It Socks` | |
| Co-op | `yes`, shape `scene-parts` | Q2147, Q2205 |
| Zoo | `yes` | Q2207, Q2211 |
| Blender | `yes` | Q2152: the Blender scripts stay and build meshes |
| Profily | `yes` | the old game uses it |
| Models | `sonnet by default; opus for Blender, hard netcode or debugging, big refactors` | the old project's rule |
| Save compatibility from | `the first outside play-test` | Q1795 |
| Parallel agents | ask: the old project ran up to 5 | |
Check: the checks the kit's README lists (`tools/run.sh`, `tools/shot.sh`, `grep_rules.py`, `asset_lint.py`, the
tools' unit tests, `setup.py --check`). Expected: each prints its PASS or OK line; write the lines into the setup
ticket's Built log.
The capture tour is not a setup value: it is a template (`.claude/skills/godot-game-dev/templates/`, part
`tour/`), copied into the game when the first baseline view can be shown (M3 at the latest).
The kit's question numbering starts at Q1 for a new game. **Here the numbers continue the old game's sequence**
(Q2197): the next free number is line 1 of `docs/migration/decisions.md`. Say so in `CLAUDE.md` (step 4).

### 3. The pack
Do: unzip `it-socks-port-pack.zip` into the repository root. It adds `START-HERE.md`, `PACK-MANIFEST.md`,
`docs/migration/`, `.claude/skills/migration-port/`, `reference/.gdignore`, tickets under `docs/llm/`, and it
**replaces** the kit's stub `GLOSSARY.md` with the game's. It touches no other kit file.
Check: `python3 docs/migration/check_pack.py` prints `OK pack: <n> files`.
Then delete the kit's two example tickets (`docs/llm/mvp/issues/01-first-playable.md`,
`docs/llm/questions/issues/01-core-loop.md`); `maintenance/issues/01-project-setup.md` stays as M0's ticket
and move both zips out of the repository (or delete them): they must not be committed.

### 4. The repository's own lines
Do:
- Append to `.gitignore`: `/reference/*` and `!/reference/.gdignore`.
- Insert the text of `docs/migration/claude-md-section.md` into `CLAUDE.md` under "Rules only this project has".
- `docs/llm/mvp/spec.md`: replace the placeholder lines with a ten-line pitch taken from `GLOSSARY.md`'s opening
  and `docs/migration/behaviour-core-loop.md` part 1, and a pointer to `docs/migration/README.md`.
Check: `git check-ignore -v reference/x` names the rule; `python3 tools/placeholders.py` runs.

### 5. The reference clone
Do (Q2180, Q2206: the tagged commit only):
```
git clone --depth 1 --branch v0.1.1 https://github.com/Griperis/sock-it.git reference/it-socks
git -C reference/it-socks lfs pull
git -C reference/it-socks config core.filemode false
file reference/it-socks/assets/house/house.glb
git -C reference/it-socks log -1 --format='%H %ad %s'
```
Expected: the `file` line says `glTF binary model`, not `ASCII text` (an LFS pointer). Write the commit line into
`docs/migration/README.md` under "Reference commit". `tools/check.sh` and `tools/run.sh` still pass (the kit's
tools skip `reference/`); `git status --short | grep -c reference/it-socks` prints 0.
Fails: `could not read Username` or a 403: follow "Git Authentication" and "Network access" in the sandbox's
`CLAUDE.md`, give the designer the exact command it names, and wait. Still pointers after `lfs pull`: the LFS
objects were not pushed; tell the designer (they push the old repository themselves, Q2179).
The old game's engine can be reused: `cp extras/Godot_v4.7.1-stable_linux.x86_64 reference/it-socks/extras/` lets
its tools run (`reference/it-socks/tools/`), for example its bench and its capture tour.

### 6. The first commit and push
Do: `tools/commit.sh -m "M0: starter kit 7.1, the port pack, setup" <exact paths>` (everything the kit and the
pack brought, and what steps 2 to 4 changed; no `Co-Authored-By` line, the tool refuses one), then `bash tools/git_check.sh main`, then `git push -u origin main`.
Expected: `PASS git_check`; `git status -sb` shows `## main...origin/main`.
Fails: "unable to read tree" or "invalid object": retry once; then `bash tools/git_repair.sh .`, check again, tell
the designer in one line. This drive does that a few times a day.

### 7. Close M0
Set the setup ticket (`docs/llm/maintenance/issues/01-project-setup.md`) to `done` with a dated Built log (what ran, what it printed),
mark M0 in `docs/migration/milestones.md`, add the journal entry (`docs/migration/journal.md`), commit, push.
Tell the designer in a few lines: what is in place, the reference commit and its date, anything that failed.

## Then: M0.5, with the designer
Go straight on; do not wait for a word to start. M0.5's own first step is a conversation, not code:
1. Load `migration-port`, `zoo-design`, `multiplayer-game-dev` and `designer-grilling`.
2. Read `docs/migration/coop-structure-for-the-port.md` (how every old co-op mechanism maps onto the new
   structure) and `docs/migration/behaviour-core-loop.md`.
3. Take the first M0.5 ticket (`docs/llm/core/issues/01-zoo-movement.md`): write its behaviour list from the
   reference, and ask the designer to approve it in the dialog. Then its design (classes, fields, a code sketch)
   and the grilling. Only then code (Q2159, Q2165).
The four M0.5 tickets and the three M0.6 tickets are in `docs/llm/core/issues/`. Asset and house tickets (M1, M2)
are opened when the designer calls for them; they may run beside the zoo (Q2214).

## What the designer said about how to work (the kit's skills hold the general rules; these are theirs)
- "Every line of code has to fight for it's life." Before a line is added, ask whether an existing piece does it.
- "A lot of authorship and decisions on my side." Explain the structure; ask about it; never decide a choice of
  play, look, wording, sound or cost.
- Merging: "My OK per piece, merged in batches. Ideally don't have too much additional process in integrating
  the branches, we should move quickly." (Q2200)
- Small visible faults are fixed at once (`fast-lane`); the designer asked "how this fix can take 10 minutes?"
  of one that went through the full ticket flow.
- Reproduce before you diagnose: the old session's first diagnosis of a visual fault was wrong and cost a round.
- Tests: "They can pin layout, but it shouldn't be the THING that's important." The core loop is tested most.
  Never test through a zoo or debug button.
- The zoo: "Real entities from the game - so we are not testing / implementing two different systems at once.
  Zoo should be always a scene, that can be easily edited in editor." (Q2211)
- Animations: "I would like to consider animationplayers for the animations, not directly code animations."
  (Q2213)
- Balance numbers come only from the designer; every placeholder is marked.
- A journal is kept from the first day; the move ends in a retrospective and a reusable skill set for moving
  another project the same way.
