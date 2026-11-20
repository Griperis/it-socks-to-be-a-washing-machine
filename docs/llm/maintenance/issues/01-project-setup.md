---
type: ticket
status: ready-for-human
kind: docs
area: tools
feature: maintenance
priority: next
created: 2026-11-20
done:
blocked_by: []
notes: []
terms: []
---

# Project setup from the starter kit

Make this repo the new game's: fill in the placeholders `kit/tools/setup.py --init` copied in with
the game's files (the kit itself stays in `kit/`, a git submodule; its README is `kit/README.md`),
and check the tools run on this machine.

## Acceptance
- `<GAME NAME>`, the glossary's pitch line and the example tickets' `created:` dates are replaced.
- `kit/tools/engine.sh` prints the engine version.
- `kit/tools/run.sh` prints PASS and `kit/tools/shot.sh` writes a PNG that shows "It runs".
- The first commit is on `main` (optionally tagged `baseline-<date>`).
- The `area:` list in `docs/llm/_templates/ticket.md` fits this game.
- `git lfs install` has run; `kit/tools/housekeeping.sh` ends OK.
- The `project-setup` skill has run: `CLAUDE.md` "Project values" (platforms and renderer among them) hold no `<ask at setup>`, and the
  game's files of the parts the designer opted out of are gone (`python3 kit/tools/setup.py --check`
  prints OK: it also names a file that is still a Git LFS pointer and a script git records as not
  executable).
- The kit's plugin is installed on this machine (`python3 kit/tools/setup.py --plugin`): the skills
  are listed as `game-kit:<skill>`.

## Answers
- Project values as the port pack decided them: name It Socks; co-op yes, shape scene-parts; zoo yes; Blender
  yes; Profily yes; models "sonnet by default; opus for Blender, hard netcode or debugging, big refactors"; save
  compatibility from the first outside play-test; renderer Forward+ (Q2227, 2026-11-20).
- Parallel agents: 5 (Q2228, 2026-11-20).
- Platforms: Windows and Linux desktop (Q2229, 2026-11-20).
- No GitHub remote for now: commit locally, push later (Q2230, 2026-11-20).

## Open follow-ups
- [blocking] The reference clone (START-HERE step 5) failed: `git clone` of the private `Griperis/sock-it` says
  `could not read Username for 'https://github.com'`. The sandbox has no GitHub token; the designer runs on the
  host: `sbx secret set github --sandbox claude-it-socks-to-be-a-washing-machine -t "$(gh auth token)"`.
- [later] Add a private remote as a backup (`git remote add origin <url>`): the designer makes the repo.

## Built log
- 2026-11-20 (lead). Kit 8.0 (`kit/` submodule at 1cd1ec6), not the zipped kit 7.1 START-HERE names: setup
  followed `kit/docs/SETUP.md` section 1 instead of START-HERE step 2's unzip.
  - Installed git-lfs, xvfb, mesa-vulkan-drivers and the X libraries, Pillow 13.0.0; `git lfs install`.
  - `python3 kit/tools/setup.py --init`: `setup: 112 changes`, `plugin: game-kit@game-kit installed for this machine`.
  - `kit/tools/engine.sh --fetch`: `4.7.2.stable.official.ed1daf0bf` (the pinned 4.7 minor's newest patch; the
    old game used 4.7.1).
  - `python3 kit/tools/setup.py --name="It Socks" ... --coop=yes --coop-shape=scene-parts --zoo=yes --blender=yes
    --profily=yes`: `setup: 53 changes`, nothing removed; `--check`: `OK setup: every project value is set`.
  - `kit/tools/run.sh`: `PASS 303 checks, 74 cases`. `kit/tools/shot.sh`: `-> docs/screens/shots/shot.png`
    (shows "It runs"). `grep_rules.py`: `PASS rules: 9 rules, no new hit`. `asset_lint.py`: `PASS asset_lint:
    0 glb of 1 binaries, 2 look scenes, no problem`. Kit unit tests: `Ran 168 tests ... OK`.
  - The port pack unzipped on top (GLOSSARY.md replaced): `OK pack: 115 files`. Example tickets deleted:
    `mvp/issues/01-first-playable.md`, `questions/issues/01-core-loop.md`, and kit 8's `mvp/issues/02-walking-skeleton.md`
    (blocked by the first). The pack's kit-7 paths (`tools/...`) repointed to `kit/tools/...`.
  - `.gitignore`: `/reference/*`, `!/reference/.gdignore`, `/it-socks-port-pack.zip` (the zip could not be moved
    out: the parent folder is read-only from the sandbox). `git check-ignore -v reference/x` names `.gitignore:43`.
  - `CLAUDE.md` "Rules only this project has" from `docs/migration/claude-md-section.md`; `docs/llm/mvp/spec.md`
    holds the pitch. `placeholders.py`: `PASS placeholders: wrote 4 items`.
  - `housekeeping.sh`: one WARN only, the host disk 90% full (194 GB free).
  - Not done: the reference clone (above, blocking), the push (no remote, Q2230).
