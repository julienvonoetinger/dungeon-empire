shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
uniform float life = 1.0;
void fragment() {
	vec2 p = UV - vec2(.5);
	float r = length(p);
	vec2 q = mat2(vec2(cos(phase),sin(phase)),vec2(-sin(phase),cos(phase))) * p;
	// Blend samples, not angles: phase 0 and 2PI match at every radius.
	vec4 ink = mix(texture(TEXTURE,UV),texture(TEXTURE,q+vec2(.5)),1.0-smoothstep(.23,.29,r));
	float sector = floor(fract((atan(p.y,p.x)+1.8849556)/6.2831853)*10.0);
	if (r > .30 && sector >= ceil(life*10.0)) {
		float grey = dot(ink.rgb,vec3(.2126,.7152,.0722));
		ink.rgb = mix(ink.rgb,vec3(grey*.48),.88);
	}
	COLOR *= ink;
}
