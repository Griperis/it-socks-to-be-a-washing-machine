---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: ui
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25, from the Windows build (Q2664)"]
terms: []
---

# UI polish from the designer's build: subtitle icon, menu button order, the Esc key, the Stage bar fill

Four things the designer saw in the Windows debug build:

1. **The subtitle icon floats in empty space.** It should sit right at the left of the spoken text. Today
   `game/voice/subtitle_row.tscn` is a centred HBoxContainer with the Icon and a Label that centres its own text
   (`horizontal_alignment = 1`). When the label is wider than its text, the icon ends up far from the words. The
   icon hugs the text's left edge on one line and on two lines, and the pair stays centred on screen. Check the
   old game's subtitle (`reference/it-socks/game/audio/voice_player.gd:248-274` and its scene) and match it.
2. **Quit, Leave and the like go at the bottom of a dialogue, not the top.** In `game/ui/esc_menu/esc_menu.tscn` the
   menu lists BackToTitle, QuitGame, EndSession and Leave first, and Options last. Ending or leaving actions go
   last: Options, then the leave and quit actions, with Quit at the very bottom. Apply the same rule to every
   dialogue and page that has such a key: the title's pages, the Lobby's asks, the World drawer's asks, the Final
   screen, Options. List each one you changed. Check the old game's order (`reference/it-socks/game/ui/`) and say
   where it differed.
3. **The Esc close key lights orange.** The corner close key (`game/ui/close_button.tscn`, the `Back` in the Esc
   menu) shows the orange lit or hover look when a menu opens or Esc is pressed. It should look like an unpressed
   key unless the mouse is over it or a pad or Tab selection is on it (Q2654).
4. **The Stage bar's fill is a rectangle inside the rounded track.** `game/ui/stage_bar.tscn` `Row/Column/Track/Fill`
   is a ColorRect. The fill takes the track's rounded ends (a Panel with a rounded StyleBox on the Theme, or the
   track clipping its children), at every fill amount, the nearly empty one included.

## Acceptance
- Each of the four is fixed. Visuals are authored in nodes and the Theme (Q2658).
- Stills before and after of the subtitle (one line and two lines, a long and a short line), the Esc menu, one other
  dialogue, the close key just after Esc, and the Stage bar at 5%, 50% and 100%, in `builds/review-core-115/`.
  Look work stops at the stills: `ready-for-human`.
- A real-path case for the button order (the Esc menu's last key is Quit) and for the close key (not lit after an
  Esc press). The menus and Stage bar suites pass.

## Open follow-ups

## Built log
