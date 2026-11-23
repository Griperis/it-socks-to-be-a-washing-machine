---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["M4's first piece; design core/57, Q2553-Q2562; list docs/migration/m4-lists/01-main-menu-and-saves.md"]
terms: [Host, Guest, Mess, Part, Hands]
---

# The main menu and saves (M4)

Build `docs/architecture/saves.md` as decided (its "Decided" section, Q2553-Q2562) and the behaviour list
`docs/migration/m4-lists/01-main-menu-and-saves.md` (fold the answers into its header and lines first; one test per
line, named after it).

## Scope (Q2562)
Title, Options (volume incl. the Voice bus slider of Q2549 if cheap, mouse speed, FPS cap, graphics presets,
fullscreen), Licence, the loading screen (house/09 makes a placeholder one: reuse and restyle it), the cursor, menu
sounds, the ESC menu, and saves. Screens are scenes on the one Theme (Q2163); reuse the godot-game-dev templates
(settings, saving, pause menu, scene changer) as the design names. Not in scope: the Lobby, the World list, the studio
intro, key remapping, the encyclopedia key.

## The loading screen's old look (Q2575)
- Port the old loading screen by examination (`reference/it-socks/game/ui/loading_screen.gd`): the cream card with what
  is happening, the tumbling sock in its fixed square, the bar, the backdrop colour and the fade into play; on house/09's
  placeholder (reuse its scene and progress).

## Must-haves
- The save is the join snapshot written to a file (Parts), per World; Worlds as Q2554; autosave Q2555; the failed write
  Q2556; the version and migration chain with sample saves in the suite (Q2557); the id list test (Q2558); the load
  resets (Q2559); things in the air laid where they would land (Q2560); the menu flow Q2561.
- First fix the port gap core/57 found: alone, Hands keys the player by peer number, not player id.
- The kit save template's follow-up (a broken file may replace a good backup): fix in the game's copy and note it for
  the lead to propose upstream.

## Steam Cloud readiness (Q2564-Q2567, `docs/research/steam-cloud-saves.md`)
- Every save read and write goes through a `SaveStore` (read, write, list, delete of named files, batch begin and end)
  with a local-file backend and an in-memory one for tests; no other code touches save files.
- Worlds at `user://worlds/<player id>/<slot>.json` (Q2566); the profile synced, settings local (Q2565); temp, backup
  and damaged files named outside the Auto-Cloud pattern; a test ties every saved file name to the pattern written in
  the doc (`docs/architecture/saves.md` gets the Steamworks Auto-Cloud settings to enter).
- `use_custom_user_dir` "It Socks" in project.godot (Q2567; `--allow-project`).

## Acceptance
- Real path: launch, the title, Solo, the house loads behind the loading screen, pick and pair a Sock, quit to the
  title, Solo again: the Mess, Hands, Cabinets and Coins are as left (with Q2559's resets).
- A Host's co-op World saves and a Guest joining after a reload sees it.
- A sample save of the first version loads after a migration step is added (a case with a made-up v2).
- A failed write shows the HUD line once and keeps the old file.
- Stills for the designer: the title, Options, the ESC menu and the loading screen (`builds/review-menus/`); the look is a
  first still (the screens' style is reviewed before the merge).

## Answers
- The screens merge as their stills show (`builds/review-menus/`) (Q2578, 2026-11-23).
- The loading card reads "Loading the house...", for a New Game too; a loaded World skips the generators' laying
  instead of laying and replacing (Q2579, 2026-11-23).
- The title's Zoo key is in debug builds only; a release build has none (Q2580, 2026-11-23).

## Open follow-ups
- [later] Wording is the old game's, all placeholder: "Could not save the game", "This World was saved by a newer
  version of It Socks" (a newer build's file is refused, not loaded), the loading screen's words, the ESC menu's
  "Menu" heading.
- [later] Old details not built here, for the designer to keep or drop: the pad's menu guard (pad focus walk with LB/RB,
  the pad not read while unfocused); the 3D switched off while the loading screen shows; the title's "Connecting to
  <ip>..." line (a Guest now goes in behind "Joining..." and comes back to the title with the reason); `LICENSES.txt`
  beside the exported game (with the release export).
- [later] Kit (for the lead to propose): the save template's `.bak` rule (the old file becomes the backup only when it
  reads, else a broken file replaces a good backup), the unchecked `store_string` / `get_error()` before the renames,
  and `JSON.from_native` writing a `PackedByteArray` byte by byte (the game's copy writes Base64): fixed in
  `game/save/save.gd` and `local_file_store.gd`.
- [later] `tools/shot_hooks.gd` is over 600 lines (grep_rules note).

## Built log
### 2026-11-23
- Changed: the game starts on the title (Solo, Multiplayer with Host and Join, Options, Licence, Quit); a choice
  loads the house behind the old loading screen (cream card, tumbling sock, bar, 0.5 s fade). Each World is saved as
  the join snapshot to `user://worlds/<player id>/<slot>.json` through a SaveStore: within 2 s of a change (worker
  thread) and on every way out of the ESC menu (which never pauses); a failed write keeps the old file and the HUD
  says so once; backup and damaged files; a version per Part with steps and sample saves; Q2559 resets; flying Socks
  laid where they land. Alone the player is in its own Roster by player id (Hands, Coins). Options rows on Settings,
  menu sounds, the cursor, the "It Socks" user folder.
- Files: game/save/, game/ui/{title,options,licence,esc_menu}/, game/level/loading_screen.tscn, game/scenes/scene_changer.gd,
  game/audio/ui_sounds.gd, game/look/keycap_style.gd, game/look/theme.tres, tests/save_test.gd, tests/menus_test.gd,
  tests/saves/.
- Verified: kit/tools/run.sh --touched in agent_finish (suite line in the commit's run); grep_rules and asset_lint
  PASS; stills builds/review-menus/menus-*.png.
### 2026-11-23 (house/09 merged in)
- Changed: one loading screen for every wait, `game/level/loading_screen.tscn` (house/09's laying driver with the old
  look, Q2575): "Loading the house..." always (Q2579), "Joining..." for a Guest; SceneChanger's copy fills the first
  tenth of the bar while the scene loads, then hands over to the house's laying, which fades out when the Socks are
  laid. A loaded World skips the generators' laying (`Mess.skip_generated`). `game/ui/loading/` is gone.
- Files: game/level/loading_screen.{gd,tscn}, loading_tuning.gd, game/scenes/scene_changer.gd,
  game/level/level_runtime.gd, game/mess/mess.gd, tests/menus_test.gd, tests/house_test.gd.
- Verified: agent_finish's full run; still builds/review-menus/menus-loading.png retaken.
- Merged: 3647abf9 (2026-11-23, branch core/58-main-menu-and-saves)
