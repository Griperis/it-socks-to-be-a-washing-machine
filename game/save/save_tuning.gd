## The saves' numbers (docs/architecture/saves.md): one .tres beside it, edited in the inspector.
class_name SaveTuning
extends Resource

## How soon after a change the World is saved (Q2555: within 2 s), in seconds.
@export_range(0.5, 60.0, 0.5, "suffix:s") var autosave_seconds := 2.0 # placeholder: the old number (Q2555), until the designer tunes it
## How many co-op Worlds there may be (the old 5, Q1647, Q2554).
@export_range(1, 20, 1) var coop_slots := 5 # placeholder: the old number (Q1647, Q2554)
## How long the HUD line of a save that could not be written shows, in seconds (Q2556).
@export_range(0.5, 10.0, 0.5, "suffix:s") var failed_line_seconds := 4.0 # placeholder: the designer's number (Q2556)
