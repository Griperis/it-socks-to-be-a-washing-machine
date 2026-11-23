// A mirror's glass (the old house/mirror.gdshader; assets/07): the round or oval pane inscribed in its
// quad. Live, it shows the reflection camera's picture (game/devices/mirror.gd), as light of its own so
// the room's lighting and tonemapping act on it once, like on everything seen directly. Off (the Low
// preset, or before its first picture), a soft lit gradient with a diagonal sheen stands in.
shader_type spatial;
render_mode cull_back;

// The reflection: linear HDR (the viewport renders with use_hdr_2d), mirrored left to right here.
uniform sampler2D reflection : hint_default_black, filter_linear, repeat_disable;
uniform bool live = false;
// A faint cool tint of the glass over the reflection.
uniform vec3 tint = vec3(0.93, 0.97, 1.0);
uniform vec3 fake_top : source_color = vec3(0.86, 0.92, 0.95);
uniform vec3 fake_bottom : source_color = vec3(0.6, 0.68, 0.74);

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	if (dot(c, c) > 1.0) {
		discard;
	}
	if (live) {
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		EMISSION = texture(reflection, vec2(1.0 - UV.x, UV.y)).rgb * tint;
	} else {
		vec3 col = mix(fake_top, fake_bottom, smoothstep(0.0, 1.0, UV.y));
		float sheen = exp(-pow((UV.x + UV.y - 0.8) * 5.0, 2.0)) * 0.18;
		ALBEDO = col + sheen;
		ROUGHNESS = 0.2;
		SPECULAR = 0.7;
	}
}
