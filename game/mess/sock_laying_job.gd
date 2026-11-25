## One laying of a SockGenerator from one seed, done a slice at a time or all at once (house/09,
## Q2542): plan() finds every area's places, then lay() lays the areas' Socks one by one and the trails,
## avoiding the boxes `before`. The work and the dice are the same however it is cut into slices, so
## the same seed always gives the same rows (SockGenerator.lay() runs it whole).
@tool
class_name SockLayingJob
extends RefCounted

var generator: SockGenerator
var seed := 0
## The rows laid so far (made by the first lay()).
var laying: SockLaying
## The Mess records, once records() is done (SockGenerator.records_of()).
var made: Dictionary = {}

## A Stage's laying (core/77, SockGenerator.records_for()): the Designs to lay, one Pair each, spread
## over the areas by their `pairs` (equal when all are 0), `high` of them on tops at least `high_over`
## over the floor; no trails. Empty `given`: the generator's own (every area's Pairs, the trails).
var given := PackedInt32Array()
var high := 0
var high_over := 0.0

var _areas: Array[SockArea] = []
## The passes of the laying in order: {"area": index, "pairs": Pairs (-1: the area's own), "high": bool}.
var _passes: Array[Dictionary] = []
var _trails: Array[SockTrail] = []
var _keep_out: Array[Array] = []
## Each area's places, made as plan() reaches it, dropped once its Socks are laid.
var _places: Array[SockPlaces] = []
## How many areas have all their places, how many are laid (the next one being laid while `_in_area`),
## how many trails are laid, and whether the laying is over.
var _planned := 0
var _laid_areas := 0
var _in_area := false
var _laid_trails := 0
var _done := false
## records(): the Pairs and Designs dealt (SockGenerator.deal()), the next row to restack and whether
## `made` is ready.
var _dealt: Array = []
var _restacked := 0
var _recorded := false


func _init(of: SockGenerator, with_seed: int, designs := PackedInt32Array(), high_pairs := 0, over := 0.0) -> void:
	generator = of
	seed = with_seed
	given = designs
	high = high_pairs
	high_over = over
	generator.collect(generator, _areas, _trails, _keep_out)
	if not given.is_empty():
		_trails.clear()
	_passes = _make_passes()


## The passes: each area's own Pairs, or the given Designs' Pairs shared out over the areas by their
## `pairs` (the remainder to the earlier areas), the high ones taken off the first areas.
func _make_passes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if given.is_empty():
		for i in _areas.size():
			out.append({"area": i, "pairs": -1, "high": false})
		return out
	var total := given.size()
	var weights: Array[int] = []
	var sum := 0
	for area in _areas:
		weights.append(area.pairs)
		sum += area.pairs
	if sum == 0:
		for i in weights.size():
			weights[i] = 1
		sum = weights.size()
	var shares: Array[int] = []
	var given_out := 0
	for w in weights:
		shares.append(total * w / sum)
		given_out += shares[-1]
	var k := 0
	while given_out < total and not shares.is_empty():
		shares[k % shares.size()] += 1
		given_out += 1
		k += 1
	var high_left := mini(high, total)
	for i in _areas.size():
		var up := mini(high_left, shares[i])
		high_left -= up
		if shares[i] - up > 0:
			out.append({"area": i, "pairs": shares[i] - up, "high": false})
		if up > 0:
			out.append({"area": i, "pairs": up, "high": true})
	return out


## How many Socks the laying asks for: every area's Pairs and every trail's Socks.
func asked() -> int:
	var n := 0
	for pass_ in _passes:
		n += (_areas[int(pass_["area"])].pairs if int(pass_["pairs"]) < 0 else int(pass_["pairs"])) * 2
	for trail in _trails:
		n += trail.socks
	return n


## How many Socks have been tried (laid or left out) so far.
func tried() -> int:
	return laying.tried() if laying != null else 0


## Finds the areas' places, area by area, while `clock` has room for one more unit (null: no limit).
## Returns whether all are found.
func plan(clock: SliceClock) -> bool:
	while _planned < _areas.size():
		if _places.size() == _planned:
			if not SliceClock.fits(clock, &"places", true):
				return false
			var level := generator.scan if generator.scan != null else generator.get_parent() as Node3D
			_places.append(SockPlaces.new(_areas[_planned], generator.tuning, level if level != null else generator,
					generator.washer, _keep_out, false))
		if not _places[_planned].step(clock):
			return false
		_planned += 1
	return true


## After plan(): lays the Socks, a try at a time (a trail at a time), avoiding `before` ([size,
## middle's transform] each; read by the first call), while `clock` has room. Returns whether all are
## laid; the generator's last_report then tells how it went.
func lay(before: Array[Array], clock: SliceClock) -> bool:
	if _done:
		return true
	if laying == null:
		if not SliceClock.fits(clock, &"laying", true):
			return false
		laying = SockLaying.new(generator.tuning, generator, before)
	while _laid_areas < _passes.size():
		if not SliceClock.fits(clock, &"try" if _in_area else &"area", not _in_area):
			return false
		var pass_ := _passes[_laid_areas]
		var index := int(pass_["area"])
		if not _in_area:
			laying.set_spacing(_areas[index].rules.spacing)
			laying.begin_area(_areas[index], _places[index], seed, int(pass_["pairs"]),
					high_over if pass_["high"] else -1.0, "high" if pass_["high"] else "")
			_in_area = true
		elif not laying.lay_try():
			_in_area = false
			_laid_areas += 1
			# The area's places go once no later pass is on the same area.
			if _laid_areas >= _passes.size() or int(_passes[_laid_areas]["area"]) != index:
				_places[index] = null
	laying.set_spacing(0.0)
	while _laid_trails < _trails.size():
		if not SliceClock.fits(clock, &"trail"):
			return false
		laying.lay_trail(_trails[_laid_trails], seed, _keep_out)
		_laid_trails += 1
	_done = true
	generator.last_report = {"asked": laying.asked, "laid": laying.rows.size(), "left_out": laying.left_out.duplicate(),
			"fails": laying.fails.duplicate(), "hidden_to_floor": laying.hidden_to_floor.duplicate()}
	return true


## After lay(): the Pairs dealt their Designs of `catalogue`, the Heaps restacked a few rows at a time,
## then the Mess records in `made` (SockGenerator.records_of(), cut into units), while `clock` has
## room. Returns whether `made` is ready.
func records(catalogue: DesignCatalogue, clock: SliceClock) -> bool:
	if _recorded:
		return true
	if _dealt.is_empty():
		if not SliceClock.fits(clock, &"deal", true):
			return false
		_dealt = generator.deal(laying, seed, catalogue) if given.is_empty() else generator.deal_given(laying, seed, given, catalogue)
		_restacked = 0
	while _restacked < laying.rows.size():
		_restacked = laying.restack_from(_dealt[2], _restacked, clock)
		if _restacked < laying.rows.size():
			return false
	if not SliceClock.fits(clock, &"records", true):
		return false
	made = generator.records_dealt(laying, _dealt)
	_recorded = true
	return true
