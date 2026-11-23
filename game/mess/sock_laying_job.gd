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

var _areas: Array[SockArea] = []
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


func _init(of: SockGenerator, with_seed: int) -> void:
	generator = of
	seed = with_seed
	generator.collect(generator, _areas, _trails, _keep_out)


## How many Socks the laying asks for: every area's Pairs and every trail's Socks.
func asked() -> int:
	var n := 0
	for area in _areas:
		n += area.pairs * 2
	for trail in _trails:
		n += trail.socks
	return n


## How many Socks have been tried (laid or left out) so far.
func tried() -> int:
	return laying.tried() if laying != null else 0


## Finds the areas' places, area by area, until all are found or the clock (Time.get_ticks_usec())
## passes `until` (below 0: no limit). Returns whether all are found.
func plan(until: int) -> bool:
	while _planned < _areas.size():
		if _places.size() == _planned:
			var level := generator.scan if generator.scan != null else generator.get_parent() as Node3D
			_places.append(SockPlaces.new(_areas[_planned], generator.tuning, level if level != null else generator,
					generator.washer, _keep_out, false))
		if not _places[_planned].step(until):
			return false
		_planned += 1
		if until >= 0 and Time.get_ticks_usec() >= until:
			return _planned >= _areas.size()
	return true


## After plan(): lays the Socks, a Sock at a time (a trail at a time), avoiding `before` ([size,
## middle's transform] each; read by the first call), until all are laid or the clock passes `until`.
## Returns whether all are laid; the generator's last_report then tells how it went.
func lay(before: Array[Array], until: int) -> bool:
	if _done:
		return true
	if laying == null:
		laying = SockLaying.new(generator.tuning, generator, before)
	while _laid_areas < _areas.size():
		if not _in_area:
			laying.set_spacing(_areas[_laid_areas].rules.spacing)
			laying.begin_area(_areas[_laid_areas], _places[_laid_areas], seed)
			_in_area = true
		elif not laying.lay_next():
			_in_area = false
			_places[_laid_areas] = null
			_laid_areas += 1
			continue
		if until >= 0 and Time.get_ticks_usec() >= until:
			return false
	laying.set_spacing(0.0)
	while _laid_trails < _trails.size():
		laying.lay_trail(_trails[_laid_trails], seed, _keep_out)
		_laid_trails += 1
		if until >= 0 and Time.get_ticks_usec() >= until and _laid_trails < _trails.size():
			return false
	_done = true
	generator.last_report = {"asked": laying.asked, "laid": laying.rows.size(), "left_out": laying.left_out.duplicate(),
			"fails": laying.fails.duplicate(), "hidden_to_floor": laying.hidden_to_floor.duplicate()}
	return true


## After lay(): the Pairs dealt their Designs of `catalogue`, the Heaps restacked a slice at a time,
## then the Mess records in `made` (SockGenerator.records_of(), cut into slices), until done or the
## clock passes `until`. Returns whether `made` is ready.
func records(catalogue: DesignCatalogue, until: int) -> bool:
	if _recorded:
		return true
	if _dealt.is_empty():
		_dealt = generator.deal(laying, seed, catalogue)
		_restacked = 0
		if until >= 0 and Time.get_ticks_usec() >= until:
			return false
	while _restacked < laying.rows.size():
		_restacked = laying.restack_from(_dealt[2], _restacked, until)
		if _restacked < laying.rows.size():
			return false
	made = generator.records_dealt(laying, _dealt)
	_recorded = true
	return true
