// The knocked player's vignette (coop/10, Q2490): the screen's edges darken, from `start` (0 the
// middle, 1 a corner) to `dark` at the corners. Its numbers come from KnockdownTuning.
shader_type canvas_item;

uniform float dark : hint_range(0.0, 1.0) = 0.7;
uniform float start : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	float r = length((UV - 0.5) * 2.0) / 1.41421356;
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(start, 1.0, r) * dark);
}
