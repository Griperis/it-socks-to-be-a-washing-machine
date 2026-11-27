## The house's day (core/160, Q2693; docs/architecture/day-and-exterior.md "How it is authored"): its length, the
## sun's path and the moon, the lamps' hours and the basement's fill, the old `day.json` and `day_cycle.gd` numbers.
## Edited in the inspector (day_tuning.tres beside it). Azimuths are degrees from east (+X) through south (+Z); north
## is -Z.
class_name DayTuning
extends Resource

## A whole day (24 in-game hours) lasts this many real minutes.
@export_range(0.05, 240.0, 0.05, "suffix:min") var length_minutes := 20.0 # placeholder: the designer's number (the old day.json length_minutes)
## The hour a New Game starts at.
@export_range(0.0, 24.0, 0.25, "suffix:h") var start_hour := 9.0 # placeholder: the designer's number (the old day.json start_hour)
## The sun is up from this hour, in the east ...
@export_range(0.0, 24.0, 0.25, "suffix:h") var sunrise := 6.0 # placeholder: the designer's number (the old day_cycle.gd SUNRISE)
## ... to this one, in the south-west (`sunset_azimuth`).
@export_range(0.0, 24.0, 0.25, "suffix:h") var sunset := 20.0 # placeholder: the designer's number (the old day_cycle.gd SUNSET)
## The sun's highest elevation, kept low so warm patches fall through the windows.
@export_range(0.0, 90.0, 0.5, "suffix:deg") var sun_max_elevation := 28.0 # placeholder: the designer's number (the old day_cycle.gd SUN_MAX_ELEVATION)
## The sun's bearing at sunset, from east through south: the evening sun still finds the south windows.
@export_range(0.0, 360.0, 1.0, "suffix:deg") var sunset_azimuth := 150.0 # placeholder: the designer's number (the old day_cycle.gd SUNSET_AZIMUTH)
## The moon stands still all night, this high ...
@export_range(0.0, 90.0, 0.5, "suffix:deg") var moon_elevation := 40.0 # placeholder: the designer's number (the old day_cycle.gd MOON_ELEVATION)
## ... at this bearing from east through south (the south-east).
@export_range(0.0, 360.0, 1.0, "suffix:deg") var moon_azimuth := 60.0 # placeholder: the designer's number (the old day_cycle.gd MOON_AZIMUTH)
## The lamps switch on at this hour ...
@export_range(0.0, 24.0, 0.25, "suffix:h") var lamps_on := 19.5 # placeholder: the designer's number (the old day_cycle.gd LAMPS_ON)
## ... and off at this one.
@export_range(0.0, 24.0, 0.25, "suffix:h") var lamps_off := 7.0 # placeholder: the designer's number (the old day_cycle.gd LAMPS_OFF)
## The share of the sky's ambient that reaches the basement (0 none, 1 as upstairs).
@export_range(0.0, 1.0, 0.01) var basement_ambient := 0.35 # placeholder: the designer's number (the old day.json basement_ambient)
## The basement's warm fill colour.
@export var basement_tint := Color("#ffd4a0") # placeholder: the designer's number (the old day.json basement_tint)

@export_group("Technical")
## The Host syncs every machine's hour this often while Guests play.
@export_range(0.5, 120.0, 0.5, "suffix:s") var sync_every := 10.0
## The sun, the sky and the basement's fill follow the hour every this many frames (a sky change re-bakes it).
@export_range(1, 120, 1) var sky_every := 30 # the old room.gd SKY_EVERY
## The ambient and the lamps follow every this many frames.
@export_range(1, 60, 1) var light_every := 6 # the old room.gd LIGHT_EVERY
## The least change of the sky's phase or energy worth a re-bake.
@export_range(0.0, 0.1, 0.001) var sky_step := 0.005 # the old room.gd SKY_STEP
@export_group("")


## Whether the sun is up at `hour`.
func is_day(hour: float) -> bool:
	var h := fposmod(hour, 24.0)
	return h >= sunrise and h <= sunset


## Whether the lamps are switched on at `hour`: from `lamps_on` to `lamps_off` the next morning.
func lamps_lit(hour: float) -> bool:
	var h := fposmod(hour, 24.0)
	return h >= lamps_on or h < lamps_off


## The unit direction towards the sun at `hour`, or towards the moon by night (the old DayCycle.sample()).
func to_light(hour: float) -> Vector3:
	var h := fposmod(hour, 24.0)
	var elevation := deg_to_rad(moon_elevation)
	var azimuth := deg_to_rad(moon_azimuth)
	if is_day(h):
		var f := (h - sunrise) / maxf(sunset - sunrise, 0.001)
		elevation = deg_to_rad(sun_max_elevation) * sin(PI * f)
		azimuth = deg_to_rad(sunset_azimuth) * f
	return Vector3(cos(elevation) * cos(azimuth), sin(elevation), cos(elevation) * sin(azimuth))
