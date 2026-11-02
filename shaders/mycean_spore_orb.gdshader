shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float burst = 0.0;
varying vec4 orb_tint;

// Preserve node modulation without multiplying the procedural orb by the
// fallback sprite's alpha falloff a second time in fragment().
void vertex() { orb_tint=COLOR; }

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float mist(vec2 p) { return noise(p)*.57+noise(p*2.07)*.28+noise(p*4.17)*.15; }

void fragment() {
 vec2 p=UV*2.0-1.0;
 float r=length(p), a=atan(p.y,p.x);
 vec2 swirl=vec2(cos(a+r*4.0-phase*2.7),sin(a+r*4.0-phase*2.7))*r;
 float n=mist(swirl*5.5+vec2(phase*.8,-phase*.5));
 float shell=1.0-smoothstep(.40+n*.13,.58+n*.16,r);
 float veins=pow(max(0.0,1.0-abs(n-.51)*6.8),3.0);
 float core=exp(-r*r*21.0);
 float halo=exp(-r*r*5.4)*.40;
 float erosion=smoothstep(burst*.75,burst*.75+.25,n);
 float alpha=(shell*.88+halo)*(1.0-burst)*mix(1.0,erosion,burst);
 vec3 ink=mix(vec3(.035,.25,.21),vec3(.16,.91,.72),n);
 ink=mix(ink,vec3(.72,1.0,.62),veins*.70);
 ink=mix(ink,vec3(1.0,1.0,.80),core*.95);
 COLOR=vec4(ink,clamp(alpha,0.0,1.0))*orb_tint;
}
