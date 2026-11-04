shader_type canvas_item;
render_mode unshaded;
uniform vec2 origin;
uniform vec2 extent;
uniform vec2 centre = vec2(40.0,-350.0);
uniform float opening = 0.0;
uniform float charge = 0.0;
uniform float effect_time = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint=COLOR;
}

void fragment() {
	vec4 stone = texture(TEXTURE,UV) * vertex_tint;
	vec2 p = origin + UV * extent - centre;
	float jagged = sin(p.y*.073)*2.2 + sin(p.y*.19+.9)*1.3;
	float width = mix(1.5,72.0,opening);
	vec2 q = vec2((p.x-jagged)/width,p.y/92.0);
	float arch = max(length(vec2(q.x,min(q.y,0.0)))-1.0,max(abs(q.x)-1.0,q.y-.9));
	float inside = (1.0-smoothstep(-.02,.035,arch))*smoothstep(0.0,.08,opening);
	float inner_rim = smoothstep(-.30,-.055,arch);
	float floor_light = smoothstep(.3,.92,q.y)*.13;
	vec3 depth = mix(vec3(.012,.008,.024),vec3(.055,.025,.09),clamp(q.y*.5+.5,0.,1.));
	depth += stone.rgb*inner_rim*.26 + vec3(.22,.10,.30)*floor_light;
	float edge = exp(-abs(arch)*30.0)*charge;
	float haze = exp(-abs(arch)*7.0)*charge*.18;
	vec3 lit = mix(stone.rgb,depth,inside);
	lit += (vec3(.47,.14,.82)*haze + vec3(.69,.32,.95)*edge*.65);
	COLOR = vec4(lit,stone.a);
}
