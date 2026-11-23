## One third-party work (or one kind of the game's own assets) on the Licence page (the old
## data/credits.json entry): its section, what it is, who made it, where it comes from, its licence and
## the asset files it accounts for (`covers`: `*` matches any run of characters, slashes too).
class_name CreditEntry
extends Resource

@export var section := ""
@export var what := ""
@export var author := ""
@export var source := ""
@export var licence := ""
@export var covers: PackedStringArray = []


## Whether this entry accounts for the asset at `path` (relative to the project: "assets/ui/sock.svg").
func covers_file(path: String) -> bool:
	for pattern in covers:
		if path.match(pattern):
			return true
	return false
