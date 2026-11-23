## The dust sheet's pull (assets/07, the old locks.json). Edited in the inspector
## (dust_sheet_tuning.tres beside it); its colour is the material in dust_sheet.tscn.
class_name DustSheetTuning
extends Resource

## Seconds the sheet takes to be pulled off.
@export_range(0.05, 3.0, 0.05, "suffix:s") var pull_time := 0.5 # placeholder: the designer's number (ported from the old game, locks.json sheet_time)
## The fewest seconds from the unlock to the reveal's sound (it also waits for the pull).
@export_range(0.0, 3.0, 0.05, "suffix:s") var reveal_delay := 0.5 # placeholder: the designer's number (ported from the old game, locks.json reveal_delay)
