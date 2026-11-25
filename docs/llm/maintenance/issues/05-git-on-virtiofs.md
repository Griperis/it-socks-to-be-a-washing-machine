---
type: ticket
status: ready-for-agent
kind: maintenance
area: maintenance
feature: git
priority: now
created: 2026-11-25
done:
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

## Built log
