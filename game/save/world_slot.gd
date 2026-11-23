## The World a level plays, handed to the level when it loads (never a static path another class
## reads, as the old Saves.save_path was): its slot and file, its record, the saved Parts' state ({}
## for a New Game) and the profile it is saved under. Made by Worlds.pick_solo() / pick_host().
class_name WorldSlot
extends RefCounted

## "solo", "coop1" .. "coop5".
var slot := ""
## Its file in the SaveStore: `worlds/<player id>/<slot>.json`.
var file := ""
var record := WorldRecord.new()
## Every saved Part's state by id, and each one's version (Parts.load_save()); {} for a New Game.
var parts := {}
var versions := {}
## No save yet: the level starts as built.
var is_new := true
## Played with Guests welcome (Host), or alone.
var hosting := false
## The player this World is kept under.
var profile: PlayerProfile


## The words of the loading screen for this World (the old M:209-211; "Loading the house...", Q2579).
func loading_heading() -> String:
	return "The washer bursts open..." if is_new else "Loading the house..."
