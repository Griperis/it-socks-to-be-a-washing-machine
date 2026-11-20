# Since the research: the old game at its freeze

Most of the copied research in this folder was written on 2026-11-19 **before** the last merges of that day. The old
game was then frozen and tagged **`v0.1`** (commit `10db4d04`), and tagged again as **`v0.1.1`** after one
tooling-only addition (the capture tour) and the last documents. The reference clone is `v0.1.1`. The clone is the
truth; where the research and the clone disagree, the clone wins. This file lists what the research does not know.
Written the same night, after the freeze, and current: `coop-structure-for-the-port.md`, `hl-multiplayer-report.md`,
`ids-roster-guards.md`, `godot-demo-projects.md`.

## Merged after the research was written
| What | Where in the reference | The research says |
|---|---|---|
| **Simple and Patterns Collections** (progression/97): "Basic" became "Simple" (single colour, no patches), "Casual" became "Patterns"; per-Design trim patches (all, top and toe, heel and toe, none); the one big motif sits on the calf, not across the heel | `data/designs.json`, `game/world/sock_look.gd`, `game/world/sock_pattern.gdshaderinc`, `assets/cabinet/simple.glb`, `patterns.glb` | still "Basic" and "Casual" in places; Design counts may differ |
| **Backpack vacuum** (tools/27): carried or worn, no filter, its own tank | `game/devices/backpack_vacuums.gd`, `backpack_vacuum_view.gd`, `assets/vacuum_devices/backpack_vacuum.glb`, `data/tuning/backpack.json` | listed as planned in `feature-catalogue.md` |
| **Splitter** (tools/28): a carriable sorter, two filtered outputs, a third by Upgrade; stands on the pairing machine's old spot | `game/devices/splitters.gd`, `splitter_view.gd`, `assets/vacuum_devices/splitter.glb`, `data/tuning/splitter.json` | listed as planned |
| **Smart vacuum rework** (tools/25, tools/29): pour and spit, the filter behind the House Upgrade "Filter nozzle", the clip-on display pod on the nozzle from the start (capacity only without the Upgrade) | `game/devices/sock_vacuums.gd`, `sock_vacuum_view.gd`, `sock_filter_display.gd`, `assets/vacuum_devices/nozzle_display.glb` | the old vacuum |
| **Pairing machine off** (tools/26) | `PairingMachines.enabled()` | on |
| **Capture tour** (maintenance/151): `ItSocks.exe -- --tour=<views file> --tour-out=<folder>` walks a list of views in one run and saves a still of each; F7 in a debug build adds the current view to the file | `game/debug/tour/`, `game/debug/tour_socks.gd`, `tools/tour.sh`, `tests/tour_test.gd` | not known |
| **Device models** (tools/30): three new models, built by `assets/vacuum_devices/make_*.py` and `build.sh` | `assets/vacuum_devices/` (art doc `vacuum_devices.md`) | not in `assets-inventory.md`: add them to the M1 port list |

House Upgrades at the freeze: 21 Upgrades, 36 levels, 49 Drawers under the drum (`tests/upgrades_test.gd`). The prices of
the Filter nozzle (2) and the Splitter's four (11) are the designer's placeholders.

## Placeholders the designer has not settled (do not port them as decisions)
- Splitter: which way it faces in the bathroom, its Upgrade prices against the 33 Drawers a run pays, its wording, E
  while it is carried, its height in the layout (placed at y = 2.9 from the "pairing" entry; unchecked).
- Backpack: no sounds or streaks of its own; the gauge is the dial; crouching with it unchecked.
- Vacuum numbers: `spit_interval` 0.1, `spit_tap` 0.25, `pour_interval` 0.15, `pour_tilt_deg` 70.
- The display pod's screen layout, its "n / cap" count line and the red glow as the alert (the agent's additions).
- Which patches each Design has (the agent's proposal, to be corrected in play).
- Cuff ribs fade out from about 1.5 m on a 1080p screen (progression/98).
- `vacuum.hose_budget_ms` 0.30: the timing check failed once at 0.366 ms under load.
- The glossary names these devices and parts since Q2188-Q2195 (Sock vacuum, Backpack vacuum, Splitter, Filter, Filter
  nozzle, Nozzle display, Tank, Spit, Pour, Hopper, Output, Pile, Reject): `GLOSSARY.md` has them. The old code and
  UI text were not renamed.

## Three lessons from the last day (for the journal and the port rules)
1. **A whole number sent to a shader per instance must be `flat` and rounded before it is unpacked.** A Simple Sock's
   look code (exactly 48) arrived as 47.99 on some pixels and unpacked as another look: speckle that read as two meshes
   fighting. Only the MultiMesh path showed it; stills taken with the single-mesh uniform could not (progression/98).
2. **A Guest's predicted body must not change shared state.** A Guest's own Throw woke Resting Socks on the Guest only;
   the Host never corrects a Sock it did not move, so the desync was permanent. It hid for weeks because the Host's
   body usually hit the same Socks. Fixed in `SockFlights._impact_wakes`; no dedicated test pins it (follow-up on
   tools/28). In the new state design this is a rule: prediction is looks only.
3. **Branches that each pass can fail together.** Four of the day's five merges needed a fix in the integration
   worktree (a renamed function, a node name ending `_wheel` importing as a `VehicleWheel3D`, re-exported models, the
   desync above). A full-suite run costs about 30 minutes; one import hang cost 39. Plan merges as batches, and give
   the import a timeout (the starter kit's runner has one).

4. **Reproduce before you diagnose, and use the fast lane for a small visible fault.** The first diagnosis of the
   speckle in lesson 1 (cuff ribs) was wrong; the designer saw at once that it "looks like two meshes clipping", and
   asked why the fix took ten minutes.
5. **One process, many pictures.** Taking 70 stills as 70 game starts took about 48 seconds each in the sandbox and
   got worse in parallel; the capture tour takes all 70 in one run of about 10 minutes.
6. **An animated collider must itself be the `AnimatableBody3D`**, and a node named `..._wheel` imports as a
   `VehicleWheel3D`: both cost a round while building the starter kit's example entity.

## The looks baseline (done)
70 views of the old game at `v0.1`, taken by the capture tour in the sandbox: `docs/migration/baseline/` (the
stills, the views file, `tour_info.txt`, and `numbers.md`: counts, sizes and the suite verdict). Software renderer,
1280x720, High preset. 69 of 70 are pixel-identical between two runs; `avatar-hat-clothes` is not. No frame-time
numbers were taken on the designer's PC: the old game's bench can still produce them from the reference clone
(`reference/it-socks/tools/bench.sh`, its `docs/perf/tools.md`).
Not in the views (no way to set them up): the Splitter carried, the Cellar hatch and the Grotto.

## Open at the freeze (the old game's, not ported as facts)
- No dedicated test pins lesson 2's fix. The Splitter's height in the layout (y = 2.9) is unchecked.
- The old game's suite at the freeze: PASS, 33,102 checks in 1,062 cases, about 30 minutes.
- The exported build at the tag is `builds/windows/ItSocks.exe` in the old folder (git-ignored: not in the clone).
