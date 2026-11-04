shader_type canvas_item;
render_mode unshaded;
uniform sampler2D poses : source_color, filter_linear, repeat_disable;
uniform sampler2D sovereign : source_color, filter_linear, repeat_disable;
uniform vec2 view_span = vec2(10.,5.85);
uniform float opened = 1.;
uniform float moment = 0.;
uniform float descent = 0.;
uniform int pose_index = 0;
// Registration of the engraved platform on the painted square, in master pixels.
uniform vec2 altar_center = vec2(768.,718.);
uniform vec2 altar_radius = vec2(233.,116.);

void fragment(){
	vec2 src = (UV-.5)*view_span/14.+.5;
	vec2 pixel = src*1536.;
	vec2 altar = (pixel-vec2(768.,718.))/vec2(233.,116.);
	vec2 painted_uv = (altar_center + altar*altar_radius)/1536.;
	vec3 col = texture(TEXTURE,clamp(painted_uv,vec2(.001),vec2(.999))).rgb;

	// The light lies in the same projected plane as the original paving.
	float r=length(altar);
	float a=atan(altar.y,altar.x);
	float ink=exp(-abs(r-.44)*170.)+.6*exp(-abs(r-.85)*200.);
	float curl=exp(-abs(sin(a*5.+r*5.-moment*.55))*38.)*smoothstep(.38,.48,r)*(1.-smoothstep(.77,.84,r));
	float charge=smoothstep(0.,1.5,moment)*(1.-descent);
	col+=vec3(.29,.13,.47)*(.7+.3*sin(moment*2.-r*9.))*charge*(ink+curl*.75);
	vec2 contact=(pixel-vec2(871.,656.))/vec2(69.,25.);
	col*=1.-.37*exp(-dot(contact,contact)*1.5);

	// The spirit's pulse travels inward across the engraved stone.
	float birth = smoothstep(1.0,2.45,moment);
	float presence = birth*(1.-descent);
	float pulse = .5+.5*cos(moment*3.+r*8.);
	col += vec3(.24,.045,.38)*presence*(ink*pulse+.28*exp(-r*r*5.));

	// Identical crop and scale for every pose (see pack_sprites.py).
	vec2 local=(pixel-vec2(576.,472.))/vec2(400.,336.);
	if(all(greaterThanEqual(local,vec2(0.)))&&all(lessThanEqual(local,vec2(1.)))){
		vec2 tile=vec2(float(pose_index%6),float(pose_index/6));
		vec4 actor=texture(poses,(tile+clamp(local,vec2(.0021),vec2(.9979)))/vec2(6.,8.));
		col=mix(col,actor.rgb,actor.a);
	}
	// Filaments gather around a spark, then contract into the altar.
	if (birth>0. && descent<1.){
		vec2 original = vec2(textureSize(sovereign,0));
		float width = 244.*mix(.13,1.,birth)*mix(1.,.06,descent);
		vec2 size = vec2(width,width*original.y/original.x);
		vec2 center = mix(vec2(768.,650.),vec2(745.,612.),birth);
		center.y += 3.*sin(moment*1.8);
		center = mix(center,altar_center,descent);
		vec2 offset = (pixel-center)/size;
		float turn = .14*sin(moment*2.-length(offset)*6.)+.8*descent;
		vec2 uv = mat2(vec2(cos(turn),sin(turn)),vec2(-sin(turn),cos(turn)))*offset+.5;
		if(all(greaterThanEqual(uv,vec2(0.)))&&all(lessThanEqual(uv,vec2(1.)))){
			vec4 spirit = texture(sovereign,uv);
			float reveal = 1.-smoothstep(.67*birth,.67*birth+.15,length(offset));
			col = mix(col,spirit.rgb,spirit.a*reveal*birth*.88*(1.-descent));
		}
	}
	vec2 p=UV-vec2(.49,.41);
	p.x*=SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
	float ripple=sin(p.y*17.+sin(p.y*29.))*.012;
	float edge=length(vec2((p.x+ripple)*1.25,p.y*.63))-opened*2.;
	float ridge=sin(p.y*27.+sin(p.x*8.+p.y*4.)*3.);
	vec3 far_realm=mix(vec3(.028,.011,.049),vec3(.23,.054,.18),smoothstep(.70,1.,ridge)*.48);
	col=mix(col,far_realm,smoothstep(-.028,.015,edge));
	col+=vec3(.52,.21,.68)*exp(-90.*abs(edge))*(1.-opened);
	col*=1.-.22*smoothstep(.27,.72,length((UV-vec2(.5,.43))*vec2(.93,1.)));
	COLOR=vec4(col,1.);
}
