# Can the save layer be ready for Steam Cloud and easy to swap for another store, or none?

Asked for: the designer, about the decided save design (`docs/architecture/saves.md`, "Decided", Q2553-Q2562),
2026-11-23. Engine 4.7.2, GodotSteam 4.24 (see `steam-multiplayer.md` for the install and version facts). Earlier
decision this rests on: Q1684 (old game, 2026-11-11): "Steam Cloud: sync the Profile and the Worlds (Auto-Cloud)".

Every claim is "read, not tried" unless it says otherwise. Steam cannot run in this sandbox, so nothing about Steam
itself was tried. Godot engine facts were read in the 4.7.2-stable source, not run.

## Answer

- **Yes, and the decided design is already most of the way there.** One small self-contained JSON file per World,
  written whole, is exactly what Valve recommends ("As a general rule, smaller files will work better"). What is
  missing is only discipline about file names and folders, plus a thin storage seam.
- **Two Steam routes.** *Auto-Cloud* is set up on the Steamworks site (root folder, subfolder, file pattern, OS
  mapping, quota) and needs **no code**: Steam syncs the matching files before the game starts and after it exits.
  The *Remote Storage API* (`ISteamRemoteStorage`, GodotSteam's `Steam.fileWrite` etc.) means the game reads and
  writes through Steam, which keeps the files in its own folder; it needs a code backend.
- **Autosave every 2 s is not a problem for either route.** Steam uploads after the game exits, not on every write
  ("will automatically be replicated to the Steam servers after the game exits"). The cloud sees the last state of
  each file once per session. Only the opt-in Dynamic Cloud Sync (Steam Deck suspend) uploads during a session.
- **Conflicts are Steam's own:** when local and cloud files differ at launch (typically after playing offline on
  two PCs), the Steam client shows its conflict window and the player picks a side. The game is not involved in
  either route unless it does its own syncing logic.
- **Recommendation: Auto-Cloud, plus a storage seam with one local-file backend.** Auto-Cloud keeps Steam out of the
  save code entirely, works the same for a DRM-free or other-store build, and GOG Galaxy has the same folder-sync
  model. The seam keeps an API backend (Steam, Epic, GOG `IStorage`) possible later without touching `Save`'s callers.
- **Four things to change in the design for Auto-Cloud:** a dedicated, narrow folder and pattern (`worlds/*.json`,
  `profile.json`), so `.tmp`, `.bak`, the damaged file, settings, logs and benches never sync; a per-account subfolder
  (two Steam accounts on one PC must not share Worlds); a project-specific `user://` name set before the first
  outside play-test; and wrapping each save in `Steam.beginFileWriteBatch()` / `endFileWriteBatch()` when Steam is
  present (optional hint, works with Auto-Cloud too).
- **One engine fact affects the write:** in an exported game Godot's `FileAccess` writes in place (its safe
  temp-and-replace is editor-only and not exposed to GDScript), and `DirAccess.rename` on Windows deletes the target
  and then moves the file, so a rename over an existing file is two steps, not one. The kit's `.tmp`/`.bak` order
  copes with that (a crash between the steps leaves `.bak`), so the design holds; it just must not assume an atomic
  replace.

## Findings

### 1. Auto-Cloud versus the Remote Storage API

Source for this section unless named: Steamworks, "Steam Cloud", https://partner.steamgames.com/doc/features/cloud .

- What each is: "Steam Auto-Cloud was designed for games where you choose to not integrate the Steam Cloud API."
  It "lacks the flexibility that is available with the Steam Cloud API." The API "isolates individual Steam users
  files from each other and provides a greater level of control", for example "allowing to choose which save files
  are stored in the cloud." read, not tried.
- Both need the quota set: "set the `Byte quota per user` and `Number of files allowed per user` options on the
  Steam Cloud Settings page." The quota is "enforced on each Cloud-enabled game, on a per-user-per-game basis."
  read, not tried. Valve's page gives no default or maximum quota; it says a single `FileWrite` is limited to 100 MB
  and that at 256 MB the storage endpoint may be "non-optimal". read, not tried.
- When Steam syncs: "Steam will automatically sync the groups of files when the application launches and exits";
  on a new computer "the files are automatically downloaded to the new computer prior to the game launching";
  written files "will automatically be replicated to the Steam servers after the game exits." read, not tried.
- Size advice: "smaller files will work better"; split state so unchanged data is not re-uploaded; large or many
  small files can "cause a noticeable impact" on bandwidth and "also delay their ability to shut down Steam or
  re-launch the game." And: "Avoid machine-specific configurations such as video settings." read, not tried.
- Multiple Steam users on one OS account: "be sure the path will be unique for the current Steam user" (the page
  points to `ISteamUser::GetSteamID`); Auto-Cloud subfolders accept `{64BitSteamID}` and `{Steam3AccountID}`.
  read, not tried. With the API, Steam itself keeps each user's files apart (quote above).
- Writing while Steam syncs: the page does not cover it. Since normal syncing happens before launch and after exit,
  the game is not running while Steam reads or writes the folder. The page warns that a sync delays a re-launch,
  which suggests Steam holds the launch until the upload ends; not stated outright. read, not tried.
- Dynamic Cloud Sync (the exception): with it, "Steam will suspend your game process and upload any changed files to
  the Steam Cloud" (the example is a suspended Steam Deck); another device can then play, and the Deck downloads the
  changes on wake and tells the game. Valve warns "enabling Dynamic Cloud Sync for all users could lead to data loss
  when running builds" that do not handle it; it is opt-in per app. Developers "can use the file-write batch calls"
  so Steam syncs safely at suspend. read, not tried. A game that opts in must react to `local_file_changed`
  (GodotSteam signal, "One or more files for this app have changed locally after syncing to remote session changes.
  Only posted if this happens during the local app session.", https://godotsteam.com/classes/remote_storage/ ).
- Auto-Cloud setup: each Root Path is Root + Subdirectory (`.` for none) + Pattern (`*` wildcard, e.g. `*.sav`) + OS
  Restriction (default `[Cross-Platform]`) + Recursive. Roots include `WinAppDataRoaming`, `WinAppDataLocal`,
  `WinMyDocuments`, `WinSavedGames`, `LinuxHome` (`~/`), `LinuxXdgDataHome` (`$XDG_DATA_HOME/`), `SteamCloudDocuments`
  and `App Install Directory`. Root Overrides map a root to another OS's root ("Original Root, OS, New Root, Add/Replace
  Path, and Replace Path"), and "If you use Root Overrides, you must specify `[Cross-Platform]`". Valve "strongly
  recommend[s]" cross-platform even for a single-OS game. "The file steam_autocloud.vdf will be created in each
  location specified by your Steamworks cloud paths." read, not tried.
- Conflicts: the Steamworks page does not describe them. Steam Support's FAQ (https://help.steampowered.com/faqs/view/68D2-35AB-09A9-7678 ,
  seen only as a search-result excerpt; the page answered 403 to the fetch) says: "The Steam Cloud conflict window will
  be shown when a game is launched, if Steam detects that the local files associated with that game differ from the
  ones stored on the cloud", and that playing offline pauses syncing until the next connection. Third-party guides
  (not primary) say the window shows both sides with a modification time and the player picks one. read, not tried.
- The Remote Storage API (https://partner.steamgames.com/doc/api/ISteamRemoteStorage ):
  - `FileWrite` / `FileRead` are synchronous and "block the calling thread and the SteamAPI" during disk I/O;
    `FileWriteAsync` / `FileReadAsync` are recommended against hitching. read, not tried.
  - Limits: "Cloud files cannot be written in a single chunk over 100MiB and cannot be over 200MiB total." File names
    must be valid on all OSes, at most 260 characters (`k_cchFilenameMax`), subfolders allowed (`GetFileCount`
    "including files in subfolders"). Quota errors: "The current user's Steam Cloud storage quota has been exceeded.
    They may have run out of space, or have too many files" (`FileWrite` returns false). read, not tried.
  - Atomic replace: `FileWriteStreamOpen` / `WriteChunk` / `Close`: the target "isn't overwritten until
    `FileWriteStreamClose`"; `FileWriteStreamCancel` leaves the old file untouched. Plain `FileWrite` says nothing
    about atomicity. read, not tried.
  - `FileDelete` deletes locally and in the cloud; `FileForget` removes from the cloud only. `GetQuota`,
    `IsCloudEnabledForAccount` and `IsCloudEnabledForApp` ("check both"); `SetCloudEnabledForApp` only on an explicit
    player request. `SetSyncPlatforms` limits a file to some OSes. read, not tried.
  - `BeginFileWriteBatch` / `EndFileWriteBatch` wrap writes or deletes that form one state change; optional but it
    "will provide better reliability". GodotSteam's copy of the Valve text adds: "the functions may be used whether the
    writes are done using the Remote Storage API, or done directly to local disk (where AutoCloud is used)."
    (https://godotsteam.com/classes/remote_storage/ ). read, not tried.
  - Where the API keeps files on disk is not on the page. Community posts say `Steam/userdata/<account id>/<app id>/remote/`
    (not primary). So API files are not in `user://`: a game that moves from local files to the API must import them.

**Which fits a game that autosaves every 2 s:** both. Neither uploads per write. With Auto-Cloud the game's own
writes stay as decided (worker thread, `.tmp`, `.bak`). With the API each autosave is a `fileWriteAsync` of the
whole file into Steam's folder: still a local disk write, but through Steam's thread and callbacks, and the `.bak`
safety has to be rebuilt on top of Steam files (a second cloud file per World, or a local-only copy).

### 2. Paths: `user://` on each OS, the Steam Deck

- Godot 4.7 docs (https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html , header "Godot Engine 4.7
  documentation"): by default `user://` is `%APPDATA%\Godot\app_userdata\[project_name]` on Windows and
  `~/.local/share/godot/app_userdata/[project_name]` on Linux (lower-case `godot`). With
  `application/config/use_custom_user_dir` it is created "next to" Godot's data path without the
  `Godot/app_userdata` part (e.g. `%APPDATA%\[project_name]`), and `custom_user_dir_name` may contain separators
  ("Studio Name/Game Name"). On Linux the XDG variables (`XDG_DATA_HOME`) move it. read, not tried.
- This project sets neither (`project.godot`, only `config/name="It Socks"`), so today a player's Worlds would be in
  `%APPDATA%\Godot\app_userdata\It Socks\worlds\` and `~/.local/share/godot/app_userdata/It Socks/worlds/`. Read in
  the repo. Logs (`user://logs`), benches (`user://bench`), `settings.json` and `profile.json` share that root.
- Auto-Cloud mapping that follows from the two pages (not tried): Root `WinAppDataRoaming`, Subdirectory
  `<user dir>/worlds/{64BitSteamID}`, Pattern `*.json`, `[Cross-Platform]`; a Root Override for Linux to
  `LinuxXdgDataHome` with Replace Path for the case and folder difference (`Godot` vs `godot`). Whether Steam's
  `LinuxXdgDataHome` falls back to `~/.local/share` when `XDG_DATA_HOME` is unset (as Godot does) is not stated
  (see "Not found"). A custom user dir name removes the `Godot`/`godot` case difference and gives a folder name a
  player recognises.
- Steam Deck (https://partner.steamgames.com/doc/steamdeck/recommendations ): "For games that allow saving, we
  recommend enabling automatic clouding of saved games"; "make sure graphics settings are not included in that
  clouded data"; "Graphics settings should be set and saved on a per-device basis". These are recommendations, not
  Verified requirements (the page ties Verified to input items). read, not tried.
- A native Linux build runs as Linux on the Deck, so the Linux root applies. If the Windows build ran under Proton,
  `user://` would be inside the Proton prefix (`compatdata/<appid>/pfx/drive_c/users/steamuser/AppData/Roaming/...`,
  community sources only); how Auto-Cloud maps Windows roots under Proton is not on Valve's page. Shipping the
  native Linux build avoids the question.

### 3. Godot side: GodotSteam, and Auto-Cloud in code

- Auto-Cloud needs nothing in code: it is a Steamworks setting and Steam does the copy (quotes in 1). The game does
  not even need GodotSteam for it. The only optional code is the batch hint, which needs GodotSteam.
- GodotSteam 4.24 (GDExtension `v4.24-gde` for Godot 4.4+, or the module builds with a 4.7.2 variant; details and
  sources in `steam-multiplayer.md` 1) exposes the whole Remote Storage API. From its header
  (https://codeberg.org/godotsteam/godotsteam/raw/branch/godot4/godotsteam.h ) and class page
  (https://godotsteam.com/classes/remote_storage/ , "Only available in the main GodotSteam branches", which the
  GDExtension is built from): `beginFileWriteBatch()`, `endFileWriteBatch()`, `fileWrite(file, data, size)` -> bool,
  `fileWriteAsync(file, data, size)` (signal `file_write_async_complete` with `result`), `fileRead(file, size)` ->
  `{ret, buf}`, `fileReadAsync(file, offset, size)` (signal `file_read_async_complete`), `fileExists`, `fileDelete`,
  `fileForget`, `filePersisted`, `getFileCount`, `getFileNameAndSize(i)`, `getFileSize`, `getQuota` -> Dictionary,
  `isCloudEnabledForAccount`, `isCloudEnabledForApp`, `setCloudEnabledForApp`, `fileWriteStreamOpen` / `WriteChunk`
  / `Close` / `Cancel`, `getLocalFileChangeCount`, `getLocalFileChange`, `get/setSyncPlatforms`, signal
  `local_file_changed`. read, not tried. Async results arrive only while `Steam.run_callbacks()` is called each frame
  (GodotSteam's usual setup; see `steam-multiplayer.md`).
- Whether GodotSteam calls are safe from `WorkerThreadPool` is not documented; Valve says the sync calls block the
  SteamAPI. An API backend should call `fileWriteAsync` from the main thread with bytes made on the worker. Not found.
- Godot's own write, read in the 4.7.2-stable source:
  - `FileAccess` only writes to a temp file and replaces the target when "backup save" is on
    (`core/io/file_access.h`: `static inline bool backup_save = false`). Only the editor turns it on
    (`editor/editor_node.cpp`: `FileAccess::set_backup_save(EDITOR_GET("filesystem/on_save/safe_save_on_backup_then_rename"))`),
    and it is not bound to GDScript. So in an exported game `FileAccess.open(path, WRITE)` truncates in place. The
    temp file it would use is `<file>-XXXXXX` on Linux and `<file><n>.tmp` on Windows, in the same folder.
  - `DirAccessWindows::rename` (`drivers/windows/dir_access_windows.cpp`): when the target exists it calls
    `remove(new_path)` then `MoveFileW`, two steps. `DirAccessUnix::rename` is POSIX `rename()`, one atomic step on
    one filesystem.
  - `FileAccess.flush()` is `fflush` only (no `fsync` / `FlushFileBuffers`).
  - Consequence: the kit template (`kit/skills/godot-game-dev/templates/save/save.gd` lines 59-67: write `.tmp`,
    rename the old file to `.bak`, rename `.tmp` into place) never relies on an atomic replace, and the read falls
    back to `.bak`, so a crash at any step leaves a readable file. Good as decided. The template does not check
    `store_string`'s bool or `get_error()` before the renames; saves.md already says the game's copy checks it.

### 4. Other stores, for the seam

- GOG Galaxy has the same two models: the Galaxy client syncs a folder the developer configures, at launch and at
  close, or the game uses the SDK's `IStorage` (`FileWrite` relative to local storage, subfolders allowed), and GOG
  announced a 200 MB per-game limit. Sources: https://docs.gog.com/gc-cloud-saves/ and https://docs.gog.com/sdk-storage/
  (seen only as search-result excerpts; both pages refused the fetch). read, not tried.
- Epic Online Services "Player Data Storage" is an API only (the game uploads and downloads files per player); its
  limits could not be read (Epic's pages refused the fetch). An EOS backend would be an API backend.
- So a folder-sync store (Steam Auto-Cloud, GOG Galaxy) needs only "keep the files in a known folder with a clean
  pattern", while an API store (Steam API, GOG `IStorage`, EOS) needs a backend behind a seam.

## What makes the save layer store-agnostic

1. **A storage seam for named blobs.** `SaveStore` (one base class, RefCounted, in its own file) with
   `read(name) -> {ok, bytes, reason}`, `write(name, bytes) -> {ok, reason}`, `list() -> Array[String]`,
   `delete(name)`, and `begin_batch()` / `end_batch()` (no-ops by default). `Save` keeps the slots, versions,
   migrations, `.bak`/corrupt rules and the worker thread, and only calls the store. Backends extend it one step
   (the project's code shape, Q2251): `LocalFileStore` (now, `user://worlds/...`), later `SteamRemoteStore`,
   `GogStorageStore`, `EosStore`, and `MemoryStore` for tests. `Save.dir` today is already the first half of this.
2. **The backend decides atomicity.** `LocalFileStore.write` does `.tmp` -> `.bak` -> rename (as decided);
   `SteamRemoteStore.write` would use `fileWriteStream*` (Valve's only stated no-overwrite-until-close path) or
   `fileWriteAsync`. Callers never see temp names.
3. **Names are portable:** lowercase letters, digits, `_`, `-`, one `.json` extension, well under 260 characters,
   valid on Windows (the kit's `_valid(slot)` already restricts slots to letters, digits, `_` and `-`).
4. **Synced files apart from local-only files.** Synced: `worlds/<account>/<slot>.json` and `profile.json`.
   Local only: `<slot>.json.bak`, `.tmp`, the damaged file, `settings.json` (graphics, window, audio device),
   `logs/`, `bench/`. With Auto-Cloud the pattern does this; with an API backend, only synced names go to Steam.
5. **Per-account folder.** On Steam the player id is the Steam ID (Q2458); `worlds/<player id>/` matches the Auto-Cloud
   subfolder `{64BitSteamID}` and keeps two accounts on one PC apart. Off Steam the folder is the profile's id.
6. **Small, whole files**, one per World (decided), so the 2 s autosave rewrites a few tens of KB and the cloud
   uploads at most 6 Worlds and a profile per session.
7. **Host-only saves** (decided, Q249): a Guest has no `Autosave`, so a Guest's cloud never holds the Host's World.
   The World lives in the Host's account only; the Group can play it only when that player hosts (already the rule).

## The concrete differences for this game

| | Auto-Cloud | Remote Storage API |
|---|---|---|
| Code | none; optional batch hint (about 5 lines, only when `Engine.has_singleton("Steam")`) | a `SteamRemoteStore` backend, async callbacks, quota and "cloud off" handling, an import of local files on first Steam run |
| Where files live | `user://worlds/...`, same as off Steam and in tests | Steam's userdata folder; off Steam `user://` |
| `.bak`, `.tmp`, damaged file | stay local by pattern | must be designed: a second cloud file per World (doubles the file count) or a local-only backup beside Steam's folder |
| Two Steam accounts, one PC | needs the per-account subfolder | Steam separates them |
| Other stores | GOG Galaxy folder sync works the same; DRM-free build unchanged | each API store is one more backend |
| Conflicts | Steam's window at launch | Steam's window at launch (both are the client's sync) |
| Steamworks setup | root, subfolder, pattern, Linux override, quota | quota only |

**What changes in `saves.md` for Auto-Cloud (the recommendation):** the file path becomes
`user://worlds/<player id>/<slot>.json`; the damaged file is renamed so it does not match `*.json` (for example
`<slot>.json.damaged`) or moved out of `worlds/`; the save brackets its writes with the batch hint when Steam is
present; a `SaveStore` seam with `LocalFileStore` sits under `Save`; `use_custom_user_dir` is set before the first
outside play-test (moving it later strands testers' saves); settings stay out of the synced folder. Nothing else in
the "Decided" section changes: autosave frequency, the worker thread, `.bak`, versions and migrations stay.

**What would change for the API instead:** all of the above plus the `SteamRemoteStore` backend, the `.bak` design
on Steam files, a main-thread hand-off for `fileWriteAsync`, an import step for saves made before Steam was present,
and test cases for quota-full and cloud-disabled answers.

**Risks**

- Autosave frequency: no cloud cost (uploads happen after exit). A large Mess makes the file bigger: measure at
  10,000 Socks (already in the build ticket) and set the quota with a margin (6 Worlds + profile, per account).
- Conflict window on two PCs: happens when the player plays offline on both, or a session ended without the exit
  sync (crash, Steam closed). The player picks a whole folder side; the game cannot merge Worlds. Low risk for a
  game with six files, but a tester should see it once before release.
- A crash: the last autosave (at most 2 s old) is on disk; whether Steam uploads after a crashed process exits is
  not documented. The next clean exit uploads it.
- The `.bak` and `.tmp` with a pattern that is too wide (`*` or recursive over `user://`): a `.bak` from one PC could
  land on another, and a half-written `.tmp` could be uploaded. The narrow pattern prevents both; the backup then
  protects one machine only, which is enough for a failed write.
- Settings synced by accident (a pattern on the `user://` root): Valve recommends against syncing graphics settings.
- Two accounts on one OS user without the per-account folder: one account's Worlds would upload into the other's
  cloud.
- Dynamic Cloud Sync: leave it off; turning it on later needs `local_file_changed` handling (reload the title's World
  list, refuse to keep playing a World that changed underneath).

## Testing

- **Without Steam (every run, CI):** `MemoryStore` (a dictionary of name -> bytes) with switches for a failed write,
  a full quota and a slow write; the `Save` suite runs against it (round trip, failed write keeps the old file,
  damaged file, migration chain, list after delete). `LocalFileStore` gets its own few cases in a throwaway folder
  (`.tmp` left behind is ignored, `.bak` read when the file is damaged, names outside the pattern never listed). A
  case asserts that every file name `Save` writes for syncing matches the Auto-Cloud pattern and every local-only name
  does not, so the Steamworks setting and the code cannot drift apart. These need no GodotSteam and match the kit's
  headless runner.
- **With Steam, app id 480 (Spacewar):** good for the API (GodotSteam `fileWrite`/`fileRead`/`getQuota` work against
  Spacewar's own cloud settings) but **not for Auto-Cloud**: Auto-Cloud paths are set on the app's Steamworks page,
  which only Valve controls for 480. Spacewar's quota could not be read (see "Not found"), its cloud is shared by every
  developer test on that account, so use a unique file prefix and delete what the test writes.
- **With the game's own app id:** Steamworks has "Enable cloud support for developers only" (only accounts with a
  developer licence see the cloud). Steam console (`steam://open/console`): `testappcloudpaths <AppId>` and
  `set_spew_level 4 4` show what Auto-Cloud would sync; `%Steam Install%\logs\cloud_log.txt` logs syncs; after
  publishing a cloud setting wait "up to 10 minutes or restarted your Steam client". Dynamic sync is tested with
  `@cloud_testdynamicsyncapp <AppId>`, `prepare_for_suspend`, `resume_suspended_games`. Source: the Steam Cloud page.
- **A manual pass before release:** play on PC A, quit, start on PC B (World appears); play offline on both, go online,
  start (conflict window appears, each side loads); Linux to Windows and back (the root override works); two accounts
  on one PC (Worlds stay apart).

## Not found

- What Steam does if the game process crashes: whether the exit upload still runs.
- Whether `LinuxXdgDataHome` falls back to `~/.local/share` when `XDG_DATA_HOME` is unset (Godot does); this decides
  between `LinuxXdgDataHome` and `LinuxHome` + `.local/share/...` in the override. Check with `testappcloudpaths`.
- How Auto-Cloud maps Windows roots for a Windows build under Proton (only community posts).
- A default or maximum value for the byte and file quotas; app 480's cloud quota (steamdb refused the fetch).
- Whether plain `FileWrite` replaces a file atomically, and where API files sit on disk (only community posts).
- Whether GodotSteam's Remote Storage calls are safe from a worker thread.
- The Steam conflict window's exact options (the Steam Support page refused the fetch; only a search excerpt).
- Epic Player Data Storage limits and GOG's pages (fetch refused); the GOG facts are from search excerpts.

## Recommendation

Target **Auto-Cloud** for Steam, and build the save layer now with a **`SaveStore` seam and one `LocalFileStore`**.
Reasons: the decided design (small whole files, autosave on a worker thread, `.bak`, versions) works unchanged;
Steam stays out of the save code, so the DRM-free build, tests and a GOG folder-sync build are the same code; the 2 s
autosave costs nothing in cloud traffic; conflicts are handled by the Steam client either way. The seam costs one
small base class and keeps an API backend (Steam, EOS, GOG `IStorage`) a one-file addition if a store ever demands it.
The changes to make with the save build: `worlds/<player id>/<slot>.json`, a damaged-file name outside `*.json`,
`use_custom_user_dir` before the first outside play-test, the optional batch hint when Steam is present, and a test
that ties file names to the Auto-Cloud pattern. The Steamworks setup (root, override, quota) is part of the M4 Steam piece.

## Choices for the designer

Each with options; **(rec)** marks the recommendation.

- **C1. How Steam syncs the saves.**
  a) **(rec)** Auto-Cloud: set on the Steamworks site, no save code; the save layer gets a storage seam anyway.
  b) The Remote Storage API through GodotSteam: the game knows about the cloud (quota, "cloud is off"), more code, and
     the backup file needs a new design.
  c) No cloud at launch; add Auto-Cloud later (possible at any time, since it needs no code).
- **C2. What follows the player between PCs.**
  a) **(rec)** Worlds and the profile (as Q1684); settings stay on each PC (Valve's advice for graphics).
  b) Worlds only.
  c) Worlds, the profile and the non-graphics settings (audio levels, controls), which means splitting settings into
     two files.
- **C3. Two Steam accounts on one PC.**
  a) **(rec)** Each account has its own Worlds (`worlds/<player id>/`); one account never sees the other's.
  b) Worlds shared by everyone on the PC (simpler folder, but one account's Worlds would upload to the other's cloud).
- **C4. The save folder's name players see.**
  a) **(rec)** Set now, before the first outside play-test: `%APPDATA%\It Socks\` and `~/.local/share/It Socks/`
     (Godot's custom user folder; a studio folder above it if wanted).
  b) Godot's default (`...\Godot\app_userdata\It Socks\`), which never moves.
