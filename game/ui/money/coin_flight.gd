## The flight of a payout to its HUD counter (docs/architecture/economy.md "The HUD counters and the
## flight", the old coin_flight.gd): a "+N" with its Currency's icon pops at a screen point, grows in with
## a little overshoot, holds, then bursts into N icons that spread out and curve into the counter from
## below, shrinking, staggered so the whole payout ends in `total` seconds whatever N. A bonus (Q2668)
## has no "+N" and no icons: its N landings are only spread over the same time, `bonus_delay` later.
## Looks only: the Bank holds the decided numbers; this counts what is still flying on this machine.
## The "+N" and the icons are `money_pop.tscn` and `flying_icon.tscn`, instanced from a pool.
class_name CoinFlight
extends Control

## `count` of `currency` reached its counter.
signal landed(currency: Currency, count: int)

@export var tuning: CoinFlightTuning
@export var pop_scene: PackedScene
@export var icon_scene: PackedScene

## Where each currency flies to: {Currency: the counter's icon}. The counters set it.
var targets: Dictionary[Currency, Control] = {}

## What is still on its way to each counter: {Currency: int}.
var _pending: Dictionary[Currency, int] = {}
## The "+N" showing now: [{"node", "at", "amount", "currency"}].
var _pops: Array[Dictionary] = []
## The icons flying now: [{"node", "from", "off", "currency"}].
var _flying: Array[Dictionary] = []
var _pop_pool: Array[Control] = []
var _icon_pool: Array[TextureRect] = []
var _rng := RandomNumberGenerator.new()


## Pops "+`amount`" of `currency` at `at` (screen pixels, kept inside the screen); its icons follow.
func pay(at: Vector2, amount: int, currency: Currency) -> void:
	if amount <= 0 or currency == null:
		return
	_pending[currency] = pending(currency) + amount
	var pop := _take_pop()
	(pop.get_node("Amount") as Label).text = "+%d" % amount
	(pop.get_node("Amount") as Label).add_theme_color_override(&"font_color", currency.tint)
	(pop.get_node("Icon") as TextureRect).texture = currency.icon
	pop.reset_size()
	at = on_screen(at, pop.size)
	pop.pivot_offset = pop.size * 0.5
	pop.position = at - pop.size * 0.5
	pop.scale = Vector2.ZERO
	pop.visible = true
	var entry := {"node": pop, "at": at, "amount": amount, "currency": currency}
	_pops.append(entry)
	var tween := pop.create_tween().set_parallel(true)
	tween.tween_method(_pop_scale.bind(pop), 0.0, 1.0, maxf(tuning.pop_in, 0.01))
	tween.tween_callback(_burst.bind(entry)).set_delay(tuning.hold)


## A bonus of `amount` `currency` (Q2668): no "+N", no icons; they land one by one in the counter over
## the payout's time, `bonus_delay` after a "+N"'s first landing.
func pay_bonus(amount: int, currency: Currency) -> void:
	if amount <= 0 or currency == null:
		return
	_pending[currency] = pending(currency) + amount
	var tween := create_tween().set_parallel(true)
	var first := tuning.first_landing(true)
	for k in amount:
		tween.tween_callback(_arrive.bind(currency)).set_delay(first + tuning.landing_after(k, amount))


## How much of `currency` is still on its way to its counter on this machine.
func pending(currency: Currency) -> int:
	return int(_pending.get(currency, 0))


## The "+N" texts showing now, e.g. ["+10", "+1"].
func pop_texts() -> Array[String]:
	var out: Array[String] = []
	for p in _pops:
		out.append("+%d" % int(p["amount"]))
	return out


## Where each "+N" showing now pops (screen pixels), in pop_texts()'s order.
func pop_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in _pops:
		out.append(p["at"] as Vector2)
	return out


## How many icons fly now.
func flying() -> int:
	return _flying.size()


## `at` moved so a box of `box` centred on it stays `margin` inside the screen.
func on_screen(at: Vector2, box: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	var half := box * 0.5 + Vector2.ONE * tuning.margin
	return Vector2(clampf(at.x, half.x, maxf(half.x, vp.x - half.x)), clampf(at.y, half.y, maxf(half.y, vp.y - half.y)))


## The "+N" grows in with a little overshoot (`u` 0 to 1).
func _pop_scale(u: float, pop: Control) -> void:
	pop.scale = Vector2.ONE * (u * (1.0 + 0.25 * sin(u * PI)))


## The "+N" has held: it bursts into its icons and goes back to the pool.
func _burst(entry: Dictionary) -> void:
	var pop: Control = entry["node"]
	pop.visible = false
	_pop_pool.append(pop)
	_pops.erase(entry)
	var amount := int(entry["amount"])
	var currency: Currency = entry["currency"]
	var at: Vector2 = entry["at"]
	for k in amount:
		var node := _take_icon()
		node.texture = currency.icon
		node.size = Vector2.ONE * tuning.icon
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2.ONE
		node.position = at - node.size * 0.5
		node.visible = true
		var off := Vector2.from_angle(_rng.randf() * TAU) * tuning.radius * sqrt(_rng.randf_range(0.15, 1.0))
		var icon := {"node": node, "from": at, "off": off, "currency": currency}
		_flying.append(icon)
		var tween := node.create_tween()
		tween.tween_method(_burst_step.bind(icon), 0.0, 1.0, maxf(tuning.burst, 0.01)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_interval(tuning.landing_after(k, amount))
		tween.tween_method(_fly_step.bind(icon), 0.0, 1.0, maxf(tuning.flight, 0.01))
		tween.tween_callback(_land.bind(icon))


## An icon spreads out of its "+N" (`out` 0 to 1, eased).
func _burst_step(out: float, icon: Dictionary) -> void:
	var node: TextureRect = icon["node"]
	node.position = (icon["from"] as Vector2) + (icon["off"] as Vector2) * out - node.size * 0.5


## An icon flies from where it burst to its counter (`u` 0 to 1): out a little further along the
## burst, then round into the counter from below, shrinking.
func _fly_step(u: float, icon: Dictionary) -> void:
	var node: TextureRect = icon["node"]
	var target: Control = targets.get(icon["currency"] as Currency)
	var to := target.get_global_rect().get_center() if target != null and is_instance_valid(target) else Vector2(40.0, 40.0)
	var e := smoothstep(0.0, 1.0, u)
	var off: Vector2 = icon["off"]
	var start: Vector2 = (icon["from"] as Vector2) + off
	node.position = start.bezier_interpolate(start + off * 1.2, to + Vector2(40.0, 140.0), to, e) - node.size * 0.5
	node.scale = Vector2.ONE * lerpf(1.0, tuning.land_scale, e)


## An icon reached its counter: back to the pool.
func _land(icon: Dictionary) -> void:
	var node: TextureRect = icon["node"]
	node.visible = false
	_icon_pool.append(node)
	_flying.erase(icon)
	_arrive(icon["currency"] as Currency)


func _arrive(currency: Currency) -> void:
	_pending[currency] = maxi(0, pending(currency) - 1)
	landed.emit(currency, 1)


func _take_pop() -> Control:
	if not _pop_pool.is_empty():
		return _pop_pool.pop_back()
	var pop := pop_scene.instantiate() as Control
	add_child(pop)
	return pop


func _take_icon() -> TextureRect:
	if not _icon_pool.is_empty():
		return _icon_pool.pop_back()
	var node := icon_scene.instantiate() as TextureRect
	add_child(node)
	return node
