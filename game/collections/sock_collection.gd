## One Collection of Socks (core/125, docs/architecture/gifts.md "Collections as data"): its name, colour,
## Cabinet name, icon and wrapping, edited in the inspector. One `.tres` per Collection beside this script;
## `Collections` lists them. Its Designs are in `designs.tres`, which name it by `id`.
class_name SockCollection
extends Resource

## The id the Designs name it by ("simple").
@export var id: StringName = &""
## The player's name for it ("Simple", "Patterns": the 2026-11-19 names, Q1954).
@export var name := ""
## The pairing moment's sparkles and ring (the old designs.json colour).
@export var colour := Color(1.0, 0.8, 0.4)
## Its Cabinet's name ("Simple cabinet"); an aimed drawer reads "<name> Drawer".
@export var cabinet_name := ""
## Its icon (assets/ui/<id>.svg).
@export var icon: Texture2D = null
@export_group("Wrapping")
## A present's paper, the pattern ink and the bow (the old wrapping.json). A transparent colour falls back
## to the old rule: paper is the colour lightened 35 %, ink darkened 25 %, the bow the colour itself.
@export var paper := Color(0.0, 0.0, 0.0, 0.0)
@export var ink := Color(0.0, 0.0, 0.0, 0.0)
@export var bow := Color(0.0, 0.0, 0.0, 0.0)
@export_group("")
## On only for the Lost Socks, whose home is the Drum of batch D (Q2675): a held-back Collection is in no
## encyclopedia page, start set, pool or present.
@export var held_back := false


## The paper colour, or the colour lightened 35 % when none is set.
func paper_colour() -> Color:
	return paper if paper.a > 0.0 else colour.lightened(0.35)


## The ink colour, or the colour darkened 25 % when none is set.
func ink_colour() -> Color:
	return ink if ink.a > 0.0 else colour.darkened(0.25)


## The bow colour, or the colour itself when none is set.
func bow_colour() -> Color:
	return bow if bow.a > 0.0 else colour
