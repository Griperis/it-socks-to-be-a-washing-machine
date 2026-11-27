## One keyframe of the day (core/160; the old day_cycle.gd KEYS): the light, the sky, the ambient and the lamps at
## one hour. DayLight eases between the keys around the shown hour, wrapping at 24. One `.tres` per key in
## `game/day/keys/` (listed at load: a new key is a dropped file). The nine keys are placeholders: the old table,
## until the designer sets them (Q2693).
class_name DayKey
extends Resource

## The hour (0 to 24) this key is at.
@export_range(0.0, 24.0, 0.05, "suffix:h") var hour := 12.0
## The light's colour: the sun's by day, the moon's by night.
@export var light_colour := Color(1.0, 0.93, 0.82)
## The light's energy; 0 hides it (at sunrise and sunset, where sun and moon swap).
@export_range(0.0, 8.0, 0.01) var light_energy := 2.4
## Which photo the sky shows: 0 day, 1 dusk, 2 night; fractions blend the neighbours.
@export_range(0.0, 2.0, 0.01) var sky_phase := 0.0
## The sky's brightness (it lights the ambient and the reflections too).
@export_range(0.0, 4.0, 0.01) var sky_energy := 0.9
## The ambient light's energy.
@export_range(0.0, 4.0, 0.01) var ambient := 0.75
## The lamps' brightness while they are on (core/161's lamp factor; 1 is a lamp's own).
@export_range(0.0, 4.0, 0.01) var lamps := 1.0
## 0 by day, 1 by night (the old window panes' darkening; nothing reads it since Q2709 dropped the night panes).
@export_range(0.0, 1.0, 0.01) var night := 0.0
