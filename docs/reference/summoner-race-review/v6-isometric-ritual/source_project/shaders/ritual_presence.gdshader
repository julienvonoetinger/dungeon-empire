shader_type spatial;
render_mode unshaded;
uniform float clock_time = 0.;
varying vec3 local;
void vertex(){
	local=VERTEX;
	float flutter=sin(VERTEX.y*15.+clock_time*2.+VERTEX.x*8.)*sin(VERTEX.y*8.-clock_time);
	VERTEX+=NORMAL*flutter*.035;
	float tail=smoothstep(.04,.5,-VERTEX.y);
	VERTEX.xz*=1.-tail*.8;
	VERTEX.x+=tail*.11*sin(clock_time*2.);
	VERTEX.y-=tail*.23;
}
void fragment(){
	float rim=pow(1.-max(dot(normalize(NORMAL),normalize(VIEW)),0.),2.2);
	float veins=sin(local.y*19.+4.*sin(local.x*13.+local.z*8.+clock_time)+sin(local.z*25.-local.x*18.)-clock_time*1.6);
	vec3 ink=mix(vec3(.032,.012,.065),vec3(.26,.066,.28),smoothstep(.82,.99,veins)*.75);
	ALBEDO=ink+rim*vec3(.65,.19,.89);
}
