## The Stages station's list of a StagePlan, built from the data at load (Q2337): a label per Stage
## lying on the ground (its number, title, floor, fewest Pairs, its Part's name), its Part's Looks
## lying beside it when the Part has one (core/79). A new Stage or Part shows with no other change.
class_name StagePlanBoard
extends Node3D

const LABEL := preload("res://game/zoo/zoo_label.tscn")
## The space between two Stages' rows, and where a Part's Looks lie from its row's label.
const ROW_STEP := 0.6
const LOOKS_AT := Vector3(-0.6, 0.0, 0.0)

## The plan it lists.
@export var plan: StagePlan


func _ready() -> void:
	if plan == null:
		return
	for i in plan.size():
		var s := plan.stage(i)
		var row := Vector3(0.0, 0.0, i * ROW_STEP)
		var label := LABEL.instantiate() as Label3D
		label.name = "Stage%d" % (i + 1)
		var part_name := s.part.name if s.part != null else "none"
		label.text = "Stage %d: %s   floor %d   %d Pairs   Part: %s%s" % [i + 1, s.title, s.floor, s.pairs, part_name,
				"   counts only its own Cabinets" if s.counts_only_own else ""]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.position = row + Vector3(0.0, 0.01, 0.0)
		add_child(label)
		if s.part != null and s.part.looks != null:
			var looks := s.part.looks.instantiate() as Node3D
			looks.name = "Part%d" % (i + 1)
			looks.position = row + LOOKS_AT
			add_child(looks)
