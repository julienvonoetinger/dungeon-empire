shader_type canvas_item;
render_mode unshaded, blend_mix;

// Age is measured from the sound of the rock breaking, on the film's clock.
uniform float age = -2.0;
uniform vec2 strike_uv;

float hash(vec2 p) {
	vec3 q = fract(p.xyx * vec3(.1031, .1030, .0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x),
			mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}

void fragment() {
	float spread = smoothstep(-1.08,-.04,age);
	float clearing = smoothstep(1.15,3.85,age);
	vec2 p = UV;
	// Advect the near wisps and the deeper bank in different directions.
	vec2 drift = vec2(noise(p*7.0+vec2(age*.32,1.7)), noise(p*8.0-vec2(3.2,age*.4))) - .5;
	float eddy = noise(p*13.0 + drift*2.7 - vec2(age*.36,0.0));
	vec2 curled = p + drift*.055 + vec2(.017*sin(age*1.1+p.y*8.0), clearing*.085);
	vec4 front = texture(TEXTURE,clamp(curled,vec2(0.),vec2(1.)));
	vec2 back_uv = vec2(1.0-p.x,p.y) + drift*.075 + vec2(.025*sin(.8*age),-.037);
	vec4 back = texture(TEXTURE,clamp(back_uv,vec2(0.),vec2(1.)));
	vec3 body = mix(back.rgb*.65,front.rgb,front.a);
	float paint = front.a + (1.0-front.a)*back.a*.91;

	vec2 center = mix(strike_uv,vec2(.5,.53),spread);
	float radius = length((p-center)*vec2(2.05,2.17)) + (eddy-.5)*.20;
	float inflow = 1.0-smoothstep(spread*1.32-.17,spread*1.32+.05,radius);
	// The wind opens holes from the lower treads toward the arch.
	float holes = .48*(1.0-p.y) + .27*p.x + .40*eddy + drift.y*.16;
	float erosion = smoothstep(clearing*1.52-.23,clearing*1.52,holes);
	float dense = 1.0-smoothstep(.54,.92,radius);
	float alpha = max(paint,dense)*inflow*erosion;
	// A muted violet bounce catches the moving folds above the fracture.
	float pulse = exp(-abs(age)*4.0)*(.22+.78*eddy);
	body += vec3(.11,.024,.19)*pulse*paint;
	COLOR = vec4(body,alpha);
}
