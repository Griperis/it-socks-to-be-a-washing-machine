## One pillar of the Achievements station (core/145): an Achievement's title, condition, reward and whether this
## machine's profile has earned it (a gold top, else a grey one), its reward's preview on top (Wardrobe.preview).
class_name AchievementPillar
extends Node3D

## The Achievement it shows (show_achievement()).
var achievement: Achievement = null
## Whether it shows it earned.
var earned := false


## Shows `a`, earned or not.
func show_achievement(a: Achievement, is_earned: bool) -> void:
	if achievement != a:
		achievement = a
		name = "Pillar_%s" % a.id
		var piece := Achievements.reward_id(a)
		if piece != &"":
			($RewardPoint as Node3D).add_child(Wardrobe.preview(piece))
	set_earned(is_earned)


## Shows it earned or not.
func set_earned(is_earned: bool) -> void:
	earned = is_earned
	var a := achievement
	var piece := Achievements.reward_id(a)
	($Label as Label3D).text = "%s%s\n%s\nreward: %s\n%s" % [a.title, " (hidden)" if a.hidden else "", a.condition_text(),
			Wardrobe.piece_name(piece) if piece != &"" else "none", "EARNED" if is_earned else "not earned"]
	($EarnedTop as Node3D).visible = is_earned
	($Top as Node3D).visible = not is_earned
