## How one Session opens and closes this machine's peer: hosting, joining, the SceneMultiplayer signals it
## listens to, and closing back to a Host of one with every helper's state cleared.
class_name SessionPeer
extends RefCounted

var _s: Session


func _init(session: Session) -> void:
	_s = session


## Opens the game for Guests (Session.host()).
func host() -> Error:
	var s := _s
	_prepare()
	if Session.free_port:
		s.port = 0
	var err := s.transport.host(s.port, s.tuning.max_players * 2)
	if err != OK:
		Log.error("net", "cannot listen on port %d (%s)" % [s.port, error_string(err)])
		return err
	s._peer = s.transport.peer
	if s.transport.local_port() > 0:
		s.port = s.transport.local_port()
	_open_gate()
	s.multiplayer.peer_connected.connect(s._on_peer_joined)
	s.multiplayer.peer_disconnected.connect(s._on_peer_left)
	s._relay.listen(s.parts)
	if s.roster != null:
		s.parts.apply(s.roster.joined(s.profile.id, Roster.HOST, s.profile.name, s._gate.clamped_hands(s._gate.own_hands()), s._gate.own_said()))
	s._note("hosting on %s" % s.transport.describe(), false)
	return OK


## Joins the Host at `where` (Session.join()).
func join(where: String) -> Error:
	var s := _s
	_prepare()
	var err := s.transport.join(where)
	if err != OK:
		return err
	s._peer = s.transport.peer
	_open_gate()
	s.multiplayer.peer_authenticating.connect(s._on_authenticating)
	s.multiplayer.server_disconnected.connect(s._on_host_gone)
	s.multiplayer.connection_failed.connect(s._on_unreachable)
	s._relay.set_relay(s._relay.send_up)
	s._relay.listen(s.parts)
	s._joining = where
	s._give_up.start(s.tuning.join_timeout)
	return OK


## Leaves (Session.close()): a Host's Guests hear the Host quit; a Guest's machine is a Host of one again,
## with nobody in its Roster.
func close() -> void:
	var s := _s
	if s._peer == null:
		return
	s._peer.close()
	# Also when something wraps our peer (a test's delay): the machine is alone again either way.
	s.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	s._scene_multiplayer().auth_callback = Callable()
	var mp := s.multiplayer
	for pair: Array in [[mp.peer_connected, s._on_peer_joined], [mp.peer_disconnected, s._on_peer_left],
			[mp.peer_authenticating, s._on_authenticating], [mp.server_disconnected, s._on_host_gone],
			[mp.connection_failed, s._on_unreachable]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	s._relay.listen(null)
	var was_guest := s.parts != null and s.parts.relay.is_valid()
	s._relay.set_relay(Callable())
	if was_guest and not s._leaving:
		s.parts.went_alone()  # coop/12: its looks-only bodies become its own
	s._peer = null
	s.transport.peer = null
	s._joining = ""
	s._give_up.stop()
	s._guests.clear()
	s._gate.clear()
	s._house.clear()
	s._guard.clear()
	var roster := s.roster
	if roster != null and not s._leaving and not roster.players.is_empty() and s.parts != null and s.parts.of(roster.id) == roster:
		s.parts.apply(roster.cleared())


func _prepare() -> void:
	if _s.profile == null:
		_s.profile = PlayerProfile.fresh()
		_s.profile_made = true


## Nobody is admitted before the gate's checks (SessionGate), then the peer goes live.
func _open_gate() -> void:
	var sm := _s._scene_multiplayer()
	sm.auth_callback = _s._gate.answer
	sm.auth_timeout = _s.tuning.auth_timeout
	_s.multiplayer.multiplayer_peer = _s._peer
