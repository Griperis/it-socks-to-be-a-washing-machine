## assets/18's line-ups: a row of AvatarLooks wearing the hats and clothes of one Collection (or the ten
## basic pieces), placed and framed as the old game's line-up (the old
## tools/blender/wardrobe_pieces/lineup.py: a creature per piece 0.9 m apart, each turned 14 degrees, in
## the player colours in order, the last wearing a hat and clothes together; a 50 mm lens from 10.8 m).
## The Socks and the Trail keep their places bare until assets/19. Dressed as wardrobe.md "The dressed
## Avatar" says the Dresser will: a hat's Looks under HatPoint, clothes under the Body with their skin
## bound to the Avatar's Skeleton3D. `--scene=res://tools/wardrobe_lineup.tscn`, then the shot hook
## `wardrobe_lineup:<collection>` (tools/shots/sets/wardrobe-lineup.txt).
extends Node3D

const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
const LOOKS := "res://game/wardrobe/looks/%s.tscn"
const COLOURS := "res://game/net/coop_tuning.tres"
const GAP := 0.9
const TURN := -14.0
## Each Collection's six places in the old gifts.json order (hat, hat, clothes, clothes, Socks, Trail).
const ROWS: Dictionary[StringName, Array] = {
	&"simple": [&"sock_hat", &"peg_band", &"laundry_sack", &"odd_sock_scarf", &"", &""],
	&"sport": [&"sweatband", &"bike_helmet", &"team_jersey", &"gold_medal", &"", &""],
	&"food": [&"chef_hat", &"cone_hat", &"pizza_poncho", &"donut_float", &"", &""],
	&"patterns": [&"bucket_hat", &"headphones", &"hoodie", &"backpack", &"", &""],
	&"animals": [&"bear_ears", &"frog_hood", &"tiger_tail", &"bee_wings", &"", &""],
	&"superhero": [&"hero_mask", &"winged_helmet", &"hero_cape", &"power_belt", &"", &""],
	&"winter": [&"earmuffs", &"santa_hat", &"reindeer_jumper", &"puffy_coat", &"", &""],
	&"space": [&"antenna_band", &"space_helmet", &"space_suit", &"jetpack", &"", &""],
	&"fruit": [&"banana_peel_cap", &"pineapple_crown", &"watermelon_vest", &"fruit_basket_backpack", &"", &""],
	&"nature": [&"mushroom_cap", &"birds_nest", &"moss_shawl", &"ivy_wrap", &"", &""],
	&"vegetables": [&"carrot_top_beanie", &"pumpkin_helmet", &"gardeners_apron", &"onion_layers", &"", &""],
	&"drinks": [&"teacup_hat", &"coffee_steam_crown", &"milk_carton_costume", &"bubble_tea_backpack", &"", &""],
	&"math": [&"pi_headband", &"mobius_halo", &"times_table_cardigan", &"calculator_chestplate", &"", &""],
	&"tech": [&"gaming_headset", &"vr_visor", &"circuit_hoodie", &"robot_chest_panel", &"", &""],
	&"transport": [&"pilots_goggles", &"traffic_cone_hat", &"high_vis_vest", &"balloon_backpack", &"", &""],
	&"machinery": [&"hard_hat", &"welding_mask", &"overalls", &"tool_belt", &"", &""],
	&"lost": [&"porthole_helmet", &"detergent_cap_crown", &"softener_cape", &"hose_scarf", &"", &""],
}
## The ten basic pieces, one creature each, no last creature (the old game shot them one by one).
const BASIC: Array[StringName] = [&"beanie", &"cap", &"top_hat", &"party_hat", &"bobble_hat", &"crown",
		&"scarf", &"apron", &"bow_tie", &"jumper"]
## The old line-up's last creature: its Collection's first hat and second clothes, but where the old theme
## file named its own pair.
const COMBO: Dictionary[StringName, Array] = {&"vegetables": [&"carrot_top_beanie", &"gardeners_apron"]}

## How many Looks scenes went on, and how many failed to load (read by the check case).
var dressed := 0
var failed := 0


## Stands the row of `collection` ("basic" for the ten basic pieces) and frames it.
func show_row(collection: String) -> void:
	for c: Node in $Row.get_children():
		c.free()
	var places: Array = []
	if collection == "basic":
		for id: StringName in BASIC:
			places.append([id])
	else:
		var row: Array = ROWS[StringName(collection)]
		for id: StringName in row:
			places.append([id] if id != &"" else [])
		places.append(COMBO.get(StringName(collection), [row[0], row[3]]))
	var colours: Array[Color] = (load(COLOURS) as CoopTuning).colours
	var n := places.size()
	for i in n:
		var avatar := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
		avatar.colour = colours[i % colours.size()]
		avatar.position = Vector3((float(n - 1) / 2.0 - float(i)) * GAP, 0.0, 0.0)
		avatar.rotation.y = deg_to_rad(TURN)
		$Row.add_child(avatar)
		for id: StringName in places[i]:
			wear(avatar, id)
	# The old camera stepped back for a longer row.
	var far := maxf(1.0, float(n) / 7.0)
	var cam := $Camera as Camera3D
	cam.position = Vector3(0.0, 2.6 * far, -10.8 * far)
	cam.look_at(Vector3(0.0, 0.9, 0.0))


## Puts piece `id`'s Looks on `avatar`: a hat (no skin) under HatPoint, clothes under the Body, skinned
## to the Avatar's bones.
func wear(avatar: AvatarLooks, id: StringName) -> void:
	var scene := load(LOOKS % id) as PackedScene
	if scene == null:
		failed += 1
		return
	var looks := scene.instantiate() as Node3D
	var skinned: Array[MeshInstance3D] = []
	for m: Node in looks.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).skin != null:
			skinned.append(m as MeshInstance3D)
	var body := avatar.get_node(^"Body") as Node3D
	if skinned.is_empty():
		body.get_node(^"HatPoint").add_child(looks)
	else:
		body.add_child(looks)
		var skeleton := avatar.body().get_parent() as Skeleton3D
		for m: MeshInstance3D in skinned:
			m.skeleton = m.get_path_to(skeleton)
	dressed += 1
