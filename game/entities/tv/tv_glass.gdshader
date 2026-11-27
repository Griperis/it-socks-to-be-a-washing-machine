// The TV's glass (assets/27; ported from the old game's game/devices/tv_screen.gdshader, flat/47 and flat/62):
// dark glass that catches the room's light, with the picture of the TV's SubViewport (`feed`, set by TvScreen)
// glowing through it with a CRT's look: a slight bulge, scanlines and a soft vignette. `noise` swaps the picture
// for static (square grains whatever the picture's shape); `power` 0..1 switches it on, and switching off
// collapses the picture to a bright line that fades. The Looks' clips key `power` and `noise` (on, off, static).
shader_type spatial;
render_mode blend_mix, specular_schlick_ggx;

uniform sampler2D feed : source_color, hint_default_black, filter_linear, repeat_disable;
uniform float power : hint_range(0.0, 1.0) = 0.0;
uniform float noise : hint_range(0.0, 1.0) = 0.0;
uniform float brightness = 1.5;
uniform float lines = 120.0;
uniform vec3 glass : source_color = vec3(0.05, 0.07, 0.065);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 c = UV - 0.5;
	vec2 uv = 0.5 + c * (1.0 + 0.1 * dot(c, c));
	// Switching on or off: the picture opens from (or collapses to) a line across the middle.
	float open = mix(0.006, 1.0, smoothstep(0.35, 1.0, power));
	uv.y = 0.5 + (uv.y - 0.5) / open;
	float inside = step(0.0, uv.y) * step(uv.y, 1.0) * step(0.0, uv.x) * step(uv.x, 1.0);
	vec3 pic = texture(feed, clamp(uv, 0.0, 1.0)).rgb;
	vec2 fs = max(vec2(textureSize(feed, 0)), vec2(1.0));
	float n = hash(floor(UV * vec2(lines * fs.x / fs.y, lines)) + floor(TIME * 25.0) * vec2(1.7, 3.1));
	pic = mix(pic, vec3(n * 0.9), noise);
	float scan = 0.82 + 0.18 * sin(uv.y * lines * 6.2832);
	float vignette = smoothstep(0.78, 0.3, length(c * vec2(1.0, 1.15)));
	vec3 lit = pic * scan * vignette * inside * brightness * smoothstep(0.0, 0.3, power);
	ALBEDO = glass;
	ROUGHNESS = 0.16;
	SPECULAR = 0.6;
	EMISSION = lit;
}
