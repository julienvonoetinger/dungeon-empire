shader_type canvas_item;
render_mode unshaded;

// Static strip topology; the preview clock drives both shape and flowing ink.
// Deliberately no TIME, so pause, speed and seeking remain exact.
uniform vec2 source_point;
uniform vec2 seal_point;
uniform float phase = 0.0;
uniform float strand = 0.0;
uniform float strength = 1.0;

float noise_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}
float mist(vec2 p) {
	vec2 cell = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	return mix(mix(noise_hash(cell),noise_hash(cell+vec2(1,0)),u.x),
		mix(noise_hash(cell+vec2(0,1)),noise_hash(cell+vec2(1,1)),u.x),u.y);
}
void vertex() {
	float t = UV.x;
	vec2 delta = seal_point-source_point;
	vec2 normal = vec2(-delta.y,delta.x)/max(length(delta),0.001);
	float envelope = sin(3.14159265*t);
	float spiral = sin(t*9.424778-phase*8.0+strand*3.14159265);
	vec2 centre = mix(source_point,seal_point,t) + vec2(0,-6.0*envelope)
		+ normal*spiral*9.0*envelope;
	float width = (2.0+6.3*envelope)*(0.8+0.2*sin(t*18.0-phase*5.0));
	VERTEX = centre + normal*(UV.y*2.0-1.0)*width;
}
void fragment() {
	float transverse = pow(max(sin(UV.y*3.14159265),0.0),1.7);
	float flecks = mist(vec2(UV.x*21.0-phase*3.0,UV.y*5.0+strand*7.0));
	float fine = mist(vec2(UV.x*43.0-phase*5.0,UV.y*9.0));
	float envelope = smoothstep(0.0,0.08,UV.x)*(1.0-smoothstep(0.94,1.0,UV.x));
	float alpha = transverse*(0.35+0.65*flecks)*(0.65+0.35*fine)*envelope*strength;
	vec3 violet = vec3(0.48,0.13,0.93);
	vec3 lit = mix(vec3(0.86,0.57,1.0),vec3(0.57,0.97,0.90),strand*0.55);
	COLOR = vec4(mix(violet,lit,smoothstep(0.35,0.8,flecks)),alpha*0.85);
}
