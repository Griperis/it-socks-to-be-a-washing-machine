---
type: ticket
status: done
kind: bug
area: core
feature: lobby
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: opus", "designer 2026-11-25, playing the Windows debug build from main d2f9e45 (builds/review-windows-1125/)"]
terms: [Lobby]
---

# The Lobby shows no players on their pedestals in the exported build

The designer: "now I don't see players on their pedestals in the build." They played the Windows debug export
(`builds/review-windows-1125/`, presets in `export_presets.cfg`, made 2026-11-25; its exclude filter drops `kit/*,
tests/*, docs/*, tools/*, game/zoo/*, builds/*, extras/*, reference/*, assets_src/*`).

What the lead saw: in the editor project, the Lobby still `tools/shot_lobby.tscn` (`four`) shows four figures on
their pedestals (`docs/screens/shots/lobby-now.png`). That still sets the Roster and LobbyState directly, so it is
not the real path. Since the designer last saw the figures, core/109 made the pedestals scene nodes
(`lobby_stage.tscn`) and core/111 moved Lobby looks into nodes and the Theme.

## What to do
1. Reproduce first, on the real path: title, Host, Lobby.
   - In the editor project (`kit/tools/shot.sh` with clicks, or a suite case through the title's own wiring).
   - In an exported build: `kit/tools/export.sh --preset=Linux --out=<scratch>`, then run it under `xvfb-run`.
     Drive it to the Lobby with xdotool or a `--` argument the game already reads (`game/debug/game_cli.gd`), and
     take a frame with `--write-movie` or the game's own screenshot.
   - Say which one shows the bug: export only, real path only, or both.
2. Find the cause and fix it. Candidates:
   - something the figures need that the export leaves out (a filtered folder, a non-resource file, an
     editor-only path, `OS.has_feature`);
   - the pedestal and figure placement after core/109;
   - the place and Ready wiring after core/111;
   - the local player's place in a real one-player Roster.
3. If the export filter is the cause, fix the filter in `export_presets.cfg` and name the file it was dropping.

## Acceptance
- A real-path case: through the title's Host key into the Lobby, the local player's figure stands on its pedestal
  (its Looks under the place, visible, in the player's colour). A second case with a Guest joined.
- If the cause was export-only, a check that catches it again (for example a test that every resource the main
  scenes load is outside the export's exclude filter).
- Stills of the Lobby from the exported Linux build before and after the fix, in `builds/review-core-113/`.
- The full suite passes.

## Open follow-ups
- [later] With the Host's World drawer open (it opens that way), the drawer covers the fourth pedestal at every window
  size (stills in `builds/review-core-113/`, editor and build alike). Is that wanted, or should the row make room for it?

## Built log

### 2026-11-25
- Changed: Reproduced on the real path (title, then Host, then Lobby) in the exported Linux build at 1920x1080, 1280x720,
  2560x1440 and 1600x900 (resized after start): no pedestals, no figures, and the name rows piled in the top-left corner.
  The editor project was fine. Cause, measured: `lobby_stage.tscn`'s root (the Stage SubViewportContainer) stored its anchors
  but no `layout_mode`, and neither did its instance in `lobby.tscn`. The export laid it out at size 0, so its 3D view
  was 2x2 and `box_of()` projected every place to 0,0. Either line alone fixes the build; both are now there, as the editor
  writes them. `vignette`, `focus_glow` and `stage_bar` had the same root fault and now store `layout_mode = 3`.
  The export filter was not the cause. The stage camera no longer uses physics interpolation, which ends the first frame's
  `p.d == 0` errors from `box_of()`.
- Files: game/lobby/lobby_stage.tscn, game/lobby/lobby.tscn, game/knockdown/vignette.tscn, game/ui/focus_glow.tscn,
  game/ui/stage_bar.tscn, tests/lobby_test.gd (k16 title Host at four window sizes, k17 Guest joined, k18 the layout_mode check)
- Verified: `kit/tools/run.sh --touched` (90 of 96 suites): PASS 22929 checks, 722 cases; exported Linux build before and after the fix, stills and a line-up in `builds/review-core-113/`
