shader_type spatial;
render_mode cull_disabled;

uniform sampler2D artwork : source_color, filter_linear_mipmap, repeat_disable;
uniform bool exhausted = false;

void fragment() {
	// The floor owns the stone rim; only the inner abyss overlays its recess.
	if (exhausted || distance(UV, vec2(0.5)) > 0.34) discard;
	vec4 texel = texture(artwork, UV);
	// Use the same albedo and lighting response as the continuous paving.
	ALBEDO = texel.rgb;
	float violet = smoothstep(0.015, 0.18, texel.b - texel.g) * smoothstep(0.01, 0.12, texel.r - texel.g);
	EMISSION = texel.rgb * violet * 0.65;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	ALPHA = step(0.15, texel.a);
	ALPHA_SCISSOR_THRESHOLD = 0.15;
}
