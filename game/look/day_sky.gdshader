// The zoo's sky (core/18): the old game's day HDRI at a fixed noon, ported from the old day_sky.gdshader with the
// dusk and night panoramas left out (they come with a day cycle). The window view seen from the ground up is the
// photo's sky above `sky_floor`, with a little haze at the horizon; the light the sky gives (ambient and
// reflections, the cubemap pass) is mostly grey with a warm tint so the green lawn does not tint the Socks.
shader_type sky;

uniform sampler2D day_panorama : filter_linear, repeat_enable, hint_default_black;
// Brings the panorama's average brightness to about 1 (the old value for the day photo).
uniform float normalise = 8.0;
// How far the panorama is turned (in turns) so its sun sits where the Sun light is.
uniform float turn = 0.67;
// The overall brightness (the old noon: 0.9).
uniform float energy = 0.9;
// The photographed sun is clipped to this after normalising, so it does not outshine the Sun light.
uniform float clip = 8.0;
uniform float light_saturation : hint_range(0.0, 1.0) = 0.3;
uniform vec3 light_tint : source_color = vec3(1.0, 0.95, 0.88);
// The elevation (degrees) above which the photo is clear sky, over its tallest tree or roof.
uniform float sky_floor = 36.0;
uniform float horizon_haze : hint_range(0.0, 1.0) = 0.35;

vec3 sample_pano(vec3 dir, bool sky_only) {
	float v = acos(clamp(dir.y, -1.0, 1.0)) / PI;
	if (sky_only) {
		float f = radians(sky_floor);
		float e = max(asin(clamp(dir.y, -1.0, 1.0)), 0.0);
		v = (PI * 0.5 - (f + e * (PI * 0.5 - f) / (PI * 0.5))) / PI;
	}
	vec2 uv = vec2(atan(dir.x, -dir.z) / TAU + 0.5 + turn, v);
	return min(textureLod(day_panorama, uv, 0.0).rgb * normalise, vec3(clip));
}

void sky() {
	vec3 c = sample_pano(EYEDIR, !AT_CUBEMAP_PASS);
	if (AT_CUBEMAP_PASS) {
		float grey = dot(c, vec3(0.2126, 0.7152, 0.0722));
		c = mix(vec3(grey), c, light_saturation) * light_tint;
	} else {
		float pale = max(c.r, max(c.g, c.b));
		c = mix(c, vec3(pale), horizon_haze * (1.0 - smoothstep(0.0, 0.45, EYEDIR.y)));
	}
	COLOR = c * energy;
}
