## What this game adds to the test runner (kit/docs/TESTING.md "The game's hooks").
extends RefCounted

## The scene a "world": true case gets. The project's main scene is the zoo now, so the kit's
## placeholder main scene is named here until the game has a real start.
const WORLD := "res://main/main.tscn"


## Between cases, after the runner's own resets: the settings and the sounds back to a fresh start.
static func scrub(_tree: SceneTree) -> void:
	Settings.autosave = false
	Settings.reset_to_defaults()
	Sounds.reset()
	PadRumble.reset()
	# coop/12: every Host in a test listens on a free port, so parallel runs never clash.
	Session.free_port = true
