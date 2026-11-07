shader_type canvas_item;

uniform bool construction = false;

void fragment() {
	vec4 icon = texture(TEXTURE, UV);
	vec2 step_uv = 2.5 * TEXTURE_PIXEL_SIZE;
	float outline = max(
		max(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a)
	);
	float light = dot(icon.rgb, vec3(0.299, 0.587, 0.114));
	vec3 mint = mix(vec3(0.12, 0.46, 0.50), vec3(0.82, 1.0, 0.94), light);
	if (construction) {
		// Bring out the hinges and teeth of the dark inventory paintings.
		mint = mix(vec3(0.04, 0.19, 0.21), vec3(0.84, 1.0, 0.94), smoothstep(0.03, 0.50, light));
	}
	COLOR = vec4(mix(vec3(0.88, 1.0, 0.93), mint, icon.a), max(outline * (1.0 - icon.a) * 0.97, icon.a * 0.78));
}
