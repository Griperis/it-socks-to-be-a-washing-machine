## The Wardrobe's numbers (core/128): the swish, the steps that lay a Trail's marks, the name tag over a
## hat, the demo steps of a Trail's sample and a piece's preview. One `.tres` beside it, edited in the
## inspector; the old avatar.json and trail_effect.gd values.
class_name WardrobeTuning # placeholder: every number here is the old avatar.json / trail_effect.gd value until the designer sets them
extends Resource

@export_group("Swish")
## Of a SwishL / SwishR piece's full swing at a full waddle (avatar.json swish).
@export_range(0.0, 2.0, 0.05) var swish := 1.0
## How far behind the body's sway it swings, in radians.
@export_range(0.0, 3.2, 0.05, "suffix:rad") var swish_lag := 0.9
## Standing, the share of a full swing it sways (avatar.json swish_idle), and how fast.
@export_range(0.0, 1.0, 0.05) var swish_idle := 0.3
@export_range(0.0, 10.0, 0.1, "suffix:rad/s") var swish_idle_speed := 1.8

@export_group("Steps")
## A step lays a Trail's mark only over this waddle (avatar.gd).
@export_range(0.0, 1.0, 0.05) var step_walk := 0.3
## How far over the floor a mark is laid.
@export_range(0.0, 0.1, 0.001, "suffix:m") var mark_lift := 0.006

@export_group("Name tag")
## How far over the hat's top the name tag floats (Q2462).
@export_range(0.0, 1.0, 0.01, "suffix:m") var tag_lift := 0.25

@export_group("Demo")
## A Trail's sample beside a creature that does not walk (the Wardrobe's preview, the gift reveal, the
## zoo's stands): `demo_steps` steps `demo_stride` apart, `demo_x` to its side, left and right
## `demo_side` off that line in turn, a new one every `demo_time`, coming up from `demo_back` behind.
@export_range(0.0, 2.0, 0.01, "suffix:m") var demo_x := 0.3
@export_range(0.0, 0.5, 0.01, "suffix:m") var demo_side := 0.08
@export_range(0.05, 1.0, 0.01, "suffix:m") var demo_stride := 0.26
@export_range(0.0, 2.0, 0.05, "suffix:m") var demo_back := 0.7
@export_range(1, 20, 1) var demo_steps := 6
@export_range(0.05, 2.0, 0.05, "suffix:s") var demo_time := 0.35

@export_group("Preview")
## A piece's preview is this large at its largest side (the gift reveal's FIT).
@export_range(0.1, 3.0, 0.01, "suffix:m") var preview_fit := 0.62
