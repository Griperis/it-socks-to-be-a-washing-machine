## What the pings look like on this machine (core/43 lines 22-43): one PingMark (ping_mark.tscn) for
## each ping the level's Pings says stands, made when a new one comes (replacing that player's last at
## once, line 40) and freed when its time is up on this machine's clock (line 42). Looks only: it reads
## Pings and decides nothing. It is also the hint arrows' ping source (lines 44-53): it adds itself to
## the local player's HintArrows once the level is ready.
class_name PingMarks
extends Node3D

## One ping's look (loaded at start, not preloaded: its script names this class).
const MARK_PATH := "res://game/ping/ping_mark.tscn"
## The sticker bubble texture's side, its round part's middle and radius, and its tail tip's row, in
## pixels (line 31: the old pings.gd PX, BUBBLE_Y, BUBBLE_R, TIP_Y).
const PX := 96
const BUBBLE_Y := 40.0
const BUBBLE_R := 36.0
const TIP_Y := 94.0
## The bubble's cream middle (a share of the round part) and the icons' colours (the old UiBits).
const MIDDLE_SHARE := 0.74
const CREAM := Color(1.0, 0.957, 0.878)
const INK := KeycapStyle.INK
## The hint arrows' priority of a ping (line 50: before every other source's 0).
const ARROW_PRIORITY := 1

## The level's Pings.
@export var pings: Pings

var _mark_scene: PackedScene
## Each standing ping's mark, by its pinger's peer.
var _marks: Dictionary[int, PingMark] = {}
## Each colour's bubble, made once.
static var _bubbles: Dictionary[String, ImageTexture] = {}


func _ready() -> void:
	_mark_scene = load(MARK_PATH) as PackedScene
	_join_arrows.call_deferred()


## The local player's hint arrows take the pings as a source (line 53).
func _join_arrows() -> void:
	var runtime := LevelRuntime.of(self)
	var player := runtime.player if runtime != null else null
	if player != null and player.hud() != null and player.hud().hint_arrows() != null:
		player.hud().hint_arrows().add_source(hint_targets)


func _process(delta: float) -> void:
	if pings == null:
		return
	var standing := pings.standing()
	for peer: int in _marks.keys():
		var mark := _marks[peer]
		if not standing.has(peer) or int(pings.pings[peer].get("n", -1)) != mark.n:
			_marks.erase(peer)
			mark.queue_free()
	for peer: int in standing:
		if not _marks.has(peer):
			var mark := _mark_scene.instantiate() as PingMark
			mark.name = "Ping%d" % peer
			add_child(mark)
			mark.setup(self, peer, pings.pings[peer])
			_marks[peer] = mark
	for peer: int in _marks:
		_marks[peer].place(delta)


# --- What a mark asks ----------------------------------------------------------------------------

## This machine's own player's peer.
func local_peer() -> int:
	return multiplayer.get_unique_id()


## The numbers.
func tuning() -> PingTuning:
	return pings.tuning if pings != null and pings.tuning != null else PingTuning.new()


## Player `peer`'s colour (the Roster's); one the Roster does not know (a zoo stand-in) its avatar's as
## drawn, else white.
func colour_of(peer: int) -> Color:
	var runtime := LevelRuntime.of(self)
	var roster := runtime.roster if runtime != null else null
	if roster != null and not roster.entry_of(peer).is_empty():
		return roster.colour_of(peer)
	var avatar := pings.avatar_of(peer) if pings != null else null
	return avatar.looks.colour if avatar != null and avatar.looks != null else Color.WHITE


## The camera this machine draws with, or null.
func camera() -> Camera3D:
	return get_viewport().get_camera_3d() if is_inside_tree() else null


## Where a bubble over player `avatar` stands: `head_lift` over their avatar's `Head` node, else over
## their body's height (lines 33, 37).
func head_point(avatar: Avatar) -> Vector3:
	var lift := tuning().head_lift
	var head := avatar.find_child("Head", true, false) as Node3D
	if head != null:
		return head.global_position + Vector3.UP * lift
	var t := avatar.tuning if avatar.tuning != null else AvatarTuning.new()
	return avatar.global_position + Vector3.UP * (t.stand_height + lift)


## Whether a wall or a piece of furniture stands between the camera and `at` (line 36): a ray that
## stops `wall_slack` short of it, on the house layer. A space query: from a physics tick only.
func occluded(at: Vector3) -> bool:
	var cam := camera()
	if cam == null:
		return false
	var from := cam.global_position
	var d := at - from
	var slack := tuning().wall_slack
	if d.length() <= slack:
		return false
	return not PhysicsQueries.ray(self, from, at - d.normalized() * slack, Mess.LAYER_HOUSE).is_empty()


# --- Read back -----------------------------------------------------------------------------------

## The mark of player `peer`'s ping on this machine, or null.
func mark_of(peer: int) -> PingMark:
	var m: PingMark = _marks.get(peer)
	return m if m != null and is_instance_valid(m) else null


## How many pings this machine draws now.
func count() -> int:
	return _marks.size()


## What the hint arrows point at (lines 44-53): every ping standing here, in its pinger's colour, at
## what it follows now, with its emoji; an emoji ping only while its bubble stands (line 48); a ping on
## this machine's own player has none (lines 43, 48).
func hint_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for peer: int in _marks:
		var mark := _marks[peer]
		if not is_instance_valid(mark) or mark.on_self() or not mark.arrow_on():
			continue
		out.append({"at": mark.point(), "colour": mark.colour, "priority": ARROW_PRIORITY, "emoji": mark.emoji})
	return out


## A speech-bubble sticker in `colour` (line 31): a round part with a cream middle (MIDDLE_SHARE of it)
## and an ink rim for the emoji, and a short tail down to its tip, all with the icons' ink outline. Made
## once per colour.
static func bubble(colour: Color) -> ImageTexture:
	var key := colour.to_html()
	if _bubbles.has(key):
		return _bubbles[key]
	var img := Image.create(PX, PX, false, Image.FORMAT_RGBA8)
	var cx := (PX - 1) * 0.5
	for y in PX:
		for x in PX:
			var d := Vector2(x - cx, y - BUBBLE_Y).length() - BUBBLE_R
			if y > BUBBLE_Y and y <= TIP_Y:
				# The tail narrows from half the round part's width to a point at the tip.
				var half := BUBBLE_R * 0.5 * (TIP_Y - y) / (TIP_Y - BUBBLE_Y)
				d = minf(d, absf(x - cx) - half)
			var a := clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var inner := Vector2(x - cx, y - BUBBLE_Y).length() - BUBBLE_R * MIDDLE_SHARE
			var face := colour
			if inner < 0.0:
				face = CREAM.lerp(INK, clampf(inner + 1.0, 0.0, 1.0))
			elif inner < 3.5:
				face = INK.lerp(colour, clampf(inner - 2.5, 0.0, 1.0))
			var px := face.lerp(INK, clampf(d + 4.0, 0.0, 1.0))
			px.a = a
			img.set_pixel(x, y, px)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_bubbles[key] = tex
	return tex
