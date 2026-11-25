# Damaged commits on the virtiofs mount: cause and fix

Asked for: ticket `docs/llm/maintenance/issues/05-git-on-virtiofs.md` (designer, 2026-11-25: "most likely the
virtiofs filesystem in the Docker sandbox; figure something out"). Measured 2026-11-25 in throwaway lab repos
(deleted afterwards, except a few raw-test files the sandbox could not delete; see the end). git 2.47.3 in the sandbox, Linux 7.0.14, Windows host folder mounted over virtiofs
(`host[/c/Users/...]`, `rw,nosuid,nodev,relatime`). Everything below was **tried**, unless it says "hypothesis".

## Answer

- **The cause is the way git finishes a new object file: `link(tmp, final)` and then `unlink(tmp)`**
  (`core.createObject=link`, the default on Linux). On this mount, a file made that way sometimes cannot be
  opened afterwards, for seconds to many minutes: a directory listing shows the name (`ls -la` prints the mode with a
  trailing `?`, as in `-r--r--r--?`), but `open()` and `stat()` get **ENOENT**. It was never EACCES, EBUSY or EIO. Git then calls the object
  "invalid", "Could not read" or "could not parse HEAD". This needs neither several processes nor several
  worktrees: one process writing one file at a time does it.
- **`git config core.createObject rename` ends it.** Git then finishes each object with one `rename(tmp, final)`.
  Over 5500 lab commits on the mount (single and parallel, one run made while link-mode workers in another
  lab repo were stuck): **0 refused, 0 damaged, 0 noise, fsck clean.** In the same loops the default gave
  10-60 events per 1000 commits. No measurable cost per commit.
- **Waiting is not a fix.** Most unreadable objects turn up within 1 s, but a measured share took 2-6 minutes and
  a few raw test files were still unreadable after 40 minutes. A `commit.sh` that waits up to 3 minutes with
  backoff gave up 15 times in one run (below).
- **Nothing was lost in the git labs:** every object git called invalid read back later, and `git fsck --full`
  passed on every repo. Damage is a delay, not a loss. The game's object store showed no unreadable loose
  object when it was scanned (6742 listed, 0 unreadable).
- `core.fsync`, `gc.auto=0` and `core.checkstat=default` do not help (table).

## Setup

- Lab repos: one under `.claude/gitfs-lab/` on the mount (gdignored by `.claude/.gdignore`) and the control under
  `/tmp` (the sandbox's overlay disk). Config like the game's: `core.filemode false`, `core.symlinks false`,
  `core.ignorecase true`, and the sandbox's global `core.checkstat minimal`.
- A run: `git init`, one commit, N worktrees; per worktree a loop that writes a new file in one of 7 folders and
  appends to a shared file, `git add`, `git commit`, then reads the commit back as `commit.sh` does
  (`git cat-file -e <c>^{tree}` and `git ls-tree -r -t <c>`); `git fsck --full` at the end.
  - **refused**: git made no commit ("invalid object ... Error building trees", "unable to read tree", "could not parse HEAD").
  - **damaged**: a commit was made but does not read back (`commit.sh`'s `COMMIT DAMAGED`).
  - **noise**: a commit was made and reads back, but git printed "invalid object" on the way (what `commit.sh` hides).
- Raw tests without git (Python): write a temp file, finish it with link+unlink, rename, or link only, then
  open the final name from a new process.

## Counts

Per 1000 commits. 5 worktrees x 200 commits unless the label says otherwise. avg s = mean seconds per `add`+`commit`
on the mount (the host's load varied by run: compare within a pair, not across rows).

| Run | Settings | refused | damaged | noise | fsck | avg s |
|---|---|---|---|---|---|---|
| /tmp control (3 runs, 3500 commits) | default | 0 | 0 | 0 | ok | 0.016-0.019 |
| /tmp control | `core.createObject=rename` | 0 | 0 | 0 | ok | 0.022 |
| base (1000) | default | 16 | 0 | 30 | ok | 0.159 |
| base2 (5x300) | default (an auto gc ran in the middle) | 7 | 0 | 9 | ok | 0.116 |
| base3 | default | 19 | 0 | 13 | ok | 0.139 |
| objects folders made beforehand (5x300) | default | 23 | 0 | 22 | ok | 0.120 |
| single worktree (1x500) | default | 26 | 0 | 36 | ok | 0.076 |
| watch (5x400) | default | 186* | 5 | 6 | ok | 0.157 |
| fsync | `core.fsync=objects,derived-metadata,reference` + `core.fsyncMethod=fsync` | 33 | 3 | 25 | ok | 0.156 |
| gc.auto=0 | `gc.auto=0` | 116 | 0 | 23 | ok | 0.137 |
| checkstat | `core.checkstat=default` | 25 | 1 | 31 | ok | 0.094 |
| **rename** | `core.createObject=rename` | **0** | **0** | **0** | ok | 0.200 |
| **rename2** | `core.createObject=rename` | **0** | **0** | **0** | ok | 0.113 |
| **rename3 (5x400)** | `core.createObject=rename`, run while link-mode workers in another lab repo were stuck | **0** | **0** | **0** | ok | 0.140 |
| **rename, single (1x500)** | `core.createObject=rename` | **0** | **0** | **0** | ok | 0.093 |
| **rename + fsync** | both | **0** | **0** | **0** | ok | 0.242 |

\* 352 of the 371 refusals in that run followed from a damaged commit: once HEAD's commit or tree cannot be read,
the worktree's next commits are refused ("unable to read tree", "could not parse HEAD") until it turns up. That
cascade is why one late object can look like several damaged commits in a session.

Raw test, without git (fresh folder per file, a new process opens it at once, then again for up to 3-300 s):

| Finish | files | open failed (ENOENT) |
|---|---|---|
| `link(tmp, final)` + `unlink(tmp)` | 15 + 40 + 15 + 4 | 7, 23, 5, 4 |
| `rename(tmp, final)` | 200 | 0 |
| `link(tmp, final)`, no unlink | 200 | 0 |

The mode of the file (0444 as git makes it, or 0644) makes no difference. `sudo` dropping the guest's caches
(`echo 2 > /proc/sys/vm/drop_caches`) did not bring a failed file back, and neither did another spelling of
the name (the host is case-insensitive): the state is on the host's side of the mount, not in the sandbox's kernel.
Such a file also cannot be deleted from the sandbox (`rm`: "No such file or directory", folder "not empty").
Looking at a failed file again and again does not keep it unreadable: of 40 files that all failed at once
(19:29, during a bad spell), 20 opened every 2 s and 20 left alone were still all unreadable at 3, 6 and 10 minutes.
Yet `rm` then deleted those 40, while 12 files from the first tests (18:53-19:00) could still be neither read nor deleted
at 19:40.

## Is it only late? (the designer's question)

For each object git called invalid, the lab read it again later:

- watch run (38 objects, polled every 0.5 s): all readable within 1.1 s, most within 0.2 s; the 9 objects behind
  the 5 damaged commits within 0.2 s.
- base3 (32 objects, read at 0, 1, 5, 30, 120 s): 13 at once, 10 by 1 s, 2 by 5 s, **7 still unreadable at 120 s**.
- fsync run (33 objects): 1 by 5 s, **32 still unreadable at 120 s**; the 3 damaged commits' trees read back at 1 s.
- The lead's live case in the main checkout (19:14): a tree unreadable at +0, +5 and +30 s, readable at about +45 s.
- In every git lab repo, every one of these objects was readable a few minutes later (0 unreadable on a full scan).
- **A `commit.sh` that waits** (lab copy: a refused commit retried, a damaged one re-read, backoff 0.5 s doubling to
  16 s, up to 192 s): of 20 waits, 5 succeeded after 7.6 s and **15 gave up at 192 s**. The 15 failures happened in three
  bursts (19:21:17, 19:24:37 and 19:27:50) in all 5 worktrees at once. The objects from the first burst turned up 3-6 minutes after they were
  written. A rename-mode lab run made during the second burst, on the same mount, had no failures.
- Raw test files that failed were mostly still unreadable after 30-40 minutes.

So the object is written and turns up later. But "later" ranges from under a second to many minutes, so a wait in
`commit.sh` would catch most cases but not all, and each wait could hold an agent for minutes. A short wait
(about 5 s) before printing DAMAGED is still worth keeping as a second line of defence (see Proposed).

## Mechanism

What is certain (tried): the trigger is deleting the temp link of a file that has just been given a second name.
Rename and link-without-unlink never fail. The failure is on the host's side of virtiofs (the sandbox kernel's
caches are not involved, and other names and processes see the same). It comes and goes in bursts.

Hypothesis (not tried, the host cannot be reached from here): on Windows, deleting a file that something still
has open does not remove it at once. The delete stays "pending" until the last handle closes, and while it is
pending the file cannot be opened. If NTFS applies that to the file and not only to the deleted name, the new
name `final` is unopenable too, and the virtiofs server reports that as ENOENT. Holders that could keep the
handle open: the host's virtiofs server itself (handles it caches per file), or a scanner or indexer that
opens every new file (Windows Defender real-time protection, the Windows Search indexer, a backup or sync
client). Rename-mode files written at the same moment never failed, so a scanner that blocks every new file is
unlikely. The likelier one is whatever holds the temp name open when git deletes it.

Candidates from the ticket, checked:

| Candidate | Result |
|---|---|
| link()+unlink() finishing (`core.createObject`) | **the cause**: rename gives 0 |
| renames not atomic or seen late | no: rename-only finishing never failed |
| no fsync (`core.fsync`, `core.fsyncMethod`) | no: fsync on, damage still there (3 damaged per 1000) |
| stale attribute or dentry cache in the sandbox | no: dropping the guest's caches did not help; another spelling did not help |
| wrong mtimes, so gc/prune drops fresh objects | no: mtimes read back correctly (to 0.1 µs); nothing was lost; `gc.auto=0` did not help |
| the host's git pruning worktrees or objects | not seen: nothing was lost; the labs had no host git |
| several worktrees or processes at once | not needed: one worktree, one process (and the raw test) do it |
| freshly made `objects/xx` folders | not needed: folders made beforehand still failed |

## Proposed settings (not applied)

1. **The fix:** in the game's repository config (`.git/config`; shared by every worktree, so one line covers
   all agents):

   ```
   git config core.createObject rename
   ```

   Git's documentation for `core.createObject` says link+unlink "is unreliable" on some file system and OS
   combinations and to use `rename` there. The trade-off it names: rename "will remove the check that makes sure
   that existing object files will not get overwritten". In git 2.47 the rename path still `stat()`s the final
   name first and keeps an existing file (`finalize_object_file_flags` in `object-file.c`), so what is lost is
   only a guard against two writers racing on one object. Both would write the same bytes, because objects are
   named by their content.
   **Git for Windows already works this way:** git's build file sets `OBJECT_CREATION_USES_RENAMES` for Windows,
   MINGW and Cygwin (`config.mak.uname`), so the designer's git on the host has always used rename on this folder.
   Only the sandbox's Linux git uses link+unlink here. The setting makes the two match, and the host's git is
   unaffected by it.

   Better still, `kit/tools/agent_start.sh` (or `setup.py --check`) could set or check it whenever the repo is on a
   virtiofs mount, so a new clone or a second game gets it too. That is a kit change: a follow-up for the lead.
2. **Keep, and improve, the second line of defence in `kit/tools/commit.sh`:** before printing `COMMIT DAMAGED`,
   re-read for a few seconds (for example 0.5, 1, 2 s: the lab's shortest waits all fell inside 1.1 s). It costs
   nothing when the commit reads back. Not a long wait: past a few seconds, git_repair.sh is quicker.
3. **Not needed:** `core.fsync`/`core.fsyncMethod` (no effect, slower), `gc.auto=0` (no effect; leave gc on),
   `core.checkstat` (no effect).

## If the setting is not enough: what the host could change

Not tried; in order of cost:

- **A Defender exclusion for the repository folder** (Windows Security, Virus and threat protection,
  Exclusions, Folder: `C:\Users\Gripe\personal\repositories\it-socks-to-be-a-washing-machine`), and taking the
  folder out of the Windows Search index. This only helps if a scanner or indexer is what holds the handle (the
  hypothesis above). It lowers protection for that folder.
- **Clone mode** (`sbx` `--clone`): the repo lives on the sandbox's own disk, where the control runs had no
  failures at all and git was 6-8x faster (0.016-0.022 s against 0.09-0.20 s per commit). The trade-offs: the designer's
  editor, Godot and Obsidian on Windows no longer see the agents' work until it is fetched
  (`git fetch sandbox-<name>`). Commits not pushed are lost if the sandbox is removed. The designer's own
  working copy and the sandbox's copy must be kept in step by hand.
- Freeing disk space on the host (97% full) is good practice but was not shown to matter.

## Sources

- git-config documentation, `core.createObject` (git-scm.com/docs/git-config): "a hardlink followed by a delete of
  the source are used ... On some file system/operating system combinations, this is unreliable. Set this config
  setting to 'rename' there; however, this will remove the check that makes sure that existing object files will
  not get overwritten." (read in `Documentation/config/core.txt` at tag v2.47.0). The names `core.createObject`,
  `core.fsync` and `core.fsyncMethod` were checked against the strings in the sandbox's git 2.47.3 binary.
- git source at v2.47.0: `object-file.c` `finalize_object_file_flags()` (link, then unlink; rename mode stats
  first and keeps an existing file); `environment.c` (default `OBJECT_CREATION_USES_HARDLINKS`);
  `config.mak.uname` (`OBJECT_CREATION_USES_RENAMES = UnfortunatelyNeedsTo` for Cygwin, Windows and MINGW).
- Windows delete-pending behaviour (a deleted file stays until its last handle closes, and cannot be opened
  while pending): Microsoft's `DeleteFile` documentation, from memory; the page could not be fetched from the
  sandbox (HTTP 403), so treat it as part of the hypothesis.
- The lab: the scripts were throwaway (scratchpad); the numbers above are their output.

## Left behind

The git lab repos (on the mount and in `/tmp`) were deleted whole. 12 raw-test files (200-300 bytes of random
data or `x`, no git content) in `.claude/gitfs-lab/lt/` in the main checkout could be neither read nor deleted
from the sandbox. Delete the folder `.claude\gitfs-lab` from Windows, or try `rm -rf` again later.
It is gdignored and untracked.
