## One of the washer's two cutscene camera spots (`Shots/Wide`, `Shots/Close`): where the camera stands
## and looks (this node's transform, looking down its -Z) and its field of view. Moving a shot is moving
## the marker (Q2164: a placed prop's number is a field on it). The cutscene frame (core/88) reads it.
class_name WasherShot
extends Marker3D

@export_range(10.0, 120.0, 1.0, "suffix:deg") var fov := 60.0 # placeholder: the old RM wide shot fov
