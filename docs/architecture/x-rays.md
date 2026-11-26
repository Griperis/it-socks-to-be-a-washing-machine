# The X-rays: Show pair and Show Cabinet

**Status: build plan for batch C (designed in core/152 on the designer's answer Q2701, with Q2697 and Q2705;
2026-11-26). Not filed yet: the drafts below are for the lead to file.** Behaviour list:
`docs/migration/m4-lists/10-x-rays.md` (31 lines). Batch C is built unattended and reviewed in play as a whole, as
batches A and B were (Q2603-Q2605): an open choice an agent meets takes the old game's answer and goes on the batch's
review sheet (Q2604).

## What it owns

The two X-ray abilities each player owns once they have bought them: the Sock X-ray's **Show pair** (key 1) and the
Cabinet X-ray's **Show Cabinet** (key 2, renamed from "Show drawer", Q2701); their clocks (on for a while, then a
cooldown); what each one shows and how (the mate's glow through walls, a Teammate's held mate, the whole Cabinet
outlined in amber); the screen tint while one is on; their hint arrows; their two ability icons on the HUD; their
sounds and words; the effects of the eight Personal X-ray Upgrades (their `stat`s).

It does not own the Upgrade grid, the `buy` verb or the menu (core/129, built: it gives eight Upgrades their `stat`
and fixes the Cabinet X-ray's words), `Upgrades.value()` (core/129), the outline (core/11, built: it adds two
styles), the hint arrows (core/43, built: it adds two sources), the Sole cues and the `match` sound (core/131: the
ready sound borrows its clips), the Hands, the Mess or the Cabinets (it reads them), the lamps' clicks (core/149's
149-H: they borrow its on and off clips). Where they meet it, it names the seam.

## The shape

**No Part and no Command.** An X-ray decides nothing anybody else sees: it changes no shared state, and its glows only
show what this machine already knows of the Mess, the Cabinets and the Teammates' Hands (behaviour list "Owning and
using" line 6; Q2701: only its user sees it). So it is a view on the player's own machine, like the pings' marks and
the Sole cues, and the rules "decided state lives on Parts" are kept by having none.

- **`XRayAbility`** (Resource, `game/xray/xray_ability.gd`; one `.tres` per X-ray in `game/xray/abilities/`:
  `sock.tres`, `cabinet.tres`). What differs between the two X-rays, as data:

  | Field | Show pair (`sock.tres`) | Show Cabinet (`cabinet.tres`) |
  |---|---|---|
  | `action: StringName` | `xray_show` | `cabinet_xray_show` |
  | `upgrade: Upgrade` (the refusal's name, the icon's picture) | `upgrades/xray.tres` | `upgrades/cabinet_xray.tres` |
  | `owned`, `all_hands`, `duration`, `cooldown: UpgradeStat` | `xray`, `all_hands_xray`, `xray_duration`, `xray_cooldown` | `cabinet_xray`, `all_hands_cabinet_xray`, `cabinet_xray_duration`, `cabinet_xray_cooldown` |
  | `shows: Shows` (MATES, CABINET) | MATES | CABINET |
  | `name` / `short_name` / `on_text` | "Show pair" / "X-ray" / "Sock X-ray on" | "Show Cabinet" / "Cabinet X-ray" / "Cabinet X-ray on" |
  | `colour: Color` | `#33d6ff` | `#ffa826` |
  | `outline: OutlineStyle` | `game/xray/sock_xray_outline.tres` | `game/xray/cabinet_xray_outline.tres` |
  | `view: PackedScene` (what shows while on) | `game/xray/mate_glows.tscn` (152-B) | `game/xray/cabinet_glow.tscn` (152-C) |
  | `key_icon: Texture2D` | `assets/ui/key_1.svg` | `assets/ui/key_2.svg` |
  | `on_sound`, `off_sound`, `ready_sound` | `xray_on`, `xray_off`, `xray_ready` | the same three |
  | `screen_slot: int` (the tint's slot, below) | 0 | 1 |
  | `order: int` (left to right on the HUD) | 0 | 1 |

  The old made the Cabinet X-ray a subclass of the X-ray with its tuning section switched by name (weak point 2); here
  one class reads one Resource, and the only branch is `shows` (what counts as a target).
- **`XRays`** (`game/xray/xrays.gd`, a Node under the local player in `player.tscn`): at ready it lists
  `game/xray/abilities/` with `ResourceLoader.list_directory()` (an export lists the remapped files too) and makes one
  `XRay` child per ability, sorted by `order`. A Teammate's avatar has none (only its user sees an X-ray).
- **`XRay`** (`game/xray/xray.gd`, a Node, one per ability): the clock, the key, the targets, the words and sounds.
  - **The clock is two `Timer` nodes** (`Show`, `Cooldown`; one-shot, pausable with the tree), started from
    `Upgrades.value(ability.duration, by)` and `Upgrades.value(ability.cooldown, by)` when they start (never cached:
    a Lingering or Recharge bought mid-cooldown counts from the next show). The old ran its clock by hand in a view's
    `_process` (weak point 1); a Timer is Godot's own node for the job. Not saved, not joined: a load or a join starts
    both ready (line 5).
  - **The key:** `_unhandled_input` takes a press of `ability.action` (pressed, not an echo; keyboard and pad), so a
    menu that takes the input (the Upgrade menu, the Esc menu, the ping wheel) blocks it, and riding the Elevator or
    lying down does not (the old `press_to_use` in `_unhandled_key_input`, `RIG:174-186`).
  - **`use()`:** not owned (`Upgrades.value(ability.owned, by)` is 0): the player's refusal "%s not bought" with
    `short_name` ("X-ray not bought", "Cabinet X-ray not bought"), with `refuse`, as any refusal. Owned but not
    `usable()`: nothing at all, no sound, no cooldown spent (line 4, Q2010). Else `Show` starts, the HUD says `on_text`
    (not a refusal) and `on_sound` plays flat for this player; `Show`'s timeout plays `off_sound` and starts `Cooldown`.
  - **What it shows** (`shown_items()`): the active held item when it fits (MATES: a loose Sock, not a Pair or a
    token, `XR:128-131`; CABINET: a loose Sock or a Pair, not a token, `CX:39-41`); with the All-Hands stat at 1 every
    fitting item in the Hands (Q1345). `targets()` from them:
    - MATES: for each shown item's Design, the other Sock of that Design (two records per Design, `Mess.count_of`)
      while it is LYING or FLYING in the Mess, each once; and every Teammate's held loose Sock of that Design, in any of
      their slots (the old `_mates_held` took every slot, `RIG:516-525`; Q252).
    - CABINET: for each shown item's Collection, the level's Cabinet (group `cabinets`) that `takes()` it, each once,
      whether locked, sheeted or full (the old showed the Collection's Cabinet whatever its state:
      `next_drawer` fell back to the aimed drawer, `CX:58-64`, `cabinets.gd:123-130`). The Dirty Socks' bin rule is
      not ported (Q1075).
  - `usable()` is owned, neither timer running, and `targets()` not empty. `state()` for the icon: HIDDEN (not owned),
    ON, COOLDOWN, READY or GREYED (owned, idle, nothing to show).
  - Signals: `switched(on: bool)`, `became_ready` (the `Cooldown` timeout while `usable()`, Q1988: a cooldown ending
    while nothing fitting is held gives nothing, and picking a Sock up later only lights the icon, Q2701).
  - `targets()` is refreshed on `Parts.applied` (any answer may move a Sock, a Hands slot or a Cabinet's Rows) and on
    the Hands' cycle, not every frame.
- **The views** (one per kind, instanced as the XRay's child from `ability.view`, shown only while ON): `MateGlows`
  (152-B) and `CabinetGlow` (152-C). Each adds its targets to the HUD's `HintArrows` as a source (as `PingMarks` does).
- **The HUD** (152-D): `XRayScreen` and `AbilityIcons` on the local player's `Hud`.

### The kinds of state (`coop-structure-for-the-port.md`)

| What | Kind | Where |
|---|---|---|
| owning an X-ray and its Upgrades' levels | decided state | the `Upgrades` Part (core/129, synced; read with `value()`) |
| an X-ray on or cooling down, how long is left | looks, this machine only | the `XRay`'s two Timers; not saved, not joined (line 5) |
| what is held, where a Sock lies, a Cabinet's Rows | decided state, read only | the Hands, the Mess, the Cabinet Parts, as this machine has applied them |
| the glows, the outline, the arrows, the tint, the icons | looks | views of the XRay and of the Parts it reads |

A Guest's X-ray reads its own applied copies: it shows a mate where its Mess has it (a Guest's moving Socks are its
own looks, Q3 of the co-op structure), and never asks the Host anything (line 6).

## What shows (the views)

### Show pair: `MateGlows` (152-B)
- **A Mess mate:** a live copy of the Sock's Looks (`SockDress.make`, as the ping's copy: the Mess draws in batches),
  following its drawn pose while it lies or flies, scaled `glow_scale` 1.08 (`XV:13`), wearing the X-ray glow material
  (`game/xray/xray_glow.gdshader`, ported from the old: unshaded, no depth test so it shows through walls, Heaps and
  furniture; the colour, whitened towards the rim by 0.3, brightness 0.9-1.2 and alpha 0.9-1.0 breathing at 1.5 Hz)
  and outlined with `sock_xray_outline.tres`. The behaviour list says "glows ... pulsing" in one word; this is the old's
  whole look (`XV:46-76`, `xray_glow.gdshader`).
- **A Teammate's held mate** (on their avatar, in any slot): the glow material as an overlay on its meshes and an
  Outline of the X-ray style beside its own, so both follow the cloth (`XV:211-218`; the outline's copies keep the
  skin and blend shapes, core/11).
- **The copy follows the Sock** each frame (the old rebuilt it only when the World changed, so a moving mate left its
  glow behind: improved technically, no look change). The ping's copy-following code moves out of `ping_mark.gd` into
  one shared node, `game/mess/sock_copy.gd` (a Mess Sock's live Looks copy at its drawn pose), used by both: one way
  to draw a Mess Sock outside its batch.
- Cycling the Hands moves the glow (the targets follow the active item).

### Show Cabinet: `CabinetGlow` (152-C)
- **The whole Cabinet** that takes the shown item: a second `Outline` of `cabinet_xray_outline.tres` beside the
  Cabinet's own (as the ping adds one), round its real silhouette, drawers and dust sheet included, through walls;
  no separate drawer mark and no box glow (Q1964, Q1971, Q2040: `box_glow` false, so the box glow is not ported).
- **A Cabinet that grows** new Rows while shown (a floor opens): its outline is remade so the new drawers are in it
  (`CXV:72-74`). The Outline makes its copies the first time it is shown; it must make them again when the Cabinet's
  `rows` change (read from `Parts.applied`, no edit to `cabinet.gd`).

### How both look (the numbers are the old placeholders, judged at the first still, Q2701)
- The outline is the game's one outline (core/11) at `width` 1.5, `pulse_hz` 1.5, `pulse_grow` 0.6, `pulse_bright`
  0.4, `pulse_fade` 0.45, the colour the X-ray's; its `priority` above the ping's and the Sole cues' styles, so it is
  drawn last (the old `Highlight.LATE_PRIORITY`).
- The pulse runs in the outline's and the glow's shaders (core/11's pulse uniforms): no code motion.

### The hint arrows
Each view adds a source to the local player's `HintArrows` while ON: one target per glowing Sock (a Teammate's held
mate at its drawn place) or Cabinet (its middle), in the X-ray's colour, priority 0 (pings' 1 come first), no emoji
(`XV:167-179`, Q1513-Q1519). The arrows' own rules (off screen only, direction only, `max_arrows`, keeping clear of
the HUD) are core/43's.

## The HUD (152-D)

### The screen tint: `XRayScreen`
`game/xray/xray_screen.tscn`: a full-screen `ColorRect` (mouse ignored) with `xray_screen.gdshader` (ported as it was:
a tint over the whole screen and an edge vignette, the two X-rays' colours blended by strength in one pass) and its
material's `tint` 0.06, `vignette` 0.45, `vignette_start` 0.45 set in the inspector (`# placeholder:`). It sits in the
`Hud` right after the `Vignette`, under every other HUD node. Each XRay writes its slot's colour and strength:
1 while on, falling to 0 over the show's last `XRayTuning.screen_fade` 3 s, 0 off. The strength is the clock's value,
not a motion of its own, so it is set from the Timer, not a clip. One rect with two slots, as the old, rather than
one rect per X-ray, because stacked rects would not blend the same (a third X-ray would need a third slot).

### The ability icons: `AbilityIcons`
An `HBoxContainer` anchored bottom left (24 px in, 24 px up, separation 28) on the `Hud`, one
`game/ui/ability_icon/ability_icon.tscn` per XRay, made at ready in `order`. Authored in nodes (Q2658), filled by
`ability_icon.gd`:

| Node | What it is |
|---|---|
| `Halo` | four soft rings behind the keycap in the X-ray's colour (a `TextureRect` of a ring texture, modulated) |
| `Keycap` | an 84 px round `Panel` with the Theme's keycap look: variations `AbilityKeycap` (cream, ink rim, shaded lip), `AbilityKeycapGrey`, `AbilityKeycapOn` (rim in the X-ray's colour via `KeycapStyle.frame_colour`) |
| `Keycap/Picture` | the Upgrade's icon (`ability.upgrade.icon`), 1.25 x the face's radius |
| `Keycap/Sweep` | a radial `TextureProgressBar` (dark, alpha 0.6): what is left of the cooldown, shrinking clockwise from the top |
| `Keycap/Ring` | a radial `TextureProgressBar` in the X-ray's colour, 5 px: the show left, emptying |
| `Key` | the key's keycap (`ability.key_icon`, 36 px), centred under it, hanging 22 px down |
| `AnimationPlayer` | the clips below |

| State | Look |
|---|---|
| HIDDEN | the icon hidden (before the Upgrade is bought) |
| READY | the cream keycap, the picture in full |
| GREYED | `AbilityKeycapGrey`, the picture faded (0.35, 0.34, 0.32, 0.5), the whole icon at alpha 0.72 (Q1967) |
| COOLDOWN | greyed as above with the `Sweep` at the cooldown's fraction left |
| ON | `AbilityKeycapOn`, the `Halo` breathing, the `Ring` at the show's fraction left, the keycap pressed |

**Motion is clips (Q2697):**
- `press` (0.08 s): the face sinks down-right onto 0.7 of its lip, which shrinks under it, and darkens 0.4 towards its
  shade; `release` (0.08 s) springs it back when the show ends (Q2016).
- `halo` (looping, 1.5 Hz): the four rings at alpha (0.28, 0.22, 0.16, 0.10) x (0.6 to 1.0), 5 px out and 3.5 px
  apart (`AI:132-137`).
- `ready_pulse` (0.6 s): the keycap swells to 1.14 and back (a sine) while a ring in the X-ray's colour spreads from
  6 px to 24 px out of the rim, fading from 0.8 to 0 (`AI:121-127`; the list names the swell, the ring is the same
  old pulse). Played on `became_ready`, with `ready_sound` (Q1988, Q2701).

The icons' rectangles join the HUD's `keep_clear()` so a hint arrow slides past them (core/43, Q1537).

## How it is authored (Q2607)

- **Typed Resources in the inspector:** the two `XRayAbility` files (the words, colours, sounds, keys); the eight
  `UpgradeStat`s (`game/economy/stats/`, the old `upgrades.gd:191-197` and `data/tuning/xray.json`,
  `cabinet_xray.json`, each `# placeholder:`, Q2701):

  | Stat | Kind | base | step | least | format |
  |---|---|---|---|---|---|
  | `xray`, `cabinet_xray` | FLAG | | | | |
  | `all_hands_xray`, `all_hands_cabinet_xray` | FLAG | | | | |
  | `xray_duration` | ADD | 10 s | 5 (Lingering) | | `%.0fs` |
  | `xray_cooldown` | SCALE_DOWN | 50 s | 0.2 (Recharge) | 0.1 | `%.0fs` |
  | `cabinet_xray_duration` | ADD | 10 s | 5 | | `%.0fs` |
  | `cabinet_xray_cooldown` | SCALE_DOWN | 30 s | 0.2 | 0.1 | `%.0fs` |

  Set on the eight Upgrade files as their `stat` (`xray` -> `xray`, `all_hands_xray` -> `all_hands_xray`,
  `xray_recharge` -> `xray_cooldown`, `xray_linger` -> `xray_duration`, and the Cabinet four alike), so they stop
  being "Coming soon" (Q2669). Their prices and cells stay (150; 250; 100/160; 100/160; 200; 300; 100/160; 100/160,
  `# placeholder:`). `XRayTuning` (`game/xray/xray_tuning.tres`): `glow_scale` 1.08, `screen_fade` 3 s. The two
  `OutlineStyle`s and the glow's `ShaderMaterial` (`game/xray/sock_xray_glow.tres`). The tint's numbers on the screen
  scene's material.
- **Dropped files, no code:** a third X-ray of a kind that exists (MATES or CABINET) is an `XRayAbility` `.tres` in
  `game/xray/abilities/` (plus its Upgrades, stats, input action and sounds, all files): the player's `XRays`, the HUD's
  icons and the zoo station's board find it. A new kind of target is code (one branch of `targets()` and a view).
- **The zoo station** `game/zoo/stations/xrays.tscn` (its own things under `game/zoo/xrays/`), built from the data at
  load (Q2337): a board with one row per `XRayAbility` in the folder (its icon and key, its words, its Upgrades and
  their stats' now -> top) and one switch per X-ray Upgrade found by its stat (Own / level up / Reset, through the
  station's own `Upgrades.set_level`); a small room with a wall and a Heap: Socks of a few Designs with their mates
  behind the wall and one under the Heap; a Teammate stand-in holding a mate (as the Hand-off station's `Holder`);
  two small Cabinets of the station's Designs (one sheeted and locked) with a "Grow a Row" switch; its own `Mess`,
  `Hands`, `Upgrades`. A new ability shows its row and its icon with no other change.
- **Authored in nodes (Q2658):** the icons, the icon row, the screen tint and the board's rows are scenes and Theme
  variations; code fills them and instances a row scene per item.
- **Motion:** the icon's press, release, halo and ready pulse are AnimationPlayer clips in `ability_icon.tscn`
  (Q2697); the glows' and outlines' breathing is their shaders' pulse (core/11). There is no code tween.
- **Sounds** (SoundEvents in `sound_catalogue.tres`, flat, SFX; the old picks or shares):
  - `xray_on`: the old `cc0/laleksic_switch_on`; `xray_off`: `cc0/laleksic_switch_off` (the clips copied to
    `assets/audio/` as `xray_on__laleksic_switch_on.ogg` and `xray_off__laleksic_switch_off.ogg` with their
    `SOURCES.md` rows and credits).
  - `xray_ready`: shares `match`'s clips (core/131: the first synth candidate at -8 dB, Q2701).
  - `lamp_on` and `lamp_off` (149-H) share `xray_on`'s and `xray_off`'s clips. Whichever ticket lands first copies the
    clip and adds its row; the other only adds its SoundEvent naming the same file. Each stays its own SoundEvent, so
    the designer can part them on the Sounds bench.
- **Input:** `python3 kit/tools/input_actions.py add xray_show <key 1> <pad D-pad left>` and
  `cabinet_xray_show <key 2> <pad D-pad right>` (the old bindings, physical keys 1 and 2, joypad buttons 13 and 14;
  the pad ones are placeholders until batch D's controller work, as Q2698 did for the vacuums).
- **Models:** none (Q2705 has no X-ray family): the Upgrade pictures (`assets/ui/upgrade_*xray*.svg`) and the key
  caps (`key_1.svg`, `key_2.svg`) are in the port already. No asset ticket.

## Words (Q2701)
"Show pair", "Show Cabinet", "Sock X-ray on", "Cabinet X-ray on", "X-ray not bought", "Cabinet X-ray not bought", the
key caps "1" and "2", and the eight Upgrades' titles and tooltips as the old (`UJ:185-340`, already in the port's
files), but for the Cabinet X-ray's: its title becomes "Cabinet X-ray: Show Cabinet" and its tooltip says the whole
Cabinet glows (the exact sentence is the designer's: Open follow-ups).

## Saves, joins and the Lobby
Nothing: an X-ray is not saved and not joined (line 5); its Upgrades' levels are the `Upgrades` Part's (core/129).
`tests/saves/shape.json` does not change.

## Seams to the other pieces
- **The Upgrade grid (core/129, built):** this piece sets `stat` on its eight files and changes the Cabinet X-ray's
  title and tooltip. `tests/upgrades_test.gd` uses `xray` as its "Coming soon" case: 152-A moves that case to a
  test-only Upgrade with no `stat` (a `.tres` under `tests/`), so no later batch C ticket breaks it when the last of
  the 16 stops being "Coming soon".
- **The Personal Upgrades (core/130):** nothing shared but `Upgrades.value()`, which core/129 built. The X-rays' stats
  are their own files; core/130's `player_upgrades.gd` is not touched.
- **The outline (core/11, built):** two `OutlineStyle`s; a second Outline beside a thing's own, as the ping does.
  Nothing in `outline.gd` changes, but the Cabinet's outline must be remade when its Rows grow (152-C).
- **The Sole cues (core/131):** both outline a Teammate's held Sock on this machine and both read the avatar's held
  view to find it; the X-ray's style takes the higher `priority`. `xray_ready` shares `match`'s clips: if core/131 has
  not landed when 152-D runs, 152-D copies the old synth candidate and core/131 points `match` at it.
- **The pings (core/43, built):** `PingMark`'s Mess copy moves to `game/mess/sock_copy.gd` (152-B), the pings' look
  unchanged (the `pings` suite proves it); the hint arrows take two more sources.
- **The day (core/149, `day-and-exterior.md`):** `lamp_on`/`lamp_off` share `xray_on`/`xray_off` (above).
- **The other batch C pieces:** none. The Elevator, the devices and the Cat touch nothing here; `sound_catalogue.tres`
  and `tests/upgrades_test.gd` are the only files shared across the docs (the waves note them).

## Changed technically from the old (no choice: tell the designer at the sitting)
- The clock is two Timers on the player's machine, not a hand-run count in a view's `_process`; still not saved.
- One X-ray class and one Resource per X-ray, not a subclass switched by name.
- The glows and outlines are the port's one outline and a shared Mess-copy node; the copy now follows a moving mate.
- The icon is nodes, Theme variations and clips, not 177 lines of drawing; the press and pulses are clips.
- The Dirty Socks' bin rule is not ported (Q1075).

## The designer's answers this piece rests on
- Q2701: the X-rays as the old, with one wording fix: "Show Cabinet", the tooltip saying the whole Cabinet glows; the
  ready sound borrows the Sole Mates cue; no cue until it is usable; only its user sees it; the old timings and prices
  as placeholders; the outline judged at its first still, a Teammate's held Sock included.
- Q2697: motion is AnimationPlayer clips, not code tweens.
- Q2705: batch C's models are ported by the port rules (the X-rays have none).
- Q2669: the eight Upgrades are "Coming soon" until this piece.
- Earlier, kept: Q536, Q539-Q543, Q601-Q604, Q1345, Q1346, Q1513-Q1519, Q1964-Q1971, Q1987-Q1989, Q2010-Q2016, Q2040,
  Q252.

## Draft tickets (ready-for-agent; the lead files them)

Each builds on graybox where a Looks is missing and waits for no asset; every number `# placeholder:` the old. "Lines"
are the behaviour list's (`10-x-rays.md`) by heading. Every new script has its `.uid`; the real-path case drives player
input through the scene's own wiring.

### 152-A The X-rays: owning, the keys, the clock, the Upgrades
- **Lines:** "Owning and using" (all 6); "Show pair" line 3 (a Pair or a token shows nothing) and the rule of line 4
  (All-Hands: which items count); "Show drawer" line 3 (nothing active, nothing shows) and the rule of line 4; "The
  Upgrades" (all 8: their stats, so they are bought and take effect); "Words" (all, with "Show Cabinet", Q2701).
- **Build:** `XRayAbility`, `XRays`, `XRay` (the Timers, the key, `use()`, `shown_items()`, `targets()` for both
  kinds, `usable()`, `state()`, the signals), `XRayTuning`, the two ability files (no `view` yet), the eight stats set
  on the eight Upgrades, the Cabinet X-ray's new title and tooltip (as the designer's answer gives it), the two input
  actions, `xray_on` and `xray_off` with their clips, sources and credits (unless 149-H has added them), `XRays` in
  `player.tscn`, the X-rays station, `tests/upgrades_test.gd`'s "Coming soon" case moved to a test-only Upgrade.
- **Acceptance:** in the station, with the X-ray owned, the player picks a loose Sock whose mate lies behind the wall
  (a left click on it) and presses key 1: the HUD reads "Sock X-ray on", `xray_on` plays, `usable()` is false while
  on; after the show (a test-only duration stat) `xray_off` plays and the cooldown runs for the stat's cooldown; a
  press while cooling down does nothing and plays nothing; with the X-ray not owned key 1 reads "X-ray not bought"
  with `refuse`; holding a Pair, key 1 does nothing and spends no cooldown, key 2 (Cabinet X-ray owned) reads
  "Cabinet X-ray on"; with empty Hands neither does anything; All-Hands X-ray makes `targets()` hold the mates of
  every loose Sock held, each Design once; Recharge level 2 makes the cooldown 30 s, Lingering level 1 the show 15 s;
  the eight Upgrades are bought from the menu (no longer "Coming soon") and the board's numbers show "%.0fs"; a save
  and load in the house while an X-ray cools down starts it ready; on a Guest, the X-ray uses the Guest's own copy
  and sends no Command (the Session's sent count is unchanged). **Real path:** the player's key 1 press, through
  `XRay._unhandled_input`, to the HUD's message "Sock X-ray on" and the `xray_on` sound played.
- **suites:** [xrays, upgrades, economy, coop_xrays]
- **Model:** opus.
- **Authored:** the abilities and stats in the inspector; a dropped ability file shows in the station's board.

### 152-B Show pair: the mates glow
- **Lines:** "Show pair" lines 1, 2 and 4 (the glow of every target); "How they look" line 1 (the Sock X-ray's) and
  line 3 (its arrows); "Owning and using" line 6 for the glows (only its user sees them).
- **Build:** `game/mess/sock_copy.gd` (moved out of `ping_mark.gd`, which uses it), `MateGlows` (`mate_glows.tscn`,
  `.gd`), `xray_glow.gdshader` and `sock_xray_glow.tres`, `sock_xray_outline.tres`, the overlay and second Outline on
  a Teammate's held mate, the arrows' source; `sock.tres`'s `view`. Stills of a mate through the wall, under the Heap
  and in the stand-in Teammate's Hands go to `<main checkout>/builds/review-xrays/` for the batch review sheet (Q2701:
  the outline is judged at its first still).
- **Acceptance:** in the station, with Show pair on, the mate behind the wall has a copy at its drawn pose wearing
  the glow and the cyan outline, both visible in the camera's render through the wall; the mate under the Heap too;
  a thrown mate's copy follows it in the air; cycling the Hands (the mouse wheel) to another loose Sock moves the
  glow to its mate; a Pair active shows none; All-Hands shows each held Sock's mate once; the mate held by the
  Teammate stand-in in a non-active slot carries the overlay and the outline; the mate off screen has an edge arrow
  in `#33d6ff`, gone once it is on screen; the glow ends with the show. In co-op the Guest's X-ray glows the Host's
  held mate on the Guest's screen and the Host sees no glow. The pings' look is unchanged. **Real path:** key 1, then
  the mouse wheel's cycle, through the scene's wiring, to the outlined copy over the new active Sock's mate in the
  rendered view.
- **suites:** [xray_mates, coop_xrays, pings, outline]
- **Model:** opus.
- **Authored:** the glow material and the outline style in the inspector; the glow's breathing is the shader's.

### 152-C Show Cabinet: the Cabinet in amber
- **Lines:** "Show drawer" lines 1, 2 and 4 (the outline of every target Cabinet); "How they look" line 1 (the
  Cabinet X-ray's) and line 3 (its arrows).
- **Build:** `CabinetGlow` (`cabinet_glow.tscn`, `.gd`), `cabinet_xray_outline.tres`, the remade outline on a Rows
  change, the arrows' source; `cabinet.tres`'s `view`. Stills of a Cabinet through a wall to
  `<main checkout>/builds/review-xrays/`.
- **Acceptance:** in the station, holding a Pair with Show Cabinet on, the Cabinet of its Collection has a second
  Outline in `#ffa826` shown round its meshes and no other Cabinet has one; the sheeted, locked one shows when its
  Collection is held; "Grow a Row" while it shows puts the new drawer's mesh in the outline's copies; All-Hands
  Cabinet X-ray shows each held Collection's Cabinet once; cycling to empty-handed hides it; off screen an amber arrow
  points at it; the outline ends with the show. **Real path:** key 2 with a Pair held (picked with a left click),
  through the scene's wiring, to the amber Outline shown on that Cabinet.
- **suites:** [xray_cabinet, cabinet, outline]
- **Model:** sonnet.
- **Authored:** the outline style in the inspector.

### 152-D The X-rays on the HUD: the icons and the screen tint
- **Lines:** "The ability icons (HUD)" (all 5); "How they look" line 2 (the screen tint).
- **Build:** `ability_icon.tscn` and `.gd` with its clips, the Theme variations on `game/look/theme.tres`,
  `AbilityIcons` and `XRayScreen` in `player.tscn`'s `Hud`, `xray_screen.tscn` and `.gdshader`, the icons in the
  HUD's `keep_clear()`, `xray_ready` (sharing `match`'s clips). A still of both icons in each state and of the tint with
  both X-rays on to `<main checkout>/builds/review-xrays/`.
- **Acceptance:** in the house with neither Upgrade owned no icon shows; owning the X-ray shows its icon at the
  bottom left (24 px, 24 px) with "1" under it, the Cabinet X-ray's 28 px to its right; with empty Hands it is greyed
  (alpha 0.72); a Sock picked lights it with no pulse and no sound; key 1 puts it ON (the `press` clip played, the
  `Ring` at 1 and falling) and the tint's slot 0 at strength 1, falling to 0 over the show's last 3 s; at the show's
  end `release` plays and the `Sweep` starts at 1; the cooldown ending with a Sock held plays `ready_pulse` and
  `xray_ready` once; ending with empty Hands plays neither, and a later pick only lights it; both on, the tint's two
  slots are set; a hint arrow at the bottom left slides clear of the icons. **Real path:** key 1 with a Sock held,
  through `XRay` and the HUD's wiring, to the icon's `press` clip played and the screen tint's strength 1.
- **suites:** [xray_hud, hud, pings]
- **Model:** sonnet.
- **Authored:** the icon is nodes, Theme variations and clips; the tint's numbers on its material.

### Behaviour lines not in a draft
None: every line is in 152-A to D. Not ported, as the list says: the Dirty Socks' bin glow (Q1075), the F1 menu's
debug X-ray (Q2599), the Size and Collection X-rays (Q536).

## The waves

At most 5 agents; a wave starts when the waves before it are merged.

| Wave | Drafts (suggested model) | Files each is alone on in its wave |
|---|---|---|
| 1 | 152-A (opus) | `game/xray/xray*.gd`, `game/xray/abilities/`, `game/economy/stats/` (8 new), the 8 X-ray Upgrade files, `project.godot` (two actions), `sound_catalogue.tres`, `assets/audio/` (2 clips), `assets/audio/SOURCES.md`, `game/ui/licence/credits.tres`, `player.tscn`, `zoo.tscn`, `game/zoo/stations/xrays.tscn`, `game/zoo/xrays/`, `tests/upgrades_test.gd`, `tests/xrays_test.gd`, `tests/coop_xrays_test.gd` |
| 2 | 152-B (opus); 152-C (sonnet); 152-D (sonnet) | 152-B: `game/mess/sock_copy.gd`, `ping_mark.gd`, `game/xray/mate_glows.*`, `xray_glow.gdshader`, `sock_xray_glow.tres`, `sock_xray_outline.tres`, `abilities/sock.tres`, `tests/xray_mates_test.gd`, `tests/coop_xrays_test.gd`; 152-C: `game/xray/cabinet_glow.*`, `cabinet_xray_outline.tres`, `abilities/cabinet.tres`, `tests/xray_cabinet_test.gd`; 152-D: `game/ui/ability_icon/`, `game/xray/xray_screen.*`, `player.tscn`, `hud.gd`, `game/look/theme.tres`, `sound_catalogue.tres`, `tests/xray_hud_test.gd` |

The X-rays can run beside any wave of the other batch C docs except on the files they share: `sound_catalogue.tres`
(149-A, 149-D, 149-H, and core/150's and core/151's sound tickets) and `tests/upgrades_test.gd` (any ticket that sets a
"Coming soon" Upgrade's `stat`: 149-A, 149-E, core/150's vacuum Upgrades). `player.tscn` is also 149-D's (the riders).
152-A should land before the other pieces' Upgrade tickets so the "Coming soon" case is moved once.

## Gotchas for the build
- Read `Upgrades.value()` when a timer starts and when `use()` asks, never at ready: a level bought mid-game counts.
- In a level without an `Upgrades` Part (most zoo stations) the X-ray is not owned: nothing shows, the icon is
  hidden. The X-rays station has its own `Upgrades`.
- A Design has two records: the mate is the other one; `Mess.count_of` and a scan of `designs` find it. Refresh
  `targets()` on `Parts.applied` and the Hands' cycle, not each frame.
- The Outline makes its copies the first time it is shown: a Cabinet that grows must be outlined anew, or the new
  drawers stay out of it.
- The glow's overlay on a Teammate's held Sock must be taken off when the show ends or the Sock leaves their Hands
  (the old cleared `material_overlay` on every rebuild).
- The X-ray's input must not fire through a menu: use `_unhandled_input`, as the old did.
- The `Show` and `Cooldown` Timers are pausable with the tree: a pause in Solo holds the clock, as the old's
  `_process` did.
- `tests/upgrades_test.gd`'s "Coming soon" case must not name an Upgrade a later ticket gives a `stat`.

## Open follow-ups
The choices below are in the ticket's `## Open follow-ups` (`docs/llm/core/issues/152-batch-c-x-rays-design.md`).
