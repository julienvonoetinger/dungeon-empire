shader_type canvas_item;
render_mode unshaded;
uniform float reveal=0.;
uniform sampler2D earth : source_color, filter_linear, repeat_disable;
uniform vec2 earth_offset;
uniform float earth_scale = 1.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
	vec4 stone=texture(TEXTURE,UV)*tint;
	// Dust from the adjoining shale collects on the lowest pixels of the two exposed stone faces.
	vec2 px=UV/TEXTURE_PIXEL_SIZE;
	float base_y=min(168.0+.5*px.x,303.5-.5*px.x);
	float chips=.5+.5*sin(px.x*.22+sin(px.x*.63)*1.7);
	float contact=smoothstep(base_y-4.0-4.0*chips,base_y+1.0,px.y);
	vec3 grit=texture(earth,(px+earth_offset)/(earth_scale*vec2(textureSize(earth,0)))).rgb;
	stone.rgb=mix(stone.rgb,grit,contact*(.45+.45*chips));
	float grain=sin(UV.x*91.+sin(UV.y*37.)*2.)*sin(UV.y*83.);
	float field=UV.x*.35+(1.-UV.y)*.65+grain*.035;
	float threshold=mix(-.12,1.12,reveal);
	float exposed=1.-smoothstep(threshold-.035,threshold+.035,field);
	float edge=exp(-abs(field-threshold)*90.)*sin(reveal*3.14159265);
	stone.rgb+=vec3(.35,.15,.5)*edge*.35;
	COLOR=vec4(stone.rgb,stone.a*exposed);
}
