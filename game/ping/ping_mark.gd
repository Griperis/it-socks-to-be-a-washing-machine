## One player's ping as this machine draws it (core/43 lines 22-39; PingMarks makes one per standing
## ping). Looks only.
##
## A highlight (lines 22-30): the pinged thing is outlined in the pinger's colour, through walls,
## `outline_width` times the crosshair's outline, after it: a Teammate's avatar and a thing with an
## Outline get a second Outline of this mark's style beside their own; a Mess Sock or Pair a live copy of
## its Looks (the Mess draws in batches), outlined and following it (line 23). Nothing to outline (a bare
## spot, a Sock picked up since) is the Ring lying on the surface (lines 25, 26). Nothing at all is drawn
## on this machine's own player (line 29).
## An emoji (lines 31-39): the Sticker over the pinged thing, and the OverHead copy beside the pinger's
## head (not on the pinger's own machine, line 38), both hidden behind walls (line 36) and gone with the
## bubble's time (line 35).
## Both pop in (line 27) and fade over the ping's last second (line 28).
class_name PingMark
extends Node3D

## The rim's colour (the icons' ink).
const INK_RIM := KeycapStyle.INK

@onready var _ring: Node3D = $Ring
@onready var _rim: MeshInstance3D = $Ring/Rim
@onready var _band: MeshInstance3D = $Ring/Band
@onready var _sticker: Sprite3D = $Sticker
@onready var _over_head: Sprite3D = $OverHead

## The pinger's peer, the ping's serial and its entry (Pings.pings).
var peer := -1
var n := -1
var entry := {}
## The pinger's colour, and the emoji's name ("" for a highlight).
var colour := Color.WHITE
var emoji := ""
## How far it has popped in (pop_from to 1), and its fade (1 to 0) now.
var grow := 0.01
var alpha := 1.0
## Whether a wall hid the sticker and the copy beside the head as of the last physics tick; until a tick
## has asked, both are hidden (line 36).
var sticker_hidden := true
var head_hidden := true

var _marks: PingMarks
var _tuning: PingTuning
var _style: OutlineStyle
## The Outline this mark added beside a target's own, and that target's own.
var _outline: Outline = null
var _beside: Outline = null
## The live copy of a pinged Mess Sock, and its Sock.
var _copy: Node3D = null
var _copy_sock := -1
var _sticker_at := Vector3.ZERO
var _head_at := Vector3.ZERO
var _shown_alpha := -1.0
var _on_self := false
var _bubble_on := false


## Made by PingMarks for player `p_peer`'s ping `p_entry`.
func setup(marks: PingMarks, p_peer: int, p_entry: Dictionary) -> void:
	_marks = marks
	_tuning = marks.tuning()
	peer = p_peer
	entry = p_entry
	n = int(entry.get("n", -1))
	colour = marks.colour_of(peer)
	emoji = Pings.emoji_of(entry)
	grow = _tuning.pop_from
	_style = OutlineStyle.new()
	_style.colour = colour
	_style.width = _tuning.outline_width
	_style.shells = Outline.AIM.shells.duplicate()
	_style.priority = _tuning.outline_priority
	_make_ring()
	_sticker.visible = false
	_over_head.visible = false
	_ring.visible = false
	if emoji != "":
		_dress_sticker(_sticker, 1.0)
		_dress_sticker(_over_head, _tuning.head_share)


func _exit_tree() -> void:
	_drop_outline()
	if _copy != null and is_instance_valid(_copy):
		_copy.queue_free()
	_copy = null


# --- Read back -----------------------------------------------------------------------------------

## Whether this machine's own player is the one pinged (nothing is drawn on them, no arrow).
func on_self() -> bool:
	return int(entry.get("mate", -1)) == _marks.local_peer()


## Whether the hint arrow still points at it: an emoji while its bubble stands, a highlight all its time.
func arrow_on() -> bool:
	return emoji == "" or bubble_left() > 0.0


## Seconds left of the emoji's bubble on this machine's clock (0 for a highlight or when over).
func bubble_left() -> float:
	if emoji == "":
		return 0.0
	var left := _marks.pings.left_of(peer)
	return maxf(0.0, left - (float(entry.get("seconds", 0.0)) - _tuning.bubble_seconds))


## The Outline drawn round the pinged thing now, or null (none, or a ring instead).
func outline() -> Outline:
	if _copy != null and is_instance_valid(_copy):
		return Outline.of(_copy)
	return _outline if _outline != null and is_instance_valid(_outline) else null


## The ring, while it shows; else null.
func ring() -> Node3D:
	return _ring if _ring.visible else null


## The bubble over the pinged thing, while it shows; else null.
func sticker() -> Sprite3D:
	return _sticker if _sticker.visible else null


## The copy beside the pinger's head, while it shows; else null.
func over_head() -> Sprite3D:
	return _over_head if _over_head.visible else null


## Where the ping is now (line 49): on its Sock, Pair or Teammate, else its spot.
func point() -> Vector3:
	var sock := int(entry.get("sock", -1))
	if sock >= 0 and _marks.pings.lies_or_flies(sock):
		return _marks.pings.mess.where_of(sock)
	var mate := int(entry.get("mate", -1))
	var avatar := _marks.pings.avatar_of(mate) if mate >= 0 else null
	if avatar != null:
		return _marks.head_point(avatar)
	return entry.get("at", Vector3.ZERO) as Vector3


# --- Each frame ----------------------------------------------------------------------------------

## Puts the ping where it belongs this frame (its Sock, Pair, Teammate, thing or spot), popped in and
## fading with its time.
func place(delta: float) -> void:
	var t := _tuning
	var left := _marks.pings.left_of(peer)
	alpha = clampf(left / maxf(t.fade, 0.001), 0.0, 1.0)
	grow = move_toward(grow, 1.0, delta / maxf(t.pop, 0.001)) if delta > 0.0 else grow
	_on_self = on_self()
	var spot := entry.get("at", Vector3.ZERO) as Vector3
	var top := spot
	var thing := false
	var outlined: Outline = null
	var sock := int(entry.get("sock", -1))
	var mate := int(entry.get("mate", -1))
	var path := String(entry.get("path", ""))
	var mess := _marks.pings.mess
	if sock >= 0 and _marks.pings.lies_or_flies(sock):
		thing = true
		top = mess.where_of(sock) + Vector3.UP * t.sock_top
		if mess.is_pair(sock) and mess.state_of(sock) == Mess.State.LYING:
			top = mess.pose_of(sock).origin + Vector3.UP * SockDress.ball_radius(mess.design_of(sock))
		if emoji == "":
			_follow_copy(sock)
	else:
		_drop_copy()
		if mate >= 0:
			var avatar := _marks.pings.avatar_of(mate)
			if avatar != null:
				thing = true
				top = _marks.head_point(avatar)
				outlined = Outline.of(avatar)
		elif path != "":
			var node := _marks.pings.thing_at(path)
			if node != null:
				thing = true
				outlined = Outline.of(node)
	if emoji == "":
		_highlight(outlined, thing, spot)
	else:
		_place_sticker(top, thing)


## A highlight: the outline round what it follows (or the copy's), else the ring on the spot.
func _highlight(outlined: Outline, thing: bool, spot: Vector3) -> void:
	if _on_self:
		_drop_outline()
		_ring.visible = false
		return
	if _copy != null:
		_drop_outline()
	elif outlined != null:
		_add_outline(outlined)
	else:
		_drop_outline()
	_fade_outline()
	_ring.visible = not thing or (outlined == null and _copy == null)
	if _ring.visible:
		_lay_ring(spot)


## An emoji: the bubble over the target (its tail at `top`, lifted half as far over a thing) and the
## copy beside the pinger's head.
func _place_sticker(top: Vector3, thing: bool) -> void:
	var t := _tuning
	var left := bubble_left()
	_bubble_on = left > 0.0
	var bubble_alpha := minf(alpha, clampf(left / maxf(t.fade, 0.001), 0.0, 1.0))
	_sticker_at = top + Vector3.UP * (t.lift * 0.5 if thing else t.lift)
	_sticker.global_position = _sticker_at
	_sticker.scale = Vector3.ONE * grow
	_sticker.visible = not _on_self and _bubble_on and not sticker_hidden
	_fade_sprite(_sticker, bubble_alpha)
	var pinger := _marks.pings.avatar_of(peer) if peer != _marks.local_peer() else null
	var head_on := _bubble_on and pinger != null
	if head_on:
		var cam := _marks.camera()
		var right := cam.global_basis.x if cam != null else Vector3.RIGHT
		_head_at = _marks.head_point(pinger) + right * t.head_side
		_over_head.global_position = _head_at
		_over_head.scale = Vector3.ONE * grow
		_fade_sprite(_over_head, bubble_alpha)
	_over_head.visible = head_on and not head_hidden


## The wall tests of the bubble and the copy beside the head, one ray each, in the physics tick (line
## 36): the frame shows the answer, which may be a tick old.
func _physics_process(_delta: float) -> void:
	if emoji == "" or not _bubble_on:
		return
	sticker_hidden = _marks.occluded(_sticker_at)
	head_hidden = _marks.occluded(_head_at) if peer != _marks.local_peer() else true


# --- The outline ---------------------------------------------------------------------------------

## A second Outline of this mark's style beside `own` (the target's), outlining the same meshes.
func _add_outline(own: Outline) -> void:
	if _beside == own and _outline != null and is_instance_valid(_outline):
		return
	_drop_outline()
	_beside = own
	_outline = Outline.new()
	_outline.name = "PingOutline%d" % peer
	_outline.add_to_group(Outline.PING)
	_outline.meshes = own.meshes
	_outline.style = _style
	_outline.shown = true
	own.get_parent().add_child(_outline)
	_shown_alpha = -1.0


func _drop_outline() -> void:
	if _outline != null and is_instance_valid(_outline):
		_outline.get_parent().remove_child(_outline)
		_outline.queue_free()
	_outline = null
	_beside = null


## The style's shells take the fade's alpha (one style per mark).
func _fade_outline() -> void:
	if is_equal_approx(alpha, _shown_alpha):
		return
	_shown_alpha = alpha
	for m in _style.shell_materials():
		m.set_shader_parameter(&"colour", Color(colour, colour.a * alpha))


## The live copy of Sock `sock` that the outline goes round (line 23): its Looks, scaled `copy_scale`
## and raised `copy_raise`, where the Mess draws it now.
func _follow_copy(sock: int) -> void:
	var mess := _marks.pings.mess
	if _copy == null or _copy_sock != sock:
		_drop_copy()
		_copy = SockDress.make(mess.design_of(sock), SockDress.LYING, mess.is_pair(sock))
		_copy.name = "PingSock"
		var anim := _copy.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
		if anim != null:
			anim.active = false
		add_child(_copy)
		var own := Outline.of(_copy)
		if own != null:
			own.style = _style
			own.shown = true
		_copy_sock = sock
		_shown_alpha = -1.0
	var drawn: Variant = mess.drawn_flight_of(sock) if mess.state_of(sock) == Mess.State.FLYING else null
	var at: Transform3D = drawn if drawn is Transform3D \
			else mess.lying_drawn_pose(sock) * Transform3D(Basis.from_scale(Vector3.ONE * SockDress.scale_of(mess.design_of(sock))))
	_copy.global_transform = at * Transform3D(Basis.from_scale(Vector3.ONE * _tuning.copy_scale), Vector3(0.0, _tuning.copy_raise, 0.0))


func _drop_copy() -> void:
	if _copy != null and is_instance_valid(_copy):
		_copy.queue_free()
	_copy = null
	_copy_sock = -1


# --- The ring ------------------------------------------------------------------------------------

## The ring's two tori (line 25): the ink rim `ring_rim` wider all round, then the band in the colour.
func _make_ring() -> void:
	var t := _tuning
	for pair: Array in [[_rim, INK_RIM, t.ring_inner - t.ring_rim, t.ring_outer + t.ring_rim], [_band, colour, t.ring_inner, t.ring_outer]]:
		var mi := pair[0] as MeshInstance3D
		var torus := (mi.mesh as TorusMesh).duplicate() as TorusMesh
		torus.inner_radius = float(pair[2])
		torus.outer_radius = float(pair[3])
		mi.mesh = torus
		mi.scale = Vector3(1.0, t.ring_squash, 1.0)
		var m := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = pair[1]
		mi.material_override = m


## Lays the ring flat on the surface at `at` by the ping's normal, raised `ring_raise`, grown with the
## camera's distance and never smaller across than `min_ring` of the screen's height (line 26).
func _lay_ring(at: Vector3) -> void:
	var t := _tuning
	var up := (entry.get("normal", Vector3.UP) as Vector3).normalized()
	if up.length() < 0.5:
		up = Vector3.UP
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var cam := _marks.camera()
	var far := 1.0
	if cam != null:
		var dist := cam.global_position.distance_to(at)
		var readable := t.min_ring * 2.0 * tan(deg_to_rad(cam.fov) * 0.5) * dist / (2.0 * t.ring_outer)
		far = maxf(1.0, maxf(dist * t.ring_grow, readable))
	_ring.global_transform = Transform3D(Basis(side, up, side.cross(up)).scaled(Vector3.ONE * far * grow), at + up * t.ring_raise)
	for mi: MeshInstance3D in [_rim, _band]:
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color.a = alpha


# --- The stickers --------------------------------------------------------------------------------

## A sticker: the bubble in the colour with the emoji's icon in it, `share` of the full size, a fixed
## size on screen (line 32), its tail's tip on its node.
func _dress_sticker(s: Sprite3D, share: float) -> void:
	var t := _tuning
	var cam := _marks.camera()
	var fov := cam.fov if cam != null else 75.0
	var px := t.size * 2.0 * tan(deg_to_rad(fov) * 0.5) / PingMarks.PX * share
	s.texture = PingMarks.bubble(colour)
	s.pixel_size = px
	s.offset = Vector2(0.0, PingMarks.TIP_Y - PingMarks.PX * 0.5)
	var icon := s.get_node(^"Emoji") as Sprite3D
	var tex := UiIcons.texture("emoji_" + emoji)
	icon.texture = tex
	if tex != null:
		var icon_px := px * PingMarks.PX * t.icon_share / float(tex.get_height())
		icon.pixel_size = icon_px
		icon.offset = Vector2(0.0, (PingMarks.TIP_Y - PingMarks.BUBBLE_Y) * px / icon_px)


func _fade_sprite(s: Sprite3D, a: float) -> void:
	s.modulate.a = a
	(s.get_node(^"Emoji") as Sprite3D).modulate.a = a
