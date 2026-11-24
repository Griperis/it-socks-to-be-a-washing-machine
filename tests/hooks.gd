## What this game adds to the test runner (kit/docs/TESTING.md "The game's hooks").
extends RefCounted

## The scene a "world": true case gets. The project's main scene is the zoo now, so the kit's
## placeholder main scene is named here until the game has a real start.
const WORLD := "res://main/main.tscn"


## Between cases, after the runner's own resets: no game link left, the settings and the sounds back
## to a fresh start.
static func scrub(tree: SceneTree) -> void:
	# core/62: a game link a case made (a title's, a test's) goes with its session; a level's own goes
	# with its level.
	for node in tree.get_nodes_in_group(GameLink.GROUP):
		var link := node as GameLink
		if link != null and not link.is_private() and link.get_parent() != null:
			link.get_parent().remove_child(link)
			link.free()
	Settings.autosave = false
	Settings.reset_to_defaults()
	Sounds.reset()
	PadRumble.reset()
	# coop/12: every Host in a test listens on a free port, so parallel runs never clash.
	Session.free_port = true
	# core/58: saves go to a fresh in-memory store, the Worlds under a fresh profile, no title line.
	Save.reset()
	Worlds.reset()
