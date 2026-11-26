// A Stage present's wrapping paper (core/137; the old game/campaign/gift_paper.gdshader, Q1591): the paper
// colour with the Collection's icon as a repeating pattern in its ink colour. The pattern is mapped from
// the box's own object-space position (the face's two axes), so it needs no UVs and tiles the same on
// every face; a half-drop repeat, like printed wrapping paper. Present sets paper, ink, icon, tiles and
// ink_strength from the present's SockCollection and PresentTuning.
shader_type spatial;

uniform vec4 paper : source_color = vec4(0.98, 0.96, 0.9, 1.0);
uniform vec4 ink : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform sampler2D icon : source_color, filter_linear_mipmap, repeat_disable;
uniform float tiles = 2.0;
uniform float ink_strength = 0.85;
// The box's width: one face holds `tiles` icons across it.
uniform float size = 0.3;
uniform float roughness_value = 0.45;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec3 n = abs(local_normal);
	vec2 uv;
	if (n.x > n.y && n.x > n.z) {
		uv = local_pos.zy;
	} else if (n.y > n.z) {
		uv = local_pos.xz;
	} else {
		uv = local_pos.xy;
	}
	uv = uv / size * tiles;
	float row = floor(uv.y);
	uv.x += mod(row, 2.0) * 0.5;
	vec2 cell = fract(uv);
	// The icon sits in the middle of its cell, a little smaller, so neighbours do not touch.
	vec2 p = (cell - 0.5) / 0.7 + 0.5;
	float a = 0.0;
	if (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) {
		a = texture(icon, p).a;
	}
	ALBEDO = mix(paper.rgb, ink.rgb, a * ink_strength);
	ROUGHNESS = roughness_value;
}
