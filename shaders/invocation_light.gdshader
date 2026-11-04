shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float effect_time = 0.0;
varying vec4 tint;
varying float is_filament;

void vertex() {
	tint = COLOR;
	// Procedural ribbons use V=2..3. Existing glow sprites keep their normal UVs.
	is_filament = step(1.5, UV.y);
	UV.y -= 2.0 * is_filament;
}

void fragment() {
	if (is_filament > 0.5) {
		float u = UV.x;
		float drift = 0.08 * sin(u * 2.3 - effect_time * 1.2)
			+ 0.035 * sin(u * 6.7 + effect_time * 0.8);
		float d = (UV.y - 0.5) * 2.0 - drift;
		float thickness = 0.85 + 0.12 * sin(u * 3.1 + effect_time);
		d /= thickness;
		float halo = exp(-d * d * 5.0);
		float body = exp(-d * d * 32.0);
		float core = exp(-d * d * 140.0);
		float irregularity = 0.70 + 0.17 * sin(u * 1.7 - effect_time * 1.3)
			+ 0.09 * sin(u * 5.9 + effect_time * 0.7);
		float edge = 1.0 - smoothstep(0.72, 1.0, abs((UV.y - 0.5) * 2.0));
		vec3 hue = mix(vec3(0.48, 0.12, 0.90), vec3(0.83, 0.52, 1.0), core * 0.75);
		COLOR = vec4(hue, (halo * 0.24 + body * 0.38 + core * 0.20)
			* irregularity * edge * tint.a);
	} else {
		COLOR = texture(TEXTURE, UV) * tint;
	}
}
