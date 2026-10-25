shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 ground_u;
uniform vec2 ground_v;
uniform vec2 effect_origin;
uniform vec2 frame_offset;
uniform vec2 logical_per_texel = vec2(1.0);
uniform bool clip_enabled = true;
uniform ivec2 floor_origin;
uniform uint floor_mask = 0u;
varying vec2 ground_position;

void vertex() {
	vec2 pixel = frame_offset + VERTEX * logical_per_texel;
	ground_position = effect_origin + vec2(dot(pixel, ground_u), dot(pixel, ground_v));
}

void fragment() {
	if (clip_enabled) {
		ivec2 cell = ivec2(floor(ground_position)) - floor_origin;
		if (cell.x < 0 || cell.y < 0 || cell.x >= 4 || cell.y >= 4) {
			discard;
		} else {
			uint bit = uint(cell.y * 4 + cell.x);
			if ((floor_mask & (1u << bit)) == 0u) {
				discard;
			}
		}
	}
}
