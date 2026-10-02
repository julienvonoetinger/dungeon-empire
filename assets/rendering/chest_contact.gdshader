shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

void fragment() {
	vec2 p = abs(UV * 2.0 - 1.0);
	float edge = length(max(p - vec2(0.5), vec2(0.0)));
	ALBEDO = vec3(0.035, 0.025, 0.018);
	ALPHA = (1.0 - smoothstep(0.08, 0.5, edge)) * 0.42;
}
