shader_type canvas_item;
render_mode unshaded;
uniform sampler2D quiet : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D strata : source_color, repeat_disable, filter_linear_mipmap;
uniform sampler2D mineral : source_color, repeat_disable, filter_linear_mipmap;
uniform int surface = 0; // 0 cap, 1 raw ground, 2 exposed face
float noise(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+17.3)*43758.5453); }
vec4 patch(sampler2D tex, vec2 world, float period, float span, vec2 salt) {
	vec2 cell=floor(world/period), f=fract(world/period);
	vec2 centre=vec2(.5)+vec2(noise(cell+salt),noise(cell+salt.yx+7.0))*.12-.06;
	vec2 uv=(f-centre)/span+.5;
	vec4 col=texture(tex,clamp(uv,vec2(0.0),vec2(1.0)));
	col.a*=step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
	col.a*=step(.34,noise(cell+salt+19.0));
	return col;
}
void fragment() {
	vec4 base=texture(quiet,UV/3.0);
	if(surface==0) {
		vec4 layers=patch(strata,UV,3.6,.75,vec2(103.0,-41.0));
		base.rgb=mix(base.rgb,layers.rgb,layers.a*.58);
		vec4 vein=patch(mineral,UV,4.4,.40,vec2(-34.0,62.0));
		base.rgb=mix(base.rgb,vein.rgb,vein.a*.72);
		vec2 p=UV/5.7,c=floor(p),f=smoothstep(vec2(0.0),vec2(1.0),fract(p));
		float shade=mix(mix(noise(c),noise(c+vec2(1,0)),f.x),mix(noise(c+vec2(0,1)),noise(c+vec2(1,1)),f.x),f.y);
		base.rgb=mix(base.rgb,vec3(.02,.035,.07),.25+shade*.28);
	} else if(surface==1) base.rgb=mix(base.rgb,vec3(.063,.098,.149),.61);
	else base.rgb=mix(base.rgb,vec3(.035,.055,.09),.48);
	COLOR=vec4(base.rgb*COLOR.rgb,1.0);
}
