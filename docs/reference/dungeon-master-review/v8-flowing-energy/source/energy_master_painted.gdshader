shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D energy_paint : source_color, filter_linear_mipmap, repeat_disable;
uniform float clock_time = 0.0;
uniform float strength : hint_range(0.0,1.0) = 1.0;
uniform float kind = 0.0;
uniform float seed = 0.0;

void vertex() {
	float edge = sin(UV.x*3.14159265);
	VERTEX += NORMAL*sin(UV.y*25.1327+clock_time*0.5+seed)*edge*0.018;
}
void fragment() {
	float across = UV.x;
	float angle;
	float radius;
	float opacity = strength;
	bool ribbon = (kind > 0.5 && kind < 1.5) || kind > 2.5;
	if (ribbon) {
		// Painted sheets run along curved 3D ribbons, with tapered mesh ends.
		angle = UV.y*2.5+seed-clock_time*0.11;
		radius = mix(0.19,0.44,across);
		opacity *= pow(max(sin(across*3.14159265),0.0),0.65);
		opacity *= smoothstep(0.0,0.10,UV.y)*(1.0-smoothstep(0.87,1.0,UV.y));
	} else {
		// Differential rotation bends painted currents inward on the funnel.
		angle = UV.y*6.2831853-clock_time*0.10+seed;
		angle += sin(across*5.0-clock_time*0.3+seed)*0.055;
		radius = mix(0.128,0.49,across);
		radius += sin(angle*3.0+clock_time*0.35)*0.003*sin(across*3.14159265);
		opacity *= smoothstep(0.0,0.035,across);
	}
	vec2 sample_uv = vec2(0.5)+vec2(cos(angle),sin(angle))*radius;
	vec4 painted = texture(energy_paint,sample_uv);
	ALBEDO = painted.rgb * ((kind > 0.5 && kind < 1.5) ? 1.25 : 1.0);
	ALPHA = painted.a*opacity;
}
