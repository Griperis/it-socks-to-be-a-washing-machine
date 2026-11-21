# The shared material library (assets/04)

- `game/materials/<name>.tres`: one `StandardMaterial3D` per material name, used by every family of
  models (furniture first; the house kit's `game/house/kit/materials/` joins in a later ticket). Each
  carries `metadata/old_pieces`: the old furniture pieces that used the name.
- A model uses them through its `.glb.import`: each glb material of that name is mapped to the library
  file (`use_external`), so the glb's own copies are never drawn.
- `tools/materials_from_old.py` wrote them from the old glbs (values as Godot's glTF importer made them:
  colours to sRGB, double-sided as culling off, emission strength as energy). It never overwrites a file:
  the `.tres` are the truth, edited in the inspector.
- The fab_* cloths had glTF sheen in the old models; StandardMaterial3D has no sheen and the old import
  dropped it, so they are ported without it (Q2390). A soft sheen is a later look change.
- The zoo's Materials station (`game/zoo/stations/materials.tscn`): `MaterialBoard` hangs every file on a
  sphere, built from the folder at load (Q2337); `MaterialBoardLayout` its spacing. A folder
  `candidates/<name>/` (several files of one name) shows as its own row. Shots: the set `materials`.

## The picks (Q2389)

24 names were used by the old furniture with several sets of values. In each, the set the most old pieces
used stays; on a tie, the one nearest the group's median roughness. To override a group, edit
`game/materials/<name>.tres` (its roughness and metallic, below, are what was picked).

| Name | Picked | Old pieces with it | Why | Roughness | Metallic | Pieces with the name, of sets |
|---|---|---|---|---|---|---|
| brass | `brass_1` | 16 | most pieces | 0.30 | 0.80 | 20 of 3 |
| cardboard | `cardboard_1` | 7 | most pieces | 0.85 | 0.00 | 12 of 4 |
| charcoal | `charcoal_1` | 7 | tie, nearest median 0.45 | 0.60 | 0.00 | 22 of 6 |
| dark_wood | `dark_wood_1` | 7 | most pieces | 0.60 | 0.00 | 12 of 2 |
| glass | `glass_1` | 1 | most pieces (the house kit's own glass not counted) | 0.05 | 0.00 | 1 of 2 |
| grey | `grey_1` | 3 | most pieces | 0.50 | 0.30 | 7 of 4 |
| leaf | `leaf_1` | 3 | most pieces | 0.55 | 0.00 | 4 of 2 |
| leaf_dark | `leaf_dark_1` | 3 | most pieces | 0.55 | 0.00 | 4 of 2 |
| mustard | `mustard_1` | 9 | most pieces | 0.50 | 0.00 | 23 of 6 |
| navy | `navy_1` | 5 | most pieces | 0.60 | 0.00 | 11 of 4 |
| oak | `oak_2` | 10 | tie, nearest median 0.55 | 0.60 | 0.00 | 35 of 7 |
| pad | `pad_2` | 1 | tie, nearest median 0.70 | 0.70 | 0.00 | 3 of 3 |
| paper | `paper_1` | 4 | most pieces | 0.80 | 0.00 | 9 of 4 |
| pink | `pink_1` | 8 | most pieces | 0.40 | 0.00 | 16 of 7 |
| porcelain | `porcelain_1` | 4 | most pieces | 0.15 | 0.00 | 7 of 2 |
| red | `red_1` | 9 | most pieces | 0.40 | 0.00 | 21 of 4 |
| sage | `sage_1` | 11 | most pieces | 0.55 | 0.00 | 24 of 7 |
| sage_dark | `sage_dark_1` | 4 | most pieces | 0.60 | 0.00 | 7 of 3 |
| sky | `sky_1` | 9 | most pieces | 0.40 | 0.00 | 24 of 8 |
| steel | `steel_1` | 5 | most pieces | 0.35 | 0.70 | 13 of 4 |
| stem | `stem_1` | 2 | most pieces | 0.70 | 0.00 | 3 of 2 |
| stripe | `stripe_1` | 4 | most pieces | 0.70 | 0.00 | 9 of 3 |
| terracotta | `terracotta_1` | 2 | most pieces | 0.75 | 0.00 | 4 of 3 |
| white | `white_1` | 12 | most pieces | 0.60 | 0.00 | 20 of 4 |

The candidates' values and their pieces are in git history (commit a372eddd,
`game/materials/candidates/`) and on the strips in `builds/review-furniture/`.
