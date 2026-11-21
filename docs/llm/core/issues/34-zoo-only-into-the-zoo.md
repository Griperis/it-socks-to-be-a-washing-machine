---
type: ticket
status: ready-for-agent
kind: build
area: tools
feature: zoo
priority: now
created: 2026-11-21
done:
blocked_by: ["[[28-review-correctness-fixes]]", "[[33-zoo-labels-near-the-ground]]"]
notes: []
terms: [station]
---

# What only the zoo needs, into the zoo

The designer (Q2409, 2026-11-21): "could the entities and stuff necessary only for the zoo be somehow marked, so
it's not in the game folders? Maybe the switches, texts, ... that are used in the zoo should only be in the zoo?"
The folder is the mark: zoo-only things live under `game/zoo/`, and the game never refers to `game/zoo/`, so a
release build can leave the folder out whole.

## Behaviour list
- Z1 Moved under `game/zoo/` (with `.uid` files, by Godot's own path rewrite or by editing the references; every
  `uid=` reference stays valid):
  - `game/entities/upgrade_switch/` (the zoo's Sock Smarts / Sock Sense switch, marked for replacement in M4);
  - `game/audio/sound_spot.gd` (the Sounds station's buttons);
  - `game/house/kit/house_kit_line_up.gd` (the kit station's line-up);
  - `game/house/kit/rooms/` (the kit station's sample rooms; `house_kit_build.gd` writes them to the new place);
  - `game/player/zoo_upgrades.tres` (the zoo's upgrade flags).
  `AmbientLoop` stays in `game/audio/` (a level's node); the Cabinet, the cupboard, the Player, the avatar, the
  picture and the kit's pieces and materials stay (the game's own, used only by the zoo until the main scene
  holds them).
- Z2 `game/zoo/` is grouped per station: a station's helper scripts, layouts and zoo-only props in
  `game/zoo/<station>/` (as `game/zoo/heap/` is today: `sounds/`, `screen/`, `house_kit/`, `cabinet_gallery/`,
  `every_sock/`, `furniture/`, `materials/`, `sock_looks/`, `icons/`, `handling/` for the lose button); the
  station scenes stay one file each in `game/zoo/stations/` (Q2359); `zoo.tscn`, `stations.gd` and `zoo_net.gd`
  stay at the top. The untracked `game/zoo/test.tscn` is the designer's: leave it alone.
- Z3 The two build-time generators leave `game/`: `game/house/kit/house_kit_build.gd` and
  `game/furniture/furniture_build.gd` move to `tools/` beside `tools/old_house_build.gd`; their `--script` runs,
  docs (`docs/architecture/house-kit.md`, `furniture.md`, `docs/human/house-kit.md`, `models-*.md`) and any tool
  that names them follow.
- Z4 `game/ui/prompts.gd` switches on `UpgradeSwitch` and `LoseButton`; replace that with a `prompt_title()` on
  `Part` that both override (core/30's T5, done here instead). No guard check for zoo references (the designer:
  "We don't need the guard check for this", Q2410).
- Z5 `docs/architecture.md` (and the `zoo-design` notes in `docs/`) say where zoo-only things live.

## Acceptance
- `check` and the full suite pass; no `uid` or path reference is broken (`asset_lint` and the editor's load of
  `zoo.tscn` clean).
- Real-path case: in the zoo's Screen station the player clicks the upgrade switch and the Sock Sense readout
  appears (the moved switch, through the new `prompt_title()`).
- A list in the report of every file moved, old path to new.

## Answers
- Zoo-only things live under `game/zoo/`, per station; the game never refers to them; generators go to `tools/`
  (Q2409, 2026-11-21).
- No guard check for references into `game/zoo/` (Q2410, 2026-11-21).

## Open follow-ups

## Built log
- Model: Sonnet: mechanical moves and one check.
