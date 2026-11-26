## assets/18-19's line-ups: a row of AvatarLooks wearing the pieces of one Collection (or the ten basic
## pieces), placed and framed as the old game's line-up (the old
## tools/blender/wardrobe_pieces/lineup.py: a creature per piece 0.9 m apart, each turned 14 degrees, in
## the player colours in order, the last wearing a hat, clothes and the Socks together; a 50 mm lens from
## 10.8 m). Dressed as wardrobe.md "The dressed Avatar" says the Dresser will: a hat's Looks under
## HatPoint, clothes under the Body with their skin bound to the Avatar's Skeleton3D, a Socks pair's Looks
## under each foot with only that foot's sock shown at identity. A Trail's meshes (assets/wardrobe/meshes/,
## assets/19) lie scattered behind its creature as the old line-up laid them: nine steps' worth, rising as
## they age. `--scene=res://tools/wardrobe_lineup.tscn`, then the shot hook
## `wardrobe_lineup:<collection>` (tools/shots/sets/wardrobe-lineup.txt).
extends Node3D

const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
const LOOKS := "res://game/wardrobe/looks/%s.tscn"
const MESHES := "res://assets/wardrobe/meshes/"
const COLOURS := "res://game/net/coop_tuning.tres"
const GAP := 0.9
const TURN := -14.0
## Each Collection's six places in the old gifts.json order (hat, hat, clothes, clothes, Socks, Trail).
const ROWS: Dictionary[StringName, Array] = {
	&"simple": [&"sock_hat", &"peg_band", &"laundry_sack", &"odd_sock_scarf", &"odd_pair", &"lint_puffs"],
	&"sport": [&"sweatband", &"bike_helmet", &"team_jersey", &"gold_medal", &"tube_stripes", &"turf_prints"],
	&"food": [&"chef_hat", &"cone_hat", &"pizza_poncho", &"donut_float", &"strawberry_socks", &"sprinkles"],
	&"patterns": [&"bucket_hat", &"headphones", &"hoodie", &"backpack", &"rainbow_stripes", &"bubblegum_pops"],
	&"animals": [&"bear_ears", &"frog_hood", &"tiger_tail", &"bee_wings", &"paw_socks", &"paw_prints"],
	&"superhero": [&"hero_mask", &"winged_helmet", &"hero_cape", &"power_belt", &"hero_boots", &"lightning_sparks"],
	&"winter": [&"earmuffs", &"santa_hat", &"reindeer_jumper", &"puffy_coat", &"fair_isle", &"snowflakes"],
	&"space": [&"antenna_band", &"space_helmet", &"space_suit", &"jetpack", &"moon_boots", &"stardust"],
	&"fruit": [&"banana_peel_cap", &"pineapple_crown", &"watermelon_vest", &"fruit_basket_backpack", &"kiwi_socks", &"juice_drops"],
	&"nature": [&"mushroom_cap", &"birds_nest", &"moss_shawl", &"ivy_wrap", &"grass_tuft_socks", &"falling_leaves"],
	&"vegetables": [&"carrot_top_beanie", &"pumpkin_helmet", &"gardeners_apron", &"onion_layers", &"broccoli_fluff_socks", &"sprouting_footprints"],
	&"drinks": [&"teacup_hat", &"coffee_steam_crown", &"milk_carton_costume", &"bubble_tea_backpack", &"coffee_bean_socks", &"fizz_bubbles"],
	&"math": [&"pi_headband", &"mobius_halo", &"times_table_cardigan", &"calculator_chestplate", &"plus_and_minus_argyle", &"floating_digits"],
	&"tech": [&"gaming_headset", &"vr_visor", &"circuit_hoodie", &"robot_chest_panel", &"pixel_socks", &"falling_pixels"],
	&"transport": [&"pilots_goggles", &"traffic_cone_hat", &"high_vis_vest", &"balloon_backpack", &"tyre_tread_socks", &"tyre_tracks"],
	&"machinery": [&"hard_hat", &"welding_mask", &"overalls", &"tool_belt", &"hazard_stripe_socks", &"oil_drips"],
	&"lost": [&"porthole_helmet", &"detergent_cap_crown", &"softener_cape", &"hose_scarf", &"glowing_odd_socks", &"tumbling_socks"],
}
## The ten basic pieces, one creature each, no last creature (the old game shot them one by one).
const BASIC: Array[StringName] = [&"beanie", &"cap", &"top_hat", &"party_hat", &"bobble_hat", &"crown",
		&"scarf", &"apron", &"bow_tie", &"jumper"]
## The old line-up's last creature: its Collection's first hat, second clothes and Socks, but where the old
## theme file named its own.
const COMBO: Dictionary[StringName, Array] = {&"vegetables": [&"carrot_top_beanie", &"gardeners_apron", &"broccoli_fluff_socks"]}

## How many Looks scenes (and Trails) went on, and how many failed to load (read by the check case).
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
		places.append(COMBO.get(StringName(collection), [row[0], row[3], row[4]]))
	var colours: Array[Color] = (load(COLOURS) as CoopTuning).colours
	var n := places.size()
	for i in n:
		var avatar := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
		avatar.colour = colours[i % colours.size()]
		avatar.position = Vector3((float(n - 1) / 2.0 - float(i)) * GAP, 0.0, 0.0)
		avatar.rotation.y = deg_to_rad(TURN)
		$Row.add_child(avatar)
		for id: StringName in places[i]:
			var piece := Wardrobe.of(id)
			if piece != null and piece.slot == WardrobePiece.Slot.TRAIL:
				lay_trail(avatar, id)
			elif piece != null and piece.slot == WardrobePiece.Slot.SOCKS:
				wear_socks(avatar, id)
			else:
				wear(avatar, id)
	# The old camera stepped back for a longer row.
	var far := maxf(1.0, float(n) / 7.0)
	var cam := $Camera as Camera3D
	cam.position = Vector3(0.0, 2.6 * far, -10.8 * far)
	cam.look_at(Vector3(0.0, 0.9, 0.0))


## The old line-up's close-up of one piece (its --only): one creature in the second player colour,
## turned 25 degrees, wearing piece `id`, near the old camera for its slot (a Trail from the side, above,
## looking down the steps behind; Socks low at the feet).
func show_one(id: String) -> void:
	for c: Node in $Row.get_children():
		c.free()
	var avatar := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
	avatar.colour = (load(COLOURS) as CoopTuning).colours[1]
	avatar.rotation.y = deg_to_rad(-25.0)
	$Row.add_child(avatar)
	var piece := Wardrobe.of(StringName(id))
	var cam := $Camera as Camera3D
	if piece != null and piece.slot == WardrobePiece.Slot.TRAIL:
		lay_trail(avatar, StringName(id))
		cam.position = Vector3(2.4, 1.9, 0.3)
		cam.look_at(Vector3(-0.3, 0.1, 1.1))
	else:
		wear_socks(avatar, StringName(id))
		cam.position = Vector3(0.9, 0.55, -1.6)
		cam.look_at(Vector3(0.0, 0.12, 0.0))


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


## Puts Socks piece `id`'s pair on `avatar` as the Dresser does: its Looks under each foot, only that
## foot's sock (`sock_l`, `sock_r`) shown, at identity.
func wear_socks(avatar: AvatarLooks, id: StringName) -> void:
	var scene := load(LOOKS % id) as PackedScene
	if scene == null:
		failed += 1
		return
	var feet := avatar.feet()
	for i: int in feet.size():
		var pair := scene.instantiate() as Node3D
		feet[i].add_child(pair)
		var keep := &"sock_r" if i == 1 else &"sock_l"
		for m: Node in pair.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			mi.visible = mi.name == keep
			if mi.name == keep:
				mi.transform = Transform3D.IDENTITY
	dressed += 1


## Trail `id`'s meshes (assets/wardrobe/meshes/<id>_a.res, _b ...), scattered behind `avatar` as the old
## line-up laid them: nine steps alternating feet, each part kept a little over half the time, rising
## as they age, turned and sized at random (seeded, so every shot is the same).
func lay_trail(avatar: AvatarLooks, id: StringName) -> void:
	var meshes := trail_meshes(id)
	if meshes.is_empty():
		failed += 1
		return
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 3
	var root := Node3D.new()
	root.name = "Trail"
	avatar.add_child(root)
	for k in 9:
		for mesh: Mesh in meshes:
			if rnd.randf() < 0.45:
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			var side := 0.13 if k % 2 == 0 else -0.13
			mi.position = Vector3(side + rnd.randf_range(-0.08, 0.08), 0.02 + 0.03 * k * rnd.randf_range(0.3, 1.0),
					0.25 + 0.22 * k + rnd.randf_range(-0.05, 0.05))
			mi.rotation.y = rnd.randf_range(0.0, 6.3)
			mi.scale = Vector3.ONE * rnd.randf_range(0.8, 1.3)
			root.add_child(mi)
	dressed += 1


## Trail `id`'s mesh resources in order (_a, _b ...).
static func trail_meshes(id: StringName) -> Array[Mesh]:
	var out: Array[Mesh] = []
	for letter in "abcdefgh":
		var path := "%s%s_%s.res" % [MESHES, id, letter]
		if not ResourceLoader.exists(path):
			break
		out.append(load(path) as Mesh)
	return out
