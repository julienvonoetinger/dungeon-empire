shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D artwork : source_color, filter_linear, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float ground_height = 0.185;

void vertex() {
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	vec3 point = (billboard * vec4(VERTEX, 1.0)).xyz;
	// Slide the lower corners along the orthographic view ray onto the paving.
	// Screen alignment is unchanged, but the quad no longer intersects the floor.
	vec3 toward_camera = INV_VIEW_MATRIX[2].xyz;
	point += toward_camera * max(0.0, (ground_height - point.y) / max(toward_camera.y, 0.01));
	VERTEX = (VIEW_MATRIX * vec4(point, 1.0)).xyz;
	MODELVIEW_MATRIX = mat4(1.0);
}

void fragment() {
	vec4 color = texture(artwork, UV) * tint;
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.15;
}
