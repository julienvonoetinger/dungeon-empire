shader_type spatial;
uniform sampler2D artwork : source_color, filter_linear_mipmap, repeat_disable;
uniform float half_offset = 0.0;
uniform float rune_energy = 0.0;
void fragment() {
	vec3 color = texture(artwork, vec2(UV.x * 0.5 + half_offset, UV.y)).rgb;
	ALBEDO = color;
	ROUGHNESS = 0.88;
	float rune = smoothstep(1.15, 1.55, color.b / max(color.g, 0.002))
		* smoothstep(1.1, 1.4, color.r / max(color.g, 0.002));
	EMISSION = vec3(0.48, 0.045, 0.95) * rune * rune_energy;
}
