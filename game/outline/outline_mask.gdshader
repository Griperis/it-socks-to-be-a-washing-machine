// The outline's first pass (Outline, game/outline/outline.gd): marks the target's silhouette in the
// stencil buffer and draws nothing, so the shells after it (outline.gdshader) stay outside it.
// Ported from the old game's game/ui/outline_mask.gdshader as it was.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;
stencil_mode write, compare_always, 77;

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
