## The washing machine's numbers that are not the speaker's (docs/architecture/washer.md "Numbers"): what
## its senses notice, how it glows, how it looks broken, how its drum spins in the washes. Every one is a
## placeholder, as in the old tuning; the speaker's own (cooldown, hearing, tails) are
## `game/voice/speakers/washer.tres`. `washer_tuning.tres`.
class_name WasherTuning
extends Resource

@export_group("Senses")
## A look at the machine for this long, from within `stare_range` and `stare_degrees` of its middle, asks for a comment.
@export_range(0.1, 30.0, 0.1, "suffix:s") var stare_seconds := 4.0 # placeholder: the old TV stare_seconds
@export_range(0.5, 50.0, 0.5, "suffix:m") var stare_range := 8.0 # placeholder: the old TV stare_range
@export_range(1.0, 90.0, 0.5, "suffix:deg") var stare_degrees := 12.0 # placeholder: the old TV stare_degrees
## The middle of the machine the look aims at, above its foot.
@export_range(0.0, 2.0, 0.05, "suffix:m") var stare_up := 0.5 # placeholder: the old TV stare_up
## Nobody has shelved a Pair for this long: an idle comment is asked (checked once a second).
@export_range(1.0, 600.0, 1.0, "suffix:s") var idle_seconds := 60.0 # placeholder: the old TV idle_seconds
## A thrown thing that lands within this of it (on the floor plane) asks for a "hit" comment.
@export_range(0.1, 10.0, 0.1, "suffix:m") var hit_radius := 1.4 # placeholder: the old TV hit_radius

@export_group("Drum light")
## The lining's glow while the machine is silent.
@export var glow_idle_colour := Color(0.9, 0.75, 0.5) # placeholder: the old TV glow.idle
@export_range(0.0, 8.0, 0.05) var glow_idle_energy := 0.6 # placeholder: the old TV glow.idle
## The light inside the drum, a share of the glow's energy, and how far it reaches (the drum only).
@export_range(0.0, 4.0, 0.05) var light_energy := 0.6 # placeholder: the old TV light
@export_range(0.05, 3.0, 0.05, "suffix:m") var light_range := 0.45 # placeholder: the old TV light_range
## The shown glow eases to the wanted one at this rate a second.
@export_range(0.5, 40.0, 0.5) var glow_ease := 6.0 # placeholder: the old washer_face.gd glow lerp
## At repair 0 the glow and the light are dimmed to this share, and flicker this deep (core/87).
@export_range(0.0, 1.0, 0.05) var repair_dim := 0.3 # placeholder: the old TV repair_dim
@export_range(0.0, 1.0, 0.05) var repair_flicker := 0.8 # placeholder: the old TV repair_flicker
@export_range(0.01, 1.0, 0.01, "suffix:s") var flicker_step := 0.07 # placeholder: the old TV flicker step

@export_group("Body")
## The talking bob and the rumble run at their own pace; the bob is weighted by the acting's wiggle.
@export_range(0.1, 3.0, 0.05) var talk_speed := 1.0 # placeholder: the old MF talk loop
@export_range(0.1, 3.0, 0.05) var rumble_speed := 1.0 # placeholder: the old MF rumble loop
## The acting's angry share from which the body rumbles instead of bobbing.
@export_range(0.0, 1.0, 0.05) var rumble_from := 0.5 # placeholder: the old WF rumble choice

@export_group("Broken")
@export var sparks_min := 6 # placeholder: the old TB sparks
@export var sparks_max := 40 # placeholder: the old TB sparks
@export var burst_slowest := 2.4 # placeholder: the old TB burst gap
@export var burst_fastest := 0.5 # placeholder: the old TB burst gap
@export var smoke_min := 0.8 # placeholder: the old TB smoke
@export var smoke_max := 4.0 # placeholder: the old TB smoke
@export var buzz_db_min := -22.0 # placeholder: the old TB buzz
@export var buzz_db_max := -6.0 # placeholder: the old TB buzz
@export var cutscene_calm := 0.15 # placeholder: the old TB cutscene_calm
## How many levels the zoo's mood pillars offer (0 calm to this the angriest).
@export_range(1, 12, 1) var zoo_levels := 5 # placeholder: the old five Parts

@export_group("Washes")
@export var wash_spin := 0.8 # placeholder: the old TW wash_spin (turns a second)
@export var after_spin := 0.12 # placeholder: the old TW after_spin
## The cutscene's length when it has no voice, by level (cutscene_1 to _6).
@export var no_voice_seconds: PackedFloat32Array = PackedFloat32Array([5.0, 5.5, 6.5, 7.5, 8.5, 10.0]) # placeholder: the old TR seconds
## How the machine looks in each cutscene (core/88 and core/87 read them).
@export var cutscene_looks: Array[WasherCutsceneLook] = []


## The look of cutscene `trigger`, or null.
func cutscene_look(trigger: StringName) -> WasherCutsceneLook:
	for l in cutscene_looks:
		if l != null and l.trigger == trigger:
			return l
	return null
