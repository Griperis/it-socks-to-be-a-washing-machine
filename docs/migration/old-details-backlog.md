# Old details not yet ported

Details of the old game that the merged pieces do not have yet, each with the designer's answer on when it comes
(Q2277: every small detail is explored and only the designer drops one). Found by comparing core/01, 02, 03 and 08
with the reference on 2026-11-20. Each line names its old source; numbers are in the reference's `data/tuning/`.
A ticket that builds a line moves it out of here.

## M1.1 Sound (Q2278): plug-and-play, the old clips and numbers
- Footsteps every 1.4 m, wood or tile by floor (`game/player/player.gd:423-433`, `audio.json` step_distance).
- Landing after a fall of 3 m/s or more (`player.gd:430`, `audio.json` land_speed).
- Pick, drop and wheel switch: "pick", "drop", "cycle" (`core/game.gd:1458`, `hands/hands_rules.gd:267`, `game.gd:23`).
- Refusal: "refuse" (`core/game.gd:1448`).
- Pairing: "pair" on fusing, "pop" when the ball pops (`core/game.gd:1462`, `player/rig.gd:259`).
- Throw: "throw_charge" at charge start, "throw" swish on release (`hands/thrower.gd:116`, `hands/hands_rules.gd:374`).
- Drawer open and shut (`drawer_open__a/b`, `drawer_close__a/b`) and the Door's (`game/campaign/cabinet_drawer.gd:56`,
  `game/house/openable.gd:39`).
- Bounce: a ball landing or a thrown item hitting something (`world/flights.gd:39`).
- Pad rumble on throw (0.3 weak / 0.7 strong, 0.25 s), pair and knock (`player/pad_rumble.gd:19-26`, `pad.json`).

## Polish pass (Q2279-Q2281)
- The crosshair prompt "Pick up [LMB]" and the corner key hints "Drop", "Drop / hold: Throw" (`ui/prompts.gd`).
- The aimed Sock's Size letter at the crosshair with the LMB icon (`ui/hud.gd:237-243`, `player/rig_aim.gd:107`).
- A "Paired!" message on fusing (`core/game.gd:1461`).
- The held Size letter boxed beside the active Sock, following it, the zoom and the sway (`ui/hud.gd:452-500`,
  `hands/held_view.gd:785-815`).
- The aimed outline: warm white, three soft shells fading outward, constant width on screen (`ui/highlight.gd:20-26`,
  `outline.gdshader`).
- The refusal wobble (0.45 s, 0.07 rad, 5 Hz) and 2 s on screen (`ui/hud.gd:22-24, 646-660`).
- A sock ball landing squashes, hops 4 cm and rolls 12 cm (`world/sock_ball.gd:263-345`, `ball.json`).
- The pairing fold curls the Socks along their cloth bones, curl 1.3 (`hands/paired_moment.gd`, `paired.json`);
  needs core/09's cloth.
- The drop flick and a Throw's catch-up from the hand eased in and out, not linear (`release.json` flick,
  catch_up; `hands/thrown_item.gd:180-250`).
- The cloth bends only on a change of speed (start, stop, jump, turn), hanging still at a steady walk: the old
  "gravity minus acceleration" (`world/sock_actor.gd`); core/09 uses the spring-bone node's bend with speed (Q2286).
- A cloth Sock near the ground straightens its whole bend so no part dips below (`world/sock_actor.gd` `_room`, up to
  8 rings of 12 mesh points); core/09 uses the node's per-joint plane, which may crumple (Q2287).

## Decided elsewhere (for the record)
- The Cabinet's "+N" Coins pop and flight to the bank, a filled drawer paying the team's Drawers, and new Rows
  dropping in with a thunk and dust: M4 (core/04 C06; `game/player/rig.gd:653, 661`, `game/campaign/cabinet.gd:125-209`).
- Pad stick curve and speed-up: a later ticket (Q2235). Held count, Collection and Design name: Sock Smarts, M4
  (Q2243). The Sock's knit look and the ball's print: M1 (Q2249, Q2263). Co-op match glow and a teammate's burst: M0.6.
