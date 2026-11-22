## The avatar's Looks: the old game's sock creature (assets/avatar/avatar.glb, coop/04), ported as is.
## It only shows. The `player` surface of the body takes `colour` (a copy of the made material with
## that albedo, as the old game's avatar.gd did); the trim, eyes and pupils keep their made colours.
## The nodes the avatar's behaviour may lean on are named in looks_contract.json beside it.
class_name AvatarLooks
extends Node3D

## The body's surface that takes the player's colour (the material's name in the glb).
const TINTED := &"player"
## The skinned body inside the model.
const BODY := ^"Body/Armature/Skeleton3D/Avatar"

## The player's colour on the body. White shows the model as made.
@export var colour := Color.WHITE: # placeholder: the player's colour from the Roster (coop/03)
	set(value):
		colour = value
		if is_node_ready():
			_tint()


func _ready() -> void:
	_tint()


## The body mesh, skinned to the four-bone spine.
func body() -> MeshInstance3D:
	return get_node(BODY) as MeshInstance3D


func _tint() -> void:
	var mi := body()
	for i: int in mi.mesh.get_surface_count():
		var made := mi.mesh.surface_get_material(i) as BaseMaterial3D
		if made == null or made.resource_name != TINTED:
			continue
		var paint := made.duplicate() as BaseMaterial3D
		paint.albedo_color = colour
		mi.set_surface_override_material(i, paint)
