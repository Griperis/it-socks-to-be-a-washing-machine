## How an Outline draws (core/11): its colour, width, shells, pulse and render priority. One `.tres`
## per use: aim.tres (the crosshair's warm white), full.tres (the red "full" tint on a drawer with no
## room, Q221); pings and X-rays add their own.
class_name OutlineStyle
extends Resource

const MASK_SHADER := preload("res://game/outline/outline_mask.gdshader")
const SHELL_SHADER := preload("res://game/outline/outline.gdshader")

## The shells' colour (its alpha scales them all).
@export var colour := Color(1.0, 0.94, 0.82)
## How much wider than the crosshair's outline it is (each shell's growth times this).
@export var width := 1.0
## Each shell, inner to outer: x its growth (a fraction of the distance to the camera, so the outline
## keeps one width on screen), y its opacity.
@export var shells: Array[Vector2] = [Vector2(0.003, 0.9), Vector2(0.006, 0.45), Vector2(0.0095, 0.2)]
@export_group("Pulse")
## Breaths a second (0: it holds still).
@export var pulse_hz := 0.0
## How much wider it grows at the peak (a factor of its width).
@export var pulse_grow := 0.0
## How much brighter it is at the peak.
@export var pulse_bright := 0.0
## How much fainter it is at the trough.
@export var pulse_fade := 0.0
@export_group("")
## The mask pass's render priority; the shells take the next ones. A later outline (an X-ray's) takes
## a higher one, so its mask never cuts an earlier one's shells.
@export_range(-128, 120, 1) var priority := 100

var _material: ShaderMaterial = null


## The mask pass with the shells chained after it, one material shared by every copy of this style.
## Built on first use; a change to the style afterwards needs rebuild().
func material() -> ShaderMaterial:
	if _material == null:
		_material = _build()
	return _material


## Builds the material again on its next use, after a change to the style.
func rebuild() -> void:
	_material = null


## The shell passes of the material, inner to outer.
func shell_materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var m := material().next_pass as ShaderMaterial
	while m != null:
		out.append(m)
		m = m.next_pass as ShaderMaterial
	return out


func _build() -> ShaderMaterial:
	var mask := ShaderMaterial.new()
	mask.shader = MASK_SHADER
	mask.render_priority = priority
	var prev := mask
	for i in shells.size():
		var shell := ShaderMaterial.new()
		shell.shader = SHELL_SHADER
		shell.render_priority = priority + 1 + i
		shell.set_shader_parameter(&"colour", colour)
		shell.set_shader_parameter(&"grow", shells[i].x * width)
		shell.set_shader_parameter(&"strength", shells[i].y)
		shell.set_shader_parameter(&"pulse_hz", pulse_hz)
		shell.set_shader_parameter(&"pulse_grow", pulse_grow)
		shell.set_shader_parameter(&"pulse_bright", pulse_bright)
		shell.set_shader_parameter(&"pulse_fade", pulse_fade)
		prev.next_pass = shell
		prev = shell
	return mask
