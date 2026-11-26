## The Achievements station's board (core/145), built from the Achievements folder at load (Q2337): one pillar per
## file, in a row of `columns` from this node, each showing whether this machine's profile has earned it. With no
## files the board stays empty and its note says so. It follows the profile: a change of the earned ones (a
## switch, a debug key, a tally reached) shows at once.
class_name AchievementBoard
extends Node3D

## One pillar.
@export var pillar: PackedScene
@export_range(1, 20, 1) var columns := 6
## How far apart the pillars stand along a row (x) and between rows (z).
@export var gap := Vector2(1.5, 2.0)

var _seen := -1


func _ready() -> void:
	var i := 0
	for a in Achievements.all():
		var p := pillar.instantiate() as AchievementPillar
		p.position = Vector3(float(i % columns) * gap.x, 0.0, floorf(float(i) / float(columns)) * gap.y)
		add_child(p)
		p.show_achievement(a, false)
		i += 1
	($EmptyNote as Node3D).visible = i == 0
	refresh()


func _process(_delta: float) -> void:
	var p := _profile()
	if p != null and hash(p.achievements.keys()) != _seen:
		refresh()


## Every pillar shows whether this machine's profile has earned its Achievement.
func refresh() -> void:
	var p := _profile()
	if p == null:
		return
	_seen = hash(p.achievements.keys())
	for pl in pillars():
		pl.set_earned(p.achievements.has(String(pl.achievement.id)))


## Every pillar, in the list's order.
func pillars() -> Array[AchievementPillar]:
	var out: Array[AchievementPillar] = []
	for c in get_children():
		if c is AchievementPillar:
			out.append(c as AchievementPillar)
	return out


func _profile() -> PlayerProfile:
	var achievements := Achievements.of(self)
	return achievements.current_profile() if achievements != null else Worlds.profile()
