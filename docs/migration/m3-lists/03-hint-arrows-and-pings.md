> Behaviour list for core/43 (hint arrows and pings), written from the reference on 2026-11-23, for the designer to approve. Step 1 of the `migration-port` skill: nothing is built. The open choices are `[blocking]` Open follow-ups in `docs/llm/core/issues/43-hint-arrows-and-pings.md`.

# M3 piece 3: Hint arrows and pings (behaviour list, draft)

Words follow `GLOSSARY.md`. Paths are in `reference/it-socks/` (tag v0.1.1) unless they start with `game/` or `docs/` of the port (a line says "port" then). "Old" is the game at tag v0.1.1. A line is one thing the designer can keep or drop. Nothing is left out as minor. Abbreviations: **PG** `game/ui/pings.gd`, **PW** `game/ui/ping_wheel.gd`, **HA** `game/ui/hint_arrows.gd`, **RC** `game/player/rig_click.gd`, **HR** `game/house/house_rules.gd`, **G** `game/core/game.gd`, **HL** `game/ui/highlight.gd`, **PT** `data/tuning/ping.json` (placeholders: seconds 4, range 30, hold 0.25, lift 0.3, head_lift 0.45, size 0.12, ring_grow 0.25, min_ring 0.04, head_side 0.35, bubble_seconds 3), **HT** `data/tuning/hint_arrows.json` (size 34 px, margin 56 px, outline 3 px, max_arrows 4).

What it is: **pings** are the co-op marks a player places for their Teammates with the middle mouse (multiplayer/08 and /19, Q300-Q303, Q362-Q363, Q551-Q552): a tap highlights what the crosshair points at, a hold opens a wheel of five emojis. The **hint arrow** is a small arrow at the screen edge that points to a target that is off screen (progression/76, Q1513-Q1519, Q1536-Q1538, Q1929). Pings are one source of its targets; the old game's other sources (the X-ray's Show pair glow, the Cabinet X-ray's Show drawer glow, the Sole Mates teammate with Mate Radar, the Laundry bin's drawer glow, a Teammate's held mate) belong to M4 and M5 features and plug into the same source list later. "Teammate outlines through walls" (catalogue B65) is the ping's highlight of a Teammate (lines 33, 37); the always-on Teammate marker is Mate Radar (M4, Q2463).

Scope tags: **(zoo)** can be shown in the zoo with two players today; **(needs X)** waits for another piece.

## Behaviour list

### A. Making a ping: the input

1. When the middle mouse is pressed with the mouse captured, then the Rig starts counting how long it is held; the press is read only when pinging works and the player is not frozen. (zoo) (ref: RC:196-203; player.gd:247-249; the port has no `click_middle` action yet)
2. When pinging "works", then it is when the game is a co-op session (alone or not) or a Teammate is in the flat; with no session and no Teammate the middle button does nothing and no hint shows (Q363). (zoo) (ref: rig.gd:575-579 `can_ping`; RC:196-203)
3. When the middle mouse is released within `ping.hold` (0.25 s), then it is a tap: it places a highlight ping. (zoo) (ref: RC:204-212; PT hold)
4. When the middle mouse is held for 0.25 s, then the emoji wheel opens round the crosshair, and the mouse stops turning the view; it steers the wheel's pointer instead. (zoo) (ref: RC:215-227 `hold_middle`; player.gd:23-27, 110 `steering`)
5. When the wheel is open and the middle mouse is released with a slice chosen, then that emoji is placed where the crosshair points; with the pointer still in the centre, nothing is placed (cancel). (zoo) (ref: RC:206-210; PW:1-5)
6. When a menu opens, or the player is frozen or can no longer ping (a Teammate left, the last one), then the wheel closes with nothing placed. (zoo) (ref: RC:217-222)
7. When the player is knocked down, then no ping is made until they stand. (needs coop/10, built) (ref: RC:34)
8. On a pad, R3 is the middle button (tap pings, hold opens the wheel) and the right stick steers the wheel: the pointer sits at the stick's direction on the ring's radius, the stick at rest is the centre (cancel), inside `wheel_deadzone`. (the pad prototype; Q2302 puts pad differences later) (ref: player.gd:266-285, 294-303; PW:91-95)

### B. The emoji wheel

9. When the wheel opens, then five cream keycaps stand in a ring round the crosshair, `RADIUS` 150 px from its middle: **Here** (eyes) at the top, then **Help**, **Yes**, **No**, **Nice** clockwise. Each keycap shows its icon (56 px) over its name (size 22). (zoo) (ref: PW:10-17, 27-52, 107-110; game.gd:260-263 `PING_EMOJIS`; the five `emoji_*.svg` are in the port's `assets/ui`)
10. When the wheel opens, then a soft dark disc (radius 220 px, `OUTLINE` colour at 35 %) lies behind the keycaps; a ring of 24 px radius stands in the middle (cream with an ink rim; orange while the pointer is inside it, meaning cancel). (zoo) (ref: PW:131-138)
11. When the mouse moves, then the wheel's pointer follows (the motion since opening), never further out than 150 px. (zoo) (ref: PW:80-82)
12. When the pointer is 40 px or more from the centre, then the slice it points toward is chosen: the direction is read from straight up, clockwise, in fifths. Nearer than 40 px nothing is chosen. (zoo) (ref: PW:98-104; DEAD 40)
13. When a slice is chosen, then its keycap turns orange and grows to 1.18 times, and a line (ink rim, orange core) runs from the centre ring toward it, ending 52 px short of the keycap's middle. (zoo) (ref: PW:119-143; CHOSEN_SCALE)
14. When the pointer reaches a new slice, then the menus' hover tick plays; when a slice is chosen at release, then the menus' click plays. A cancel is silent. (zoo) (ref: PW:63-72, 86-87 `UiSounds`; Q336)
15. When the wheel opens, then the player's view does not turn (the mouse steers the pointer); whether the body can still walk was not checked in the old code. (zoo) (ref: player.gd:110 steering; RC:226-227)

### C. What a ping points at

16. When a ping is made, then the crosshair line is cast to `ping.range` (30 m) plus the pick slack; the nearest of these wins in this order: a Teammate's body, a Mess Sock, a floor Pair (the nearer of Sock and Pair), then the first Station or surface the line meets within range. A Teammate counts only if nearer than the Sock or Pair. (zoo) (ref: RC:239-276)
17. When the line meets nothing in range (open space), then nothing is placed, and nothing shows or sounds: no refusal, no cue. (zoo) (ref: RC:277-278 returns false; weak, see below)
18. When the aimed Teammate is the pinger themself, then it is ignored (a body never pings itself). (zoo) (ref: RC:264-265; HR:271-273)
19. When the target is a Station (the Upgrade station, a Cabinet's Drawer, an Openable), then it is named by its path under the Room, so every machine finds it; other furniture (the washer, the bed) gets the ring on the surface where the line hit it, flat against the surface by its normal. (zoo; the port's Cabinets and Drawers) (ref: RC:272-276; multiplayer/19 "A Station is identified across machines by its path under the Room")
20. When a Mess Sock or floor Pair has since gone (picked up) when the Host decides, then the ping stands at its spot instead. (zoo) (ref: HR:258-285)
21. When the emoji is not one of the five, then the ping is a highlight. (zoo) (ref: HR:277-280)

### D. The highlight ping (a tap, Q303)

22. When a highlight lands on a Mess Sock, a floor Pair, a Station or a Teammate, then that thing is outlined in the **pinger's colour**, through walls and furniture, 2.2 times as wide as the crosshair's outline, for `ping.seconds` (4 s). (zoo) (ref: PG:4-6, 31-32, 191-215, 229-232; HL:1-5, 40-60)
23. When the target is a Mess Sock, then a live copy of it (a mesh with the Sock's look, scaled 1.01 and raised 2 mm) is outlined and follows the Sock while it moves, because the Mess draws its Socks in batches. (zoo; the port's Mess draws in bulk too) (ref: PG:275-287; HL)
24. When the target is a floor Pair, then its ball is outlined; when it is a Teammate, then their avatar (every visible mesh except held items); when it is a Station, then that node. (zoo) (ref: PG:268-286)
25. When the highlight is on a bare spot or a surface (or the Sock left the Mess), then a ring in the pinger's colour lies on it instead: a flat torus (inner radius 0.2 m, outer 0.32 m, squashed to 0.2 in height) with an ink rim 0.02 m wider all round, drawn through walls, lying on the surface by its normal and raised 1 cm. (zoo) (ref: PG:28-30, 289-312, 316-336)
26. When the ring is far from the camera, then it grows with the distance (distance times `ping.ring_grow` 0.25, at least 1) and never shows less than `ping.min_ring` (4 % of the screen's height) across. (zoo) (ref: PG:316-336; PT)
27. When a ping appears, then it pops in: it grows from 1 % to full over 0.15 s. (zoo) (ref: PG:16, 267-268 `POP`; `s.grow`)
28. When a ping's last second runs, then it fades out (alpha from 1 to 0 over `FADE` 1.0 s) and is then gone. (zoo) (ref: PG:15-16, 262-266; G:1256-1259)
29. When the pinged thing is a Teammate and the viewer is that Teammate, then nothing is drawn on them (they have no body on their own machine) and no ring shows. (zoo) (ref: PG:10-11, 276-277)
30. When the outline is drawn, then it uses the game's one outline shader with the pinger's colour and width, no pulse, and draws after the aim's outline, through walls. (zoo) (ref: HL:40-60 `colour`, `width`, `PRIORITY`; PG:197-205; port: `game/outline/outline_style.gd`)

### E. The emoji ping (a hold, Q302)

31. When an emoji lands, then a sticker bubble stands over the pinged thing: a speech bubble 96 px square in the pinger's colour (round part radius 36 px at 40 px from the top, a short tail to the 94th row that stands on the spot), a cream middle (74 % of the round part) with an ink rim, and the emoji's icon 60 % of the bubble in the middle. (zoo) (ref: PG:18-25, 338-415)
32. When the bubble draws, then it is a billboard of fixed screen size (`ping.size` 0.12 of the screen's height, the same at any distance), unshaded, drawn through walls (no depth test), with linear mipmap filtering. (zoo) (ref: PG:76-92, 408-424)
33. When a bubble is over a Mess Sock, then it stands 0.3 m (`ping.lift`) over its top plus 5 cm; over a floor Pair, over the ball's top; over a Teammate, over their avatar's `Head` node by `ping.head_lift` 0.45 m (over their body height if the avatar has no Head); over a Station or a spot, `lift` over the spot, a tail pointing at it. When a target is a thing, the lift is halved. (zoo) (ref: PG:254-280, 190-200, 369-376)
34. When a bubble stands over a Teammate, then on that Teammate's own machine it is not drawn (nothing on a body you do not have). (zoo) (ref: PG:276-277)
35. When the bubble's own time is up (`ping.bubble_seconds` 3 s, inside the ping's 4 s), then it fades over its last second and is gone; the highlight's outline lives the full 4 s. (zoo) (ref: PG:117-123, 271-276; PT)
36. When a wall or a piece of furniture lies between the camera and the bubble, then the bubble is hidden (a ray from the camera to the bubble that stops 0.1 m short of it, on layers World and Station, tested once per physics tick); until the first tick has asked, it is hidden. (zoo) (ref: PG:126-146, 234-248; physics/33)
37. When a ping lands, then a small copy of the emoji (70 % of the size) also stands beside the **pinger's** head (their avatar's `Head` node, `ping.head_lift` over it, moved `ping.head_side` 0.35 m to the camera's right so it stands beside the head, not over it), with the same colour and fade; it is hidden behind walls the same way. (zoo) (ref: PG:7-10, 26-27, 275-282, 305-320)
38. When the pinger is the local player, then no copy is drawn over their own head (their avatar is not drawn in first person). (zoo) (ref: PG:10-11, 278-282 needs `pinger.avatar`)
39. When a ping is a highlight, then it has no bubble and no copy over the head. (zoo) (ref: PG:197-215)

### F. One ping each, and its sound

40. When a player pings again, then their last ping goes at once (its outline, ring, bubble and copy freed) and the new one pops in: one active ping per player, any new highlight or emoji replaces the last, with no cross-fade. (zoo) (ref: PG:191-193, 217-227; G:494-499)
41. When a ping lands, then every machine hears the "ping" event in 3D at the spot: one soft bubble blip (`synth/ping_d`, 0 dB), the same for a highlight and an emoji, and for the pinger too. There is no different sound per emoji and no pad rumble. (zoo) (ref: HR:289-291; data/sounds.json "ping"; multiplayer/19 open follow-up "A different sound per emoji?", never answered)
42. When a ping's 4 s are up, then the Game's clock removes it and every machine frees its parts. Pings are not saved and not in the join snapshot: a joiner sees none that are standing. (zoo) (ref: G:1256-1259, 494-499)
43. When a Teammate pings the local player (the local player's body is the target), then nothing is drawn on the local player and no arrow points at them; the blip still plays at the spot. (zoo) (ref: PG:276-277; HR:289-291)

### G. The hint arrow

44. When a target is off screen, then a small arrow sits at the screen edge pointing toward it, behind the camera too; it hides while the target is on screen. (zoo) (ref: HA:1-5, 59-77, 167-172; progression/76 Q1513-Q1515)
45. When the arrow is placed, then the target's direction from the screen's centre (camera x and y, flipped for the screen) is followed out to a rectangle inset from the screen's edge by `hint_arrows.margin` (56 px): the arrow's tip is at that rectangle. A target straight behind the camera points down. (zoo) (ref: HA:59-77)
46. When the arrow is drawn, then it is a filled arrowhead `hint_arrows.size` 34 px long: a tip, two side points 40 % of its length to each side, and a notch in its back (30 % in), with an outline of `hint_arrows.outline` 3 px in the HUD's outline colour; its fill is the target's colour (the pinger's colour for a ping). (zoo) (ref: HA:210-225)
47. When the target has an emoji (an emoji ping), then the emoji's icon (the arrow's size square) is drawn beside the arrow, behind its notch, nearer the screen's middle. (zoo) (ref: HA:224-231)
48. When a ping's emoji bubble is over (3 s) the arrow goes with it; a highlight's arrow lasts the ping's 4 s. A ping on yourself (a Teammate pinging you) gets no arrow. (zoo) (ref: PG:154-173)
49. When a ping is still standing and its target moves, then the arrow follows what the ping follows now (its Sock, floor Pair or Teammate, else the spot). (zoo) (ref: PG:176-188)
50. When several targets are off screen, then at most `hint_arrows.max_arrows` (4) are shown: ping arrows first (priority 1 before 0), then nearest first. (zoo) (ref: HA:155-184; Q1536)
51. When an arrow would cover a part of the HUD (the counters, the Stage bar, the prompt text, the aimed Sock, the message row, the held info, the key hints, the ability icons, the banner), then it slides along the screen edge (6 px per try, either way, around the corners too, keeping its direction and 8 px clear) to the nearest spot that covers none; if the whole edge is taken it stays put. (zoo; the port's HUD parts) (ref: HA:25-31, 91-152; ui/hud.gd:742; Q1537)
52. When the HUD is hidden, then no arrow is drawn; the arrows live in the HUD, are local, and change no state; the list is asked every frame and redrawn only when it changed. (zoo) (ref: HA:186-202; rig.gd:214-215)
53. When another piece wants an arrow, then it adds a source (a function returning positions and colours, optional priority and emoji); the arrow knows no feature. (zoo) (ref: HA:7-10, 15; ui/teammate_news_installer.gd:16; core/main.gd:379)
54. When a Teammate is far or behind a wall, then there is no arrow to them unless Mate Radar and the X-ray are owned (Q2463; M4). (needs M4) (ref: ui/teammate_news_installer.gd:20-33; Q1519)
55. When the X-ray's Show pair glow or the Cabinet X-ray's Show drawer glow is on, then arrows point to its targets in the glow's colour; the Laundry bin's drawer glow and a Teammate's held mate too (Q1513, Q1538). (needs the X-rays, M4/M5) (ref: progression/76 acceptance, Answers)

### H. Key hints

56. When pinging works, then the corner key hints show "Ping" with the middle-mouse icon, after "Cycle" and "Sprint", before "Jump". The old multiplayer/19 also gave "[MMB] hold: Emoji"; the current prompt list shows only "Ping". (zoo) (ref: ui/prompts.gd:104-108; multiplayer/19 built log)

## Co-op: what the Host decides, what a Guest predicts (`docs/migration/coop-structure-for-the-port.md`)

- **The Host decides** the one thing that is shared: that a ping exists, its target (a Mess Sock or floor Pair that still exists, a Teammate who is still in the game and is not the pinger, a Station path, else the spot), its emoji (one of five, else a highlight), its normal, its end time (the Game's clock plus 4 s), and replacement of the pinger's last ping. The answer carries who and what, and a sound event at the spot. The state (one ping per player, `until`) is a Part's, not saved, not in the join snapshot.
- **A Guest predicts nothing:** the old game does not predict a ping (only a pick, a drop, a Throw, a wheel turn and the pairing machine's load are predicted); the pinger sees their own ping when the Host's answer comes back, so at 100 ms there is a delay of a round trip between tap and ring. Looks only means the outline, ring, bubble and arrow are drawn from the Host's answer.
- **What each machine draws by itself:** the outline, ring, bubble, copy over the pinger's head, arrow and the wheel; the wheel and the arrow exist only on the machine that has them (local HUD).
- **A thing's identity:** a Mess Sock is found by its Mess id, a Station by its path, a Teammate by player id, so every machine draws the same thing. In the port the Mess is one bulk Part; a ping on a Sock is a Command naming its id and the Host checks that it still exists.
- **Late join and leave:** a ping is not in the join snapshot; a pinger who leaves has their ping removed with them (the old game removes it on its own clock, within 4 s).

## Already in the port

- `game/outline/outline.gd`, `outline_style.gd`, `outline.gdshader`, `outline_mask.gdshader`, `aim.tres`: the outline as one component with a style Resource (colour, width, shells, pulse, render priority); no ping style, no through-walls use yet.
- `assets/ui/emoji_here.svg`, `emoji_help.svg`, `emoji_yes.svg`, `emoji_no.svg`, `emoji_nice.svg` and the `key_mmb` icon (`game/ui/ui_icons.gd`).
- `game/net/roster.gd`: each player's colour (Q2441); `game/parts/avatar/looks_contract.json`: the `Head` node.
- `game/ui/hud.gd`, `game/player/player.gd`: the message row and the refusal wobble; no hint-arrow Control, no keep-clear rectangles, no wheel.
- No `click_middle` input action and no pad R3 mapping; no `ping` Command, no ping Part, no `ping` sound event (checked by grep in `game/`).

## What was weak in the old game (for the designer to weigh)

- A ping into empty space does nothing and says nothing (line 17).
- A Guest's own ping waits for the Host's answer (the co-op section).
- There is one sound for every emoji and for a highlight (line 41).
- A highlight and an emoji replace each other with no transition (line 40).
- The key hint "[MMB] hold: Emoji" of multiplayer/19 is not in the current prompt list (line 56).
- The wheel is mouse-and-pad only; a keyboard-only player has no way to pick an emoji.
- The arrow shows direction only: no distance (Q1515, a decision).
- The hold time 0.25 s opens the wheel; a slow tap may open it by accident.
- The bubble copy beside the pinger's head is not shown to the pinger.

## Questions for the designer

1. **Pinging when playing alone.** Old: it works in any co-op session even with no Teammate yet, and not in a game with no session (Q363). In the port's zoo and house a solo player is always in a session. Keep the old rule, or allow it only with a Teammate present?
2. **What a ping may outline.** Old: a Sock, a floor Pair, a Teammate, an Upgrade station or Drawer or Openable; other furniture gets a ring. The port outlines every interactable (Q2292, Q2298). Ping everything that has the Outline component, or keep the old short list?
3. **A ping into empty space.** Old: nothing. Keep, or play the "refuse" sound (no text), or place a ring at the farthest point?
4. **One sound for all.** Old: one blip for a highlight and each emoji. Keep (sound is M1.1), or a per-emoji sound or pitch?
5. **How soon the pinger sees it.** Old: a Guest sees their own ping only on the Host's answer. Keep, or draw the pinger's own ring at the click as a looks-only ghost (as the Throw and the drop do, Q2221, Q2473)?
6. **The arrow's scope in this piece.** Only pings feed it today (the X-rays and Mate Radar come in M4). Build the arrow Control with the ping source and an open source list now (recommended), or build it with the X-ray piece in M4?
7. **The hold-emoji hint.** Old had "[MMB] hold: Emoji" in multiplayer/19; the current list shows only "Ping". Show both hints (an addition to the corner), or only "Ping"?
8. **Wheel on a keyboard-only player.** Old: none. Keep, or add keyboard keys 1 to 5 while the wheel is open (an addition)?
