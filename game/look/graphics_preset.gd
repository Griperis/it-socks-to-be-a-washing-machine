## One graphics preset of the old game (data/tuning/graphics.json): low, medium or high, one .tres each in
## game/look/presets/. The project setting `it_socks/graphics/preset` names the one in force until the Options menu
## exists. Only the settings the zoo's picture has today are here (the mirror's came with assets/07); the old preset's mess and
## lamp lines come with their features.
class_name GraphicsPreset
extends Resource

## The project setting that names the preset, and the preset used when it is missing or unknown.
const SETTING := "it_socks/graphics/preset"
const DEFAULT_NAME := "high"
const FOLDER := "res://game/look/presets/"

## 0 off, 2 or 4 samples (Viewport.MSAA).
@export_enum("Off:0", "2x:1", "4x:2", "8x:3") var msaa := 2 # placeholder: the old preset, until the designer tunes it
## Screen-space anti-aliasing on top of MSAA.
@export var fxaa := true # placeholder: the old preset
## 1.0 renders at the window's size; below that the 3D picture is upscaled (the old FSR 1 or bilinear).
@export_range(0.25, 1.0, 0.05) var render_scale := 1.0 # placeholder: the old preset
@export var fsr := false # placeholder: the old preset
## The sun's shadow cascades: 1, 2 or 4.
@export_enum("1:1", "2:2", "4:4") var sun_splits := 4 # placeholder: the old preset
## Soft shadow edges (the old blur 1.5) or hard ones (no blur, the cheapest).
@export var sun_soft := true # placeholder: the old preset
@export var sun_atlas := 4096 # placeholder: the old preset
@export_range(1.0, 100.0, 0.5, "suffix:m") var sun_distance := 18.0 # placeholder: the old preset
@export var ssao := true # placeholder: the old preset
@export var glow := true # placeholder: the old preset
## The sky's reflection map size (32 to 2048).
@export_range(32, 2048, 1) var sky_radiance := 256 # placeholder: the old preset
## The colour grade and the vignette (the old "amb_grade").
@export var grade := true # placeholder: the old preset
## The wall mirrors draw a real reflection; off, their glass shows a soft gradient (assets/07, Q2505).
@export var mirror := true # placeholder: the old preset (Low: off)


## The preset the project setting names; "high" when it names none that exists.
static func chosen() -> GraphicsPreset:
	return named(String(ProjectSettings.get_setting(SETTING, DEFAULT_NAME)))


## The preset of that name ("low", "medium", "high"), or "high" for an unknown name.
static func named(preset_name: String) -> GraphicsPreset:
	var path := FOLDER + preset_name + ".tres"
	if not ResourceLoader.exists(path):
		path = FOLDER + DEFAULT_NAME + ".tres"
	return load(path) as GraphicsPreset
