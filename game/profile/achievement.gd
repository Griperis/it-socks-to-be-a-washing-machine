## One Achievement (core/145, docs/architecture/wardrobe.md "Achievements"): a named badge a player earns in their
## own Profile when its condition is met. A designer adds one by dropping a `.tres` into
## `game/profile/achievements/`: the file's name is its id (the future Steam API name), and it shows in the zoo
## station and on the Profile page with no other change. Batch B's condition kind is a Lifetime tally reaching
## `at`; a later kind adds fields here and a branch in `Achievements.reached()`.
class_name Achievement
extends Resource

## Who earns it (Q1691): the team (Stage, Collection, Final wash and big Pair counts) or the player alone (skill,
## Hand-off and prank ones). Every batch B condition is a Lifetime tally, so TEAM.
enum Credit { TEAM, OWN }

## The longest id (Steam's API names).
const ID_MAX := 40

## Its id: the file's name, set when the folder is read (Achievements.all()). Lowercase a-z, 0-9 and `_`, at most
## 40, never renamed once live (a test checks every file).
var id: StringName = &""

## What the toast and the page show.
@export var title := ""
@export_multiline var description := ""
## Its picture; empty shows the shared placeholder (Q1698, AchievementTuning.placeholder_icon).
@export var icon: Texture2D
## Shown as "???" until earned (Q1693).
@export var hidden := false
@export var credit := Credit.TEAM
@export_group("Condition")
## The Lifetime tally (one of PlayerProfile.TALLIES) that must reach `at`.
@export var tally: StringName = &""
@export_range(1, 999999999, 1) var at := 1
@export_group("")
## The Wardrobe piece it gives, or none (Q1690).
@export var reward: WardrobePiece


## Whether `text` is an id Steam takes: 1 to ID_MAX of lowercase a-z, 0-9 and `_`.
static func is_id(text: String) -> bool:
	if text.is_empty() or text.length() > ID_MAX:
		return false
	for c in text:
		if not ((c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_"):
			return false
	return true


## The condition in words, for the zoo station ("pairs_shelved 1").
func condition_text() -> String:
	return "%s %d" % [tally, at] if tally != &"" else "(no condition)"
