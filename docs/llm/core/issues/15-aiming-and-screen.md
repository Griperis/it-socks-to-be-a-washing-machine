---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: ["[[11-outline]]", "[[assets/03-ui-art]]"]
notes: []
terms: []
---

# Aiming and screen: the prompt, the key hints, the aimed Size, the crosshair's states

M0.5 batch 4 without the outline (core/11 is built separately; Q2279, Q2296, Q2300). What the player reads while
aiming. The old code: `reference/it-socks/game/ui/hud.gd` (763 lines), `game/ui/prompts.gd` (111),
`game/world/sock_label.gd`, `game/ui/ui_bits.gd` (keycaps, `size_box`), `game/player/rig_aim.gd:95-113`,
`game/house/openable.gd:53-56`, `game/house/station.gd:37-48`. Today the port has a "+" replaced by core/18's two
bars (white or red through `modulate`), one `Message` label and one `Size` label showing the held Size as text.

## How the old one works
- **Three text rows and one corner, all redrawn only when their content changed.** Crosshair prompts at 58 % of the
  screen height, 32 pt (`hud.gd:151, 225-234`); the aimed Sock's row at 63 %, 28 pt (`hud.gd:153, 239-243`); the
  message at 70 %, 28 pt (`hud.gd:174`); the key hints bottom right, 24 pt, 22 px apart, 24 px from the edges
  (`hud.gd:140-147, 580-590`).
- **A prompt is KEY icons, then an icon, then words** (`hud.gd:593-604`); keys are drawn as pictures 1.5 x the font
  (`ui_bits.gd`), 32 px in prompts. `Prompt.joined` is the plain-text twin for tests.
- **The aimed Sock shows no words.** Only the pick key and the Size letter in a box: `[LMB] [L]` (`sock_label.gd:20-31`).
  The box is a dark panel (0.16, 0.12, 0.1, alpha 0.75), cream border 2 px, corner 6, margin 7 px (`ui_bits.gd:115-124`).
  A lying Pair shows the same. Nothing is shown when nothing is aimed (`hud.gd:239-243`).
- **Hints say what each key does now** (`prompts.gd:56-110`): "Drop / hold: Throw" `[RMB]` while the Hands hold
  something (always, Q2365), "Zoom" `[G]` and "Turn" `[R]` only for a held Sock or Pair
  (`hands.gd:262-269`), "Cycle" `[Wheel]` with 2 or more items, "Jump" `[Space]` and "Crouch" `[Ctrl]` always,
  "Sprint" `[Shift]` once unlocked (M4, Upgrades).
- **A station prompt** is its title with `[E]`, or `[LMB]` when click-only; an openable reads "Open the X" or "Shut the
  X" by its state (`station.gd:37-48`, `openable.gd:53-56`).
- **The crosshair** is white at alpha 0.9, and red (0.95, 0.25, 0.2) while the held item could not be dropped where it
  points (`hud.gd:633-639`, set every aim in `rig_aim.gd:112-113`: Hands let go, no teammate to hand to, drop not ok).

## Behaviour list
- A01 When the crosshair rests on a lying Sock or Pair in reach, then the pick key and the Size letter in its box show
  at 63 % of the height (`hud.gd:239-243`, `sock_label.gd:20-31`).
- A02 When it leaves, then the row empties at once (`hud.gd:241`).
- A03 (changed by Q2388) When the crosshair rests on a Cabinet's drawer, then its Cabinet's name and "drawer" show
  with the Collection's icon and the use key ("[E] Simple Cabinet Drawer", `cabinet.gd:72`); on a cupboard its own name
  ("[E] Cupboard A Drawer", `room.gd:708`); on the Door "Open the Door", and "Shut the Door" once open
  (`room_door.gd:73`).
- A04 When the Hands hold something, then the corner shows "Drop / hold: Throw" `[RMB]` (`prompts.gd:96-98`).
- A05 When the held item is a Sock or Pair, then the corner also shows "Zoom" `[G]` and "Turn" `[R]` (`prompts.gd:99-102`).
- A06 When the Hands hold 2 or more items, then the corner shows "Cycle" `[Wheel]` (`prompts.gd:103-104`).
- A07 The corner always shows "Jump" `[Space]` and "Crouch" `[Ctrl]` (`prompts.gd:108-110`).
- A08 When the content of a row is the same as last frame, then nothing is rebuilt (`hud.gd:228, 585`).
- A09 When a drop would be refused where the crosshair points, then the crosshair turns red, and white again when it
  would not (`hud.gd:633-639`, `rig_aim.gd:112-113`). Built in core/18 as a tint; the test of the states is here.
- A10 The crosshair's red is (0.95, 0.25, 0.2) at alpha 0.9; the port has (1.0, 0.25, 0.2) at full alpha
  (audit section 2). The old numbers are the target.
- A11 A woken Sock sliding or flying under the crosshair shows its Size row like a lying one (Q2339).
- A12 Aiming a Sock does not change the crosshair; no hover colour, no growing, no extra mark (`hud.gd:121-129`).
- A13 Every text of the screen reads back as plain text for tests (`hud.gd:687-695`).

- A14 With Sock Smarts (a player flag, Q2360), the held item's readout shows the collection icon, the Design name, a
  Sock or Pair icon and the held count n/capacity, with the wheel key when 2 or more are held
  (`reference/it-socks/game/ui/hud.gd:498-512`).
- A15 With Sock Sense (a player flag, needs Smarts), the aimed loose Sock shows the readout the Hands would show once
  it is picked, "Pair" when it would fuse with a held mate (`reference/it-socks/game/player/rig_aim.gd:275-295`).
- A16 The flags are on in the zoo; a station toggles each, so all three states can be tried. M4 wires them to buying.

## Design (draft)
- A `Hud` scene part of `player.tscn` with a `Theme` (core/18): `PromptRow`, `AimedRow`, `HintRow` scenes, each built from
  a `Prompt` Resource (keys, icon, words). Aim and Hands state pick the prompts through one `Prompts` static.
- The aimed Size uses core/18's theme, one `SizeBox` panel style (shared with core/16's boxed held Size).
- Openables get their words from the `Openable` Part (a `noun` export and its state), not from the player.
- Model: Sonnet. The first still (aiming at a Sock, a drawer, the Door; the corner with a Sock held) stops for the
  designer's go.

## Acceptance
- One test per behaviour line; the real-path case: in the zoo the player aims at a lying Sock, a drawer and the Door,
  and the rows and the crosshair colour are read from the HUD.
- A still in `builds/review-core-15/`, stopped at the first still for the designer's go.

## Answers
- The Sock prompt as the old by upgrade, all three built, flags on in the zoo (Q2360, 2026-11-21).
- All the old corner hints (Q2361); the old keycap art ported (Q2362); the old places and sizes (Q2363); an
  openable's old key (Q2364); the Throw hint always shown, never gated (Q2365) (2026-11-21).
- Q2279 (screen text ported in a polish pass), Q2296 (into M0.5), Q2300 (the old crosshair, no Coins or Pairs counter,
  no ESC menu), Q2331 (default font, no Patrick Hand), Q2298 (drawers outlined; core/11), Q2339 (moving Sock aimable).
- Q2387 (2026-11-21): the designer's go on the first still (prompts, hints and readouts beside the old game's).
- Q2388 (2026-11-21): openables use the old wording: a drawer and a cupboard show the thing's own name ("[E] Simple
  Cabinet Drawer", "[E] Cupboard A Drawer"), the Door keeps "Open the Door" / "Shut the Door".

## Open follow-ups
- [later] For the designer: the old held readout also followed the held Sock's cloth sway (`held_view.gd:797-815`
  `info_sway()`). Built: it follows the held place and the zoom, not the sway. core/16 P03 lists the sway; it is left
  to core/16 unless the designer says otherwise.
- [later] "Sprint" [Shift] (`prompts.gd:105`) is not in the corner: the port has no sprint yet (M4, Upgrades).
- [later] The zoo switches' words ("Sock Smarts: on" / "off", the station sign) are placeholders of a zoo tool.
- [later] The refusal message is now at 70 %, 28 pt, in the old red text with the ink outline (it was a red tint over
  the whole label); its wobble stays with core/16 P01.

## Built log

- 2026-11-21 (stopped at the first still, designer's go awaited). Changed: a `Hud` on player.tscn's Hud layer (rows at
  58/63/70 %, 32/28/24 pt; hints bottom right 24 px in, 22 apart; the held readout beside the held item, following the
  zoom); `Prompt` and `Prompts` (the crosshair's prompt and the corner's hints, keycaps from `UiIcons.keys_for_action`,
  pad glyphs after a pad press); `Openable.noun` (Drawer, Door, Cupboard set in their entity scenes); `SizeBox`,
  `SizeLetter`, `PromptLabel`, `RowLabel`, `HintLabel` in the theme; `PlayerUpgrades` (Sock Smarts, Sock Sense; on in
  the zoo via `zoo_upgrades.tres`); an `UpgradeSwitch` entity; the zoo station `screen.tscn` at (-6, 0, 4); the
  `screen` shot action and set. look_test's two HUD paths follow the Message's new place. Files: game/ui/hud.gd,
  game/ui/hud_tuning.gd, game/ui/hud_tuning.tres, game/ui/prompt.gd, game/ui/prompts.gd, game/player/player.gd,
  game/player/player.tscn, game/player/player_upgrades.gd, game/player/zoo_upgrades.tres, game/look/crosshair.gd,
  game/look/theme.tres, game/parts/openable.gd, game/entities/{door,drawer,cupboard}/*.tscn,
  game/entities/upgrade_switch/*, game/zoo/stations/screen.tscn, game/zoo/zoo.tscn, tests/aim_screen_test.gd,
  tests/look_test.gd, tools/shot_hooks.gd, tools/shots/sets/screen.txt (and the .uid files). Still:
  builds/review-core-15/screen-old-beside-new.png (old left, port right) and the five screen-*.png. Verified: see the
  commit's suite line.

- 2026-11-21 (after Q2387, Q2388). Changed: main merged in (core/25's sounds on Openable and the entity scenes kept);
  openable prompts by the old names: `Openable.title` (empty: the name of its thing, capitalised, as the old room.gd
  named it from the layout), the Door keeps `noun` "Door"; a Cabinet's drawer reads "<Cabinet name> drawer" with the
  Collection's icon, the Cabinet names ported from the old data/designs.json into `designs.tres` (`cabinet_names`,
  `DesignCatalogue.cabinet_name()`). A03's case and the real path read the new words. Files: game/parts/openable.gd,
  game/ui/prompts.gd, game/sock/design_catalogue.gd, game/sock/designs.tres, game/entities/{drawer,cupboard}/*.tscn,
  tests/aim_screen_test.gd, this ticket. Verified: see the commit's suite line.
- Merged: c250768e (2026-11-21, branch core/15-aiming-and-screen)
