// A wall face with a tile wainscot (house/04 D01): the old bathroom's tiles (make_flat.py
// make_wall_tiles: to 1.2 m, a trim band 3.5 cm over them), the room's paint above. Heights are
// over the piece's origin, which is on its storey's floor line for every wall-like kit piece. The
// tiles run world triplanar like the library's tiled materials, so they line up across pieces.
shader_type spatial;

uniform vec4 paint : source_color = vec4(0.8, 0.91, 0.88, 1.0);
uniform float paint_roughness : hint_range(0.0, 1.0) = 0.9;
uniform sampler2D tiles : source_color, filter_linear_mipmap, repeat_enable;
// The metres one repeat of the tile image covers.
uniform float tile_repeat : hint_range(0.1, 4.0) = 0.6;
uniform float tile_roughness : hint_range(0.0, 1.0) = 0.3;
// The wainscot's top over the floor line, and the trim band over it.
uniform float top : hint_range(0.0, 3.0) = 1.2;
uniform float band : hint_range(0.0, 0.2) = 0.035;
uniform vec4 band_colour : source_color = vec4(0.98, 0.96, 0.91, 1.0);
uniform float band_roughness : hint_range(0.0, 1.0) = 0.55;

varying float height;
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	height = VERTEX.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (height < top) {
		vec3 w = pow(abs(world_normal), vec3(4.0));
		w /= (w.x + w.y + w.z);
		vec3 p = world_pos / tile_repeat;
		vec3 c = texture(tiles, p.zy * vec2(1.0, -1.0)).rgb * w.x
				+ texture(tiles, p.xz).rgb * w.y
				+ texture(tiles, p.xy * vec2(1.0, -1.0)).rgb * w.z;
		ALBEDO = c;
		ROUGHNESS = tile_roughness;
	} else if (height < top + band) {
		ALBEDO = band_colour.rgb;
		ROUGHNESS = band_roughness;
	} else {
		ALBEDO = paint.rgb;
		ROUGHNESS = paint_roughness;
	}
}
