shader_type canvas_item;
render_mode unshaded;
uniform sampler2D bedrock : source_color, repeat_enable, filter_linear;
uniform sampler2D quiet : source_color, repeat_enable, filter_linear;
uniform int surface = 0;
float noise(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+17.3)*43758.5453); }
vec3 continuous_stone(vec2 p) {
	// Crossfade only source tile boundaries; never reveal a square image edge.
	vec2 f=fract(p);
	vec2 w=smoothstep(vec2(0),vec2(.14),f)*smoothstep(vec2(0),vec2(.14),1.0-f);
	vec3 a=mix(texture(bedrock,p+vec2(.5,.5)).rgb,texture(bedrock,p+vec2(0,.5)).rgb,w.x);
	vec3 b=mix(texture(bedrock,p+vec2(.5,0)).rgb,texture(bedrock,p).rgb,w.x);
	return mix(a,b,w.y);
}
void fragment() {
	vec3 stone=mix(texture(quiet,UV/3.0).rgb*.70,continuous_stone(UV/3.0),.54);
	// Slow tonal variation keeps the substrate quiet behind the dungeon.
	vec2 p=UV/5.7,c=floor(p),f=smoothstep(vec2(0.0),vec2(1.0),fract(p));
	float shade=mix(mix(noise(c),noise(c+vec2(1,0)),f.x),mix(noise(c+vec2(0,1)),noise(c+vec2(1,1)),f.x),f.y);
	if(surface==4) {
		// Exposed rock section: a distinct plane with its foot in the recess.
		stone=mix(continuous_stone(UV/1.8)*vec3(.48,.55,.68),vec3(.032,.045,.070),.22);
		stone*=mix(.72,1.08,smoothstep(0.0,1.0,COLOR.a));
	}
	else if(surface==3) {
		// This mesh stores normalized physical height in vertex alpha. It is
		// fully opaque; the transition follows the sloped geometry, not a shadow.
		vec3 upper=stone*mix(vec3(.65,.69,.77),vec3(.76,.79,.87),shade);
		vec3 lower=mix(texture(quiet,UV/3.0).rgb,vec3(.063,.098,.149),.61);
		stone=mix(lower,upper,smoothstep(0.0,1.0,COLOR.a));
	}
	else if(surface==0) stone*=mix(vec3(.65,.69,.77),vec3(.76,.79,.87),shade);
	// Preserve the existing clearance floor and exposed-face tones as well.
	else if(surface==1) stone=mix(texture(quiet,UV/3.0).rgb,vec3(.063,.098,.149),.61);
	else stone=mix(texture(quiet,UV/3.0).rgb,vec3(.035,.055,.09),.48);
	COLOR=vec4(stone*COLOR.rgb,1.0);
}
