shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform float phase = 0.0;
uniform float instability : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Keep the thin lensing rim circular at every orthographic camera angle.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float angle = atan(p.y, p.x);
	float ripple = sin(angle * 5.0 + phase * 0.7) * (0.0015 + instability * 0.002);
	float edge = 0.408 + ripple;
	float rim = exp(-pow((r - edge) / 0.006, 2.0));
	float haze = exp(-max(r - edge, 0.0) * 48.0) * step(edge, r) * 0.32;
	float arc = 0.68 + 0.32 * sin(angle * 2.0 - phase * 0.45);
	ALBEDO = mix(vec3(0.22, 0.045, 0.40), vec3(0.48, 0.16, 0.72), rim);
	EMISSION = ALBEDO * rim * 0.45;
	ALPHA = clamp((rim * 0.9 + haze) * arc, 0.0, 1.0);
}
