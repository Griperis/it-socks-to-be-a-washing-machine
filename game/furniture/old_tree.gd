## The Old Tree (docs/architecture/economy.md "The Old Tree, the station", "The Old Tree talks"): the Upgrade
## station and a speaker.
##
## The station (Q2611): the crosshair on it outlines the tree and reads "The Old Tree" with the E key; the use
## key opens this machine's Upgrade menu for its own player (no Command: opening a menu decides nothing).
##
## The speaker (core/132, Q2545, Q2670): each machine senses for its own player (near: the local camera within
## the speaker's earshot and level band of `voice`) and asks `talk {trigger}`: `tree_greet` on arriving (the
## first time, or back after `away_seconds`), `tree_affordable` in place of it while an Upgrade became affordable
## for that player (now or on the next visit), `tree_bought` when anyone buys near it, `tree_idle` after
## `idle_seconds` near with nothing said. The Host decides: busy (a cutscene, or a higher speaker such as the
## washer talking), the speaker's cooldown, the trigger's chance, a first visit turning `greet` into `first`
## (`met`), then the picker; it answers the line and take, or a silent no. Every machine plays the answer from
## `voice`, heard and subtitled only near it (Voices). The calls: from the First wash's end (`calling`) the Host's
## timer asks `tree_call` now and then, heard and subtitled within `call_reach` from `call_voice`, until a
## player comes near (`meet`). Nothing on the tree moves while it talks: its Looks are not touched.
##
## State: `met` (player ids that heard their first line), `tips`, `beat`, `said` (core/133's: the tips said
## this run, the Fix comment waiting, the Stage's thresholds said), `calling`, and the last line said (`line`,
## `take`, `serial`, which moves with every answer; not saved: a load starts quiet). A New Game is a new World,
## so it starts from the scene's empty state. The Host's memory (the picker, the clock of the last line, the next
## call) and each machine's senses are not state.
class_name OldTree
extends Part

const TITLE := "The Old Tree"
const TALK := &"talk"
const MEET := &"meet"
const CALL_START := &"call_start"
const CALL := &"tree_call"
const FIRST := &"tree_first"
const GREET := &"tree_greet"
const IDLE := &"tree_idle"
const AFFORDABLE := &"tree_affordable"
const BOUGHT := &"tree_bought"
## The fields a save keeps (the last line said is not kept).
const SAVED: Array[StringName] = [&"met", &"tips", &"calling", &"beat", &"said"]
## Seconds a machine waits on its own ask before it asks again.
const ASK_GAP := 1.0

## This machine's Upgrade menu (a child of the tree's scene).
@export var menu: UpgradeMenu
## Whose lines these are and the voice numbers.
@export var speaker: VoiceSpeaker
@export var tuning: OldTreeTuning
## Where its lines sound from (and the point "near" is measured from); the calls sound from `call_voice`, given
## a copy of `speaker` that carries `call_reach`.
@export var voice: VoiceSource
@export var call_voice: VoiceSource

@export_group("State")
@export var met: PackedStringArray = PackedStringArray()
@export var tips := {}
@export var calling := false
@export var beat := {}
@export var said := {}
@export var line: StringName = &""
@export var take := 0
@export var serial := 0
@export_group("")

## The Host's memory: the picker, the clock of the last line given (calls aside), the clock of the next call.
var picker := VoicePicker.new()
var last_at := -INF
var call_at := -1.0
## Whether this machine's player is near the tree now.
var near := false
## This machine's clock (s, its process time): every timer of the tree runs on it.
var clock := 0.0

var _shown := 0
var _check := 0.0
var _ever_near := false
## The clock of the last line (not a call) this machine heard given: its own reading of the cooldown.
var heard_at := -INF

var _left_at := -INF
var _quiet_since := 0.0
var _asked_at := -INF
var _pending_affordable := false
var _bought_at := -INF
var _meet_asked := false
var _upgrades: Upgrades = null
var _day: LaundryDay = null


func _ready() -> void:
	if call_voice != null and speaker != null and tuning != null:
		var reach := speaker.duplicate() as VoiceSpeaker
		reach.max_distance = tuning.call_reach
		reach.earshot = tuning.call_reach
		reach.level_band = tuning.call_reach  # no level band: a call is heard from the laundry
		call_voice.speaker = reach


func prompt_title() -> String:
	return TITLE


## The player `by` used it: on their own machine their menu opens.
func use(by: int) -> void:
	if menu == null or not is_inside_tree() or by != multiplayer.get_unique_id():
		return
	var player := _player_of(by)
	if player != null:
		menu.open(Upgrades.of(self), player)


## A save keeps who met the tree, the calls and core/133's help; the last line said starts quiet.
func save_state() -> Dictionary:
	var out := {}
	for key in SAVED:
		out[String(key)] = get(key)
	return out


func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		TALK: {"args": {"trigger": {"type": TYPE_STRING, "max": 64}}, "rate": 5},
		MEET: {"args": {}, "rate": 2},
	}


func decide(cmd: Command) -> Dictionary:
	if speaker == null:
		return refuse("wrong")
	match cmd.kind:
		TALK:
			return _talk(StringName(str(cmd.args.get("trigger", ""))), cmd.by)
		MEET:
			return grant({"calling": false}) if calling else refuse("already")
		CALL_START:
			if cmd.by != Parts.HOST or calling:
				return refuse("already")
			return grant({"calling": true})
	return refuse("wrong")


## The Host's director: a grant with the line and take (and `met` on a first visit), or a silent no.
func _talk(trigger_id: StringName, by: int) -> Dictionary:
	var trigger := trigger_of(trigger_id)
	if trigger == null or trigger.kind != VoiceTrigger.Kind.COMMENT or trigger.speaker == null \
			or trigger.speaker.id != speaker.id:
		return refuse("wrong")
	if trigger.id == CALL and not calling:
		return refuse("quiet")
	if busy() or not trigger.ignores_cooldown and clock - last_at < speaker.cooldown:
		return refuse("quiet")
	if picker.rng.randf() >= trigger.chance:
		return refuse("quiet")
	var who := str(_key_of(by))
	var asked := trigger.id
	var first := (asked == GREET or asked == FIRST) and not met.has(who)
	var book := Voices.book()
	if first and not book.lines_for(speaker.id, FIRST).is_empty():
		asked = FIRST
	elif asked == FIRST:
		asked = GREET  # met already, or no first line: the greeting (the old)
	var pick := picker.pick(book.lines_of(speaker.id), asked)
	if pick.is_empty():
		return refuse("quiet")
	if trigger.id != CALL:
		last_at = clock  # the Host's own memory: not state; a call keeps the cooldown as it was (the old)
	var said_line: VoiceLine = pick["line"]
	var patch := {"line": said_line.id, "take": int(pick["take"]), "serial": serial + 1}
	if first:
		var now_met := met.duplicate()
		now_met.append(who)
		patch["met"] = now_met
	var answer := grant(patch)
	answer["trigger"] = String(trigger.id)
	return answer


## Whether the tree keeps quiet now: a cutscene plays, or a speaker of higher priority (the washer) or the tree
## itself is talking (a call gives way: the line for a player near replaces it, the old `stop()`).
func busy() -> bool:
	if Voices.cutscene_playing():
		return true
	var frame := Cutscenes.of(self) if is_inside_tree() else null
	if frame != null and frame.is_playing():
		return true
	var book := Voices.book()
	for id in book.speakers():
		var other := book.banks[id].speaker
		if Voices.talking(id) and (other.priority > speaker.priority or id == speaker.id and not calling_now()):
			return true
	return false


## Whether a call is what the tree says now (on this machine).
func calling_now() -> bool:
	var playing := Voices.line_of(speaker.id) if speaker != null else null
	return playing != null and playing.has_trigger(CALL)


func _process(delta: float) -> void:
	clock += delta
	if speaker == null or tuning == null or voice == null or parts == null:
		return
	_listen()
	if parts.is_host():
		_call_step()
	_check += delta
	if _check < tuning.check_seconds:
		return
	_check = 0.0
	sense()


## One look at the moments for this machine's player: near or not, the calls, a buy, an Upgrade newly
## affordable, the greeting, a quiet spell; it asks for the most pressing one.
func sense() -> void:
	var was := near
	near = is_near(_listener())
	var arrived := near and not was
	if was and not near:
		_left_at = clock
	if not near:
		return
	if arrived:
		_quiet_since = clock
	if calling and not _meet_asked:
		_meet_asked = true
		parts.ask(Command.new(MEET, multiplayer.get_unique_id(), id))  # the calls end for everyone (Q1865)
	var greet := arrived and (not _ever_near or clock - _left_at >= tuning.away_seconds)
	_ever_near = true
	if not _may_ask():
		return
	if clock - _bought_at <= tuning.bought_window:
		_bought_at = -INF
		_talk_ask(BOUGHT)
	elif _pending_affordable:
		_pending_affordable = false
		_talk_ask(AFFORDABLE)
	elif greet:
		_talk_ask(GREET)
	elif clock - _quiet_since >= tuning.idle_seconds:
		_quiet_since = clock - tuning.idle_seconds + tuning.idle_retry  # look again a little later
		_talk_ask(IDLE)


## Whether a listener at `at` (null: none) is near the tree: within the speaker's earshot and level band.
func is_near(at: Variant) -> bool:
	return at is Vector3 and Voices.within_earshot(at, voice.global_position, speaker.earshot, speaker.level_band)


## Whether this machine may ask now: nothing keeps the tree quiet, the cooldown since the last line heard here
## has passed, and its last ask is not still on its way. (The Host decides; this only saves asking in vain.)
func _may_ask() -> bool:
	return not busy() and clock - heard_at >= speaker.cooldown and clock - _asked_at >= ASK_GAP


## The Host's calls into the house (Q1864, Q1865): `call_first_delay` after `calling` began, then every
## `call_gap`, a `tree_call`, unless the tree keeps quiet.
func _call_step() -> void:
	if not calling:
		call_at = -1.0
		return
	if call_at < 0.0:
		call_at = clock + tuning.call_first_delay
	if clock < call_at or busy() or Voices.talking(speaker.id):
		return
	call_at = clock + picker.rng.randf_range(tuning.call_gap.x, tuning.call_gap.y)
	parts.ask(Command.new(TALK, Parts.HOST, id, {"trigger": String(CALL)}))


## Hears the level's Upgrades (every machine) and the First wash's end (the Host), once each is there.
func _listen() -> void:
	if _upgrades == null:
		_upgrades = Upgrades.of(self)
		if _upgrades != null:
			_upgrades.bought.connect(_on_bought)
			_upgrades.affordable.connect(_on_affordable)
	if _day == null and parts.is_host():
		_day = LaundryDay.of(self)
		if _day != null:
			_day.first_wash_done.connect(_on_first_wash_done)


func _on_bought(_player: int, _upgrade: Upgrade) -> void:
	if near:
		_bought_at = clock


func _on_affordable(_player: int, _upgrade: Upgrade) -> void:
	_pending_affordable = true


func _on_first_wash_done() -> void:
	if parts != null and parts.is_host():
		parts.ask(Command.new(CALL_START, Parts.HOST, id))


func _talk_ask(trigger: StringName) -> void:
	_asked_at = clock
	parts.ask(Command.new(TALK, multiplayer.get_unique_id(), id, {"trigger": String(trigger)}))


func _show(now: bool) -> void:
	if not calling:
		_meet_asked = false
		if speaker != null and calling_now():
			Voices.stop(speaker.id)  # a call never talks over the first line (the old)
	if now or serial == _shown:
		_shown = serial
		return
	_shown = serial
	if line == &"" or speaker == null:
		return
	var said_line := Voices.book().find_line(speaker.id, line)
	if said_line == null:
		return
	var is_call := said_line.has_trigger(CALL)
	if not is_call:
		heard_at = clock
		var t := said_line.takes[take] if take < said_line.takes.size() else null
		_quiet_since = clock + (t.duration if t != null else 0.0)
	Voices.say(said_line, take, call_voice if is_call and call_voice != null else voice)


## Where this machine's listener is: its camera, or null.
func _listener() -> Variant:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	return camera.global_position if camera != null else null


## The player id `by` is kept under (the Bank's key), or `by` with no Bank.
func _key_of(by: int) -> Variant:
	var ups := Upgrades.of(self)
	return ups.bank.key_of(by) if ups != null and ups.bank != null else by


## The trigger file `id`, or null.
static func trigger_of(trigger_id: StringName) -> VoiceTrigger:
	var path := "res://game/voice/triggers/%s.tres" % trigger_id
	return load(path) as VoiceTrigger if not String(trigger_id).is_empty() and ResourceLoader.exists(path) else null


## This machine's Player (the one on this Part's multiplayer), or null.
func _player_of(_by: int) -> Player:
	for node in get_tree().get_nodes_in_group(&"local_input"):
		if node is Player and node.multiplayer == multiplayer:
			return node as Player
	return null
