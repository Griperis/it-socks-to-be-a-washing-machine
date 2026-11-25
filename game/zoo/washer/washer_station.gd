## The washer station (core/86, Q2337): the real `washer.tscn` on the zoo floor, its senses on, and pillars built
## from the game's data when it enters the tree: one per mood level 0..`zoo_levels` (core/87 makes them
## show), one per Stage of the house's plan and the Laundry day (the comment set the washer picks from),
## "From the run" (any comment set), "Break it" / "Fix it" (the First wash breaks it in the house), one
## per comment trigger (fired as the game does), and one per CUTSCENE trigger ("Play cutscene_fix_1": its lines
## played plainly on the Cutscene frame, core/88). A new trigger or Stage appears with no other change. The
## switches are Commands of the station's run stand-in (`run`, a WasherRun the washer reads as its run, core/107);
## the trigger pillars ask the washer's own `talk`.
class_name WasherStation
extends Node3D

const PILLAR := preload("res://game/zoo/washer/washer_pillar.tscn")
const TRIGGERS := "res://game/voice/triggers"

@export var washer: Washer
@export var run: WasherRun
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
	if _built or washer == null or run == null:
		return
	_built = true
	build()


func build() -> void:
	var holder := Node3D.new()
	holder.name = "Built"
	add_child(holder)
	var row := 0
	for n in run.part_total() + 1:
		_pillar(holder, "mood %d" % n, "Mood %d" % n, run, WasherRun.MOOD, {"level": n}, row, n)
	row += 1
	var stages := run.plan.size() if run.plan != null else 0
	for n in stages:
		_pillar(holder, "stage %d" % (n + 1), "Stage %d" % (n + 1), run, WasherRun.STAGE, {"stage": n}, row, n)
	_pillar(holder, "laundry_day", "Laundry day", run, WasherRun.STAGE, {"stage": stages}, row, stages)
	row += 1
	_pillar(holder, "run", "From the run", run, WasherRun.STAGE, {"stage": -1}, row, 0)
	_pillar(holder, "break", "Break it", run, WasherRun.BROKEN, {}, row, 1).flips_broken = true
	_pillar(holder, "fix", "Fix it", run, WasherRun.BROKEN, {}, row, 2).flips_broken = true
	row += 1
	var triggers := _triggers()
	for n in triggers.size():
		_pillar(holder, "trigger %s" % triggers[n], "Fire %s" % triggers[n], washer, Washer.TALK, {"trigger": String(triggers[n])}, row, n)
	row += 1
	var cutscenes := _triggers(VoiceTrigger.Kind.CUTSCENE)
	for n in cutscenes.size():
		_pillar(holder, "cutscene %s" % cutscenes[n], "Play %s" % cutscenes[n], run, WasherRun.CUTSCENE, {"trigger": String(cutscenes[n])}, row, n)
	var depth := (row + 3) * row_pitch + 8.0
	var width := per_row * column_pitch + 4.0
	(pad.mesh as PlaneMesh).size = Vector2(width, depth)
	pad.position = Vector3(0.0, 0.005, 2.0 + (row * row_pitch) * 0.5)
	if title != null:
		title.position = Vector3(-width * 0.5 + 0.5, 2.0, -5.0)


func _pillar(parent: Node3D, key: String, words: String, asks: Part, verb: StringName, args: Dictionary, row: int, column: int) -> WasherPillar:
	var root := PILLAR.instantiate() as Node3D
	root.name = ("Pillar_%s" % key).replace(" ", "_")
	root.position = Vector3((column - (per_row - 1) * 0.5) * column_pitch, 0.0, 2.0 + row * row_pitch)
	(root.get_node(^"Label") as Label3D).text = words
	var part := root.get_node(^"Body/Press") as WasherPillar
	part.asks = asks
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
