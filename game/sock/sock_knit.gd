## The knit every Sock is drawn with (assets/05, Q2500): one seamless tile of knit normal, roughness
## and cavity (assets/sock/knit.png, made by assets_src/generate/sock/make_knit.py), tiled by the sock
## shader over every shape and tier under the Design's colours, pattern and print, faded with
## distance. Edited in the inspector (sock_knit.tres beside it); SockLook hands it to each material.
class_name SockKnit
extends Resource

## The tile: RG the normal, B the roughness, A the cavity (make_knit.py's header).
@export var texture: Texture2D
## Stitches across and down one tile (make_knit.py's WALES and COURSES).
@export var tile_stitches := Vector2i(8, 8)
## One stitch's width (around the Sock) and height (along it), in metres, per cloth.
@export var cotton_stitch := Vector2(0.0045, 0.004) # placeholder: the designer's eye on the strip
@export var wool_stitch := Vector2(0.009, 0.008) # placeholder: the designer's eye on the strip
@export var fuzzy_stitch := Vector2(0.007, 0.006) # placeholder: the designer's eye on the strip
## How deep the knit's bumps read (0 none, 1 the tile's full slope), per cloth.
@export_range(0.0, 2.0, 0.01) var cotton_strength := 0.6 # placeholder: the designer's eye on the strip
@export_range(0.0, 2.0, 0.01) var wool_strength := 1.0 # placeholder: the designer's eye on the strip
@export_range(0.0, 2.0, 0.01) var fuzzy_strength := 0.35 # placeholder: the designer's eye on the strip
## How much the gaps between the yarn darken the colour (0 none, 1 the tile's full cavity).
@export_range(0.0, 1.0, 0.01) var cavity := 0.5 # placeholder: the designer's eye on the strip
## The camera distances, in metres, over which the knit fades out to the plain cloth.
@export var fade_distance := Vector2(3.0, 8.0) # placeholder: the designer's eye on the strip


## One stitch's size of the cloth numbered `fabric` (SockLookTable.FABRICS order).
func stitch_of(fabric: int) -> Vector2:
	return [cotton_stitch, wool_stitch, fuzzy_stitch][clampi(fabric, 0, 2)]


## The knit's strength on the cloth numbered `fabric`.
func strength_of(fabric: int) -> float:
	return [cotton_strength, wool_strength, fuzzy_strength][clampi(fabric, 0, 2)]
