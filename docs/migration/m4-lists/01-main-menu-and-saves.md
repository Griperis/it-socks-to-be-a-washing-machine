> Behaviour list for M4's first piece (Q2540, core/57), written from the reference on 2026-11-23; the answers
> folded in by core/58, which built it: Q2553-Q2562 (saves.md "Decided": one JSON file per World; the old slots
> without the Group lock; autosave within 2 s and on every way out; a failed write keeps the old file and the HUD
> says so; old saves load through a version per Part and a migration chain; node path ids with a committed list;
> the old load resets; things in the air laid where they land; straight into the house until the Lobby; the core
> screens and saves now), Q2564-Q2567 (a SaveStore seam, Auto-Cloud, `worlds/<player id>/`, the "It Socks"
> folder). Each line ends with its case (`[save:s01]` is tests/save_test.gd, `[menus:m01]` tests/menus_test.gd),
> or why it has none: `look: still` (the designer's eye judges it, Q2421), `later` (not in this piece, Q2562),
> `changed` or `dropped` (an answer changed the old rule).

# M4 piece: the main menu and saves

Draft behaviour list (catalogue B60 main menu, Options, Licence, loading, cursor; B62 Worlds and Groups; B63 saves).
Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`.
Short forms: T = `game/ui/title_screen.gd`, S = `game/core/saves.gd`, W = `game/core/worlds.gd`,
WM = `game/core/world_meta.gd`, ST = `game/core/settings.gd`, O = `game/ui/options_view.gd`,
L = `game/ui/licence_view.gd`, LS = `game/ui/loading_screen.gd`, M = `game/core/main.gd`,
SM = `game/net/session_menu.gd`, LB = `game/lobby/lobby_screen.gd`, US = `game/audio/ui_sounds.gd`.
"(lobby)" marks a line that belongs to the Lobby piece (B61) and is listed here because the menu flow or the
Worlds reach it; "(debug)" a line only debug builds have.

## Behaviour list

### Launch and the studio intro
- When the game launches, then the title screen is the first scene; the mouse is freed (back from the game it was
  still captured). (ref: T:36, T:104) [menus:m01]
- When the title is the launched scene and the studio intro has not played this launch, then the Hudry Games intro
  plays over the title once; coming back to the title later skips it (a static flag). (ref: T:62-63, T:147-148, T:169-173) [later: the studio intro, Q2562]
- When the intro plays, then its animation and sounds run on one timeline (the gobble, a soft wooden thud as each
  HUDRY letter lands, a heavier slam as GAMES lands); any key, click or pad button skips it with a quicker fade
  (0.25 s against 0.4 s); it fades to black, emits `finished` and frees itself, and the title is behind it.
  (ref: studio_intro/intro_player.gd:1-40; studio_intro/README.md) [later: the studio intro, Q2562]
- When `--host` or a join target is on the command line, then the intro is skipped. (ref: T:147) [later: the studio intro, Q2562]
- When the command line has `--tour`, `--stress`, `--bench`, `--drum` or `--zoo`, then the title hands over to that
  scene at once (debug tools). (ref: T:105-124) (debug) [port: GameCli's --zoo, --scene= and --bench (game_cli_test); the old --tour, --stress and --drum have no port yet] (debug)
- When `--profile=<tag>` is given, then another profile file is used; without it a second copy of the game on one PC
  takes `profile_2.json` (ProfileLock). `--name=` and `--colour=` override the profile. (ref: T:128-138) [port: LevelNet and Worlds read --profile= (coop_join_test); --name and --colour not ported]

### The title's look and sounds
- When the title shows, then it is a dark backdrop (`#2b211c`) with one cream keycap panel in the middle (760 px
  wide), its pages stacked in a column 18 px apart. (ref: T:177-195) [menus:m02; look: still]
- When the home page shows, then it reads "It Socks" (64 px) over four full-width orange keycaps, each with its icon:
  Solo (`menu_play`), Multiplayer (`menu_coop`), Options (`menu_options`) and Quit (red, `menu_exit`). (ref: T:266-272) [menus:m02]
- When the home page shows, then two small icon-only orange keycaps (72 x 72 px, icon 40 px) sit in the bottom-right
  corner, 24 px in: Licence (tooltip "Licence") and, left of it, the Sock encyclopedia (tooltip "Sock encyclopedia");
  they hide on every other page. (ref: T:196-218, T:261-262) [menus:m02; the encyclopedia key is later, Q2562]
- When the game is a debug build, then a "Zoo" keycap (110 x 72) sits in the bottom-left corner of the home page and
  opens the zoo. (ref: T:219-229) (debug) [look: still; no case]
- When a page shows, then its heading is 44 px, white with the dark outline, centred; body text 24 px; buttons
  28 px. (ref: T:43-47; digest Q1495-Q1500) [look: still (Heading1 44, InkLabel 24, KeycapButton 28 on the Theme)]
- When a page other than home shows, then its Back is the ESC keycap, white text with a black outline, at the left;
  Esc or the pad's B presses it. (ref: T:349-362, T:369-386; digest maintenance/89) [menus:m03]
- When any menu button is pressed, then a soft click plays (`ui_click`, -8 dB); when the mouse comes over an enabled
  one, a very quiet tick (`ui_hover`, -20 dB); both on the UI bus, pitch and level a little different each time
  (±1.5 dB), four voices; a button marked `no_ui_sound` stays silent. Every button in every menu is hooked as it
  enters the tree. (ref: US:1-51; data/sounds.json "ui_click", "ui_hover"; Q336) [menus:m08]
- When a page changes, then nothing animates: the old pages swap at once (no slide, no fade). (ref: T:249-313) [menus:m03]
- When the title shows, then no music plays (no title music in v0.1.1). (ref: grep of `Music` in game/ui, game/lobby) [no case: nothing plays]
- When the pad is used, then every button and slider takes focus and the new page gets its first focus; Down/Up walk
  the column. (ref: T:316-321; game/ui/pad_menu_guard.gd) [partial: each page's first focus and Godot's own focus walk; no pad guard yet, a follow-up]
- When a notice is waiting (why the last session ended, or a save fell back), then it shows once in the status line
  (accent colour, 24 px, centred, wrapping) under the page. (ref: T:61, T:141-143, T:230-233, T:265) [menus:m07]

### The pages
- When Solo is pressed, then there is no page: the Solo World is chosen, nothing listens (no firewall prompt), and the
  Lobby screen opens with Continue and New Game. (ref: T:478-486) (lobby) [Q2561: straight into the house: menus:m05, save:s01] (the Lobby part later)
- When Multiplayer is pressed, then a page with Host, Join and Back shows. (ref: T:273-277) [menus:m03]
- When Host is pressed, then there is no page: the last-played co-op World that reads is chosen, or with none a New
  Game in a free slot; a Session opens listening and the Lobby opens. (ref: T:489-536) (lobby) [Q2561: straight into the house: menus:m05, save:s16] (the Lobby part later)
- When `--host` is given, then the newest co-op World is hosted, else the Solo World, else a New Game. (ref: T:510-524) [save:s16 (Worlds.pick_host(true)); the title acts on it at launch]
- When Join is pressed, then a page shows "Your name" (a field, at most 16 letters, hint "Player"), "The host's
  address" (a field, the last one remembered, hint "192.168.1.20") with a Join keycap beside it (180 px), and one
  ink line: "The host's firewall must let It Socks through on UDP port 24680". (ref: T:278-295, T:434-436) [menus:m03]
- When Enter is pressed in the address field, then it joins. (ref: T:239) [menus:m05]
- When a page is left, then the typed name and address are kept in the profile (name cleaned: trimmed, cut at 16,
  empty becomes "Player"). (ref: T:425-431; game/player/profile.gd:146-149) [menus:m04]
- When Join connects, then the status reads "Connecting to <ip>..." with no Cancel and no time limit; a full game is
  refused here ("The game is full (4 players)"), a taken colour silently becomes the next free one, and the Guest
  goes into the Host's Lobby, or straight into the World in play. (ref: T:546-578) (lobby) [changed: the Guest goes in behind "Joining..."; a join that ends goes back to the title with the reason (menus:e02)] (lobby)
- When Back is pressed on the Join page, then a half-open Session is dropped. (ref: T:359-362) [changed: the Session lives in the level, nothing is half-open on the title]
- When Options is pressed, then the Options page shows (below). (ref: T:296-301) [menus:o01]
- When the Licence key is pressed, then the Licence page shows (below). (ref: T:308-312) [menus:l01]
- When the encyclopedia key is pressed, then the Sock encyclopedia shows; LB / RB turn its pages. (ref: T:302-307,
  T:371-380) (with the encyclopedia feature, progression/53) [later, Q2562]
- When Quit is pressed, then the game closes. (ref: T:272, T:80) [menus:m06]

### Options (also in the ESC menu)
- When Options shows, then one row per setting, its name on the left (ink, no outline) and its control on the
  right, rows 50 px apart (48 px high, 2 px gap). (ref: O:1-5, O:45-54; Q1501) [menus:o01; look: still]
- When Options shows, then the rows are, in order: Graphics (Auto, Low, Medium, High), SSAO (Off, On), Master, Music,
  Effects, Ambience, UI (sliders 0-100 % in 5 % steps), Mouse speed (0.20x-3.00x), Invert Y (Off, On), Pad speed
  (0.20x-3.00x), Pad rumble (Off, On), Subtitles (Off, On), Display (Windowed, Fullscreen), V-sync (Off, On), FPS cap
  (None, 30, 60, 120, 144). (ref: O:55-74; ST:24-43) [menus:o01, Voices added (Q2549)]
- When a choice row shows, then its values are small cream keycaps and the chosen one is orange; a slider shows its
  value beside it ("85%", "1.25x"). (ref: O:89-111, O:137-166) [menus:o02]
- When a value changes, then it is applied at once and kept per machine (never in a save or the profile).
  (ref: ST:1-3, ST:121-138) [menus:o02]
- When a volume changes, then its bus plays at the designer's mix level times the slider, so 100 % is the mix as
  balanced; 0 is -80 dB. (ref: ST:8-9, ST:179-186) [menus:o02]
- When a graphics preset is picked, then SSAO goes back to the preset's own; the SSAO row always shows what is in
  force. (ref: ST:130-137; O:178-185) [menus:o03]
- When the game first launches, then "Auto" picks a preset from the GPU (software or integrated: Low; a mid-range
  discrete name: Medium; else High). (ref: game/core/graphics.gd:129-150; Q354) [menus:o03]
- When the pad's Left / Right is pressed on a focused choice row, then the value steps (no wrap) and the focus
  follows. (ref: O:114-134; Q1577) [menus:o04]
- When the game runs headless, then the display rows are not applied. (ref: ST:194-195) [no case: Settings skips the display keys headless]
- When the game is not focused, then the pad is not read (two copies on one PC). (ref: ST:66-68) [not ported: no pad guard yet]

### Licence
- When the Licence page shows, then one scrolling column (900 x 560) lists the game's credit lines ("It Socks", "A
  game by Zdenek Dolezal", "Built with Godot Engine", the first larger, centred), then each third-party work by
  section with its author, licence and a source link, all from `data/credits.json`; then "Licences" with two links,
  the Godot Engine licence and Blender. (ref: L:1-52, L:54-73, L:116-133; Q339, Q1520) [menus:l01]
- When a link is pressed, then it opens in the browser. (ref: L:133) [menus:l01]
- When the game is exported, then the long Godot licence and its components' texts go to `LICENSES.txt` beside the
  exe. (ref: L:136-160) [later: with the release export]
- When an asset is added, then a test fails unless an entry of `credits.json` covers it. (ref: data/credits.json
  `_note`; tests/menus_test.gd) [menus:l02 (credits.tres)]

### The cursor
- When the game runs, then its own cursor shows everywhere: a pure white arrow with the dark ink outline, no hover
  variant (the arrow for buttons too), hotspot (3, 2); a text field keeps the I-beam. (ref: ST:56-58, ST:82-87; Q361,
  Q362, Q373) [menus:c01]
- When the game quits, then the cursor's texture is let go first (it leaked at quit). (ref: ST:90-95) [no code: the project setting's cursor has nothing to let go]

### Loading
- When a game loads, then the flat is not drawn (3D off, so the work runs fast) and a loading screen covers it: the
  title's backdrop, a cream card (560 px) with a tumbling sock icon (96 px, turning 4 rad/s, bobbing 8 px), the
  heading, and a progress bar (440 x 28) when the wait can tell how far it is. (ref: LS:1-77, LS:97-109) [menus:d01; the 3D is not switched off yet: a follow-up]
- When it is a New Game, then it reads "The washer bursts open..." with the bake's progress; a saved game, "Loading
  the flat..."; a Guest, "Joining...". (ref: M:209-211, M:506) [menus:m05 (the words); the bake's progress is house/09's]
- When the loading work runs, then it is sliced to about 14 ms a frame so the screen stays smooth. (ref:
  data/tuning/loading.json; Q521) [house/09's laying]
- When loading ends, then the screen goes two frames later and the game fades in from the backdrop's colour over 0.5 s
  (`fade.seconds`), over everything, the HUD too, with no input lock. (ref: M:708-719; data/tuning/fade.json; Q1262-Q1265) [menus:d01]
- When the bar measured a wait that is over, then it shows full; it never goes backwards. (ref: LS:104-109) [menus:d01]

### The ESC menu (the way back to the title)
- When Esc is pressed in play, then the ESC menu opens over the game; menus never pause (the world runs on, only this
  player freezes). (ref: SM:1-7; Q253) [save:s01, menus:e01]
- When it is open, then solo shows "Back to title" and "Quit game", a Host "End session", a Guest "Leave", each a red
  exit keycap, and Options with Back. (ref: SM:1-5, SM:21; Q289, Q372, Q491) [menus:e01, menus:e02]
- When the Host presses End session, then it asks "Everyone will be sent back to the menu." End / Cancel. (ref: SM:21;
  Q315) [menus:e02]
- When Back to title, End session or Quit game is taken, then the game saves first (solo and Host), then goes to the
  title (or closes). (ref: M:1036-1057) [save:s01, menus:e01, menus:e02]
- When the window is closed, then the game saves (each player starts the loaded game where they quit) and a Host's
  Session ends for everyone. (ref: M:859-866; Q296, Q250) [no case: Autosave saves on the window's close request]
- When a Guest's session ends, then the title shows why once ("The host ended the session"). (ref: T:61; Q250, Q1657) [menus:e02, menus:m07]

### Worlds and Groups
- When the Worlds are counted, then there is one Solo World and at most 5 co-op Worlds, each its own file under
  `user://worlds/` (`solo.json`, `coop1.json` .. `coop5.json`). (ref: W:1-34; Q1647) [save:s16, save:s15 (worlds/<player id>/, Q2566)]
- When a World is shown in a list, then its row has a name (the Solo World: "Solo World"; a co-op World: its Group's
  names, or "No Group yet") and details "<floor> · played <h>h <mm>m · last <date time>". (ref: T:439-475) [save:s16]
- When the co-op Worlds are listed, then the newest (last played) comes first. (ref: W:74-83) [save:s16]
- When a co-op World is first played (Play from the Lobby), then whoever is in the Lobby becomes its Group, for good:
  no seats, no adding later. (ref: WM:210-219; Q1645) (lobby) [dropped: no Group lock, Q2554] (lobby)
- When a Guest outside a World's Group joins, then they are refused "This World belongs to its Group: you are not in
  it" (placeholder). (ref: WM:146-147, WM:169-174; Q1652) [dropped: no Group lock, Q2554]
- When the Solo World is played with at least one Guest, then it becomes a co-op World in a free slot and the Solo slot
  is left empty; played by the Host alone it stays the Solo World. (ref: W:95-124; Q1646, Q1737) [save:s04]
- When every co-op slot is used and a New Game (or the Solo World going co-op) needs one, then the Host is asked to
  delete one first: "All 5 co-op Worlds are used: delete one first". (ref: W:12-14; Q1650, Q1738) (lobby) [later with the Lobby; Autosave keeps the Solo World when every slot is used] (lobby)
- When a World is deleted, then it asks "Delete <name>? It cannot be brought back."; its file, backup and half-written
  copy go. (ref: T:52; W:127-129; Q1647) (lobby) [save:s16 (the files go); the question comes with the Lobby] (lobby)
- When Solo's New Game would overwrite the Solo World, then it asks "Start a new game? The saved game is lost.", after
  the "Pairs per Drawer" page. (ref: LB:10-11; digest Q1754, Q1766) (lobby) [later with the Lobby] (lobby)
- When a World's header does not read, then its slot shows "Damaged World", counts as used and may be deleted; a World
  of another version shows as an empty slot. (ref: W:15-17, W:50-66; Q1739) [save:s08 (a World that reads neither way); Worlds.rows() shows "Damaged World"; changed: another version is refused, save:s09]
- When a World records its players, then each player key keeps a small per-World id and the last name and colour
  seen; the World's record is Host-only, never in the join snapshot. (ref: WM:1-5, WM:177-207; Q1677) [changed: the player id is the key everywhere (Q2458); names and colours kept in the record]
- When a Group member's World is played with them absent, then their Coins, Upgrades and spot wait for them.
  (digest Q1648) [save:s03 (Coins); Upgrades are not Part state yet]

### Saves
- When a save is written, then only the Host (or solo) writes; a Guest never saves. (ref: M:804-810; Q249) [save:s03]
- When anything in the game changed, then the autosave writes within 2 s, the file's text made and written on a worker
  thread (the World copied first), so it costs no hitch; the next save, a load or a delete waits for it. (ref:
  M:829-846; S:221-233; physics/27) [save:s05]
- When the game goes back to the title, quits, closes or goes to the Lobby, then it saves at once; while the World is
  baking, setting up or spawning, it never saves. (ref: M:839-846, M:859-866, M:1036-1088) [save:s01, save:s05 (never before the World is loaded)]
- When the scene leaves with a change not yet saved, then it saves while the Mess still has its Socks (a save on
  delete wrote a flat with no Mess). (ref: M:412-419; maintenance/76) [no case: Autosave saves an unsaved change as the level leaves]
- When the save is made, then a Guest's held things are laid down round them in the saved World (nobody holds anything
  offline); the Host keeps their own Hands; whatever flies is saved as landed; the live game is untouched. (ref:
  S:208-218; Q295) [save:s13 (at the load: absent players' Socks drop, Q2559; the Host keeps theirs), save:s14 (in the air laid, Q2560)]
- When the save is made, then everyone's current spot is noted, so each player starts the loaded game where they quit;
  a new player starts at the washer spawn. (ref: M:849-855; Q296, Q285) [save:s01]
- When the save, the join snapshot and the settle stream encode the World, then they share one encoding (WorldCodec:
  a record per Sock, quantised poses, so a pose that went through once stays put). (ref: game/world/world_codec.gd:1-15;
  S:52-62) [changed: one encoding, Parts.snapshot() and save_state(); the Mess's packed state]
- When the file is written, then its first line is the World's header (version first, kind, Group, floor, play time,
  last played, members) and the second the save with the World gzipped in Base64; the menu reads only the first line.
  (ref: S:236-251, S:315-335; WM:229-236) [changed: M1 a, one JSON file {version, saved_at, data}]
- When the file is written, then it never truncates the save in place: the text goes to `.tmp`, flushed, closed and
  checked; the old save becomes `.bak` only when it reads (a broken file never replaces a good backup); the `.tmp`
  then takes its place; on failure the old save is put back and the error logged. (ref: S:236-284) [save:s07, save:s15]
- When the newest save does not read and its `.bak` does, then the `.bak` loads and the title says "Loaded your
  previous save" once. (ref: S:338-354; Q1188, Q1503) [save:s07]
- When neither reads, then the file is kept as `<name>.corrupt.json` (its name only in the log), a new game starts and
  the title says "Your laundry got lost in the wash. Starting fresh." once. (ref: S:355-369; Q1189, Q1502) [save:s08: kept as <file>.damaged, outside the synced pattern]
- When a save's version differs from the build's, then it is not loaded (no save compatibility while unshipped; 29
  versions so far). (ref: S:19-22, S:392-401; Q1795) [changed: Q2557, old saves load through migrations: save:s09, save:s10, save:s11]
- When a save loads, then every Openable and drawer starts shut (what rode out in an open drawer slides back in), the
  TV off, the Radio keeps its channel; anything saved outside the flat (Socks, the Radio, the Sock detector, Guide
  cards) lies in front of the washer. (ref: S:425-450; Q369; maintenance/06) [save:s13, save:s01]
- When a save loads, then saved players are not in the game until they join. (ref: S:182-183) [save:s13]
- When an older save numbered Socks past the 14-bit ids, then they are renumbered on load. (ref: S:65-100) [not needed: no 14-bit ids in the port]
- When a test or a tool runs, then the save path points elsewhere (never the player's file). (ref: S:7-9;
  game/debug/bench.gd:127) [tests/hooks.gd puts Save on a MemoryStore]

## What was weak
- **One class knew every field.** `Saves.to_dict` and `load_dict` list some 30 fields of a 1,600-line `Game` by hand
  (S:27-205); every feature edited them. The port's `Parts.snapshot()` already saves every Part's State group with no
  save code per feature.
- **A failed write was never shown.** `last_error` is set (S:282-284) and nothing reads it outside `saves.gd`: the
  player was never told the game was not saving.
- **Load fix-ups in one place.** Shut every Openable, put lost things back, keep the Radio's channel: all in
  `load_saved` (S:434-449), far from the things they fix.
- **Hidden global state.** `Worlds.choose` writes the static `Saves.save_path` (W:38-40); a test or a bench that
  forgot to set it wrote the player's file.
- **Fragile header.** The version is read by a regex over the first 48 bytes, with a fallback for older files whose
  keys were sorted (S:293-312).
- **Another version silently looks empty**, so a New Game there overwrites it (W:50-52, Q1739). Fine unshipped; after
  the first outside play-test it loses a tester's game.
- **Built in code.** The title (600 lines), Options, Licence and loading screen build every node in code with style
  overrides (T:177-242, O:45-80); tests press keys by their text (T:405-414). Q2163 reverses this: scenes on one Theme.
- **Options in a ConfigFile**, which builds an Object it finds in the text while it parses (the kit's settings
  template's note); the port's `Settings` is already JSON.
- **Join has no Cancel and no time limit** (T:559).
- **The Damaged and other-version rules, the per-World id and the header** add up to about 250 lines of Worlds code for
  6 files.

## Already in the port
- `Settings` autoload (`port: game/settings/settings.gd`, the kit's template): JSON at `user://settings.json`, window
  mode, vsync, master volume; `Sounds` registers the bus volumes (`audio/master_volume`, `sfx`, `ambient`, `music`,
  `ui`) and the pad rumble.
- Graphics presets Low, Medium, High as `.tres` (`port: game/look/presets/`), chosen by a project setting until
  Options exists (Q2323); no Auto, no SSAO switch yet.
- Mouse sensitivity and Invert Y are `MoveTuning` fields until Options (Q2238).
- The old font and theme: `port: game/look/theme.tres` (core/18); not set as the project's theme.
- `Parts.snapshot()` / `load_snapshot()` (`port: game/parts/parts.gd:158-178`): every Part's whole state by id, the
  join snapshot today. The Mess packs its own (zstd, `port: game/mess/mess.gd:649-665`).
- Per-player state keyed by the player id: Roster (`at`, `yaw`, `hands`), Coins, Hands (by player id, but by peer
  number when alone with no Roster: `port: game/hands/hands.gd:42-44`). Knockdowns are keyed by peer (fine: not saved).
- `user://profile.json` with the 128-bit player id (`port: game/net/player_profile.gd`); no name field in a menu yet.
- The main scene is the house (house/04, Q2509); `--host` / `--join=` from the command line (`LevelNet`).
- The cursor svg exists (`port: assets/ui/cursor.svg`); nothing sets it.
- Missing: the title, Options page, Licence page, loading screen, studio intro, ESC menu, the save file, autosave,
  Worlds, `credits.json`.

## Numbers
Placeholders in the old game unless a Q says otherwise: autosave 2 s (pitch 2026-11-11); 5 co-op slots (Q1647);
fade 0.5 s (Q1262); loading slice 14 ms (Q521); name 16 letters; port 24680; menu sizes (Q1495-Q1501); click -8 dB,
hover -20 dB, ±1.5 dB jitter (Q336); FPS caps 0/30/60/120/144; sensitivity 0.2-3.0.
