## Where a carried thing (a Carriable) rides in front of its carrier (core/78): one .tres per kind of
## carried thing, edited in the inspector (the old hold.json's body-frame kinds). The frame is the
## carrier's body as drawn: from the feet, turned as the body faces. Every slot goes down with the
## whole Crouch, never lower than `floor_clearance` over the feet.
class_name HoldSlot
extends Resource

## Where it rides from the carrier's feet: x to their right, y up, -z ahead (metres).
@export var at := Vector3(0.0, 0.95, -0.5) # placeholder: the designer's number (the old hold.json part slot)
## How it is turned in the slot, Euler radians (YXZ) from the way the body faces. Its turn about the
## up axis is also the turn it lies at once put down ("at the yaw it was held").
@export var turn := Vector3.ZERO # placeholder: the designer's number (the old hold.json: none)
## The lowest the slot may sit over the feet, crouched (the old hold.json floor_clearance).
@export_range(0.0, 1.0, 0.01, "suffix:m") var floor_clearance := 0.25 # placeholder: the designer's number (the old hold.json floor_clearance)
## How long a thing put down is drawn easing from where it was held to where it lies (the old
## release.json flick, the shared put).
@export_range(0.0, 1.0, 0.01, "suffix:s") var put_seconds := 0.1 # placeholder: the designer's number (the old release.json flick)


## The slot's pose from the feet of a body turned by `yaw` (radians), crouched by `crouch_drop`
## metres (how far the body is lowered now), in the level.
func pose(feet: Vector3, yaw: float, crouch_drop: float) -> Transform3D:
	var spot := at
	spot.y = maxf(at.y - crouch_drop, minf(at.y, floor_clearance))
	var body := Basis(Vector3.UP, yaw)
	return Transform3D(body * Basis.from_euler(turn, EULER_ORDER_YXZ), feet + body * spot)


## The turn about the up axis a thing held by a body turned by `yaw` lies at once put down.
func lying_yaw(yaw: float) -> float:
	return wrapf(yaw + turn.y, -PI, PI)
