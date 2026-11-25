## The washer station (core/86, Q2337): the real `washer.tscn` on the zoo floor, its senses on, and pillars built
## from the game's data when it enters the tree: one per mood level 0..`zoo_levels` (core/87 makes them
## show), one per Stage of the house's plan and the Laundry day (the comment set the washer picks from),
## "From the run" (the overrides off), "Break it" / "Fix it" (a stand-in for core/72's `broken`), one
## per comment trigger (fired as the game does), and one per CUTSCENE trigger ("Play cutscene_fix_1": its lines
## played plainly on the Cutscene frame, core/88). A new trigger or Stage appears with no other change.
class_name WasherStation
extends Node3D

const PILLAR := preload("res://game/zoo/washer/washer_pillar.tscn")
const PLAN := preload("res://game/run/house_stage_plan.tres")
const TRIGGERS := "res://game/voice/triggers"

@export var washer: Washer
## The ground and the name; the pad is sized to what is built.
@export var pad: MeshInstance3D
@export var title: Label3D
## Pillars of a row, and the metres between pillars and rows.
@export var per_row := 7
@export var column_pitch := 1.4
@export var row_pitch := 1.6

var _built := false
## By what each does: "mood 3", "stage 2", "laundry_day", "run", "break", "fix", "trigger washer_stare",
## "cutscene cutscene_fix_1".
var pillars: Dictionary[String, WasherPillar] = {}


func _enter_tree() -> void:
	if _built or washer == null:
		return
	_built = true
	build()


func build() -> void:
	var holder := Node3D.new()
	holder.name = "Built"
	add_child(holder)
	var row := 0
	var levels := washer.tuning.zoo_levels if washer.tuning != null else 5
	for n in levels + 1:
		_pillar(holder, "mood %d" % n, "Mood %d" % n, Washer.ZOO_MOOD, {"level": n}, row, n)
	row += 1
	var stages := PLAN.size()
	for n in stages:
		_pillar(holder, "stage %d" % (n + 1), "Stage %d" % (n + 1), Washer.ZOO_STAGE, {"stage": n}, row, n)
	_pillar(holder, "laundry_day", "Laundry day", Washer.ZOO_STAGE, {"stage": stages}, row, stages)
	row += 1
	_pillar(holder, "run", "From the run", Washer.ZOO_STAGE, {"stage": -1}, row, 0)
	_pillar(holder, "break", "Break it", Washer.ZOO_BROKEN, {}, row, 1).flips_broken = true
	_pillar(holder, "fix", "Fix it", Washer.ZOO_BROKEN, {}, row, 2).flips_broken = true
	row += 1
	var triggers := _triggers()
	for n in triggers.size():
		_pillar(holder, "trigger %s" % triggers[n], "Fire %s" % triggers[n], Washer.TALK, {"trigger": String(triggers[n])}, row, n)
	row += 1
	var cutscenes := _triggers(VoiceTrigger.Kind.CUTSCENE)
	for n in cutscenes.size():
		_pillar(holder, "cutscene %s" % cutscenes[n], "Play %s" % cutscenes[n], Washer.ZOO_CUTSCENE, {"trigger": String(cutscenes[n])}, row, n)
	var depth := (row + 3) * row_pitch + 8.0
	var width := per_row * column_pitch + 4.0
	(pad.mesh as PlaneMesh).size = Vector2(width, depth)
	pad.position = Vector3(0.0, 0.005, 2.0 + (row * row_pitch) * 0.5)
	if title != null:
		title.position = Vector3(-width * 0.5 + 0.5, 2.0, -5.0)


func _pillar(parent: Node3D, key: String, words: String, verb: StringName, args: Dictionary, row: int, column: int) -> WasherPillar:
	var root := PILLAR.instantiate() as Node3D
	root.name = ("Pillar_%s" % key).replace(" ", "_")
	root.position = Vector3((column - (per_row - 1) * 0.5) * column_pitch, 0.0, 2.0 + row * row_pitch)
	(root.get_node(^"Label") as Label3D).text = words
	var part := root.get_node(^"Body/Press") as WasherPillar
	part.washer = washer
	part.verb = verb
	part.args = args
	part.title = words
	parent.add_child(root)
	pillars[key] = part
	return part


## Every trigger's id of `kind`, sorted (the folder is the list).
func _triggers(kind := VoiceTrigger.Kind.COMMENT) -> Array[StringName]:
	var out: Array[StringName] = []
	var dir := DirAccess.open(TRIGGERS)
	if dir == null:
		return out
	var files := dir.get_files()
	files.sort()
	for f in files:
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var t := load("%s/%s" % [TRIGGERS, name]) as VoiceTrigger
			if t != null and t.kind == kind:
				out.append(t.id)
	return out
