## Where a loose Sock lies when the level starts, placed in the editor: its transform is the Sock's
## pose (lying flat, its bottom on the surface) and `design` its Design's id. The Mess turns every
## SockSpot under its `spots` node into a lying Sock when the level starts, then hides it. A marker,
## not a thing: nothing reads it after that.
class_name SockSpot
extends Marker3D

## The id of the Sock's Design (game/sock/designs.tres).
@export var design := 0
