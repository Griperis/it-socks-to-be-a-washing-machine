// One shell of the outline (Outline, game/outline/outline.gd): the target grown along its averaged
// normals by `grow` times its distance to the camera, so the outline keeps one width on screen,
// drawn in `colour` only outside the silhouette the mask pass (outline_mask.gdshader) marked.
// With `pulse_hz` above 0 it breathes: up to `pulse_grow` times wider and `pulse_bright` brighter at
// the peak, `pulse_fade` fainter at the trough. Ported from the old game's game/ui/outline.gdshader.
shader_type spatial;
render_mode unshaded, cull_back, depth_test_disabled, depth_draw_never, shadows_disabled, blend_mix;
stencil_mode read, compare_not_equal, 77;

uniform vec4 colour : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform float grow = 0.003;
uniform float strength = 1.0;
uniform float pulse_hz = 0.0;
uniform float pulse_grow = 0.0;
uniform float pulse_bright = 0.0;
uniform float pulse_fade = 0.0;

float pulse(float t) {
	return pulse_hz > 0.0 ? 0.5 + 0.5 * sin(t * TAU * pulse_hz) : 0.0;
}

void vertex() {
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	v.xyz += n * grow * (1.0 + pulse_grow * pulse(TIME)) * max(-v.z, 0.05);
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	float p = pulse(TIME);
	ALBEDO = colour.rgb * (1.0 + pulse_bright * p);
	ALPHA = colour.a * strength * (1.0 - (pulse_hz > 0.0 ? pulse_fade * (1.0 - p) : 0.0));
}
