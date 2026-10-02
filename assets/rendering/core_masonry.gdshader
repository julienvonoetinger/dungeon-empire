shader_type spatial;
render_mode cull_disabled;

uniform sampler2D artwork : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float ground_height = 0.185;
uniform float rune_energy = 0.8;

void vertex() {
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	vec3 point = (billboard * vec4(VERTEX, 1.0)).xyz;
	// Preserve projected alignment while keeping the lower edge above paving.
	vec3 toward_camera = INV_VIEW_MATRIX[2].xyz;
	point += toward_camera * max(0.0, (ground_height - point.y) / max(toward_camera.y, 0.01));
	VERTEX = (VIEW_MATRIX * vec4(point, 1.0)).xyz;
	MODELVIEW_MATRIX = mat4(1.0);
	// A stable world-up normal prevents camera rotation from changing stone lighting.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	vec4 color = texture(artwork, UV) * tint;
	ALBEDO = color.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
	float magic = smoothstep(0.04, 0.18, color.b - color.g)
		* smoothstep(0.015, 0.08, color.r - color.g);
	EMISSION = color.rgb * magic * rune_energy;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.15;
}
