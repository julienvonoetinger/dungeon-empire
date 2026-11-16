shader_type canvas_item;

uniform vec2 center;
uniform vec2 radius;
uniform float strength;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float distance_to_actor = length((world_position - center) / radius);
	float cutaway = 1.0 - smoothstep(0.62, 1.08, distance_to_actor);
	COLOR.a *= 1.0 - 0.90 * strength * cutaway;
}
