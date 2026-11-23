# Furniture (assets/04)

The old house's 67 pieces, each a scene in `game/furniture/<piece>.tscn` (Q2151): no code of its own.

- **Root:** a StaticBody3D on the house layer (`Mess.LAYER_HOUSE`), mask 0, named in PascalCase. Its
  `Shape<n>` are the old collision nodes (`sock_<n>-convcolonly`): a box where the old hull was 8 box
  corners (the old HouseParts rule), else the hull's points; the 4 `-colonly` trimeshes are met from both
  sides. Metadata from the old manifest: `footprint`, `height`, `crawl_gap`, `crawl_box`, `hide`, `rooms`,
  `plan_spot`, `note`.
- **PlayerBody:** the old player collision (Q2397): the manifest's coarse `colliders`, else one box over the
  footprint from the crawl gap up, on `Player.BLOCK_LAYER` (8), which only the player's mask meets. Socks
  (masks of the house layer) pass it and meet the root's shapes. The 4 rugs (metadata `rug`) have none.
- **Looks:** `looks/looks_<piece>.tscn`, the still meshes (Body; Board, MirrorGlass; the piano's
  `Key_<midi>` with metadata `midi`). Contract `looks/looks_contract.json`.
- **Openings:** one Node3D per old container (named as it: `Door`, `Drawer_1`, `Cabin`, `Boot`, `Lid`...)
  holding an `Openable` (metadata `kind`: the old container kind; its `open_sound` and `close_sound` are
  `<kind>_open` and `<kind>_close` of the sound catalogue, assets/07), its Looks
  `parts/looks_<piece>_<opening>.tscn` and `Inside` (the interior box where Socks hide, an Area3D on no
  layer, metadata `shelves_y`). The Looks: each moving part an AnimatableBody3D named as in the old
  model at its old pivot, with `Mesh` and its collision; `Outline`; an AnimationPlayer on physics frames
  with `open` and `shut` (the old swing: 0.35 s, easing out both ways). Contract `parts/looks_contract.json`.
- **Spots:** `Spots/Top<n>`, Area3D boxes on no layer: a rect a Sock may rest on, from the top's height
  to the headroom over it. Joined from the old manifest's cells by the old game's piece-local rule (seen,
  0.12 m headroom, 0.06 m in from the top's edges, 0.05 m bands); what the house round a placed piece
  leaves clear is the level's to decide.
- **What the Sock generator reads** (core/52, `docs/architecture/sock-generator.md`): `Spots/Top<n>` (tops),
  each opening's `Inside` and its `shelves_y` (insides), the root's `crawl_gap` and `crawl_box` (the gap under it)
  and `footprint`; a root may carry `sock_weight` (a float) to override the area's weight for all its places.
- **Lamp:** the old_tree's small light (OmniLight3D, no shadow).
- Origins at the floor centre of the bounding box, +Z front (F04); wall-hung pieces are modelled at the
  floor and lifted where they are placed.

## The devices (assets/07, `game/devices/`)

- **Opening sounds:** each Openable's two exports name catalogue events with the old clips (drawer, cupboard, fridge,
  oven, basket, litter_flap 6 dB under, piano_lid); a new kind is a catalogue entry and two exports, no code.
- **The piano's keys:** `Keys/Key_<midi>` in `piano.tscn` (made once by `tools/piano_keys_from_old.py` from the old
  manifest): a Node3D on the key's hinge with a `PianoKey` Part (`Key`) and a `Body` (its old box, 2 cm taller so the
  aim finds it over the keyboard hull). The Part's state is `strikes` and `by`; a granted `play` counts one more and
  each machine dips the Looks' `Key_<midi>` (a Tween, `piano_tuning.tres`) and plays `Sounds.play_note(&"piano",
  note, at)`. Click-only (`Part.click_only()`): E skips it, its prompt shows the left button. A Guest's own key
  sounds at once and not again on the Host's word.
- **Instruments:** a SoundEvent with an `Instrument` (roots per clip, voices, hold, release, restrike, unit size) is
  played by `Sounds.play_note`: nearest root, pitched, on the instrument's own voices.
- **The wall mirror:** `mirror.tscn` (a `Mirror` with `Glass`, a `Reflection` SubViewport and its `MirrorCamera`)
  stands at the glass's centre in `wall_mirror.tscn`. Render layers: 11 the eye's only (the own belly and held items,
  set while it renders), 12 the mirror's only (`Player.mirror_body()`, a whole avatar Looks shown while a mirror
  renders; the player's camera skips the layer), 13 the glass, 15 the Mess Socks (`MessDrawing`). Off on the Low
  preset (`GraphicsPreset.mirror`). Numbers: `mirror_tuning.tres`.
- **The dust sheet:** `dust_sheet.tscn`, a `DustSheet` child named `DustSheet` of a Cabinet's root: `Cabinet._show`
  calls `follow(locked, now)`; drawn in code, pulled off with a Tween and `cabinet_reveal` after it
  (`dust_sheet_tuning.tres`). At the station a Sport Cabinet wears one and the zoo's `CabinetLockSwitch` grants
  its `lock_patch` (until Cabinet locks exist, M4).

## Where they come from

- `assets/furniture/<piece>.glb`: the old exports with the collision nodes taken out and meshes named
  after their nodes; `.glb.import` saves each mesh to `assets/furniture/meshes/<piece>_<node>.res` and maps
  each material to the shared library (`docs/architecture/materials.md`).
- `tools/furniture_from_old.py` (the glbs, imports and a data file), an import, then
  `tools/furniture_build.gd` (the scenes; it skips a scene that exists unless `--force`), then
  `tools/furniture_from_old.py --uids`. Run once: the scenes are edited by hand from then on.

## The station

`game/zoo/stations/furniture.tscn`, at (21.5, 0, 9.5) on its own ground right east of the zoo floor (moved in from x 75.5 when the old houses that led to it left the zoo, house/04), inside the
zoo's Mess bounds (Q2396): `FurnitureLineUp` puts
every scene of `game/furniture/` in rows by name, built from the folder at load (Q2337); in front, on the right, the
sheeted Cabinet and its switch (assets/07). Shots: the sets `furniture` and `furniture-devices`; `furniture:old_<view>` shows the old models in place, read from the reference at run time.
