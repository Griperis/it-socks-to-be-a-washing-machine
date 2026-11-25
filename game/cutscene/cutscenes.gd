## Which cutscene plays, as one Part of the level runtime (core/88, docs/architecture/run-ends.md "The Cutscene
## frame"): the script's path, the take of each of its voice lines (so every machine plays the same) and a
## serial that moves with every start. Host-authoritative: a sequence's own Command starts it (core/92's Fix,
## core/94's First wash, core/96's Final wash; the washer station's pillars in the zoo) by returning `start()`'s
## patch from its `decide()`; the Host's timeline (`end`) or its skip (`skip`) ends it, both Host-only verbs a
## Guest's Session drops. The end also ends every knockdown and drag (Q745, Q759).
##
## In the join snapshot: a late joiner during it holds black and spawns after it at the laundry (Q864). Not
## saved: a load mid-cutscene runs the sequence's own load rule. Its `CutscenePlayer` shows it on every machine.
class_name Cutscenes
extends Part

const GROUP := &"cutscenes"
## The Host's skip (Space, the pad's Start) and the Host's timeline's end: Host-only.
const SKIP := &"skip"
const END := &"end"

## Ends every knockdown at the end.
@export var knockdowns: Knockdowns
## Shows it on this machine (looks only).
@export var player: CutscenePlayer

@export_group("State")
## The CutsceneScript's path (or a CUTSCENE trigger's, played plainly); empty when none plays.
@export var playing := ""
## The take index of each of its voice lines, in order.
@export var takes := PackedInt32Array()
## Moves with every start.
@export var serial := 0
@export_group("")

## The Host's dice for the takes (no save keeps them).
var rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group(GROUP)


## The Cutscenes of the level `node` is in, or null.
static func of(node: Node) -> Cutscenes:
	var runtime := LevelRuntime.of(node)
	return runtime.get_node_or_null(^"Cutscenes") as Cutscenes if runtime != null else null


## Nothing is kept in a save.
func save_state() -> Dictionary:
	return {}


## A Guest asks nothing of it: the start is a sequence's answer, the end and the skip the Host's.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {}


## Whether a cutscene plays now (from the Host's start to its end).
func is_playing() -> bool:
	return not playing.is_empty()


## The script playing, or null.
func script_now() -> CutsceneScript:
	return CutsceneScript.at_path(playing, Washer.of_level(self))


## The trigger of the cutscene playing, or null (core/87 picks the washer's `cutscene_looks` by it).
func trigger() -> VoiceTrigger:
	var s := script_now()
	return s.voice if s != null else null


## The Host, inside a sequence's `decide()`: the grant that starts the script at `path` (a CutsceneScript,
## or a CUTSCENE trigger played plainly), with a take drawn for each of its lines. A refusal while one plays
## or for a path that is not a script. Reads only.
func start(path: String) -> Dictionary:
	if is_playing():
		return refuse("busy")
	var script := CutsceneScript.at_path(path, Washer.of_level(self))
	if script == null:
		return refuse("wrong")
	var picked := PackedInt32Array()
	if script.voice != null:
		for line in Voices.book().cutscene_lines(script.voice.id):
			picked.append(rng.randi() % maxi(line.takes.size(), 1))
	return grant({"playing": path, "takes": picked, "serial": serial + 1})


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		SKIP, END:
			if cmd.by != Parts.HOST:
				return refuse("wrong")
			if not is_playing():
				return refuse("already")
			# A timeline's end asked for a cutscene the skip already ended is late.
			if cmd.kind == END and int(cmd.args.get("serial", serial)) != serial:
				return refuse("already")
			return _ended()
	return refuse("wrong")


## The end: nothing plays, and every knockdown and drag is over.
func _ended() -> Dictionary:
	var ev := grant({"playing": "", "takes": PackedInt32Array()})
	if knockdowns != null and not (knockdowns.down.is_empty() and knockdowns.drags.is_empty()):
		ev["changes"][knockdowns.id] = {"down": {}, "drags": {}, "struggles": {}}
	return ev


func _show(now: bool) -> void:
	if player != null:
		player.follow(self, now)


## This machine decides alone now (its Host quit): a timeline held for the Host's end ends here.
func went_alone() -> void:
	if player != null:
		player.follow(self, false)
