## The Old Tree's voice numbers (core/132, docs/architecture/economy.md "The Old Tree talks"): when it senses a
## player near, greets them again, muses, calls into the house, and core/133's help (beats, the Stage's share,
## the idle spell's chances). The speaker's own numbers (earshot, level band, cooldown, unit size, reach) are on
## `game/voice/speakers/old_tree.tres`; the level its lines play at is here (`voice_db`, `call_db`). Every number is the old `data/tuning/old_tree.json`'s, a placeholder.
## The motion's numbers come with the tree's rework (Q2670).
class_name OldTreeTuning
extends Resource

## A player away from the tree this long greets it again on coming back.
@export_range(0.0, 600.0, 1.0, "suffix:s") var away_seconds := 45.0 # placeholder: the old old_tree.away_seconds
## Near this long since arriving or the last line, the tree muses.
@export_range(0.0, 600.0, 1.0, "suffix:s") var idle_seconds := 40.0 # placeholder: the old old_tree.idle_seconds
## A musing the tree could not say is looked for again this much later (the old 5 s).
@export_range(0.0, 60.0, 0.5, "suffix:s") var idle_retry := 5.0 # placeholder: the old OldTreeVoice's 5 s
## How often each machine looks at the moments.
@export_range(0.05, 2.0, 0.05, "suffix:s") var check_seconds := 0.25 # placeholder: the old old_tree.check_seconds
## A purchase near the tree is said within this long of it, or not at all (the old 5 s).
@export_range(0.0, 30.0, 0.5, "suffix:s") var bought_window := 5.0 # placeholder: the old OldTreeVoice's 5 s

## The level every line of the tree plays at: the old +12.5 dB, applied at playback as the old player's volume,
## so it clips only where the old clipped, up close (the lead's reading of Q2638 for a faithful port; the
## recordings are the old ones, unchanged).
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var voice_db := 12.5 # placeholder: the old old_tree.voice_db

@export_group("Calls")
## After the First wash's end, the wait before the first call into the house (Q1864, Q1865).
@export_range(0.0, 300.0, 1.0, "suffix:s") var call_first_delay := 20.0 # placeholder: the old old_tree.call_first_delay
## The random gap between two calls (the Host's clock).
@export var call_gap := Vector2(25.0, 55.0) # placeholder: the old old_tree.call_min, call_max
## A call's level (the old's own number, the same as `voice_db`).
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var call_db := 12.5 # placeholder: the old old_tree.call_db
## How far a call carries and is subtitled (no level band: it is heard from the laundry).
@export_range(1.0, 100.0, 0.5, "suffix:m") var call_reach := 16.0 # placeholder: the old old_tree.call_max_distance

@export_group("Help (core/133)")
## The least gap before a story beat skips the cooldown; a beat unheard this long lapses.
@export_range(0.0, 600.0, 1.0, "suffix:s") var beat_gap := 20.0 # placeholder: the old old_tree.beat_gap
@export_range(0.0, 600.0, 1.0, "suffix:s") var beat_hold := 120.0 # placeholder: the old old_tree.beat_hold
## A Fix's comment comes this long into the next Stage (a random time between), with this chance.
@export var beat_delay := Vector2(120.0, 420.0) # placeholder: the old old_tree.beat_delay_min, beat_delay_max
@export_range(0.0, 1.0, 0.05) var beat_chance := 0.75 # placeholder: the old old_tree.beat_chance
## Near this long with presents still waiting, the tree mentions them again (core/140's moment).
@export_range(0.0, 1200.0, 1.0, "suffix:s") var presents_nag_seconds := 240.0 # placeholder: the old old_tree.presents_nag_seconds
## The Stage bar's shares for stage_half, stage_most, stage_last.
@export var stage_thresholds := PackedFloat32Array([0.5, 0.8, 0.95]) # placeholder: the old old_tree.stage_thresholds
## The chance an idle spell is a grumble about the washer (only while it is broken), or a hint.
@export_range(0.0, 1.0, 0.05) var grumble_chance := 0.35 # placeholder: the old old_tree.grumble_chance
@export_range(0.0, 1.0, 0.05) var hint_chance := 0.35 # placeholder: the old old_tree.hint_chance
