## The game's credits and licences (the old data/credits.json, Q339, Q1520), shown by the Licence page
## at load: the game's own lines, then each work by section, then the licence links. Every file under
## `assets/` is covered by some entry (tests/menus_test.gd): add an entry when adding an asset.
class_name Credits
extends Resource

## The game's lines, the first shown larger ("It Socks", "A game by ...", "Built with Godot Engine").
@export var game_lines: PackedStringArray = []
@export var entries: Array[CreditEntry] = []
## The "Licences" links at the end: their words and addresses (alike in number).
@export var licence_names: PackedStringArray = []
@export var licence_links: PackedStringArray = []


## The sections in the order their first entry comes.
func sections() -> PackedStringArray:
	var out := PackedStringArray()
	for e in entries:
		if not out.has(e.section):
			out.append(e.section)
	return out


## The first entry that covers the asset at `path`, or null.
func entry_for(path: String) -> CreditEntry:
	for e in entries:
		if e.covers_file(path):
			return e
	return null
