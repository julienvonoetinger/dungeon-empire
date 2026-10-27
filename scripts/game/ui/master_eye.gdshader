shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
uniform float life = 1.0;
void fragment() {
	vec2 p = UV - vec2(.5);
	float r = length(p);
	// Keep the pupil and highlight steady so the medallion reads as an eye.
	// A subtle iris pulse replaces the portal-like rotation.
	vec4 ink = texture(TEXTURE,UV);
	float iris = smoothstep(.07,.12,r) * (1.0-smoothstep(.23,.29,r));
	ink.rgb *= 1.0 - iris * .04 * (.5+.5*sin(phase));
	float sector = floor(fract((atan(p.y,p.x)+1.8849556)/6.2831853)*10.0);
	if (r > .30 && sector >= ceil(life*10.0)) {
		float grey = dot(ink.rgb,vec3(.2126,.7152,.0722));
		ink.rgb = mix(ink.rgb,vec3(grey*.48),.88);
	}
	COLOR *= ink;
}
