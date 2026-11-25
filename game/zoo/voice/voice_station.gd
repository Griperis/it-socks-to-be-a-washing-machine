## The Voice station (core/85, Q2337): built from the VoiceBook when it enters the tree, so a line baked into a
## speaker's JSON is a new pillar with no other change. Per speaker a graybox stand-in (the washer's Looks
## contract) and a second behind a shut Door, to hear the muffle and see the subtitle stay; one pillar per line, in
## rows by speaker; one per comment trigger (fired as the game does: cooldown, chance); one per cutscene trigger
## (flat, no frame); a radio pillar for the music the duck rides on. Using a pillar (E, the player's own use) asks
## its stand-in's Part through Parts, so a line plays through the real path.
class_name VoiceStation
extends Node3D

const PILLAR := preload("res://game/zoo/voice/voice_pillar.tscn")
const DOOR := preload("res://game/entities/door/door.tscn")

## The ground and the name; the pad is sized to what is built.
@export var pad: MeshInstance3D
@export var title: Label3D

## Pillars of a row, and the metres between pillars and rows.
@export var per_row := 7
@export var column_pitch := 1.5
@export var row_pitch := 1.8

var _built := false
## Speaker id -> its stand-in, and the one behind the Door.
var stand_ins: Dictionary[StringName, VoiceStandIn] = {}
var behind_door: Dictionary[StringName, VoiceStandIn] = {}
## Line id (speaker/line), trigger id -> its pillar.
var line_pillars: Dictionary[String, VoicePillar] = {}
var comment_pillars: Dictionary[StringName, VoicePillar] = {}
var cutscene_pillars: Dictionary[StringName, VoicePillar] = {}
var behind_pillars: Dictionary[StringName, VoicePillar] = {}
var radio: VoicePillar


func _enter_tree() -> void:
	if _built or pad == null:
		return
	_built = true
	build()


func build() -> void:
	var book := Voices.book()
	var holder := Node3D.new()
	holder.name = "Built"
	add_child(holder)
	var first := book.speakers()
	# The speakers: stand-ins along the north end, each with one behind a shut Door.
	for i in first.size():
		var speaker := book.banks[first[i]].speaker
		stand_ins[speaker.id] = _stand_in(holder, "Speaker_%s" % speaker.id, speaker, Vector3(-3.0 + 6.0 * i, 0.0, -6.0))
		behind_door[speaker.id] = _stand_in(holder, "Behind_%s" % speaker.id, speaker, Vector3(6.0 + 3.0 * i, 0.0, -3.7))
		var door := DOOR.instantiate() as Node3D
		door.name = "Door_%s" % speaker.id
		door.position = Vector3(6.0 + 3.0 * i, 0.0, -2.5)
		holder.add_child(door)
	# The lines, a block of rows for each speaker.
	var z := 0.0
	var widest := 0
	for id in first:
		var lines := book.lines_of(id)
		for n in lines.size():
			@warning_ignore("integer_division")
			var at := Vector3(_column(n % per_row), 0.0, z + (n / per_row) * row_pitch)
			var pillar := _pillar(holder, "Line_%s_%s" % [id, lines[n].id], at, VoicePillar.Kind.LINE, stand_ins[id],
					lines[n].id, "Say %s" % lines[n].id, _line_text(lines[n]))
			line_pillars["%s/%s" % [id, lines[n].id]] = pillar
		@warning_ignore("integer_division")
		z += ((lines.size() + per_row - 1) / per_row) * row_pitch
		widest = maxi(widest, mini(lines.size(), per_row))
	# The comment triggers, then the cutscenes: the speaker's own.
	z += 0.4
	var comments: Array[VoiceTrigger] = []
	var cutscenes: Array[VoiceTrigger] = []
	for t in _triggers():
		(comments if t.kind == VoiceTrigger.Kind.COMMENT else cutscenes).append(t)
	for n in comments.size():
		var t := comments[n]
		var pillar := _pillar(holder, "Comment_%s" % t.id, Vector3(_column(n % per_row), 0.0, z + (n / per_row) * row_pitch),
				VoicePillar.Kind.COMMENT, stand_ins.get(t.speaker.id if t.speaker != null else &"", null), t.id,
				"Fire %s" % t.id, "%s\ncomment, chance %s%s\n%s" % [t.id, t.chance, ", ignores cooldown" if t.ignores_cooldown else "", t.note])
		comment_pillars[t.id] = pillar
	@warning_ignore("integer_division")
	z += ((comments.size() + per_row - 1) / per_row) * row_pitch
	for n in cutscenes.size():
		var t := cutscenes[n]
		var owner_id: StringName = t.speaker.id if t.speaker != null else first[0]
		var pillar := _pillar(holder, "Cutscene_%s" % t.id, Vector3(_column(n % per_row), 0.0, z + (n / per_row) * row_pitch),
				VoicePillar.Kind.CUTSCENE, stand_ins.get(owner_id, null), t.id, "Play %s" % t.id,
				"%s\ncutscene, flat, no frame" % t.id)
		cutscene_pillars[t.id] = pillar
	@warning_ignore("integer_division")
	z += ((cutscenes.size() + per_row - 1) / per_row) * row_pitch
	# The pillar for each speaker's first line through the Door; the radio.
	for i in first.size():
		var lines := book.lines_of(first[i])
		if lines.is_empty():
			continue
		behind_pillars[first[i]] = _pillar(holder, "BehindDoor_%s" % first[i], Vector3(6.0 + 3.0 * i, 0.0, -0.8),
				VoicePillar.Kind.LINE, behind_door[first[i]], lines[0].id, "Say %s behind the Door" % lines[0].id,
				"%s behind the shut Door\n(the voice is muffled, the subtitle stays)" % lines[0].id)
	radio = _pillar(holder, "Radio", Vector3(_column(per_row) + 0.2, 0.0, 2.0), VoicePillar.Kind.RADIO, null, &"radio", "Radio",
			"Radio\nmusic for the cutscene's duck")
	radio.hum = _hum()
	# The ground, from the north end to the last row, and the name over the corner.
	var depth := z + 11.0
	var width := maxi(widest, 1) * column_pitch + 8.0
	(pad.mesh as PlaneMesh).size = Vector2(width, depth)
	pad.position = Vector3(0.0, 0.005, -9.0 + depth * 0.5)
	var ground := get_node_or_null(^"Ground/Shape") as CollisionShape3D
	if ground != null:
		(ground.shape as BoxShape3D).size = Vector3(width, 0.2, depth)
		ground.position = Vector3(0.0, -0.1, pad.position.z)
	if title != null:
		title.position = Vector3(-width * 0.5 + 1.0, 2.0, -8.5)


## The x of column `n`, the columns centred on the station.
func _column(n: int) -> float:
	return (n - (per_row - 1) * 0.5) * column_pitch


func _stand_in(parent: Node3D, node_name: String, speaker: VoiceSpeaker, at: Vector3) -> VoiceStandIn:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	var looks := StandInLooks.new()
	looks.name = "Looks"
	looks.speaker = speaker
	root.add_child(looks)
	var part := VoiceStandIn.new()
	part.name = "Speaker"
	part.speaker = speaker
	part.looks = looks
	root.add_child(part)
	parent.add_child(root)
	return part


func _pillar(parent: Node3D, node_name: String, at: Vector3, kind: VoicePillar.Kind, who: VoiceStandIn, target: StringName,
		prompt: String, text: String) -> VoicePillar:
	var root := PILLAR.instantiate() as Node3D
	root.name = node_name
	root.position = at
	(root.get_node(^"Label") as Label3D).text = text
	var part := root.get_node(^"Body/Press") as VoicePillar
	part.kind = kind
	part.stand_in = who
	part.target = target
	part.title = prompt
	parent.add_child(root)
	return part


## What the label over a line's pillar says: its id, triggers and sets, its takes and its marks.
func _line_text(line: VoiceLine) -> String:
	var triggers := PackedStringArray()
	for t in line.triggers:
		triggers.append(String(t.id))
	var marks := PackedStringArray(line.marks)
	if triggers.is_empty():
		marks.append("no trigger")
	if line.placeholder:
		marks.append("placeholder")
	var sets := "any set" if line.sets.is_empty() else "set %s" % ",".join(Array(line.sets).map(func(s: int) -> String: return str(s)))
	return "%s\n%s | %s\n%d take(s)%s" % [line.id, ", ".join(triggers) if not triggers.is_empty() else "-", sets,
			line.takes.size(), "\n" + ", ".join(marks) if not marks.is_empty() else ""]


## Every trigger file, sorted.
func _triggers() -> Array[VoiceTrigger]:
	var out: Array[VoiceTrigger] = []
	var dir := DirAccess.open("res://game/voice/triggers")
	if dir == null:
		return out
	var files := dir.get_files()
	files.sort()
	for f in files:
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var t := load("res://game/voice/triggers/" + name) as VoiceTrigger
			if t != null:
				out.append(t)
	return out


## A two-second chord that loops: the radio's music.
func _hum() -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	data.resize(rate * 2 * 2)
	for i in rate * 2:
		var t := float(i) / rate
		var v := 0.18 * (sin(TAU * 220.0 * t) + sin(TAU * 277.18 * t) + sin(TAU * 329.63 * t)) / 3.0
		data.encode_s16(i * 2, int(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = rate * 2
	return wav
