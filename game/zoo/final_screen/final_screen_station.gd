## The Final screen station (core/95, Q2337): the real Final screen and pillars that open it on a made-up record
## drawn from the catalogue at load (every Collection's Designs, rare ones included): 1, 2 and 4 players, a
## record where a player left (no column, their Pairs in the totals) and a long name. A new Design or Collection
## shows in the Pairs with no other change. Continue closes the screen here (core/97 makes it go to the Lobby).
class_name FinalScreenStation
extends Node3D

const PILLAR := preload("res://game/zoo/final_screen/final_pillar.tscn")
const TUNING := preload("res://game/net/coop_tuning.tres")
const DESIGNS := preload("res://game/sock/designs.tres")
const LONG_NAME := "Bartholomew Fluffington the Third of Sockshire"

@export var screen: FinalScreen
## The ground and the name; the pad is sized to what is built.
@export var pad: MeshInstance3D
@export var title: Label3D
## The metres between pillars.
@export var pitch := 1.6

var _built := false
## By what each shows: "1 player", "2 players", "4 players", "left", "long name", "with an unlock".
var pillars: Dictionary[String, FinalPillar] = {}


func _enter_tree() -> void:
	if _built or screen == null:
		return
	_built = true
	build()


func build() -> void:
	var holder := Node3D.new()
	holder.name = "Built"
	add_child(holder)
	var shows: Array[Array] = [
		["1 player", "One player", [["You", 24]]],
		["2 players", "Two players", [["Mum", 30], ["Dad", 12]]],
		["4 players", "Four players", [["Ana", 30], ["Ben", 22], ["Cleo", 40], ["Dev", 5]]],
		["left", "A player left", [["Ana", 18], ["Ben", 26], ["Gone", 14, true]]],
		["long name", "A long name", [["Ana", 20], [LONG_NAME, 20]]],
		["with an unlock", "With an unlock", [["Ana", 18], ["Ben", 12]], [&"space", &"fruit"]],
	]
	for n in shows.size():
		var show: Array = shows[n]
		var root := PILLAR.instantiate() as Node3D
		root.name = "Pillar_%s" % String(show[0]).replace(" ", "_")
		root.position = Vector3((n - (shows.size() - 1) * 0.5) * pitch, 0.0, 2.0)
		(root.get_node(^"Label") as Label3D).text = show[1]
		var part := root.get_node(^"Body/Press") as FinalPillar
		part.screen = screen
		part.title = show[1]
		part.summary = made_up(show[2])
		if show.size() > 3:
			part.summary.unlocked.assign(show[3])
		holder.add_child(root)
		pillars[show[0]] = part
	screen.continue_pressed.connect(screen.close)
	var width := shows.size() * pitch + 4.0
	(pad.mesh as PlaneMesh).size = Vector2(width, 8.0)
	pad.position = Vector3(0.0, 0.005, 1.0)
	if title != null:
		title.position = Vector3(-width * 0.5 + 0.5, 2.0, -3.0)


## A summary of players `players` ([name, Pairs, left?] each, in order): their Pairs drawn from the catalogue with a
## fixed seed, every seventh one a rare Design, each paying a made-up number of Coins; a leaver stays in the record.
static func made_up(players: Array) -> FinalSummary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2631
	var rare: Array[int] = []
	var common: Array[int] = []
	for id in DESIGNS.size():
		var d := DESIGNS.design(id)
		if d != null:
			(rare if d.rarity >= SockDesign.Rarity.RARE else common).append(id)
	var shelved := []
	var listing: Array[Dictionary] = []
	for i in players.size():
		var spec: Array = players[i]
		var id := "p%d" % (i + 1)
		var paid := 0
		for k in int(spec[1]):
			var pool := rare if (k % 7 == 6 and not rare.is_empty()) else common
			var design := pool[rng.randi() % pool.size()]
			var coins := 1 + DESIGNS.design(design).rarity * 2
			shelved.append([id, design, coins])
			paid += coins
		var bonus := 40 if i == 0 and players.size() > 1 else 0
		listing.append({"id": id, "name": spec[0], "colour": TUNING.colour(i), "left": spec.size() > 2 and bool(spec[2]),
				"coins": paid + bonus})
	return FinalSummary.make(shelved, listing, 5025, 4)
