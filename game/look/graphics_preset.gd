## One graphics preset of the old game (data/tuning/graphics.json): low, medium or high, one .tres each in
## game/look/presets/. Options' Graphics row (the setting `graphics/preset`, core/58) names the one in force; "Auto"
## picks one from the GPU (Q354), and where the GPU cannot be told (headless, no adapter name) the project setting
## `it_socks/graphics/preset` names it. Only the settings the zoo's picture has today are here (the mirror's came with assets/07); the old preset's mess and
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


## The old GPU lists (data/tuning/graphics.json "detect"): a name containing one of these is that kind.
const SOFTWARE: Array[String] = ["llvmpipe", "lavapipe", "swiftshader", "microsoft basic render"]
const INTEGRATED: Array[String] = ["intel(r) uhd", "intel(r) hd", "iris", "radeon(tm) graphics", "radeon graphics",
		"vega 8", "vega 7", "680m", "780m", "890m", "apple m"]
const MID: Array[String] = ["mx1", "mx2", "mx3", "mx4", "mx5", "gt 1030", "gtx 9", "gtx 105", "gtx 1060", "gtx 1650",
		"rtx 2050", "rtx 3050", "rx 5500", "rx 6400", "rx 6500", "arc a3"]
const AUTO := "auto"
const NAMES: Array[String] = ["low", "medium", "high"]


## The preset in force: Options' choice, or Auto's.
static func chosen() -> GraphicsPreset:
	return named(chosen_name())


## The name of the preset in force ("low", "medium", "high").
static func chosen_name() -> String:
	var picked := Settings.get_string(Settings.GRAPHICS_PRESET)
	return picked if NAMES.has(picked) else auto_name()


## Auto's pick for this machine's GPU (Q354): a software renderer or an integrated GPU Low; a
## mid-range discrete name Medium; another discrete GPU High; unknown, the project setting's.
static func auto_name() -> String:
	return for_adapter(RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_type())


static func for_adapter(adapter: String, type: int) -> String:
	var n := adapter.to_lower()
	if type == RenderingDevice.DEVICE_TYPE_CPU or _matches(n, SOFTWARE):
		return "low"
	if type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or _matches(n, INTEGRATED):
		return "low"
	if _matches(n, MID):
		return "medium"
	if type == RenderingDevice.DEVICE_TYPE_DISCRETE_GPU:
		return "high"
	var fallback := String(ProjectSettings.get_setting(SETTING, DEFAULT_NAME))
	return fallback if NAMES.has(fallback) else DEFAULT_NAME


## Whether SSAO is on now: the setting's Off or On, else the preset's own.
static func ssao_on(p: GraphicsPreset) -> bool:
	var s := Settings.get_int(Settings.SSAO)
	return p.ssao if s < 0 else s > 0


static func _matches(adapter: String, patterns: Array[String]) -> bool:
	if adapter == "":
		return false
	for p in patterns:
		if adapter.contains(p):
			return true
	return false


## The preset of that name ("low", "medium", "high"), or "high" for an unknown name.
static func named(preset_name: String) -> GraphicsPreset:
	var path := FOLDER + preset_name + ".tres"
	if not ResourceLoader.exists(path):
		path = FOLDER + DEFAULT_NAME + ".tres"
	return load(path) as GraphicsPreset
