shader_type spatial;
render_mode unshaded, fog_disabled;

void fragment() {
	// An absence of light: neither the cool key nor the torches produce reflections.
	ALBEDO = vec3(0.0);
}
