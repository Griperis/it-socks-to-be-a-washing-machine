## The in-game hour (core/160, Q2693; docs/architecture/day-and-exterior.md "The shape"): the house's 20-minute
## day as decided state. `hour` is the hour as of the Host's last answer; every machine shows `shown_hour()`, that
## hour run on by the frames since (24 hours in `length_minutes` real minutes, wrapping past midnight). The day runs
## while the level runs and stops while the game pauses, as the old.
##
## Verbs, the Host's only (no Guest verb: nothing a player does changes the hour): `start` (a New Game: the hour is
## `start_hour`, asked as the level's Parts bind; a loaded World's save writes over it) and `sync` (the hour is the
## shown hour, asked when a Guest comes into the house and every `sync_every` seconds while Guests play, so every
## machine's hour stays the Host's). A save and a late Guest's snapshot carry the shown hour, to the frame.
class_name Day
extends Part

## Emitted on every machine when the hour was written (an answer, a load, a snapshot), not as it runs on:
## `now` is true when the state arrived whole (bind, a load, a late Guest).
signal hour_set(now: bool)

const START := &"start"
const SYNC := &"sync"
const HOURS := 24.0

@export var tuning: DayTuning

@export_group("State")
## The hour (0 to 24) as of the Host's last answer.
@export var hour := 9.0
@export_group("")

## How many times faster than the tuning's day the hour runs on (1; the zoo's speed switch sets it on every
## machine through its own answer). Looks only: never decided state.
var speed := 1.0

## Seconds of this node's frames since `hour` was written.
var _since := 0.0
## Seconds until the Host's next sync.
var _sync_in := 0.0
var _session: Session = null
## The Host's start is asked once, at the first bind.
var _armed := false


func _ready() -> void:
	if tuning == null:
		tuning = DayTuning.new()
	_sync_in = tuning.sync_every


## How many in-game hours one real second is, at this speed.
func rate() -> float:
	return HOURS / maxf(tuning.length_minutes * 60.0, 0.001) * speed


## The hour this machine shows now (0 to 24): `hour` run on since it was written.
func shown_hour() -> float:
	return fposmod(hour + _since * rate(), HOURS)


func _process(delta: float) -> void:
	_since += delta
	if parts == null or not parts.is_host() or multiplayer.get_peers().is_empty():
		return
	_sync_in -= delta
	if _sync_in <= 0.0:
		sync()


## The Host: every machine's hour becomes the shown hour now.
func sync() -> void:
	_sync_in = tuning.sync_every
	if parts != null and parts.is_host():
		parts.ask(Command.new(SYNC, Parts.HOST, id, {}))


func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	match cmd.kind:
		START:
			return grant({"hour": tuning.start_hour})
		SYNC:
			return grant({"hour": shown_hour()})
	return refuse("wrong")


## The shown hour: a save and a late Guest keep the hour to the frame.
func whole_state() -> Dictionary:
	return {"hour": shown_hour()}


func _show(now: bool) -> void:
	_since = 0.0
	if parts != null and not _armed:
		_armed = true
		parts.bound.connect(_on_bound, CONNECT_ONE_SHOT)
	hour_set.emit(now)


## The level's Parts are bound: the Host starts the day (a loaded World's save then writes over it) and syncs a
## Guest that comes into the house.
func _on_bound() -> void:
	if not parts.is_host():
		return
	parts.ask(Command.new(START, Parts.HOST, id, {}))
	var runtime := LevelRuntime.of(self)
	_session = runtime.session if runtime != null else null
	if _session != null and not _session.house_changed.is_connected(_on_house_changed):
		_session.house_changed.connect(_on_house_changed)


func _on_house_changed(peer: int) -> void:
	if _session != null and _session.in_house(peer):
		sync()


func _exit_tree() -> void:
	if _session != null and is_instance_valid(_session) and _session.house_changed.is_connected(_on_house_changed):
		_session.house_changed.disconnect(_on_house_changed)
	_session = null
