shader_type canvas_item;
render_mode unshaded;
uniform sampler2D stone_masks: filter_linear, repeat_disable;
uniform vec2 sprite_origin;
uniform vec2 sprite_extent;
uniform vec2 stair_origin;
uniform vec2 stair_extent;
uniform float descending=0.;
uniform float tunnel=0.;
uniform float behind_arch=0.;
uniform vec2 region_origin=vec2(0.);
uniform vec2 region_extent=vec2(1.);
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
	vec4 actor=texture(TEXTURE,UV)*tint;
	vec2 local_uv=(UV-region_origin)/region_extent;
	vec2 p=(sprite_origin+local_uv*sprite_extent-stair_origin)/stair_extent;
	float inside=step(0.,p.x)*step(p.x,1.)*step(0.,p.y)*step(p.y,1.);
	vec3 masks=texture(stone_masks,p).rgb*inside;
	actor.a*=1.-masks.r*descending;
	// Ground in front of the near retaining wall hides everything below it.
	// Equation is the frozen x=11/12 edge at z=0 in sanctuary coordinates.
	vec2 world=sprite_origin+local_uv*sprite_extent;
	float ground_edge=-266.6666667-world.x*.5;
	actor.a*=1.-smoothstep(ground_edge-.5,ground_edge+.5,world.y)*descending;
	actor.a*=1.-masks.b*behind_arch;
	actor.a*=mix(1.,masks.g,tunnel);
	COLOR=actor;
}
