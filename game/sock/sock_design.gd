## One Sock Design: what a Sock looks like and how rare it is. A Sock's record in the Mess holds
## only its Design's id; everything else is read here. Converted once from the old game's
## data/designs.json (Q2248) and edited in the inspector from then on.
class_name SockDesign
extends Resource

enum Size { SMALL, MEDIUM, LARGE }
enum Rarity { COMMON, UNCOMMON, RARE }

## How big each Size is drawn (the old game's Design.size_scale()): Size only makes matching harder.
const SIZE_SCALES: Array[float] = [0.8, 1.0, 1.25]
## The letter a held Sock shows for its Size (H23).
const SIZE_LETTERS: Array[String] = ["S", "M", "L"]

@export var id := 0
@export var name := ""
@export var colour := Color.WHITE
## solid, dots, stripes, bands, checks or print.
@export var pattern := &"solid"
@export var size := Size.MEDIUM
@export var rarity := Rarity.COMMON
## The id of its Collection (simple, patterns, sport ...).
@export var collection := &"simple"
## Where the heel and toe patches are: none, all, top_toe or heel_toe.
@export var patches := &"none"
## The print's motif number, or -1 for none.
@export var motif := -1
## How a print is laid out (big, two, band, cuff), or empty.
@export var layout := &""
## A second print's colour (a fur coat's), transparent for none.
@export var colour3 := Color(0, 0, 0, 0)
## The coat print's motif number, or -1 for none.
@export var coat := -1
## What kind of motif a coat print carries (face), or empty.
@export var motif_kind := &""


## How big this Sock is drawn.
func size_scale() -> float:
	return SIZE_SCALES[size]


## Its Size as the letter the Hands show.
func size_letter() -> String:
	return SIZE_LETTERS[size]
