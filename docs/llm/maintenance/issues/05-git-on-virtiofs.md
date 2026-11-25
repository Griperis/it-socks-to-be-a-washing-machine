---
type: ticket
status: done
kind: maintenance
area: maintenance
feature: git
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: opus", "designer 2026-11-25: most likely the virtiofs filesystem in the Docker sandbox; figure something out", "runs with no other agent committing"]
terms: []
---

# Damaged commits on the virtiofs mount: find the cause and stop it

About 6 commits came out "damaged" last session (`kit/tools/commit.sh` prints `COMMIT DAMAGED`; the new commit's tree
or a blob doesn't read back: "unable to read tree", "invalid object"). Each was rebuilt with `kit/tools/git_repair.sh`.
It happens most with several agents committing from worktrees at once. All worktrees share the one object store
`.git/objects`.

What is known:
- The repo is a Windows host folder mounted into the Linux sandbox over **virtiofs**
  (`findmnt -T .`: `host[/c/Users/...]`, `rw,nosuid,nodev,relatime`). The host disk is 97% full (68 GB free).
- The repo's config came from Windows: `core.filemode false`, `core.symlinks false`, `core.ignorecase true`,
  `core.checkstat minimal`. git 2.47.3 in the sandbox.
- The designer may run git on the host too (an editor's git, Obsidian in `docs/.obsidian/`, Godot), on the same folder.
- `commit.sh` already hides the noise and retries once (kit, lines 18-23).

## What to do
1. **Reproduce, outside the game's repo:** a throwaway repo on the same mount (for example under
   `.claude/gitfs-lab/`, gdignored, deleted at the end) with several worktrees and parallel `git add` + `commit` loops
   (5 at once, a few hundred commits each), then `git fsck`. Do the same on the sandbox's own disk (`/tmp`) as the
   control. Count the damage on each.
2. **Find the mechanism** (candidates, check each): git finishing a loose object with `link()` then `unlink()` of the
   temp file (`core.createObject`); renames not atomic or not seen at once over virtiofs; no fsync (`core.fsync`,
   `core.fsyncMethod`); stale attribute or dentry caching between processes; mtimes the host gives back wrong, so a
   `gc --auto`/`prune` (from any process, the host's included) treats fresh objects as old; the host's own git seeing
   the worktrees' Linux paths as missing and pruning them.
3. **Is it only late?** (designer, 2026-11-25: "couldn't we just wait for some time after commit?") For each damaged
   commit in the lab, read the missing object back again after 1, 5, 30 and 120 s. If it always turns up, the object
   was written and was only not yet visible. Then the fix is `commit.sh` waiting and re-reading before it says
   DAMAGED, with the wait measured. If it never turns up, it was really lost, and waiting doesn't help.
4. **Try the fixes** in the lab, measured: `core.createObject=rename`, `core.fsync=objects,derived-metadata,reference`
   with `core.fsyncMethod=fsync`, `gc.auto=0` (gc only by hand), `core.checkstat default`, others found. Keep what
   brings the damage to zero over the same loops, and give the cost in seconds per commit.
5. Write `docs/research/git-on-virtiofs.md`: setup, counts before and after, the mechanism if found, sources.

## Acceptance
- The lab numbers: damage per 1000 commits on virtiofs and on /tmp, before and after each fix tried.
- The settings that end it are proposed, not applied: the exact `git config` lines and where they go (the repo's
  config, or a kit tool that sets them). The lead applies them with the designer's OK. If a kit change is needed,
  write it as a [blocking] follow-up for the lead.
- If nothing in the sandbox fixes it, the report says what the host should change instead (for example cloning
  into the sandbox's own disk, which is clone mode), with the trade-offs.
- The lab repo is deleted. No commits in the game's repo but the research note and the ticket.

## Open follow-ups
- [blocking] Apply the fix (designer's OK, then the lead): in the main checkout run
  `git config core.createObject rename` (repo config, shared by every worktree; Git for Windows already builds
  with rename, so the host's git is unaffected). Proof and trade-offs: `docs/research/git-on-virtiofs.md`.
- [blocking] Kit change for the lead: (a) `kit/tools/agent_start.sh` or `setup.py --check` sets or checks
  `core.createObject=rename` when the repo is on a virtiofs mount (`findmnt -T .`); (b) `kit/tools/commit.sh` re-reads
  a commit for about 3 s (0.5, 1, 2 s) before printing `COMMIT DAMAGED`, and treats "could not parse HEAD"
  as part of the glitch (`GLITCH_RE` in `kit/tools/_agent_common.sh`). Not a long wait: lab waits of 192 s
  still failed.
- [later] For the designer, only if damage returns after the setting (a hypothesis, untested): a Windows
  Defender folder exclusion for the repo and taking it out of the Search index; or clone mode (trade-offs in
  the note).
- [later] Up to a few raw-test files under `.claude/gitfs-lab/lt/` could not be opened or deleted from the
  sandbox (link+unlink "ghosts"); if the folder is still there, delete it from Windows (see the Built log).

## Built log

### 2026-11-25
- Changed: investigation only, nothing in the game changed. Cause found: on the virtiofs mount, git's default
  object finishing (`link(tmp, final)` then `unlink(tmp)`) sometimes leaves the new object listed but unopenable
  (ENOENT) for anywhere from under 1 s to many minutes. Lab, per 1000 commits on the mount, default: 7-186 refused,
  0-5 damaged, 6-36 noise; /tmp: 0. With `core.createObject=rename`: 0/0/0 over 5500 commits, no measurable cost.
  fsync, `gc.auto=0` and `core.checkstat=default` don't help. Waiting with backoff up to 192 s still failed 15 times
  out of 20. Nothing was lost: every object turned up later and fsck was clean. Git for Windows already builds with rename.
- Files: docs/research/git-on-virtiofs.md
- Verified: lab runs of 5 worktrees x 200-400 commits, and 1 x 500, plus raw link/rename tests (counts in the note);
  `git fsck --full` clean on every lab repo; lab repos deleted (12 raw-test files on the mount left, see Open follow-ups).
- Merged: b36c00d1 (2026-11-25, branch maintenance/05-git-on-virtiofs)
