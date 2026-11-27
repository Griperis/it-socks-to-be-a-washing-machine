---
type: ticket
status: done
kind: build
area: core
feature: zoo
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 1", "suggested model: sonnet"]
terms: [Elevator, Cat, X-ray, Sock vacuum, Backpack vacuum, Sock detector, TV, Radio]
suites: [sounds, sound_wiring, zoo, menus, house, save, coop_join]
---

# Batch C's groundwork: every new sound, the seven station shells and the house's system slots

Every SoundEvent the four batch C designs add, and every batch C zoo station's empty shell, and the house's five system slots, in one ticket, so no later
batch C ticket edits `game/audio/sound_catalogue.tres`, `game/zoo/zoo.tscn` or `game/house/house.tscn` (draft 150-S of `devices.md`, widened by
core/153 to the whole batch: the Elevator's, the day's, the devices', the TV and Radio's, the Cat's and the X-rays'
sounds).

**The SoundEvents** (the old picks, shares and numbers; the tables in each doc):
- the Elevator (`elevator.md` "Sounds"): `elevator_bell` (the old pick `cc0/springspring_bell`, Q2727), `elevator_creak` (the basket's creaks),
  `hatch_open`, `hatch_close` (the oven's), `elevator_button` (naming `device_click`'s clip), `elevator_ride` (flat
  loop, the old synth placeholder), `elevator_squeeze` (the old synth placeholder); no climb sound (Q2702);
- the day (`day-and-exterior.md` "How it is authored"): `lamp_on`, `lamp_off` (flat), the old picks
  `cc0/funnydude_switch_on` and `_off` (Q2709 keeps the click, Q2727 the old picks);
- the devices and the TV and Radio (`devices.md`, `tv-and-radio.md` "Sounds"): `vacuum_motor` (3D loop),
  `vacuum_thwip`, `vacuum_spit_tick` (with the old 0.09 s gap per vacuum), `vacuum_nozzle_hang`, `vacuum_nozzle_drop`,
  `vacuum_lift`, `vacuum_set_down`, `beeper_beep` (the ping's pool, -6 dB, Q2698), `device_click`, `tv_static`,
  `radio_static`, `tv_puppets`, `tv_shop`, `tv_news`, `tv_testcard`, `radio_land`; not the dead `vacuum_mode_click`
  and `vacuum_spit_out`;
- the Cat (`cat.md` "Sounds"): `cat_meow`, `cat_purr`, `cat_hiss` (Dan Knoflicek's Cat 8, CC-BY: its credit),
  `cat_land`, `cat_swat`, `litter_scratch` (the swat's clips as its placeholder until the designer picks one of the
  three recordings core/179 brings, Q2712);
- the X-rays (`x-rays.md` "How it is authored"): `xray_on` (`cc0/laleksic_switch_on`), `xray_off`
  (`cc0/laleksic_switch_off`), copied once as `xray_on__laleksic_switch_on.ogg`, `xray_off__laleksic_switch_off.ogg`;
  `xray_ready` naming `match`'s clip (core/131).

Every copied clip goes into `assets/audio/` with its `SOURCES.md` row and its `game/ui/licence/credits.tres` entry.

**The station shells** (`game/zoo/stations/<name>.tscn`, each a floor, its own ground `StaticBody3D` with a collision
shape under it, a `ZooLabel`, a Spawn and the `Pad` node `zoo:stations` requires; instanced by hand under `Stations` in `zoo.tscn`, Q2359), 14 m apart from
x = 208 (the zoo's floor ends before x = 160, so each needs its own ground):

| Station | x | Filled by |
|---|---|---|
| `elevator.tscn` | 208 | core/155 |
| `day.tscn` | 222 | core/160 |
| `vacuums.tscn` | 236 | core/168 |
| `detector.tscn` | 250 | core/167 |
| `tv_radio.tscn` | 264 | core/163 |
| `cat.tscn` | 278 | core/176 |
| `xrays.tscn` | 292 | core/182 |

**The house's system slots** (Q2720): five empty scenes in `game/house/systems/`, each a bare `Node3D` root at the
house's origin, instanced once in `house.tscn` under one `Systems` node, so each later ticket edits only its own:

| Slot | Filled by (in order) |
|---|---|
| `elevator.tscn` | core/155, then 156-158 if they place anything |
| `day.tscn` | core/160 (the `Day` Part), core/161 (the lamps' clock, the wall clock) |
| `exterior.tscn` | core/162 |
| `cat.tscn` | core/176 (`CatStart`, the low-window nap markers, the Cat placed) |
| `devices.tscn` | core/174 (the vacuums, the detector) |

A Part placed in a slot is found, synced and saved like any other (Parts binds by path, so its id is
`Systems/<slot>/...`); a case shows it.

The Day station keeps the zoo's noon until core/160 gives it its own `WorldEnvironment` (Q2299).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The godot-ai trial (Q2724): the station shells, the house slots and their instancing in `zoo.tscn` and `house.tscn`
are made through `kit/tools/godot_ai.sh` / `godot_ai.py` (the headless editor), not hand-written; report how it went
(what worked, what had to be hand-done, time). `kit/tools/drift_check.sh` passes on every file touched.
SoundEvents in the catalogue (the Sounds station shows each with no other change; the designer swaps any clip there);
the shells and the slots are scenes edited in the editor's format (Q2268), no code.

## Acceptance
- Real path: in the Sounds station (built from the catalogue at load) the player walks to the `vacuum_thwip` pillar
  and presses E; it plays. The same for `elevator_bell`, `cat_meow` and `xray_on`.
- Every SoundEvent named above is in the catalogue with its clips; the shared ones name the same files
  (`elevator_button` and `device_click`, `beeper_beep` and the ping's, `xray_ready` and `match`); `elevator_bell`,
  `lamp_on` and `lamp_off` play the old picks (Q2727).
- The seven shells load in the zoo at their x, each with its own ground under its Spawn (a player spawned there stands);
  the wiring check passes.
- The five slots are instanced in `house.tscn` under `Systems`; a test Part placed in one is bound with the id
  `Systems/<slot>/...` and survives a save and load (a case; removed or kept as a fixture, not left in the house).
- Every new file under `assets/` has its credit (`menus` l02).
- Placeholders: the sounds the old marked placeholder (`elevator_ride`, `elevator_squeeze`, `litter_scratch`).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The old placeholder sounds, no climb sound (Q2702, 2026-11-26).
- The lamps' click is kept (Q2709, 2026-11-26).
- The beep is the ping's pool (Q2698, 2026-11-26).
- The ready sound borrows the Sole Mates cue (Q2701, 2026-11-26).
- The scratch's own sound is picked by the designer from three recordings (Q2712, 2026-11-26).
- The bell and the lamps' clicks are the old picks: `springspring_bell`, the funnydude clicks (Q2727, 2026-11-27).

## Open follow-ups
- [later] Kit fault (`kit/tools/godot_ai.py`): every invocation opens a new MCP session and never ends it (no DELETE). The godot-ai server allows 32 sessions, each idle for 30 min, so after about 30 single `call`s (the `--ready` polls of `godot_ai.sh start` count too) every call gets HTTP 503 until the editor restarts. `--batch` (one session) works around it. Fix: end the session on exit, or reuse one per checkout.
- [later] Kit fault (godot-ai trial): `godot_ai.sh stop` fails drift_check on `house.tscn` after new ext_resources are added. The editor gives the four `resource_local_to_scene` Glow materials new sub-resource ids on its next save, and only a second save keeps them. `kit/tools/resave.sh` fixed it (two passes). `stop` could re-save twice, or say to run resave.sh.
- [later] godot-ai cannot set node metadata (`node_set_property` with `metadata/surface` returns PROPERTY_NOT_ON_CLASS). The shells' ground has no `surface` meta and footsteps fall back to wood.
