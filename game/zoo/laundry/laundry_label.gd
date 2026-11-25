## The Laundry station's label (core/93): the bins loaded over the bins in use, whether the last Fix is done, the
## ending's wait and the First wash (core/94). Looks only: it reads the station's LaundryDay.
class_name LaundryLabel
extends Label3D

@export var day: LaundryDay


func _process(_delta: float) -> void:
	if day == null:
		return
	var wait := "no wait"
	if day.wait_left() >= 0.0:
		wait = "wait %.1f s" % day.wait_left()
	elif day.final_started:
		wait = "Final wash asked"
	var first: String = ["pending", "playing", "done"][clampi(day.first_wash, 0, 2)]
	text = "Laundry day %d/%d loaded, last Fix %s, %s, First wash %s" % [day.loaded_bins, day.total(), "done" if day.fixed() else "not done", wait, first]
