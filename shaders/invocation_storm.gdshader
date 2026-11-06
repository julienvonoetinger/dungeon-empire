shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sanctuary_color : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength = 0.0;
uniform float effect_time = 0.0;
uniform vec4 world_rect; // top left and size of the visible sanctuary
uniform vec3 crystal_lights[6];
uniform vec2 epicenter;
uniform float center_light = 0.0;

float pool(vec2 delta, vec2 radii) {
	vec2 d = delta / radii;
	return exp(-dot(d,d));
}

void fragment() {
	// Broad moving cloud shadows across the painted set, lit from the altar below.
	vec2 p = UV * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	p = p * vec2(3.4,5.5) + effect_time * vec2(-0.082,0.037);
	float bank = sin(p.y*1.7+sin(p.x*1.4)) + 0.5*sin(p.x*2.7+p.y*2.8);
	float clouds = 0.5 + bank*0.31;
	vec2 world = world_rect.xy + UV * world_rect.zw;
	float light = center_light * pool(world - epicenter, vec2(170.0,140.0));
	for (int i=0; i<6; i++) {
		light += crystal_lights[i].z * pool(world-crystal_lights[i].xy, vec2(86.0,120.0));
	}
	float density = smoothstep(0.18,0.86,clouds);
	vec3 shade = mix(vec3(0.37,0.39,0.57),vec3(0.18,0.20,0.36),density);
	vec3 lit = mix(shade,vec3(1.0,0.83,1.0),clamp(light,0.0,1.0));
	vec3 painted = texture(sanctuary_color,SCREEN_UV).rgb;
	// Lightning and charged facets shine through the cast shadow.
	float emission = max(smoothstep(0.21,0.65,painted.b-painted.g),
		smoothstep(0.86,1.0,min(painted.r,painted.g)));
	COLOR = vec4(painted * mix(vec3(1.0),lit,strength*(1.0-emission)),1.0);
}
