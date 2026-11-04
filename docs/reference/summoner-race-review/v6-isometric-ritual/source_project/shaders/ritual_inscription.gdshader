shader_type spatial;
render_mode cull_disabled, unshaded, blend_add, depth_draw_never;
uniform float power = 0.0;
uniform float clock_time = 0.0;

float line(float distance_to_ink, float width) {
	return 1.0-smoothstep(width,width+.006,abs(distance_to_ink));
}
void fragment(){
	vec2 p = UV*2.-1.;
	float r = length(p);
	float a = atan(p.y,p.x);
	float ray = fract(a*3.81972+.5)-.5;
	float etching = line(r-.96,.006)+line(r-.80,.005)+line(r-.39,.007);
	etching += line(abs(ray)*.4+abs(r-.881)-.055,.004);
	float channel = line(sin(a*6.+r*6.-clock_time*.42)*.075,.006)*smoothstep(.34,.42,r)*(1.-smoothstep(.73,.80,r));
	float pulse = .72+.28*sin(clock_time*2.2-r*11.+a*2.);
	ALBEDO = mix(vec3(.37,.18,.85),vec3(1.,.65,.30),smoothstep(.75,.92,r));
	ALPHA = clamp((etching+channel)*power*pulse,0.,1.);
}
