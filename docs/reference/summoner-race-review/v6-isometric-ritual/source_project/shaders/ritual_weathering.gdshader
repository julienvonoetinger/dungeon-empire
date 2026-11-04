shader_type spatial;
render_mode cull_disabled;
varying vec3 object_point;

float hash(vec2 p){
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float noise_at(vec2 p){
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.-2.*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex(){object_point=VERTEX;}
void fragment(){
	vec2 p=object_point.xz+object_point.y*vec2(.39,.71);
	float beds=noise_at(p*3.4)+.44*noise_at(p*12.);
	float grit=noise_at(p*85.);
	float seam=smoothstep(.90,.99,sin((p.x*.5+p.y*.86)*22.+beds*7.));
	vec3 painted=COLOR.rgb*(.70+.30*beds+.16*grit-.12*seam);
	// Soft contact in the two boot footprints on the celebrant's flagstone.
	float sole_a=length((object_point.xz-vec2(-.51,-1.63))*vec2(3.1,4.4));
	float sole_b=length((object_point.xz-vec2(.08,-1.48))*vec2(3.1,4.4));
	float grounding=mix(.56,1.,smoothstep(0.,1.15,min(sole_a,sole_b)));
	painted*=grounding;
	ALBEDO=OUTPUT_IS_SRGB ? pow(max(painted,vec3(0.)),vec3(.62)) : painted;
	ROUGHNESS=.94-.1*beds;
}
