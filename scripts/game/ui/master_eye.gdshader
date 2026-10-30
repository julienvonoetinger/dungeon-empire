shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
uniform float life = 1.0;
uniform vec2 gaze = vec2(0.0);
uniform vec4 iris_tint : source_color = vec4(1.0);
uniform float tone = 0.0;
uniform float pupil_scale = 1.0;
uniform float aperture = 1.0;
uniform float glow = 0.0;
uniform float shudder = 0.0;
uniform vec2 eye_center = vec2(0.49756098, 0.48830409);
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
void fragment() {
	// Source is 410x342: radial calculations must use equal pixel units.
	vec2 p = (UV - eye_center) * vec2(1.0,342.0/410.0);
	float r = length(p);
	vec4 ink = texture(TEXTURE,UV);
	// Deform only the inner eye. The runes and housing never follow the gaze.
	float socket = 1.0-smoothstep(.155,.172,r);
	vec2 shake = vec2(sin(phase*53.0),cos(phase*41.0))*.003*shudder;
	vec2 q=p-(gaze*.037+shake)*(1.0-smoothstep(.085,.168,r));
	float pupil_zone=1.0-smoothstep(.055,.127,length(q));
	q/=1.0+(pupil_scale-1.0)*pupil_zone;
	vec4 iris_ink=texture(TEXTURE,eye_center+q/vec2(1.0,342.0/410.0));
	float light=max(iris_ink.r,max(iris_ink.g,iris_ink.b));
	vec3 tinted=iris_tint.rgb*light;
	// Keep bright highlights and the round black pupil legible at phone scale.
	tinted=mix(tinted,vec3(light),smoothstep(.6,1.0,min(iris_ink.r,min(iris_ink.g,iris_ink.b)))*.7);
	iris_ink.rgb=mix(iris_ink.rgb,tinted,tone);
	float iris=smoothstep(.045,.08,r)*(1.0-smoothstep(.14,.175,r));
	iris_ink.rgb*=1.0-iris*.04*(.5+.5*sin(phase));
	iris_ink.rgb+=iris*glow*mix(vec3(.65,.2,1.0),iris_tint.rgb,tone);
	// Curved dark-violet lids slide inside the original socket, with a thin rim.
	float opening=.19*aperture*sqrt(max(0.0,1.0-p.x*p.x/(.172*.172)));
	float edge=abs(p.y)-opening;
	float lid=smoothstep(-.003,.003,edge)*(1.0-step(.999,aperture));
	vec3 lid_color=mix(vec3(.035,.029,.061),vec3(.13,.095,.18),clamp((.17-abs(p.y))*4.0,0.0,1.0));
	lid_color+=mix(vec3(.27,.13,.4),iris_tint.rgb*.3,tone)*(1.0-smoothstep(.001,.007,abs(edge)));
	iris_ink.rgb=mix(iris_ink.rgb,lid_color,lid);
	ink.rgb=mix(ink.rgb,iris_ink.rgb,socket);
	float sector = floor(fract((atan(p.y,p.x)+1.8849556)/6.2831853)*10.0);
	if (sector >= ceil(clamp(life,0.0,1.0)*10.0)) {
		float grey = dot(ink.rgb,vec3(.2126,.7152,.0722));
		// Only the ten carved sectors fade; housing, pupil and lower lip stay lit.
		float ring = smoothstep(.183,.196,r) * (1.0-smoothstep(.312,.331,r));
		ink.rgb = mix(ink.rgb,vec3(grey*.36),.96*ring);
	}
	// Fragment COLOR already contains the texture sample. Multiplying it again
	// would darken the central stone and create a visible seam with both wings.
	COLOR = ink * item_tint;
}
