shader_type spatial;
uniform sampler2D stone_texture : source_color, filter_linear_mipmap_anisotropic;
uniform float cut_height = -0.14;
varying float source_height;

void vertex() {
	source_height = VERTEX.y;
}

void fragment() {
	// Retain the Meshy base, removing its fused upper rocks and reflective centre.
	if (source_height > cut_height) { discard; }
	vec3 tex = texture(stone_texture, UV).rgb;
	float value = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = mix(vec3(value) * vec3(0.72, 0.79, 0.91), tex, 0.15) * 0.8;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
	SPECULAR = 0.15;
}
