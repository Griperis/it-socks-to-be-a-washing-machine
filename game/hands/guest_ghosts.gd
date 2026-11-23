## A Guest's own pick, drop, Throw and wheel, shown at once as looks-only guesses while the Host
## decides (coop/09; Q2220, Q2221, Q2473-Q2479; list 03 D, E, F, G). A child of the Player; the Player
## asks through it on a Guest and straight through the Hands on the Host or alone (where the answer is
## at once). Every ask carries a seq (Parts.next_seq()) and the Host's answer echoes it, so each guess
## knows its answer.
##
## - A pick: "pick" sounds at the click (Q2478), the ghost flies up from where the Sock lies (the
##   HeldView's) and the Mess holds its drawing back; granted, the ghost is the held item (D04), and a
##   Pair's moment starts then (Q2479); refused, it flies back to where the Sock is or to the winner's
##   Hands (F01-F03), silently for "gone" (F04). A second pick before the answer waits for it (Q2474).
## - A Throw or a drop: the item leaves the Hands at once on a ThrowGhost from the hand, "throw" and the
##   rumble at once (G01); granted, the ghost follows the Host's body to its rest (G03-G13); refused,
##   the ghost goes and the item is back in the Hands at once (Q2476).
## - The wheel turns at once and back silently on a refusal (Q2475).
## - No answer after `answer_timeout`: back as refused, with "refuse" (Q2477).
##
## Looks only (I2): nothing here writes the Hands or the Mess.
class_name GuestGhosts
extends Node

## The ghosts' numbers.
@export var tuning: GhostTuning = preload("res://game/hands/ghost_tuning.tres")

## The guesses waiting on an answer, by seq: {"kind": &"pick" | &"throw" | &"drop" | &"cycle",
## "sock": int, "age": seconds, "ghost": ThrowGhost or null}.
var _waiting: Dictionary[int, Dictionary] = {}
## A pick asked while another waited: its Sock, sent once the first is answered (Q2474), or -1.
var _queued := -1
## Seconds since this machine's last pick was granted (the grab interval as the Guest sees it, D06).
var _since_grant := INF
## The ghosts flying on after their answer, by Sock id.
var _flying: Dictionary[int, ThrowGhost] = {}
## How many guesses timed out (a test reads it).
var timed_out := 0

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


## Whether this machine guesses: a Guest (its Parts relay to the Host).
func active() -> bool:
	var h := _hands()
	return h != null and h.parts != null and not h.parts.is_host()


## Whether a pick waits on its answer.
func pick_waiting() -> bool:
	for w: Dictionary in _waiting.values():
		if StringName(w["kind"]) == &"pick":
			return true
	return false


## The ghost of a Throw or drop of Sock `sock` on this machine, or null.
func ghost_of(sock: int) -> ThrowGhost:
	var g: ThrowGhost = _flying.get(sock)
	if g != null and is_instance_valid(g) and not g.is_done():
		return g
	for w: Dictionary in _waiting.values():
		if int(w["sock"]) == sock and w.get("ghost") != null and is_instance_valid(w["ghost"]):
			return w["ghost"]
	return null


## The Guest picks Sock `sock` (the Player's own checks passed). Another pick waiting: this one waits.
func pick(sock: int) -> void:
	var h := _hands()
	if h == null:
		return
	if pick_waiting():
		_queued = sock
		return
	if _since_grant < h.tuning_of(_me()).grab_interval:
		return  # D06: sooner than the grab interval does nothing, as on the Host.
	var seq := h.parts.next_seq()
	_waiting[seq] = {"kind": &"pick", "sock": sock, "age": 0.0}
	Sounds.play(&"pick")
	h.mess.hold_back(sock, true)
	_view().ghost_pick(sock)
	h.pick(_me(), sock, seq)


## The Guest throws its active item along `dir` with `charge`. The ghost flies the launch the Host
## works out, from this machine's first-person hand, where the Host lets it go too (Hands.start_of(),
## Q2573, coop/13): the same body and numbers, so it flies the Host's arc.
func throw(dir: Vector3, charge: float) -> void:
	var h := _hands()
	var sock := _shown_active(h)
	if sock < 0:
		return
	var launch := h.launch_of(_me(), dir, charge)
	var seq := h.parts.next_seq()
	Sounds.play(&"throw")
	PadRumble.play(PadRumble.THROW)
	_let_go(h, sock, seq, &"throw", launch)
	h.throw(_me(), dir, charge, seq)


## The Guest drops its active item on `point` (`normal` its up).
func drop(point: Vector3, normal: Vector3) -> void:
	var h := _hands()
	var sock := _shown_active(h)
	if sock < 0:
		return
	var launch := h.drop_of(_me(), point)
	var seq := h.parts.next_seq()
	_let_go(h, sock, seq, &"drop", launch)
	h.drop(_me(), point, normal, seq)


## The Guest turns the wheel by `step`.
func cycle(step: int) -> void:
	var h := _hands()
	if h == null:
		return
	var seq := h.parts.next_seq()
	_waiting[seq] = {"kind": &"cycle", "sock": -1, "age": 0.0}
	_view().guess_cycle(step)
	h.cycle(_me(), step, seq)


## An answer reached this machine (the Player passes every one, before the sounds). Returns whether
## its click sound was already played by a guess (Hearing then plays only what the answer adds).
func answered(ev: Dictionary) -> bool:
	if int(ev.get("by", 0)) != _me() or not ev.has("seq"):
		return false
	var seq := int(ev["seq"])
	if not _waiting.has(seq):
		return false
	var w: Dictionary = _waiting[seq]
	_waiting.erase(seq)
	var ok := bool(ev.get("ok", false))
	var sock := int(w["sock"])
	var h := _hands()
	match StringName(w["kind"]):
		&"pick":
			if ok:
				_since_grant = 0.0
				_view().adopt_pick(sock)
				h.mess.hold_back(sock, false)
			else:
				_view().ghost_back(sock, tuning.fly_back_time, tuning.fly_back_arc)
			_send_queued()
			return true
		&"throw", &"drop":
			var ghost: ThrowGhost = w.get("ghost")
			if ok and ghost != null and is_instance_valid(ghost):
				ghost.answered = true
				_flying[sock] = ghost
			else:
				_undo_let_go(sock, ghost)
			if not ok:
				_view().show_item(sock)
			return StringName(w["kind"]) == &"throw"
		&"cycle":
			_view().clear_guess()
	return false


## A test's look: the guesses waiting, by seq.
func waiting() -> Dictionary[int, Dictionary]:
	return _waiting


func _physics_process(delta: float) -> void:
	_since_grant += delta
	if _waiting.is_empty() and _flying.is_empty():
		return
	if not active():
		_clear()
		return
	for seq: int in _waiting.keys():
		var w := _waiting[seq]
		w["age"] = float(w["age"]) + delta
		if float(w["age"]) < tuning.answer_timeout:
			continue
		# Q2477: no answer in time: back as refused, with "refuse".
		_waiting.erase(seq)
		timed_out += 1
		var sock := int(w["sock"])
		match StringName(w["kind"]):
			&"pick":
				Sounds.play(&"refuse")
				_view().ghost_back(sock, tuning.fly_back_time, tuning.fly_back_arc)
				_send_queued()
			&"throw", &"drop":
				Sounds.play(&"refuse")
				_undo_let_go(sock, w.get("ghost"))
				_view().show_item(sock)
			&"cycle":
				_view().clear_guess()
	for sock: int in _flying.keys():
		var g := _flying[sock]
		if g == null or not is_instance_valid(g) or g.is_done():
			_flying.erase(sock)


func _let_go(h: Hands, sock: int, seq: int, kind: StringName, launch: Dictionary) -> void:
	var view := _view()
	var hand: Variant = view.drawn_of(sock)
	view.hide_item(sock)
	h.mess.hold_back(sock, true)
	var ghost := ThrowGhost.make(h.mess, sock, launch, self, kind == &"drop")
	var ht := h.tuning_of(_me())
	ghost.grow_time = ht.let_go_grow
	if hand is Transform3D and ht.let_go_grow > 0.0:
		var size := SockDress.scale_of(h.mess.design_of(sock))
		ghost.grow_from = (hand as Transform3D).basis.get_scale().x / maxf(size, 0.001)
	ghost.settled.connect(_on_ghost_settled)
	_waiting[seq] = {"kind": kind, "sock": sock, "age": 0.0, "ghost": ghost}


func _undo_let_go(sock: int, ghost: Variant) -> void:
	if ghost != null and is_instance_valid(ghost):
		(ghost as ThrowGhost).settled.disconnect(_on_ghost_settled)
		(ghost as ThrowGhost).end()
	_flying.erase(sock)
	var h := _hands()
	if h != null:
		h.mess.hold_back(sock, false)


func _on_ghost_settled(sock: int) -> void:
	_flying.erase(sock)
	var h := _hands()
	if h != null:
		h.mess.hold_back(sock, false)


func _on_ghost_returned(sock: int) -> void:
	var h := _hands()
	if h != null and not _view().has_ghost(sock):
		h.mess.hold_back(sock, false)


## The pick that waited for the first answer goes up now, if the Guest's copy still allows it.
func _send_queued() -> void:
	var sock := _queued
	_queued = -1
	var h := _hands()
	if sock < 0 or h == null:
		return
	if h.pick_refusal(_me(), sock) in ["", Hands.SOON]:
		_since_grant = INF
		pick(sock)


## Every guess dropped (the session ended): ghosts gone, the Mess draws everything again.
func _clear() -> void:
	var h := _hands()
	for w: Dictionary in _waiting.values():
		var ghost: Variant = w.get("ghost")
		if ghost != null and is_instance_valid(ghost):
			(ghost as ThrowGhost).end()
		if h != null and int(w["sock"]) >= 0:
			h.mess.hold_back(int(w["sock"]), false)
	_waiting.clear()
	for g: ThrowGhost in _flying.values():
		if g != null and is_instance_valid(g):
			g.end()
	_flying.clear()
	_queued = -1
	if _view() != null:
		_view().clear_guesses()


## The active item as this machine shows it (a wheel guess included), or -1.
func _shown_active(h: Hands) -> int:
	if h == null:
		return -1
	var items := h.items_of(_me())
	var i := _view().shown_active() if _view() != null else h.active_index(_me())
	return items[i] if i >= 0 and i < items.size() and not _view().is_hidden(items[i]) else -1


func _hands() -> Hands:
	return _player.hands() if _player != null else null


func _view() -> HeldView:
	var view := _player.held_view() if _player != null else null
	if view != null and not view.ghost_returned.is_connected(_on_ghost_returned):
		view.ghost_returned.connect(_on_ghost_returned)
	return view


func _me() -> int:
	return _player.player_id() if _player != null else Parts.HOST
