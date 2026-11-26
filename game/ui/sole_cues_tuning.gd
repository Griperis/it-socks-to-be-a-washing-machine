## The numbers of the Sole cues (core/131; the old data/tuning/sole_mates.json and hand_off.json glow_*):
## how long a Teammate's mate outline lingers out of sight, the match's glow on your own Sock, how the
## outline draws. One .tres beside it (sole_cues_tuning.tres), edited in the inspector.
class_name SoleCuesTuning
extends Resource

@export_group("Outline")
## How long a Teammate's outline stays after it leaves line of sight, so a pole or a door edge passing
## does not flicker it.
@export_range(0.0, 2.0, 0.01, "suffix:s") var los_linger := 0.15 # placeholder: the old sole_mates.json los_linger
## The outline, this many times as wide as the crosshair's (as wide as a Ping's, Q1130).
@export_range(0.5, 6.0, 0.1) var outline_width := 2.2 # placeholder: the old Pings.OUTLINE_WIDTH
## The outline's render priority: after the aim's outline.
@export_range(-128, 120, 1) var outline_priority := 110 # placeholder: the ping's, after aim.tres's 100
## How high over a Teammate's feet the line of sight aims when their whole body is outlined (Sole Hands).
@export_range(0.0, 2.0, 0.05, "suffix:m") var hands_lift := 0.9 # placeholder: the old sole_mates_view.gd 0.9

@export_group("Match")
## How long your own matching Sock glows when a match starts, and how bright it is at its peak (0..1).
@export_range(0.05, 5.0, 0.05, "suffix:s") var glow_seconds := 1.2 # placeholder: the old hand_off.json glow_seconds
@export_range(0.0, 1.0, 0.05) var glow_strength := 0.6 # placeholder: the old hand_off.json glow_strength

@export_group("Arrows")
## Where on a Teammate's body (a share of their standing height) Mate Radar's arrow points.
@export_range(0.0, 1.0, 0.05) var body_share := 0.6 # placeholder: the old teammate_news_installer.gd 0.6
## The hint arrows' priority of one (a Ping's is 1).
@export var arrow_priority := 0 # placeholder: the old arrows had no priority
