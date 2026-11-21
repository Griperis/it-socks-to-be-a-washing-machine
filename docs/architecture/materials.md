# The shared material library (assets/04)

- `game/materials/<name>.tres`: one `StandardMaterial3D` per material name, used by every family of
  models (furniture first; the house kit's `game/house/kit/materials/` joins in a later ticket). Each
  carries `metadata/old_pieces`: the old furniture pieces that used it.
- `game/materials/candidates/<name>/<name>_<k>.tres`: a name the old game used with several sets of
  values (k = 1 the set most pieces used; `_kit` the house kit's own). The designer picks the one that
  stays from the strips (Q2177); it then becomes `game/materials/<name>.tres` and the folder goes.
- `tools/materials_from_old.py` wrote them once from the old glbs (values as Godot's glTF importer made
  them: colours to sRGB, double-sided as culling off, emission strength as energy). It never overwrites a
  file: the `.tres` are the truth, edited in the inspector.
- The zoo's Materials station (`game/zoo/stations/materials.tscn`): `MaterialBoard` hangs every file on a
  sphere, built from the folder at load (Q2337); `MaterialBoardLayout` its spacing. Shots: the set
  `materials` (`materials:<group>` shows one group alone).
