## One Stage present (core/137, docs/architecture/gifts.md "A present is a spawned scene"): whose it is, which
## piece it holds and which Collection wrapped it. A spawned scene (`present.tscn`: a Carriable, this Part and
## its Looks) made by Presents' drop through the run's SpawnedParts; its State never changes after the spawn
## (where it lies and who holds it are its Carriable's).
##
## It is its Carriable's pick guard (the `carry_guards` seam): only the player it is for may aim at it and pick
## it up; a Teammate's is refused silently ("not_yours") and never aimed or outlined.
##
## Opening (core/138, "Opening"): the carrier's next left click asks `open`; the Host checks the asker is the
## player it is for and holds it, and the answer removes its row, gives the piece (the Roster's owned list) or
## pays the refund into the Bank as a bonus when they owned every piece (Q2673), and counts it in the run's
## record. Presents shows the answer on every machine (the shake and pop, the opener's reveal).
##
## Looks only: the box is wrapped from its Collection's file (paper, ink, icon, bow); the Looks' `drop` clip
## plays once on every machine that saw the drop (Presents.fresh()), then `lying` loops while it lies at its
## own phase (its row id), `RESET` while carried; the glow and the sparkle show only while it lies; the Tag
## names its player in their colour in co-op (hidden solo and while carried).
class_name Present
extends Part

## A present's Carriable asks the parts in this group whether a pick may go ahead (Carriable.GUARDS).
const NOT_YOURS := &"not_yours"
## The verb a carried present's left click asks, and the answer's key Presents shows.
const OPEN := &"open"
const OPENED := "present_opened"
## The left click (the Hands' pick action).
const PICK := &"pick"
const LOOKS := ^"../Looks"
const PLAYER := ^"AnimationPlayer"
const DROP := &"drop"
const LYING := &"lying"
const RESET := &"RESET"
## The paper's surface on the model's meshes (assets/16: 0 gift_paper, 1 gift_ribbon, 2 gift_inside).
const PAPER_SURFACE := 0
const RIBBON_SURFACE := 1
## The meshes the wrapping goes on (the model's `Box` and its `Lid`, under the Looks' turning `Box`).
const MESHES: Array[NodePath] = [^"Box/Box", ^"Box/Box/Lid"]
## The old start turn: (id mod 7) x 0.4 rad, at the old 1.2 rad/s of the `lying` loop.
const START_TURN := 0.4
const TURN_SPEED := 1.2
## The Tag's colours from the player's (the old gift_view.gd _tag).
const TAG_LIGHTEN := 0.25
const TAG_OUTLINE_DARKEN := 0.6
## The glow's colour from the bow's (the old: lightened 35 %, alpha 0.75).
const GLOW_LIGHTEN := 0.35
const GLOW_ALPHA := 0.75

@export var tuning: PresentTuning

@export_group("State")
## The Roster's player id of the player it is for.
@export var for_player := ""
## The Wardrobe piece inside.
@export var piece: StringName = &""
## The Collection that completed and wraps it.
@export var collection: StringName = &""
@export_group("")

var _carriable: Carriable
var _roster: Roster
## The Collection whose wrapping is on the box now.
var _wrapped: StringName = &""
## Whether it was drawn lying the last frame (the glow, the sparkle and the clips follow a change).
var _was_lying := false
var _started := false
## The physics frame this machine's player was first seen carrying it (-1: not carrying); a click opens it only
## on a later frame, so the click that picked it up never opens it.
var _carried_from := -1


func _enter_tree() -> void:
	add_to_group(Carriable.GUARDS)


func _ready() -> void:
	if tuning == null:
		tuning = PresentTuning.new()
	# Before the player's own tick (priority 0), so the click that opens it is swallowed before the player
	# reads it (GiftClicks).
	process_physics_priority = GiftClicks.BEFORE_PLAYER


func accepts() -> Dictionary[StringName, Dictionary]:
	return {OPEN: {"args": {}, "rate": 4}}


## Player `by` asks to open it (their left click while carrying it).
func open(by: int) -> void:
	if parts != null:
		parts.ask(Command.new(OPEN, by, id, {}))


## The Host: only the player it is for, carrying it, opens it. The answer removes its row, gives the piece or
## pays the refund (Q2673), counts it in the run's record, and carries OPENED for every machine's show.
func decide(cmd: Command) -> Dictionary:
	if cmd.kind != OPEN:
		return refuse("wrong")
	var c := carriable()
	if c == null or c.holder != cmd.by:
		return refuse("not_carried")
	if not is_for(cmd.by):
		return refuse(NOT_YOURS)
	var spawned := get_parent().get_parent() as SpawnedParts if get_parent() != null else null
	var row := row_id()
	if spawned == null or row == 0:
		return refuse("wrong")
	var changes := {spawned.id: spawned.remove_patch(PackedInt32Array([row]))}
	var ev := {"ok": true, "changes": changes}
	var fresh := not owned_by(cmd.by).has(String(piece))
	var refund := 0
	if fresh:
		var r := roster()
		if r != null:
			changes.merge(r.owned_patch(cmd.by, piece))
	else:
		refund = tuning.refund
		var bank := Bank.of(self)
		if bank != null and refund > 0:
			changes[bank.id] = bank.paid_patch(cmd.by, refund, true)
			Bank.note(ev, cmd.by, refund, 0, null, true)
	var record := RunRecord.of(self)
	if record != null:
		var tallies := RunTallies.of(self)
		changes[record.id] = record.opened_patch(tallies.key_of(cmd.by) if tallies != null else cmd.by, piece, fresh)
	var presents := Presents.of(self)
	ev[OPENED] = {"by": cmd.by, "piece": String(piece), "refund": refund, "collection": String(collection),
			"row": row, "presents": String(presents.id) if presents != null else ""}
	return ev


## The pieces player `by` owns, as the Host knows them: the Roster's, or this machine's profile with no Roster
## naming them (a station's Host of one).
func owned_by(by: int) -> PackedStringArray:
	var r := roster()
	var pid := r.id_of(by) if r != null else ""
	if pid != "":
		return r.owned_of(pid)
	return Wardrobe.owned(Worlds.profile().pieces)


## This machine's player's left click while carrying it opens it (the click goes no further).
func _physics_process(_delta: float) -> void:
	var c := carriable()
	if c == null or parts == null or not is_inside_tree():
		return
	var me := multiplayer.get_unique_id()
	if c.holder != me:
		_carried_from = -1
		return
	var frame := Engine.get_physics_frames()
	if _carried_from < 0:
		_carried_from = frame
		return
	if frame <= _carried_from or not Input.is_action_just_pressed(PICK):
		return
	var player := GiftClicks.player_of(c.hands(), me)
	if player == null or not GiftClicks.acting(player):
		return
	GiftClicks.swallow(player)
	open(me)


## Its Carriable's guard: player `by` (a peer) may pick it up only when it is theirs.
func pick_refusal(by: int) -> StringName:
	return &"" if is_for(by) else NOT_YOURS


## Its Carriable's guard: only its own player's crosshair rests on it.
func aimable_by(by: int) -> bool:
	return is_for(by)


## Whether it is for the player on peer `by`.
func is_for(by: int) -> bool:
	return for_player != "" and player_id_of(by) == for_player


## The player id of the player on peer `peer`: the Roster's, or the peer as text where there is none (a
## station's Host of one).
func player_id_of(peer: int) -> String:
	var roster := roster()
	if roster != null:
		var pid := roster.id_of(peer)
		if pid != "":
			return pid
	return str(peer)


func roster() -> Roster:
	if (_roster == null or not is_instance_valid(_roster)) and parts != null:
		_roster = parts.find(func(p: Part) -> bool: return p is Roster) as Roster
	return _roster


func carriable() -> Carriable:
	if _carriable == null:
		_carriable = get_node_or_null(^"../Carriable") as Carriable
	return _carriable


## The id of its SpawnedParts row (0 when it was placed by hand).
func row_id() -> int:
	var thing := get_parent()
	return int(thing.get_meta(&"spawned_row", 0)) if thing != null else 0


## Whether it lies (in nobody's Hands).
func lying() -> bool:
	var c := carriable()
	return c == null or c.holder == 0


func looks() -> Node3D:
	return get_node_or_null(LOOKS) as Node3D


func _show(_now: bool) -> void:
	_wrap()
	_tag()
	if not _started:
		_started = true
		var presents := Presents.of(self)
		_was_lying = lying()
		_effects()
		if presents != null and presents.fresh(row_id()) and _was_lying:
			_play_drop()
		else:
			_play_motion(true)


## Every machine that applied the drop's answer: the box drops (Presents._on_applied).
func dropped() -> void:
	if lying():
		_play_drop()


func _process(_delta: float) -> void:
	if not _started:
		return
	var now := lying()
	if now != _was_lying:
		_was_lying = now
		_effects()
		_play_motion(true)
		_tag()


## The paper, the ink, the icon and the bow from its Collection's file (once per Collection).
func _wrap() -> void:
	var looks := looks()
	var col := Collections.of(collection)
	if looks == null or col == null or _wrapped == collection:
		return
	_wrapped = collection
	wrap_looks(looks, col, tuning)


## Wraps a present's Looks `looks` in Collection `col` (the Gifts station's boxes too): the paper's colour, its
## ink and icon pattern, the ribbon and bow, the glow and the specks in the bow's colour.
static func wrap_looks(looks: Node3D, col: SockCollection, tuning: PresentTuning) -> void:
	var bow := col.bow_colour()
	for path in MESHES:
		var mesh := looks.get_node_or_null(path) as MeshInstance3D
		if mesh == null:
			continue
		var paper := mesh.get_surface_override_material(PAPER_SURFACE) as ShaderMaterial
		if paper != null:
			paper.set_shader_parameter(&"paper", col.paper_colour())
			paper.set_shader_parameter(&"ink", col.ink_colour())
			paper.set_shader_parameter(&"icon", col.icon)
			paper.set_shader_parameter(&"tiles", tuning.tiles)
			paper.set_shader_parameter(&"ink_strength", tuning.ink_strength if col.icon != null else 0.0)
		var ribbon := mesh.get_surface_override_material(RIBBON_SURFACE) as StandardMaterial3D
		if ribbon != null:
			ribbon.albedo_color = bow
	var glow := looks.get_node_or_null(^"Glow") as GeometryInstance3D
	var glow_material := glow.material_override as StandardMaterial3D if glow != null else null
	if glow_material != null:
		glow_material.albedo_color = Color(bow.lightened(GLOW_LIGHTEN), GLOW_ALPHA)
	for name: StringName in [&"Sparkle", &"Burst", &"Pop"]:
		var specks := looks.get_node_or_null(NodePath(name)) as GPUParticles3D
		var material := specks.process_material as ParticleProcessMaterial if specks != null else null
		if material != null:
			material.color = bow


## The Tag: its player's name in their colour, in co-op only, while it lies.
func _tag() -> void:
	var looks := looks()
	var tag := looks.get_node_or_null(^"Tag") as Label3D if looks != null else null
	if tag == null:
		return
	var roster := roster()
	var entry: Dictionary = roster.players.get(for_player, {}) if roster != null else {}
	var coop := roster != null and roster.players.size() > 1
	tag.visible = coop and not entry.is_empty() and lying()
	if not tag.visible:
		return
	var colour := roster.tuning.colour(int(entry.get("colour", 0)))
	tag.text = String(entry.get("name", PlayerProfile.NAME))
	tag.modulate = colour.lightened(TAG_LIGHTEN)
	tag.outline_modulate = colour.darkened(TAG_OUTLINE_DARKEN)


## The glow and the sparkle show only while it lies.
func _effects() -> void:
	var looks := looks()
	if looks == null:
		return
	var on := lying()
	var glow := looks.get_node_or_null(^"Glow") as Node3D
	if glow != null:
		glow.visible = on
	var sparkle := looks.get_node_or_null(^"Sparkle") as GPUParticles3D
	if sparkle != null and sparkle.emitting != on:
		sparkle.emitting = on


func _anim() -> AnimationPlayer:
	var looks := looks()
	return looks.get_node_or_null(PLAYER) as AnimationPlayer if looks != null else null


## The drop: from over the spot with a bounce, the burst at the landing (the clip's keys), then `lying`.
func _play_drop() -> void:
	var player := _anim()
	if player == null or not player.has_animation(DROP):
		_play_motion(true)
		return
	player.play(DROP)
	if not player.animation_finished.is_connected(_on_clip_done):
		player.animation_finished.connect(_on_clip_done)


func _on_clip_done(clip: StringName) -> void:
	if clip == DROP:
		_play_motion(true)


## `lying` while it lies, at its own phase; `RESET` while carried.
func _play_motion(restart: bool) -> void:
	var player := _anim()
	if player == null:
		return
	if lying() and player.has_animation(LYING):
		if restart or player.current_animation != LYING:
			player.play(LYING)
			var length := player.get_animation(LYING).length
			player.seek(fposmod(float(row_id() % 7) * START_TURN / TURN_SPEED, length), true)
	elif player.has_animation(RESET):
		player.play(RESET)
