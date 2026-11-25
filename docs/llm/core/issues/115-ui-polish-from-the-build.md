---
type: ticket
status: done
kind: bug
area: core
feature: ui
priority: now
created: 2026-11-25
done: 2026-11-25
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
- [later] The Esc menu's first focus (`_first_key`) is still the first exit key, not Options; no light shows for mouse and keyboard, so it is unseen. EscButton's font_focus_color is orange too (the Esc-style text keys); not asked.
- [later] The close key was lit only when the focus was on it (the End session ask grabs it); the stills show the menu open, not the ask.

## Built log

### 2026-11-25
- **Changed:** (1) `SubtitleRow`: the words take only the width their text needs (clamped to the row), so the icon hugs the text's left edge and the pair stays centred, one line or two. The old game's subtitle had no icon (a bare Label), so there was nothing else to match. (2) ESC menu order is now Options, Back to title, End session, Leave, Quit game; the old session menu was Options, Back/End/Leave, Quit game, so this matches it (the port had put the exits first). Other dialogues already had the exits last or one key only: title Home (Solo, Multiplayer, Options, Quit), Multiplayer and Join pages, Lobby asks (one key), World drawer and its delete ask (one key), Final screen (Continue), Options (rows only). The Lobby's bottom bar keeps Back at its left (a row, not a list). (3) The Theme's `CloseButton/icon_focus_color` was the orange, so a focus grabbed by code (the End session ask) lit the key; it is now white, hover stays orange, the selection light stays PadFocus's. (4) Stage bar `Fill` is a Panel with a rounded StyleBoxFlat (radius 5); `StageBarTuning.fill_colour` was dropped (the colour lives in the scene's StyleBox).
- **Files:** game/voice/subtitle_row.gd/.tscn, game/ui/esc_menu/esc_menu.tscn, game/look/theme.tres, game/ui/stage_bar.gd/.tscn, game/ui/stage_bar_tuning.gd, tests/menus_test.gd (E04), tools/shot_ui_nodes.gd, tools/shots/sets/ui-polish.txt.
- **Stills:** builds/review-core-115/ (before/, after/, pairs-bar.png, pairs-sub.png, pairs-esc.png).
- **Verified:** see the commit.
