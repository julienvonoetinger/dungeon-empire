shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float clock_time = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float kind = 0.0;
uniform float seed = 0.0;
uniform vec3 violet : source_color = vec3(0.48, 0.055, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}
float flow(vec2 p) {
	return noise(p) * 0.6 + noise(p * 2.03 + 5.7) * 0.28 + noise(p * 4.11) * 0.12;
}
void vertex() {
	float edge = sin(UV.x * 3.14159265);
	VERTEX += NORMAL * sin(UV.y * 31.4159 + clock_time * 0.7 + seed) * edge * 0.018;
}
void fragment() {
	float radial = UV.x;
	float angle = UV.y * 6.2831853;
	float t = clock_time;
	float n = flow(vec2(cos(angle - t * 0.13) * 4.0 + radial * 5.0,
		sin(angle - t * 0.13) * 4.0 + radial * 9.0 + seed));
	float edge = pow(max(sin(radial * 3.14159265), 0.0), 1.3);
	float wave = angle * 9.0 + log(0.45 + radial) * 19.0 - t * 1.5 + n * 3.0;
	float rib = pow(0.5 + 0.5 * sin(wave), 2.2);
	float filament = pow(0.5 + 0.5 * sin(wave * 2.97 + n * 3.0), 12.0);
	float brightness = 0.20 + 0.65 * rib + 0.18 * filament;
	float opacity = edge * (0.27 + n * 0.22 + rib * 0.45);
	if (kind > 0.5) {
		// A ribbon's cross-section stays soft; flow travels along its length.
		rib = pow(0.5 + 0.5 * sin(angle * 7.0 - t * 2.0 + n * 9.0), 3.0);
		brightness = 0.6 + rib * 0.25;
		opacity = edge * (0.5 + rib * 0.35);
	}
	vec3 tint = mix(violet, vec3(0.95, 0.5, 1.0), clamp(brightness * 0.8, 0.0, 1.0));
	ALBEDO = tint * (0.6 + brightness * 1.5);
	ALPHA = opacity * strength;
}
