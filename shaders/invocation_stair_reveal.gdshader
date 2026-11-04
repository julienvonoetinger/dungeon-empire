shader_type canvas_item;
render_mode unshaded;
uniform float reveal=0.;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
	vec4 stone=texture(TEXTURE,UV)*tint;
	float grain=sin(UV.x*91.+sin(UV.y*37.)*2.)*sin(UV.y*83.);
	float field=UV.x*.35+(1.-UV.y)*.65+grain*.035;
	float threshold=mix(-.12,1.12,reveal);
	float exposed=1.-smoothstep(threshold-.035,threshold+.035,field);
	float edge=exp(-abs(field-threshold)*90.)*sin(reveal*3.14159265);
	stone.rgb+=vec3(.35,.15,.5)*edge*.35;
	COLOR=vec4(stone.rgb,stone.a*exposed);
}
