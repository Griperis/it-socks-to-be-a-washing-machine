## How a Design is drawn (assets/01): which shape model and cloth its Collection has, which sock ball
## its Pair rolls into, and how the sock shader fits each model. The old game's numbers
## (data/designs.json `shape` and `fabric`, SockBall.cuff(), SockLook.SHAPE_CLOTH); edited in the
## inspector (sock_looks.tres beside it).
class_name SockLookTable
extends Resource

## The shape models (looks_<shape>.tscn) and the sock balls (looks_ball_<cuff>.tscn) there are.
@export var shapes: Array[StringName] = [&"ankle", &"crew", &"tube", &"chunky"]
@export var cuffs: Array[StringName] = []
## Each Collection's shape and cloth, by its id; a Collection missing here is DEFAULT_SHAPE, cotton.
@export var collection_shapes: Dictionary[StringName, StringName] = {}
@export var collection_fabrics: Dictionary[StringName, StringName] = {}
## Each Collection's sock ball (the folded cuff keeps its Collection's shape); else DEFAULT_CUFF.
@export var collection_cuffs: Dictionary[StringName, StringName] = {}
## The sock shader's fit per shape, and the one fit of every ball.
@export var fits: Dictionary[StringName, SockClothFit] = {}
@export var ball_fit: SockClothFit
## The ball radius `ball_fit.cloth_size` is for (the old SockBall.RADIUS).
@export var ball_radius := 0.06
## The print atlas's cells across and down (the old prints.json `cols`, `rows`).
@export var prints_grid := Vector2(12, 18)

const DEFAULT_SHAPE := &"crew"
const DEFAULT_CUFF := &"crew_plain"
## The cloths in the order the sock shader numbers them (its `fabric` uniform).
const FABRICS: Array[StringName] = [&"cotton", &"wool", &"fuzzy"]


## The shape model a Design's Sock is drawn with.
func shape_of(design: SockDesign) -> StringName:
	if design == null:
		return DEFAULT_SHAPE
	return collection_shapes.get(design.collection, DEFAULT_SHAPE)


## The sock ball a Design's Pair is drawn as.
func cuff_of(design: SockDesign) -> StringName:
	if design == null:
		return DEFAULT_CUFF
	return collection_cuffs.get(design.collection, DEFAULT_CUFF)


## The sock shader's `fabric` number of a Design's cloth.
func fabric_of(design: SockDesign) -> int:
	if design == null:
		return 0
	return maxi(FABRICS.find(collection_fabrics.get(design.collection, &"cotton")), 0)


## The fit of a shape, or the crew's for one without.
func fit(shape: StringName) -> SockClothFit:
	var f: SockClothFit = fits.get(shape)
	if f == null:
		f = fits.get(DEFAULT_SHAPE)
	return f
