## One X-ray of the local player (docs/architecture/x-rays.md "The shape"): its key, its clock, what it
## shows, its words and sounds; one per XRayAbility, made by the player's XRays. No Part and no
## Command: it decides nothing anybody else sees, and only reads what this machine has applied of the
## Hands, the Mess, the Cabinets and the Upgrades (behaviour list "Owning and using" line 6), so a
## Guest's X-ray uses the Guest's own copies and asks the Host nothing.
##
## The key (pressed, not an echo; keyboard or pad) comes through _unhandled_input, so a menu that takes
## the input blocks it. use(): not owned, the refusal "%s not bought" with `refuse`; owned but not
## usable() (on, cooling down, or nothing to show), nothing at all: no sound, no cooldown spent
## (line 4, Q2010); else the `Show` Timer starts for the duration stat, the HUD says the ability's
## on_text and on_sound plays flat for this player. The show's end plays off_sound and starts the
## `Cooldown` Timer for the cooldown stat. Both read the stats when they start (a Lingering or Recharge
## bought meanwhile counts from the next show). Not saved, not joined: a load or a join's snapshot
## (Parts.snapshot_loaded) starts it ready.
##
## What it shows: the active held item when it fits (MATES: a loose Sock; CABINET: a Sock or a Pair),
## with the All-Hands stat every fitting item held. targets() from them: MATES, the other Sock of each
## shown Design lying or flying in the Mess, held loose by a Teammate in any slot, or carried by a
## member of the group `sock_carriers` (the Cat, core/178); CABINET, the level's Cabinet that takes
## each, locked, sheeted or full. Each once. It is worked out again after an applied answer (any may
## move a Sock, a Hands slot or a Cabinet's Rows), not every frame.
class_name XRay
extends Node

## It turned on (true) or its show ended (false).
signal switched(on: bool)
## Its cooldown ended while it was usable (Q1988: one that ends with nothing to show gives nothing).
signal became_ready

## What its HUD icon shows.
enum State {
	## not owned: the icon hidden
	HIDDEN,
	ON,
	COOLDOWN,
	## owned, idle, something to show
	READY,
	## owned, idle, nothing to show
	GREYED,
}

## The refusal before the Upgrade is bought ("X-ray not bought").
const NOT_BOUGHT := "%s not bought"
## The group whose members draw a Sock no Hands hold (the Cat's mouth): drawn_sock(id) is non-null for one.
const CARRIERS := &"sock_carriers"
## A Timer is never started for less than this, in seconds.
const LEAST_TIME := 0.05

@export var ability: XRayAbility
@export var tuning: XRayTuning = preload("res://game/xray/xray_tuning.tres")

@onready var _show: Timer = $Show
@onready var _cooldown: Timer = $Cooldown

var _targets: Array = []
var _stale := true
var _listening: Parts = null


func _ready() -> void:
	_show.timeout.connect(_on_show_end)
	_cooldown.timeout.connect(_on_cooldown_end)


## Finds its level's Parts once they are there (a cheap look; the targets are not worked out here).
func _process(_delta: float) -> void:
	_bind()


func _unhandled_input(event: InputEvent) -> void:
	if ability == null or not InputMap.has_action(ability.action) or not event.is_action_pressed(ability.action):
		return
	var p := player()
	if p == null or p.input_blocked():
		return
	get_viewport().set_input_as_handled()
	use()


## Its player: the local Player it is under, or null.
func player() -> Player:
	var n := get_parent()
	while n != null and not (n is Player):
		n = n.get_parent()
	return n as Player


## Its player's id (who owns it), or the Host's with none.
func by() -> int:
	var p := player()
	return p.player_id() if p != null and p.is_inside_tree() else Parts.HOST


## The key: turns it on when it may, refuses it before the Upgrade, else does nothing.
func use() -> bool:
	var p := player()
	if p == null or ability == null:
		return false
	if not owned():
		p.say(NOT_BOUGHT % ability.short_name)
		return false
	if not usable():
		return false
	_show.start(maxf(show_seconds(), LEAST_TIME))
	p.notice(ability.on_text, p.hands_tuning.refusal_time)
	Sounds.play(ability.on_sound)
	switched.emit(true)
	return true


## Whether its player has bought it.
func owned() -> bool:
	var levels := _levels()
	return levels != null and ability != null and levels.value(ability.owned, by()) >= 1.0


## Whether its player has its All-Hands Upgrade.
func all_hands() -> bool:
	var levels := _levels()
	return levels != null and ability != null and levels.value(ability.all_hands, by()) >= 1.0


## How long a show lasts for its player now, in seconds.
func show_seconds() -> float:
	var levels := _levels()
	return levels.value(ability.duration, by()) if levels != null and ability != null else 0.0


## How long a cooldown lasts for its player now, in seconds.
func cooldown_seconds() -> float:
	var levels := _levels()
	return levels.value(ability.cooldown, by()) if levels != null and ability != null else 0.0


func is_on() -> bool:
	return _show != null and not _show.is_stopped()


func is_cooling() -> bool:
	return _cooldown != null and not _cooldown.is_stopped()


## Seconds of the show left (0 when off), and of the cooldown (0 when ready).
func show_left() -> float:
	return _show.time_left if is_on() else 0.0


func cooldown_left() -> float:
	return _cooldown.time_left if is_cooling() else 0.0


## Whether the key would turn it on now: owned, neither on nor cooling down, and something to show.
func usable() -> bool:
	return owned() and not is_on() and not is_cooling() and not targets().is_empty()


## What its icon shows now.
func state() -> State:
	if not owned():
		return State.HIDDEN
	if is_on():
		return State.ON
	if is_cooling():
		return State.COOLDOWN
	return State.READY if not targets().is_empty() else State.GREYED


## The held items it shows (Sock ids; a Pair by its lead): the active one when it fits, or with
## All-Hands every fitting one held.
func shown_items() -> PackedInt32Array:
	var out := PackedInt32Array()
	var h := _hands()
	if h == null or h.mess == null or ability == null:
		return out
	var me := by()
	if all_hands():
		for item in h.items_of(me):
			if _fits(h.mess, item):
				out.append(item)
	else:
		var item := h.active_of(me)
		if item >= 0 and _fits(h.mess, item):
			out.append(item)
	return out


## What it shows, each once: Mess Sock ids (MATES) or Cabinets (CABINET).
func targets() -> Array:
	_bind()
	if _stale:
		_stale = false
		_targets = _find_targets()
	return _targets


func _fits(mess: Mess, item: int) -> bool:
	if ability.shows == XRayAbility.Shows.MATES:
		return mess.mate_of(item) < 0  # a loose Sock, not a Pair (XR:128-131)
	return true  # a loose Sock or a Pair (CX:39-41)


func _find_targets() -> Array:
	var out: Array = []
	var h := _hands()
	if h == null or h.mess == null or ability == null:
		return out
	var shown := shown_items()
	if shown.is_empty():
		return out
	if ability.shows == XRayAbility.Shows.CABINET:
		for node in get_tree().get_nodes_in_group(Cabinet.GROUP):
			var cabinet := node as Cabinet
			if cabinet == null or cabinet.parts != h.parts or out.has(cabinet):
				continue
			for item in shown:
				if cabinet.takes(item):
					out.append(cabinet)
					break
		return out
	var mess := h.mess
	var wanted := {}
	var mine := {}
	for item in shown:
		wanted[mess.designs[item]] = true
		mine[item] = true
	var theirs := {}
	var me := str(h.key_of(by()))
	var peer := str(by())
	for key: Variant in h.held:
		if str(key) != me and str(key) != peer:
			for s in (h.held[key] as PackedInt32Array):
				theirs[s] = true
	for sock in mess.count():
		if not wanted.has(mess.designs[sock]) or mine.has(sock):
			continue
		if _mate_shows(mess, sock, theirs):
			out.append(sock)
	return out


## Whether Sock `sock` (a mate of a shown Design) shows: lying or flying, held loose by a Teammate, or
## carried by a member of CARRIERS. One in a vacuum's Tank or shelved shows nothing, as the old.
func _mate_shows(mess: Mess, sock: int, theirs: Dictionary) -> bool:
	match mess.state_of(sock):
		Mess.State.LYING, Mess.State.FLYING:
			return true
		Mess.State.HELD:
			if theirs.has(sock):
				return mess.mate_of(sock) < 0
			for carrier in get_tree().get_nodes_in_group(CARRIERS):
				if carrier.has_method(&"drawn_sock") and carrier.call(&"drawn_sock", sock) != null:
					return true
	return false


## Its player's Hands (the level's), or null.
func _hands() -> Hands:
	var p := player()
	return p.hands() if p != null and p.is_inside_tree() else null


## The Upgrades its player's levels are read from: the ones of the Hands' level, or null.
func _levels() -> Upgrades:
	var h := _hands()
	if h == null or h.parts == null:
		return null
	var u := Upgrades.of(h)
	return u if u != null and u.parts == h.parts else null


## Hears the level's applied answers once its Hands are found: each makes the targets stale.
func _bind() -> void:
	var h := _hands()
	var p := h.parts if h != null else null
	if p == _listening:
		return
	if _listening != null and is_instance_valid(_listening) and _listening.applied.is_connected(_on_applied):
		_listening.applied.disconnect(_on_applied)
		_listening.snapshot_loaded.disconnect(_start_ready)
	_listening = p
	_stale = true
	if p != null:
		p.applied.connect(_on_applied)
		p.snapshot_loaded.connect(_start_ready)


func _on_applied(_ev: Dictionary) -> void:
	_stale = true


## A save loaded or a join's snapshot (line 5): neither on nor cooling down, ready at once.
func _start_ready() -> void:
	_stale = true
	var was_on := is_on()
	_show.stop()
	_cooldown.stop()
	if was_on:
		switched.emit(false)


func _on_show_end() -> void:
	Sounds.play(ability.off_sound)
	_cooldown.start(maxf(cooldown_seconds(), LEAST_TIME))
	switched.emit(false)


func _on_cooldown_end() -> void:
	if usable():
		became_ready.emit()
