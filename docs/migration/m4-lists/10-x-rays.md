> Draft behaviour list for batch C's X-rays (core/148), written from the reference on 2026-11-26; for the designer to
> approve. No proposal is built on it yet: the design ticket follows the designer's look (index: `batch-c.md`).

# Batch C piece: the Sock X-ray and the Cabinet X-ray

Draft behaviour list (catalogue B37 X-rays: the Sock X-ray's Show pair on key 1, the Cabinet X-ray's Show drawer on
key 2; their eight Personal Upgrades). Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they
start with `port:`. Short forms: XR = `game/campaign/xray.gd`, XV = `game/campaign/xray_view.gd`, XS =
`game/campaign/xray_screen.gd`, CX = `game/campaign/cabinet_xray.gd`, CXV = `game/campaign/cabinet_xray_view.gd`,
AI = `game/ui/ability_icon.gd`, HUD = `game/ui/hud.gd`, HA = `game/ui/hint_arrows.gd`, RIG = `game/player/rig.gd`, CT
= `game/core/controls.gd`, G = `game/core/game.gd`, SB = `game/audio/sound_bank.gd`, UM =
`game/campaign/upgrade_menu.gd`, UJ:<line> = `data/upgrades.json`, T:<name> = `data/tuning/<name>.json` (every
number there is a placeholder in the old game too), DH = `docs/migration/digests/digest-house.md` section 14.

Marks: "(co-op)" a line that needs co-op (who sees what, the Host's answer); "(sound)" a sound; "(rumble)" a pad
rumble (the X-rays have none); "(Secrets, later, Q2682)": none hang on the X-rays. Not ported: the Dirty Socks'
Laundry bin glow (the Dirty Socks were switched off before v0.1.1: CX:45-53, Q1075); the F1 menu's debug X-ray
(Q2599); the flat's Size and Collection X-rays, removed in the old game already (Q536).

## Behaviour list

### Owning and using
- When a player has bought the X-ray Upgrade, then they own the Sock X-ray's ability, Show pair, used with key 1 (pad:
  a D-pad button); the Cabinet X-ray Upgrade gives Show drawer on key 2. Each is the player's own: own Upgrade, own
  cooldown. (ref: XR:1-6, XR:14-16; CX:1-4; CT:28; `project.godot` `xray_show`, `cabinet_xray_show`; Q539, Q601-Q604)
  (co-op)
- When the key is pressed (not held, not an echo) and the ability is usable, then it turns on for `duration` 10 s,
  the player reads "Sock X-ray on" / "Cabinet X-ray on", and "xray_on" plays for them; when the show ends, "xray_off"
  plays and the cooldown starts (Sock X-ray `cooldown` 50 s, Cabinet X-ray 30 s). (ref: XR:148-176; XV:100-112;
  CX:26-31; G:25-26; SB:79-80; T:xray, T:cabinet_xray; Q536, Q540, Q1989) (sound)
- When the key is pressed while the Upgrade is not bought, then the player reads "X-ray not bought" / "Cabinet X-ray not
  bought". (ref: XR:150-153)
- When the key is pressed with nothing to show (empty Hands, an item that does not fit, no mate anywhere, no Cabinet
  for it), on or cooling down, then nothing happens and no cooldown is spent. (ref: XR:87-90, XR:154-155; Q2010)
- When the World is loaded, then both X-rays start ready: neither is saved. (ref: XR:4)
- When the X-ray runs, then each player's own machine runs its clock and draws it; nobody else sees another player's
  X-ray glow, screen or icon; the Host decides nothing (the glows only show what each machine already knows of the
  Mess and the Teammates' Hands). (ref: XR:5; XV:1-5; CXV:8; HA:1-5) (co-op)

### Show pair (the Sock X-ray)
- When Show pair is on, then every Mess Sock of the active held loose Sock's Design glows through walls, Heaps and
  furniture, pulsing; only the active item's mate shows; cycling the Hands moves the glow. (ref: XV:1-5, XV:119-142;
  XR:120-131; Q540)
- When a Teammate holds a loose mate of the active Sock, then it glows in their Hands the same way, drawn over the held
  Sock and following its cloth. (ref: XV:3-4, XV:20-25, XV:144-158, XV:211-218; Q252) (co-op)
- When the active item is a Pair or a token (not a loose Sock), then Show pair shows nothing. (ref: XR:128-131)
- When the player owns All-Hands X-ray, then the mates of every loose Sock in the Hands glow, each Design once. (ref:
  XR:133-146; UJ:204; Q1345)

### Show drawer (the Cabinet X-ray)
- When Show drawer is on, then the whole Cabinet that takes the active held item (a loose Sock or a Pair) shows in
  amber through walls and furniture: its real silhouette outlined with the game's one outline, pulsing like the Sock
  X-ray's; no separate Drawer mark; no box glow (`box_glow` false). (ref: CXV:1-8, CXV:60-86, CXV:126-134; CX:39-64;
  T:cabinet_xray box_glow; Q1964, Q1971, Q2040)
- When the Cabinet grows new Rows while it shows, then the outline follows its new size. (ref: CXV:72-74)
- When nothing is active in the Hands, then nothing shows; cycling the Hands moves it. (ref: CXV:7-8)
- When the player owns All-Hands Cabinet X-ray, then the Cabinet of every Sock and Pair held shows, each once. (ref:
  CX:62-64; CXV:113-134; UJ:294; Q1345)

### How they look
- When an X-ray glows, then the Sock X-ray is cyan (`#33d6ff`) and the Cabinet X-ray amber (`#ffa826`); both pulse at
  1.5 Hz; the outline is the interaction highlight's own at 1.5 times its width, at each peak 0.6 wider and 0.4
  brighter, at each trough 0.45 fainter. (ref: XV:46-76; T:xray held_colour, held_pulse_hz, outline_*;
  T:cabinet_xray colour; Q1964, Q1965, Q1968, Q2015; port: the one outline, `game/outline/outline.gd`)
- When an X-ray is on, then the whole screen takes a light tint (0.06) and an edge vignette (0.45 from 0.45 out) in its
  colour, fading out over the show's last `screen_fade` 3 s; with both on the two blend; it lies under the rest of the
  HUD. (ref: XS:1-4, XS:31-53; XR:111-118; T:xray screen_*; Q1966)
- When a glowing target is off screen (or behind the camera), then a small arrow at the screen's edge points toward
  it in the glow's colour, direction only, hidden once it is on screen; only its user sees it. (ref: HA:1-10; XV:167-179;
  Q1513-Q1519; port: `game/ui/hint_arrows.gd`, the pings' arrows)

### The ability icons (HUD)
- When an X-ray is owned, then its icon sits at the bottom left (24 px in, 24 px up; the Cabinet X-ray right of the
  Sock X-ray, 28 px apart): the Upgrade's picture on a round cream keycap (84 px) with the ink outline and shaded lip
  of the game's keycaps, its key's keycap ("1", "2", 36 px) under it; before the Upgrade is bought it is hidden. (ref:
  AI:1-6, AI:20-42; HUD:50-55, HUD:148-150, HUD:544-551; Q543, Q1969, Q1970, Q1987, Q2014)
- When pressing would do nothing (nothing fitting held, nothing to show), then the icon is greyed: a grey keycap, the
  picture faded, the whole icon see-through (0.72). (ref: AI:6-8, AI:27-29; XR:93-103; Q1967)
- When it cools down, then it is greyed with a dark sweep over what is left of the cooldown, shrinking clockwise from
  the top. (ref: AI:8-9; XR:177-180)
- When it is on, then a pulsing halo in its colour rings a keycap rimmed in it, with a ring that empties as the show
  runs out; the keycap is pressed down (its face sunk onto a shrunk lip, a shade darker, over 0.08 s) and springs back
  up when the show ends. (ref: AI:9-12, AI:37-42; Q2016)
- When a cooldown ends and it is ready again, then it pulses once (0.6 s, swelling 14 %) and a soft "xray_ready" plays
  (borrowing the Sole Mates match cue's pool); picking up a Sock only lights it, with no pulse or sound; a cooldown
  ending while nothing fitting is held gives no pulse. (ref: AI:12-18, AI:31-32; RIG:263; SB:81; Q1967, Q1988, Q2012)
  (sound)

### The Upgrades (batch B shows them "Coming soon", Q2669)
All Personal, bought with Coins (prices placeholders); each X-ray's three others need it:
- `xray` (150, cell [2,0]): "X-ray: Show pair (key 1)": "Show pair (key 1): the held Sock's mate glows through walls."
  (ref: UJ:185; UM:18-20; port: core/129, "Coming soon" until this piece)
- `all_hands_xray` (250, needs X-ray, cell [2,1]): "X-ray shows the mates of every loose Sock in your Hands." (ref:
  UJ:204; port: core/129)
- `xray_recharge` (2 levels, 100/160, cell [2,2]): "A shorter X-ray cooldown": 20 % off the 50 s a level; the card
  shows "%.0fs". (ref: UJ:225; XR:69-72; T:xray recharge_drop_pct; port: core/129)
- `xray_linger` (2 levels, 100/160, cell [2,3]): "The X-ray glows longer": +5 s on the 10 s a level. (ref: UJ:250;
  XR:64-67; T:xray linger_per_level; Q1346; port: core/129)
- `cabinet_xray` (200, cell [3,0]): "Cabinet X-ray: Show drawer (key 2)": "Show drawer (key 2): the right Cabinet
  drawer glows through walls." (the tooltip still says drawer; the whole Cabinet shows since Q1964). (ref: UJ:275;
  UM:18-20; port: core/129)
- `all_hands_cabinet_xray` (300, needs Cabinet X-ray, cell [3,1]): "Cabinet X-ray shows the Cabinet of every Sock you
  hold." (ref: UJ:294; port: core/129)
- `cabinet_xray_recharge` (2 levels, 100/160, cell [3,2]): "A shorter Cabinet X-ray cooldown": 20 % off the 30 s a
  level. (ref: UJ:315; T:cabinet_xray; port: core/129)
- `cabinet_xray_linger` (2 levels, 100/160, cell [3,3]): "The Cabinet X-ray glows longer": +5 s a level. (ref:
  UJ:340; T:cabinet_xray; port: core/129)

### Words
- When the X-rays' wording is shown, then it is the old: "Show pair", "Show drawer", "Sock X-ray on", "Cabinet X-ray
  on", "%s not bought", the key caps "1" and "2", and the eight Upgrades' names and tooltips from UJ. (ref: XR:14-16,
  XR:50-53, XR:150-153; CX:10-31)

## What was weak in the old X-rays
- The ability's clock ran in the view's `_process` (XR:5): a frame-rate-bound clock, unsaved, on each machine.
- The Cabinet X-ray was a subclass of the X-ray (CX extends XR) with its tuning section switched by name.
- Each glow and outline was built in code (XV:46-76, CXV:60-86); the icon drew its keycap, sweep and halo by hand
  (AI, 177 lines); the screen tint was its own Control.
- The "Show drawer" name and the Cabinet X-ray's tooltip still say "drawer" though the whole Cabinet shows (Q1964).
- The Dirty Socks' bin rule stayed in code after the Dirty Socks were switched off (CX:45-53).
- `xray_ready` never got its own sound (it borrows the match cue's pool).

## Open questions for the designer
1. The Cabinet X-ray's ability is called "Show drawer" and its tooltip says "the right Cabinet drawer glows", but the
   whole Cabinet shows (Q1964). (a) Keep the old words; (b) rename to "Show Cabinet" and fix the tooltip.
2. The ready-again sound "xray_ready" borrows the Sole Mates match cue's pool (never picked). (a) Keep the borrowed
   sound, as the old; (b) pick its own sound.
3. A cooldown that ends while nothing fitting is held gives no pulse or sound (the icon just lights up later, when a
   Sock is picked up). (a) Keep, as the old; (b) pulse and sound when the cooldown ends, whatever is held.
4. Only the user of an X-ray sees its glow, screen tint and arrows; Teammates see nothing. (a) Keep, as the old; (b)
   Teammates see something (which?).
5. The X-rays' timing numbers (10 s on, 50 s and 30 s cooldowns, Recharge 20 %, Lingering +5 s) and prices are the
   old placeholders. (a) Keep them as placeholders, as the old; (b) set them now (which?).
6. The outline's width and pulse were "tune by eye in the zoo" placeholders, and the outline on a Teammate's held Sock
   was never shot. (a) Keep the old numbers and judge it at the first still; (b) tune them now.
