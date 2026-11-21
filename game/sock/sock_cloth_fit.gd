## How the sock shader's print and knit sit on one model's UV0 (the old game's SockLook.SHAPE_CLOTH
## per shape and SockBall's BALL_* numbers), measured from the model by the old make_socks.py and
## make_sock_balls.py. Part of SockLookTable.
class_name SockClothFit
extends Resource

## How much U (cuff to toe) one face-width of the flattened tube spans: keeps motifs round.
@export var print_aspect := 0.29
## Metres of cloth along U and around V: sizes the knit. A ball's is for a ball of
## SockLookTable.ball_radius and scales by its own radius.
@export var cloth_size := Vector2(0.302, 0.19)
## The U span of the calf (cuff band to heel patch), where the "big" print layout sits.
@export var calf_body := Vector2(0.1278, 0.2939)
## The two U values that split the trim into cuff band | heel patch | toe cap.
@export var patch_split := Vector2(0.1278, 0.7099)
