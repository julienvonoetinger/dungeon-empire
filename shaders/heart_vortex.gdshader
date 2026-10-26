shader_type canvas_item;
render_mode blend_mix;

// Coordinates belong to the prepared logical frame, not the whole atlas.
uniform vec4 atlas_rect;
uniform vec2 frame_size;
uniform vec2 vortex_center;
uniform float vortex_radius = 1.0;
uniform float phase = 0.0;
uniform bool animation_enabled = true;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 rgb = base.rgb;
	if (animation_enabled) {
		vec2 frame_uv = (UV - atlas_rect.xy) / atlas_rect.zw;
		vec2 p = (frame_uv * frame_size - vortex_center) / vortex_radius;
		float r = length(p);
		// Crossfade before the painted ring. Its contour/neck never move.
		float flow = smoothstep(0.06, 0.18, r) * (1.0 - smoothstep(0.58, 0.82, r));
		if (flow > 0.0) {
			float angle = phase * TAU;
			float c = cos(angle);
			float s = sin(angle);
			vec2 q = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
			// Bounded radial drift, periodic at the same loop boundary.
			q *= 1.0 + 0.018 * sin(angle*2.0) * sin(r*8.0);
			vec2 sample_uv = atlas_rect.xy + (vortex_center + q*vortex_radius) / frame_size * atlas_rect.zw;
			vec2 half_texel = TEXTURE_PIXEL_SIZE * 0.5;
			sample_uv = clamp(sample_uv, atlas_rect.xy + half_texel, atlas_rect.xy + atlas_rect.zw - half_texel);
			rgb = mix(rgb, texture(TEXTURE, sample_uv).rgb, flow);
		}
		// Pulse brightness only; original alpha, size and floor light stay fixed.
		float halo = smoothstep(0.72, 0.92, r) * (1.0 - smoothstep(1.10, 1.40, r));
		halo *= 1.0 - smoothstep(0.72, 0.92, p.y);
		rgb *= 1.0 + 0.045 * sin(phase * TAU * 3.0) * halo;
	}
	COLOR = vec4(rgb, base.a) * vertex_tint;
}
