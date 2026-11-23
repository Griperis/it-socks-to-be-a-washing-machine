## Where a SockArea's Socks may not land: the old game's rules as numbers on the area (core/52,
## Q2527). One shared .tres (sock_area_rules.tres); an area that needs other numbers makes its own copy
## unique in the inspector. Hand-placed SockExclusion boxes come on top of these.
@tool
class_name SockAreaRules
extends Resource

## Open floor lies at least this far from a wall, a roof or anything of the house that is not furniture.
@export_range(0.0, 2.0, 0.01, "suffix:m") var wall_margin := 0.28 # placeholder: ported (SockLayout: 0.18 + half the 0.2 grid)
## Open floor lies at least this far off a furniture piece's footprint.
@export_range(0.0, 1.0, 0.01, "suffix:m") var furniture_margin := 0.05 # placeholder: ported (SockLayout._floor_ok's 0.05)
## Open floor needs this much free height over it (a crouching player reaches it).
@export_range(0.1, 3.0, 0.05, "suffix:m") var headroom := 1.0 # placeholder: ported (SockLayout._floor_ok's 1 m roof rule)
## Open floor is a surface this near the area's bottom face (not a step, a top, or a floor below a stair hole).
@export_range(0.01, 1.0, 0.01, "suffix:m") var floor_band := 0.15 # placeholder: until the house's floors are laid
## A Cabinet keeps this box clear in front of it (its width, its depth out from its front).
@export var cabinet_clear := Vector2(1.8, 0.95) # placeholder: ported (house_layout.json clear_zones, 1.8 x 0.95)
## Two Socks of a flat area lie at least this far apart (a Heap's Socks may stack).
@export_range(0.0, 0.5, 0.005, "suffix:m") var spacing := 0.02 # placeholder: until the designer's look
