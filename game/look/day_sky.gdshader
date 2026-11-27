// The sky (core/18, core/160): the old game's three HDRI panoramas (day, dusk, night) blended by the hour's `phase`,
// ported from the old day_sky.gdshader. `phase` 0 is the day photo alone, the zoo's fixed noon (its dusk and night
// are never sampled). The window view seen from the ground up is each photo's sky above its `sky_floor`, with a
// little haze at the horizon; the light the sky gives (ambient and reflections, the cubemap pass) is mostly grey with
// a warm tint so the green lawn does not tint the Socks. It reads no lights and no TIME, so Godot re-bakes it only
// when a uniform changes (DayLight sets `phase` and `energy` only when they moved enough).
shader_type sky;

uniform sampler2D day_panorama : filter_linear, repeat_enable, hint_default_black;
uniform sampler2D dusk_panorama : filter_linear, repeat_enable, hint_default_black;
uniform sampler2D night_panorama : filter_linear, repeat_enable, hint_default_black;
// Brings each panorama's average brightness to about 1 (the old values: day, dusk, night).
uniform float normalise = 8.0;
uniform float dusk_normalise = 1.85;
uniform float night_normalise = 21.7;
// How far each panorama is turned (in turns) so its sun or bright spot sits where the Sun light is: the day's sun at
// the noon sun, the dusk glow at the sunset sun, the night's street lamp at the moon.
uniform float turn = 0.67;
uniform float dusk_turn = 0.393;
uniform float night_turn = 0.13;
// 0 day, 1 dusk, 2 night; fractions blend the neighbours.
uniform float phase : hint_range(0.0, 2.0) = 0.0;
// The overall brightness (the old noon: 0.9).
uniform float energy = 0.9;
// The photographed suns and lamps are clipped to this after normalising, so they do not outshine the Sun light.
uniform float clip = 8.0;
uniform float light_saturation : hint_range(0.0, 1.0) = 0.3;
uniform vec3 light_tint : source_color = vec3(1.0, 0.95, 0.88);
// The elevation (degrees) above which each photo is clear sky, over its tallest tree, roof or pole.
uniform float sky_floor = 36.0;
uniform float dusk_sky_floor = 33.0;
uniform float night_sky_floor = 56.0;
uniform float horizon_haze : hint_range(0.0, 1.0) = 0.35;

vec3 sample_pano(sampler2D pano, vec3 dir, float t, float norm, float floor_deg, bool sky_only) {
	float v = acos(clamp(dir.y, -1.0, 1.0)) / PI;
	if (sky_only) {
		// Map elevation 0..90 degrees onto floor_deg..90, so only the photo's sky shows.
		float f = radians(floor_deg);
		float e = max(asin(clamp(dir.y, -1.0, 1.0)), 0.0);
		v = (PI * 0.5 - (f + e * (PI * 0.5 - f) / (PI * 0.5))) / PI;
	}
	vec2 uv = vec2(atan(dir.x, -dir.z) / TAU + 0.5 + t, v);
	return min(textureLod(pano, uv, 0.0).rgb * norm, vec3(clip));
}

void sky() {
	float w_day = clamp(1.0 - phase, 0.0, 1.0);
	float w_night = clamp(phase - 1.0, 0.0, 1.0);
	float w_dusk = 1.0 - w_day - w_night;
	bool sky_only = !AT_CUBEMAP_PASS;
	vec3 c = vec3(0.0);
	if (w_day > 0.0) {
		c += w_day * sample_pano(day_panorama, EYEDIR, turn, normalise, sky_floor, sky_only);
	}
	if (w_dusk > 0.0) {
		c += w_dusk * sample_pano(dusk_panorama, EYEDIR, dusk_turn, dusk_normalise, dusk_sky_floor, sky_only);
	}
	if (w_night > 0.0) {
		c += w_night * sample_pano(night_panorama, EYEDIR, night_turn, night_normalise, night_sky_floor, sky_only);
	}
	if (AT_CUBEMAP_PASS) {
		float grey = dot(c, vec3(0.2126, 0.7152, 0.0722));
		c = mix(vec3(grey), c, light_saturation) * light_tint;
	} else {
		float pale = max(c.r, max(c.g, c.b));
		c = mix(c, vec3(pale), horizon_haze * (1.0 - smoothstep(0.0, 0.45, EYEDIR.y)));
	}
	COLOR = c * energy;
}
