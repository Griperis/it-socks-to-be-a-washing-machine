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
## core/133's help, from the same senses: the Stage bar's thresholds (`tree_stage_*`), the first-time tips, and an
## idle spell that may be a grumble (only while the washer is broken) or a hint (a Cabinet with a Row to fill, or
## the floor of a loose Mate: never a spot), chosen by the machine's own roll. The Fix comments and the story beats
## (the Final wash, the peace) are the Host's: it arms them on the Stages' and the Laundry day's events, sets
## `beat` when they are due, and every machine near asks them; the Host lapses an unheard one after `beat_hold`.
##
## State: `met` (player ids that heard their first line), `tips` (player id -> tips said this run), `beat` (the
## Fix comment due, `comment`, and the story beats waiting, `story`), `said` (the Stage and the threshold already
## said in it), `calling`, and the last line said (`line`,
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
## The Host's own verbs (no player asks them): arm or lapse a beat, mark the Stage's bar as it stands, forget a run.
const BEAT := &"beat"
const MARK := &"mark"
const FORGET := &"forget"
## The fields a save keeps (the last line said is not kept).
const SAVED: Array[StringName] = [&"met", &"tips", &"calling", &"beat", &"said"]
## Seconds a machine waits on its own ask before it asks again.
const ASK_GAP := 1.0

## This machine's Upgrade menu (a child of the tree's scene).
@export var menu: UpgradeMenu
## Whose lines these are and the voice numbers.
@export var speaker: VoiceSpeaker
@export var tuning: OldTreeTuning
## Where its lines sound from (and the point "near" is measured from); the calls sound from `call_voice`. Each is
## given a copy of `speaker` at the tree's playback level (the calls' with `call_reach`).
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
var _stages: Stages = null
var _stages_heard := false
## This machine's roll for an idle spell (a grumble, a hint or a musing).
var roll := RandomNumberGenerator.new()
## The Host's own memory (not state): the Fix comment armed and when it is due, when each beat was opened, the
## last mark asked, and the Final wash seen.
var _comment := {}
var _opened: Dictionary[String, float] = {}
var _marked_at := -INF
var _final_seen := false


## The sources get copies of `speaker` carrying the tree's playback level (`voice_db`, `call_db`: the old
## +12.5 dB, Q2638) and, for the calls, `call_reach`.
func _ready() -> void:
	if speaker == null or tuning == null:
		return
	if voice != null:
		var level := speaker.duplicate() as VoiceSpeaker
		level.voice_db = tuning.voice_db
		voice.speaker = level
	if call_voice != null:
		var reach := speaker.duplicate() as VoiceSpeaker
		reach.voice_db = tuning.call_db
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
		BEAT, MARK, FORGET:
			return _host_verb(cmd) if cmd.by == Parts.HOST else refuse("wrong")
	return refuse("wrong")


## The Host's director: a grant with the line and take (and `met` on a first visit), or a silent no.
func _talk(trigger_id: StringName, by: int) -> Dictionary:
	var trigger := trigger_of(trigger_id)
	if trigger == null or trigger.kind != VoiceTrigger.Kind.COMMENT or trigger.speaker == null \
			or trigger.speaker.id != speaker.id:
		return refuse("wrong")
	if trigger.id == CALL and not calling:
		return refuse("quiet")
	var story := OldTreeHelp.STORY.has(trigger.id)
	if not _may_say(trigger, by):
		return refuse("quiet")
	if busy() or (story and clock - last_at < tuning.beat_gap) \
			or (not story and not trigger.ignores_cooldown and clock - last_at < speaker.cooldown):
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
	patch.merge(_said_patch(trigger.id, who))
	var answer := grant(patch)
	answer["trigger"] = String(trigger.id)
	return answer


## Whether the Host lets `trigger` be asked for `by` now: a beat only while it waits, a tip once and when due, a
## threshold once per Stage and once the bar is there, a grumble only while the washer is broken.
func _may_say(trigger: VoiceTrigger, by: int) -> bool:
	var asked := trigger.id
	if OldTreeHelp.STORY.has(asked):
		return (beat.get("story", []) as Array).has(String(asked))
	if OldTreeHelp.is_comment(asked):
		return str(beat.get("comment", "")) == String(asked)
	if OldTreeHelp.TIPS.has(asked):
		return OldTreeHelp.tip_due(asked, _stages_of()) and not (tips.get(str(_key_of(by)), []) as Array).has(String(asked))
	var step := OldTreeHelp.STAGE.find(asked)
	if step >= 0:
		var stages := _stages_of()
		return stages != null and int(said.get("stage", -1)) == stages.stage and step > int(said.get("step", -1)) \
				and step <= OldTreeHelp.step_of(OldTreeHelp.share(stages), tuning.stage_thresholds)
	if asked == OldTreeHelp.GRUMBLE:
		var stages := _stages_of()
		return stages == null or not stages.is_fixed()
	return true


## What a said line changes: a beat leaves its list, a tip is kept for the player, a threshold is kept for the Stage.
func _said_patch(said_id: StringName, who: String) -> Dictionary:
	var patch := {}
	var waiting := beat.duplicate(true)
	if OldTreeHelp.STORY.has(said_id):
		(waiting["story"] as Array).erase(String(said_id))
		patch["beat"] = waiting
	elif OldTreeHelp.is_comment(said_id):
		waiting["comment"] = ""
		patch["beat"] = waiting
	elif OldTreeHelp.TIPS.has(said_id):
		var kept := tips.duplicate(true)
		var mine: Array = kept.get(who, [])
		mine.append(String(said_id))
		kept[who] = mine
		patch["tips"] = kept
	elif OldTreeHelp.STAGE.has(said_id):
		patch["said"] = {"stage": int(said.get("stage", -1)), "step": OldTreeHelp.STAGE.find(said_id)}
	return patch


## The Host's verbs: `beat` arms (`on`) or lapses a trigger (a story beat or the Fix comment), `mark` takes the
## Stage's bar as it stands, `forget` starts a run's memory over.
func _host_verb(cmd: Command) -> Dictionary:
	match cmd.kind:
		BEAT:
			var asked := str(cmd.args.get("trigger", ""))
			var story := OldTreeHelp.STORY.has(StringName(asked))
			var waiting := beat.duplicate(true)
			var list: Array = waiting.get("story", [])
			if bool(cmd.args.get("on", true)):
				if story:
					if list.has(asked):
						return refuse("already")
					list.append(asked)
					waiting["story"] = list
				else:
					waiting["comment"] = asked
			elif story:
				list.erase(asked)
				waiting["story"] = list
			elif str(waiting.get("comment", "")) == asked:
				waiting["comment"] = ""
			else:
				return refuse("already")
			return grant({"beat": waiting})
		MARK:
			return grant({"said": {"stage": int(cmd.args.get("stage", -1)), "step": int(cmd.args.get("step", -1))}})
		FORGET:
			return grant({"tips": {}, "said": {}, "beat": {}})
	return refuse("wrong")


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
		_help_step()
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
	if _may_ask_beat() and _ask_story():
		return
	if not _may_ask():
		return
	if str(beat.get("comment", "")) != "":
		_talk_ask(StringName(str(beat["comment"])))
	elif clock - _bought_at <= tuning.bought_window:
		_bought_at = -INF
		_talk_ask(BOUGHT)
	elif _pending_affordable:
		_pending_affordable = false
		_talk_ask(AFFORDABLE)
	elif greet:
		_talk_ask(GREET)
	elif _ask_tip() or _ask_stage():
		pass
	elif clock - _quiet_since >= tuning.idle_seconds:
		_quiet_since = clock - tuning.idle_seconds + tuning.idle_retry  # look again a little later
		_talk_ask(spell())


## Whether a listener at `at` (null: none) is near the tree: within the speaker's earshot and level band.
func is_near(at: Variant) -> bool:
	return at is Vector3 and Voices.within_earshot(at, voice.global_position, speaker.earshot, speaker.level_band)


## Whether this machine may ask now: nothing keeps the tree quiet, the cooldown since the last line heard here
## has passed, and its last ask is not still on its way. (The Host decides; this only saves asking in vain.)
func _may_ask() -> bool:
	return not busy() and clock - heard_at >= speaker.cooldown and clock - _asked_at >= ASK_GAP


## Whether this machine may ask a story beat now: it skips the cooldown but waits `beat_gap` since the last line
## it heard.
func _may_ask_beat() -> bool:
	return not busy() and clock - heard_at >= tuning.beat_gap and clock - _asked_at >= ASK_GAP


## Asks the first story beat waiting (the Final wash, the peace); whether it asked.
func _ask_story() -> bool:
	var waiting: Array = beat.get("story", [])
	if waiting.is_empty():
		return false
	_talk_ask(StringName(str(waiting[0])))
	return true


## Asks the first tip that is due for this player and not said; whether it asked.
func _ask_tip() -> bool:
	var mine: Array = tips.get(str(_key_of(multiplayer.get_unique_id())), [])
	for tip in OldTreeHelp.TIPS:
		if OldTreeHelp.tip_due(tip, _stages_of()) and not mine.has(String(tip)):
			_talk_ask(tip)
			return true
	return false


## Asks the Stage bar's threshold it has reached and the tree has not said in this Stage; whether it asked.
func _ask_stage() -> bool:
	var stages := _stages_of()
	if stages == null or int(said.get("stage", -1)) != stages.stage:
		return false
	var step := OldTreeHelp.step_of(OldTreeHelp.share(stages), tuning.stage_thresholds)
	if step <= int(said.get("step", -1)):
		return false
	_talk_ask(OldTreeHelp.STAGE[step])
	return true


## What an idle spell says (this machine's roll): a grumble about the washer while it is broken
## (`grumble_chance`), a hint (`hint_chance`) of a Cabinet with a Row to fill or the floor of a loose Mate, else a
## musing. Never a spot.
func spell() -> StringName:
	var stages := _stages_of()
	var at := roll.randf()
	if (stages == null or not stages.is_fixed()) and at < tuning.grumble_chance:
		return OldTreeHelp.GRUMBLE
	if at < tuning.grumble_chance + tuning.hint_chance:
		var rooms := OldTreeHelp.needy_cabinets(stages)
		var floor_hint := OldTreeHelp.mate_hint(stages, _hands(), _lights(), multiplayer.get_unique_id(), roll)
		if not rooms.is_empty() and (floor_hint == null or roll.randf() < 0.5):
			return rooms[roll.randi() % rooms.size()].id
		if floor_hint != null:
			return floor_hint.id
	return IDLE


func _hands() -> Hands:
	for node in get_tree().get_nodes_in_group(Hands.GROUP):
		if (node as Hands).parts == parts:
			return node as Hands
	return null


func _lights() -> HouseLights:
	var found := get_tree().get_nodes_in_group(HouseLights.GROUP)
	return found[0] as HouseLights if not found.is_empty() else null


func _stages_of() -> Stages:
	if _stages == null:
		_stages = OldTreeHelp.stages_of(self)
	return _stages


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
	if not _stages_heard and parts.is_host() and _stages_of() != null:
		_stages_heard = true
		_stages.floor_opened.connect(_on_floor_opened)
		_stages.machine_fixed.connect(_on_machine_fixed)
		_stages.run_started.connect(_on_run_started)


func _on_bought(_player: int, _upgrade: Upgrade) -> void:
	if near:
		_bought_at = clock


func _on_affordable(_player: int, _upgrade: Upgrade) -> void:
	_pending_affordable = true


func _on_first_wash_done() -> void:
	if parts != null and parts.is_host():
		parts.ask(Command.new(CALL_START, Parts.HOST, id))


## The Host's beats: the Stage's bar taken as it stands when a new Stage begins (what it already has is not
## news), the Fix comment armed when it is due, the Final wash, and any beat unheard for `beat_hold` lapsed.
func _help_step() -> void:
	var stages := _stages_of()
	if stages != null and stages.stage >= 0 and int(said.get("stage", -1)) != stages.stage and clock - _marked_at >= ASK_GAP:
		_marked_at = clock
		var step := OldTreeHelp.step_of(OldTreeHelp.share(stages), tuning.stage_thresholds)
		parts.ask(Command.new(MARK, Parts.HOST, id, {"stage": stages.stage, "step": step}))
	if not _comment.is_empty() and clock >= float(_comment["due"]):
		var due: String = _comment["trigger"]
		_comment = {}
		parts.ask(Command.new(BEAT, Parts.HOST, id, {"trigger": due}))
	if _day != null and _day.final_started and not _final_seen:
		_final_seen = true
		_comment = {}  # the Final wash ends the Fix comments (the old); the tree says nothing over it (Q2718)
	var waiting: Array[String] = []
	if str(beat.get("comment", "")) != "":
		waiting.append(str(beat["comment"]))
	for story: Variant in beat.get("story", []) as Array:
		waiting.append(str(story))
	for key: String in _opened.keys():
		if not waiting.has(key):
			_opened.erase(key)
	for key: String in waiting:
		if not _opened.has(key):
			_opened[key] = clock  # a beat found waiting (a load) starts its hold now
		elif clock - _opened[key] > tuning.beat_hold:
			_opened.erase(key)
			parts.ask(Command.new(BEAT, Parts.HOST, id, {"trigger": key, "on": false}))


## A floor opened: one Fix comment (the Part's or the floor's) comes `beat_delay` into the Stage, with `beat_chance`.
func _on_floor_opened(stage: int, _grown: Array) -> void:
	_comment = {}
	var pool := OldTreeHelp.fix_pool(_stages.plan, stage)
	if pool.is_empty() or picker.rng.randf() >= tuning.beat_chance:
		return
	var pick := pool[picker.rng.randi() % pool.size()]
	_comment = {"trigger": String(pick.id), "due": clock + picker.rng.randf_range(tuning.beat_delay.x, tuning.beat_delay.y)}


## The last Fix: no Fix comment now (the peace line is its own); the peace waits for a player near.
func _on_machine_fixed() -> void:
	_comment = {}
	parts.ask(Command.new(BEAT, Parts.HOST, id, {"trigger": String(&"tree_peace")}))


## A New Game's run starts: what is once per run starts again.
func _on_run_started() -> void:
	_comment = {}
	_opened.clear()
	_final_seen = false
	parts.ask(Command.new(FORGET, Parts.HOST, id))


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
