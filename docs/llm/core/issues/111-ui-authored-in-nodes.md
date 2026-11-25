---
type: ticket
status: done
kind: refactor
area: core
feature: ui
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: [core/109]
notes: ["suggested model: sonnet", "designer 2026-11-25 (Q2658): UI should ideally always be authored in nodes"]
terms: []
---

# UI authored in nodes, not built in code

The designer: "UI should ideally be always authored in nodes." Every screen is already a scene, but these pieces are
still built in code. Each becomes a node in its scene, or a small scene instanced per row, with its look on the
Theme (a type variation) or set in the inspector:

| Where | Built in code today | Becomes |
|---|---|---|
| `game/ui/hud.gd` `_prompt_row`, `_icon`, `_label`, `_size_box`, `say_named` | the prompt row (key icons, item icon, name), the Size box, the named row | `prompt_row.tscn` (and the Size box in it), instanced per Prompt; the named row a node in `hud.tscn` |
| `game/ui/stage_bar.gd` `_set_icons` | a TextureRect per icon | an icon scene instanced per icon |
| `game/ui/final_screen/final_screen.gd` `_label`, the totals cells | Labels with ink colour and sizes 24/44 in code; a VBox per total | a `final_total_cell.tscn`; the label looks as Theme variations |
| `game/ui/final_screen/final_column.gd` `_ready` | the player's frame StyleBoxFlat | a Theme variation; only the player's colour is set at play |
| `game/lobby/who_page.gd` | a Label per name | a name row scene |
| `game/lobby/world_row.gd` | the colour swatches; the chosen/plain box StyleBoxFlat | a swatch scene; two Theme variations (chosen, plain) |
| `game/lobby/lobby_place.gd` `_circle` | the Ready circle StyleBoxFlat | two Theme variations (ready, not ready) |
| `game/ui/pad_focus.gd` the glow | a Panel and StyleBoxFlat per lit control | a `focus_glow.tscn` with its style; numbers stay in `pad_focus_tuning.tres` or move to the scene, whichever the inspector edits best |

Left as is: `game/look/keycap_style.gd` (a StyleBox class drawn by the Theme, already a resource).

Also from core/109: the Lobby pedestals' size is now in `lobby_stage.tscn`, but `LobbyTuning.pedestal_radius` and
`pedestal_height` still feed `box_of()`. Make it one source: `box_of` reads the pedestal node's mesh.

## Acceptance
- No `Label.new()`, `TextureRect.new()`, `HBoxContainer.new()`, `VBoxContainer.new()`, `PanelContainer.new()`,
  `ColorRect.new()`, `Panel.new()` or `StyleBoxFlat.new()` left in `game/` outside `game/zoo/` and
  `game/look/keycap_style.gd`; a grep in a test (or the rules check) keeps it so.
- Same look: before/after stills of the HUD prompts, the Stage bar, the Final screen, the Lobby (Who page, World rows,
  Ready circles) and a lit key, in `builds/review-core-111/`, with 0 differing pixels or the differences named.
- The suites of each screen and the full suite pass, nothing flaky.

## Open follow-ups

## Built log

### 2026-11-25
Changed: every `Label.new()`, `TextureRect.new()`, box, Panel, ColorRect and StyleBoxFlat of `game/` (outside the zoo and
`keycap_style.gd`) is a scene or a Theme variation: `prompt_row.tscn` (+ `HudBits`: `ui_icon`, `hud_label`, `size_box`),
the named row in `player.tscn`, `final_total_cell.tscn`, `FinalColumnFrame` (tinted by `self_modulate`), `who_name.tscn`,
`world_swatch.tscn`, `WorldRowChosen/Plain`, `ReadyCircle/Off`, `focus_glow.tscn`; the Stage bar's icons are `ui_icon.tscn`.
`LobbyStage.box_of` reads the pedestal mesh. New suite `tests/ui_nodes_test.gd` (grep case + Who page real path); shot set
`ui-nodes` (+ `tools/shot_ui_nodes`). Settled choices are rows in batch-a-review.md.
Files: game/ui/*, game/lobby/*, game/look/theme.tres, game/player/player.tscn, tests/ui_nodes_test.gd, tools/.
Verified: stills in builds/review-core-111/ui-nodes-before-after.png: HUD, Stage bar, lit key, Lobby (four, drawer, Who,
focus) 0 differing pixels; the Final screen differs only in its 3D stages, which differ between two runs of the same code
too (random, not the UI); `PASS 22784 checks, 714 cases`.
