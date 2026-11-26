## One Stage of a run (docs/architecture/stages.md "How it is authored"): one floor, its title, the
## fewest Pairs it spawns, the Machine Part it earns, whether its bar counts only its own Cabinets and
## the washer's comment set while it is current. A fifth Stage is a fifth entry in the StagePlan.
class_name Stage
extends Resource

## Its name on the Stage bar and the World's row ("Basement", Q2622).
@export var title := ""
## The floor it opens (an index into HouseLights.floors); Stage 1's is open from the start.
@export_range(0, 16, 1) var floor := 0
## The fewest Pairs it spawns, at 25 Pairs per Drawer (scaled by the World's size, Q668).
@export_range(0, 1000, 1) var pairs := 50 # placeholder: the old T:stages pairs (balance round Q967)
## The Drawers one filled drawer of a Cabinet that unlocks with this Stage pays the team (core/124).
@export_range(0, 100, 1) var drawer_payout := 1 # placeholder: the old T:drawers payout_by_floor (basement 1, ground 1, first 2, attic 3)
## The Part its completion pops (core/79).
@export var part: MachinePartKind
## Its bar counts only its own Cabinets (the attic's, Q2623).
@export var counts_only_own := false
## The washing machine's comment set while it is current (docs/architecture/voice.md).
@export_range(0, 16, 1) var comment_set := 0
## The cutscene its Part's Fix plays (a CUTSCENE trigger: `cutscene_fix_1..4`, core/92). A Stage that names none
## opens its floor at once (the zoo's mini plan, tests); one that names one waits for the scene.
@export var fix_cutscene: VoiceTrigger
## The sequence that plays it (a `CutsceneScript` whose `voice` is `fix_cutscene`: the spit after a Fix that opens
## a floor, none after the last); none: the trigger's lines alone.
@export var fix_script: CutsceneScript
