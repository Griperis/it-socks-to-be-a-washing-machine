## The profile file's numbers (docs/architecture/wardrobe.md "The Profile file"): one .tres beside it
## (profile_tuning.tres), edited in the inspector.
class_name ProfileTuning
extends Resource

## The profile file is written at most this often, however many tallies moved.
@export_range(0.1, 60.0, 0.1, "suffix:s") var save_every := 2.0 # placeholder: the designer's save gap (the old wrote on each Pair)
