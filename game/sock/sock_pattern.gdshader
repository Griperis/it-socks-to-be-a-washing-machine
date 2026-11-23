// A Sock's colour, pattern, print and cloth (assets/01): the old game's sock_pattern.gdshader and
// sock_pattern.gdshaderinc in one file, ported unchanged. One shader serves the Mess's MultiMeshes
// and single meshes (a Looks' Body, SockLook.material()).
shader_type spatial;
render_mode cull_disabled;

// A Sock's look is one vec4, the same for the Mess's MultiMesh (INSTANCE_CUSTOM) and a single
// mesh (the `look` uniform). MessDrawing.look_data() packs it; every number is a whole number,
// exact in a 32-bit float:
//   x  pattern: 0 solid, 1 stripes, 2 bands, 3 checks, 4 dots, 5 print (MessDrawing.PATTERNS order),
//      plus 8 for a Dirty Sock (the old game's progression/38: greyed and stained, dirty_look()),
//      plus 16 * the patches (MessDrawing.PATCHES: 0 all, 1 top and toe, 2 heel and toe, 3 none)
//   y  print:   motif slot + 256 * coat slot + 65536 * layout
//               (slot = atlas cell + 1, 0 = none; layout 0 one big, 1 two, 2 band, 3 cuff)
//   z  colour 2 (trim, pattern marks): r * 65536 + g * 256 + b + 1 (sRGB bytes); 0 = derived
//   w  colour 3 (accent: coat marks, band lines): the same packing; 0 = colour 2
// The base colour is the instance colour (MultiMesh) or `base_color`.

uniform bool use_instance = false;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 look = vec4(0.0);
uniform float glow = 0.0;
// How dirty a single mesh is drawn (0 clean, 1 greyed and stained brown, Q1005); a Dirty Sock's
// look (x past 8) is drawn dirty anyway, in the Mess and in a single mesh alike.
uniform float dirt = 0.0;
// The print atlas (assets/sock/prints.png, its grid in SockLookTable), set by SockLook.
uniform sampler2D prints : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 prints_grid = vec2(12.0, 8.0);
// How much U (cuff -> toe) one face-width of the flattened tube spans: keeps motifs round.
uniform float print_aspect = 0.4;
// The U span between the cuff band and the toe cap where motifs sit.
uniform vec2 print_body = vec2(0.14, 0.82);
// Coat tiles across one face.
uniform float coat_tiles = 2.0;
// The cloth (SockLookTable.fabrics): 0 cotton (fine jersey knit), 1 wool (big knit stitches, a little
// heathered fuzz), 2 fuzzy (soft fluffy pile, no visible stitches). Every Sock has ribbed knit
// where the models' TrimMask V is 1 (its cuff); glTF flips V, so that is UV2.y = 0 here.
uniform float fabric = 0.0;
// The U span of the calf (cuff band to heel patch), where the "big" print layout sits, and the two
// U values that split the trim into cuff band | heel patch | toe cap (SockClothFit).
uniform vec2 calf_body = vec2(0.14, 0.82);
uniform vec2 patch_split = vec2(0.5, 0.5);
// Metres of cloth per unit of UV0: x along the Sock (U), y around it (V); sizes the stitches.
uniform vec2 cloth_size = vec2(0.30, 0.18);
// The knit (assets/05, SockKnit): one seamless tile, RG its normal (x around, y along toward the toe),
// B its roughness, A its cavity (assets_src/generate/sock/make_knit.py). Its mipmaps flatten it with
// distance, so it never shimmers; it fades out to the plain cloth between knit_fade.x and .y metres.
uniform sampler2D knit : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
// Stitches across and down one tile, and one stitch's size in metres (around, along).
uniform vec2 knit_tile_stitches = vec2(8.0, 8.0);
uniform vec2 knit_stitch = vec2(0.0045, 0.004);
uniform float knit_strength = 0.0;
uniform float knit_cavity = 0.5;
uniform vec2 knit_fade = vec2(3.0, 8.0);

varying vec4 v_color;
// flat: the look is whole numbers (patch, pattern, Dirty flag, packed colours); interpolated across a
// triangle it arrives a hair off (47.9999 for 48) and floor() would read another look per pixel.
varying flat vec4 v_custom;

void vertex() {
	v_color = COLOR;
	v_custom = INSTANCE_CUSTOM;
}

// sRGB to linear, as a source_color uniform is converted.
vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

vec3 unpack_rgb(float p) {
	p -= 1.0;
	float r = floor(p / 65536.0);
	float g = floor((p - r * 65536.0) / 256.0);
	float b = p - r * 65536.0 - g * 256.0;
	return to_linear(vec3(r, g, b) / 255.0);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// The cloth's surface detail: xy the slope (U, V) for NORMAL_MAP, z an albedo shade (1 = none).
// Detail fades out where it would shimmer (far away, in the Mess): each fade reaches zero by 0.3 to 0.6
// cycles per pixel, before the Nyquist limit of 0.5 where a point-sampled pattern turns to moire
// (progression/98; the fades used to end at 0.5 to 0.9).
vec3 cloth(vec2 uv, float rib) {
	vec2 m = uv * cloth_size;          // metres along and around
	vec2 slope = vec2(0.0);
	float shade = 1.0;
	// Ribbing: lengthwise ridges around the cuff, about 5 mm apart (wool 8 mm), a whole number
	// around so the seam is invisible.
	if (rib > 0.01) {
		float n = max(4.0, round(cloth_size.y / (fabric > 0.5 && fabric < 1.5 ? 0.008 : 0.005)));
		float cv = uv.y * n;
		float fw = fwidth(cv);
		float fade = rib * (1.0 - smoothstep(0.1, 0.3, fw));
		float h = 0.5 + 0.5 * cos(6.2831853 * cv);
		// The slope per rib: steep ridges, so a ribbed cuff reads from a step away.
		slope.y += fade * -3.14159 * sin(6.2831853 * cv) * 0.6;
		shade *= 1.0 - 0.09 * fade * (1.0 - h);
	}
	// The stitches themselves are the knit texture (knit_at); here only what each yarn adds.
	if (fabric > 0.5 && fabric < 1.5) {
		// Wool: a heathered, slightly fuzzy yarn.
		float fwn = length(fwidth(m * 260.0));
		shade *= 0.95 + 0.1 * mix(0.5, value_noise(m * 260.0), 1.0 - smoothstep(0.25, 0.6, fwn));
	} else if (fabric > 1.5) {
		// Fuzzy pile: soft blotchy nap over faint stitches.
		float e = 0.06;
		float n0 = value_noise(m * 140.0);
		float fw = length(fwidth(m * 140.0));
		float fade = 1.0 - smoothstep(0.25, 0.6, fw);
		slope += fade * 0.35 * vec2(value_noise(m * 140.0 + vec2(e, 0.0)) - n0, value_noise(m * 140.0 + vec2(0.0, e)) - n0) / e;
		shade *= 0.93 + 0.12 * mix(0.5, n0, fade);
	}
	return vec3(slope, shade);
}

// The knit tile at this point: xy the slope (U, V) as cloth() gives it, z the cavity, w the roughness;
// `amount` is the knit's strength already faded with distance.
vec4 knit_at(vec2 uv, float amount) {
	// A whole number of tiles around the tube, so the seam at V = 0 / 1 never shows.
	vec2 tile = knit_tile_stitches * knit_stitch;
	vec2 k = vec2(uv.y * max(1.0, round(cloth_size.y / tile.x)), uv.x * cloth_size.x / tile.y);
	vec4 t = texture(knit, k);
	vec2 n = t.rg * 2.0 - 1.0;
	// The tile's normal leans away from the slope: x around (V), y along (U).
	return vec4(-n.y * amount, -n.x * amount, mix(1.0, t.a, knit_cavity * clamp(amount, 0.0, 1.0)),
			mix(0.95, t.b, clamp(amount, 0.0, 1.0)));
}

// One atlas cell at local (0..1, top-left origin), with the derivatives of the unwrapped
// coordinate so mip selection never jumps at a tile or cell edge.
vec4 cell_tex(float cell, vec2 local, vec2 dx, vec2 dy) {
	vec2 cr = vec2(mod(cell, prints_grid.x), floor(cell / prints_grid.x));
	vec2 half_texel = vec2(0.5 / 256.0);
	vec2 l = clamp(local, half_texel, vec2(1.0) - half_texel);
	return textureGrad(prints, (cr + l) / prints_grid, dx / prints_grid, dy / prints_grid);
}

// A sticker of `size` face-widths centred at `c` in face space (its top toward the cuff).
vec4 sticker(float cell, vec2 f, vec2 c, float size, vec2 dx, vec2 dy) {
	vec2 local = (f - c) / size + 0.5;
	if (any(lessThan(local, vec2(0.0))) || any(greaterThan(local, vec2(1.0)))) {
		return vec4(0.0);
	}
	return cell_tex(cell, local, dx / size, dy / size);
}

vec3 sock_print(vec3 col, vec4 lk, vec2 uv, float trim, vec3 accent) {
	float layout = floor(lk.y / 65536.0);
	float coat = floor((lk.y - layout * 65536.0) / 256.0);
	float motif = lk.y - layout * 65536.0 - coat * 256.0;
	// Face space: x across one flat face (0..1, both faces read alike), y along it in
	// face-widths from the cuff. Seen from outside with the cuff up, V grows to the right on the
	// sock models and the sock balls (the old tools/blender/make_socks.py), so x follows V unflipped and
	// motifs read as drawn.
	vec2 f = vec2(fract(uv.y * 2.0), uv.x / print_aspect);
	vec2 dx = vec2(2.0 * dFdx(uv.y), dFdx(uv.x) / print_aspect);
	vec2 dy = vec2(2.0 * dFdy(uv.y), dFdy(uv.x) / print_aspect);
	float b0 = print_body.x / print_aspect;
	float b1 = print_body.y / print_aspect;
	float len = b1 - b0;

	if (coat > 0.5 && trim < 0.5) {
		float a = cell_tex(coat - 1.0, fract(f * coat_tiles), dx * coat_tiles, dy * coat_tiles).a;
		col = mix(col, accent, a);
	}
	if (motif < 0.5) {
		return col;
	}
	float cell = motif - 1.0;
	vec4 s = vec4(0.0);
	if (layout < 0.5) {
		// One big motif sits on the calf, never across the heel bend where the cloth stretches.
		float c0 = calf_body.x / print_aspect;
		float clen = (calf_body.y - calf_body.x) / print_aspect;
		s = sticker(cell, f, vec2(0.5, c0 + 0.5 * clen), min(1.0, clen), dx, dy);
	} else if (layout < 1.5) {
		float size = min(0.9, 0.5 * len);
		s = sticker(cell, f, vec2(0.5, b0 + 0.25 * len), size, dx, dy);
		vec4 s2 = sticker(cell, f, vec2(0.5, b0 + 0.75 * len), size, dx, dy);
		s = s2.a > s.a ? s2 : s;
	} else if (layout < 2.5) {
		// Two bands of three small motifs (six round the tube), each between accent lines.
		float size = 0.33;
		for (int i = 0; i < 2; i++) {
			float cy = b0 + (i == 0 ? 0.24 : 0.76) * len;
			float d = abs(f.y - cy);
			float line = step(0.5 * size + 0.02, d) * step(d, 0.5 * size + 0.07);
			col = mix(col, accent, line);
			float cx = (floor(f.x * 3.0) + 0.5) / 3.0;
			vec4 si = sticker(cell, f, vec2(cx, cy), size, dx, dy);
			s = si.a > s.a ? si : s;
		}
	} else {
		float size = min(0.95, len);
		s = sticker(cell, f, vec2(0.5, b0 + 0.5 * size + 0.03), size, dx, dy);
	}
	return mix(col, s.rgb, s.a);
}

float dirt_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float dirt_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(dirt_hash(i), dirt_hash(i + vec2(1.0, 0.0)), f.x),
			mix(dirt_hash(i + vec2(0.0, 1.0)), dirt_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// A Dirty Sock's look (Q1005): its Design greyed and dulled, brown blotches over it, the toe and
// heel caps (the trim) the most stained.
vec3 dirty_look(vec3 col, vec2 uv, float trim, float soiled) {
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum) * vec3(0.74, 0.7, 0.6), 0.8 * soiled);
	vec2 q = uv * vec2(7.0, 3.0);
	float n = dirt_noise(q) * 0.6 + dirt_noise(q * 2.3 + 5.1) * 0.4;
	float blot = smoothstep(0.52, 0.7, n) * 0.85 + trim * 0.35 * smoothstep(0.3, 0.6, n);
	vec3 brown = vec3(0.16, 0.1, 0.045);
	return mix(col, brown, clamp(blot, 0.0, 0.9) * soiled);
}

void fragment() {
	vec4 lk = use_instance ? v_custom : look;
	lk = floor(lk + 0.5);
	float patches = floor(lk.x / 16.0);
	lk.x -= 16.0 * patches;
	float flagged = step(7.5, lk.x);
	float soiled = max(dirt, flagged);
	lk.x -= 8.0 * flagged;
	// The instance colour arrives as authored (sRGB); base_color is converted by its hint.
	vec3 base = use_instance ? to_linear(v_color.rgb) : base_color.rgb;
	float pat = lk.x;
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 alt = lum > 0.6 ? base * 0.45 : mix(base, vec3(1.0), 0.6);
	alt = lk.z > 0.5 ? unpack_rgb(lk.z) : alt;
	vec3 accent = lk.w > 0.5 ? unpack_rgb(lk.w) : alt;
	vec2 uv = UV;
	float m = 0.0;
	if (pat > 0.5 && pat < 1.5) {
		m = step(0.5, fract(uv.x * 8.0));
	} else if (pat > 1.5 && pat < 2.5) {
		m = (uv.x < 0.16 || uv.x > 0.84) ? 1.0 : 0.0;
	} else if (pat > 2.5 && pat < 3.5) {
		m = mod(floor(uv.x * 10.0) + floor(uv.y * 4.0), 2.0);
	} else if (pat > 3.5 && pat < 4.5) {
		vec2 g = fract(vec2(uv.x * 8.0, uv.y * 3.0)) - 0.5;
		m = step(length(g), 0.24);
	}
	// UV2.x is 1 on the cuff band, heel and toe cap (set by the sock models): a solid trim colour.
	// Which patches the Design draws (0 all, 1 top and toe, 2 heel and toe, 3 none).
	float zone_top = 1.0 - step(patch_split.x, UV.x);
	float zone_toe = step(patch_split.y, UV.x);
	float zone_heel = 1.0 - zone_top - zone_toe;
	float top_on = 1.0 - step(1.5, patches);
	float heel_on = (patches < 0.5 || (patches > 1.5 && patches < 2.5)) ? 1.0 : 0.0;
	float toe_on = 1.0 - step(2.5, patches);
	float trim = step(0.5, UV2.x) * clamp(zone_top * top_on + zone_heel * heel_on + zone_toe * toe_on, 0.0, 1.0);
	m = max(m, trim);
	vec3 col = mix(base, alt, m);
	if (pat > 4.5) {
		col = sock_print(col, lk, uv, trim, accent);
	}
	vec3 cl = cloth(uv, 1.0 - UV2.y);
	float knit_amount = knit_strength * (1.0 - smoothstep(knit_fade.x, knit_fade.y, length(VERTEX)));
	vec4 kn = knit_at(uv, knit_amount);
	col *= cl.z * kn.z;
	// Cloth bumps: tangent space, x along U and y along V (the mesh tangents follow UV0).
	vec2 s = clamp(cl.xy * 0.15 + kn.xy, vec2(-0.8), vec2(0.8));
	NORMAL_MAP = vec3(0.5 - 0.5 * s.x, 0.5 - 0.5 * s.y, 1.0);
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = kn.w;
	// Soft fabric sheen: light catches the fuzz at grazing angles; wool and fuzzy pile catch more.
	float fuzz = fabric > 1.5 ? 1.0 : (fabric > 0.5 ? 0.45 : 0.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	col = mix(col, col * 1.35 + vec3(0.03), fuzz * fres * 0.6);
	if (soiled > 0.0) {
		col = dirty_look(col, uv, trim, soiled);
	}
	ALBEDO = col;
	RIM = 0.45 + 0.4 * fuzz;
	RIM_TINT = 0.6 + 0.3 * fuzz;
	EMISSION = vec3(glow);
}
