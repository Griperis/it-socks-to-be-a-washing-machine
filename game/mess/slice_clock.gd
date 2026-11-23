## The clock of work done a slice per frame (house/09, Q2542): before each unit of work (a floor cell,
## a Sock, a restacked row ...) the work asks room(kind), which says no when the longest unit of that
## kind timed so far (twice over) would end past the slice's end. So a slice stops before it would run
## over, not after. The first unit of a slice always has room (the work always moves on). @tool: the
## generator's editor preview reaches it.
@tool
class_name SliceClock
extends RefCounted

## A kind of unit not timed yet is guessed to take this long (µs).
const FIRST_GUESS := 6000
## A unit is let start only when this many times the longest of its kind still fits: a unit may run
## longer than any of its kind before (the cache cold, the machine busy).
const HEADROOM := 2
## It also keeps at least this much to spare after the longest of its kind (µs): a tiny unit (a floor
## cell) gets 3 ms, for the frame's own jitter (another thread or process taking the core a while).
const SPARE := 3000
## Each unit of a kind lets the longest so far fade by this much, so one unit stalled once (the core
## taken a while) slows its kind for a few dozen units, not for good.
const FADE := 0.97

## When the slice ends (Time.get_ticks_usec()).
var until := 0
## The longest unit of each kind timed so far, fading (µs), kept from slice to slice.
var longest: Dictionary[StringName, int] = {}
var _last := 0
var _last_kind := &""
var _units := 0


## A new slice that ends at `end` (Time.get_ticks_usec()).
func start(end: int) -> void:
	until = end
	_last = Time.get_ticks_usec()
	_last_kind = &""
	_units = 0


## Before a unit of `kind`: whether it fits in what is left of the slice. The time since the last call
## is the last unit's (with whatever ran between). An `alone` unit (one that grows from use to use: a
## generator's laying set up, its Pairs dealt, its records) only ever starts a slice.
func room(kind: StringName, alone := false) -> bool:
	var now := Time.get_ticks_usec()
	if _last_kind != &"":
		longest[_last_kind] = maxi(int(int(longest.get(_last_kind, 0)) * FADE), now - _last)
	_last = now
	_last_kind = &""
	var need := int(longest.get(kind, FIRST_GUESS))
	if _units > 0 and (alone or now + maxi(need * HEADROOM, need + SPARE) > until):
		return false
	_last_kind = kind
	_units += 1
	return true


## Whether `clock` (null: no limit) has room for a unit of `kind` (room()).
static func fits(clock: SliceClock, kind: StringName, alone := false) -> bool:
	return clock == null or clock.room(kind, alone)
