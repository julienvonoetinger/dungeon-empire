shader_type canvas_item;

// One retained physical rail segment. The scene sorts the two segments around
// the door separately; this shader only reuses their original prepared paint.
uniform vec4 atlas_region;
uniform vec4 logical_frame;
uniform vec3 support_min;
uniform vec3 support_max;
uniform vec3 projection_x;
uniform vec3 projection_y;
uniform vec3 view_direction;
uniform vec2 segment_span;
uniform bool along_x = false;
varying vec4 vertex_modulate;

void vertex() {
	vertex_modulate = COLOR;
}

void fragment() {
	vec2 screen = logical_frame.xy + (UV-atlas_region.xy)/atlas_region.zw*logical_frame.zw;
	vec2 s = screen/256.0;
	float det = projection_x.x*projection_y.y-projection_x.y*projection_y.x;
	vec3 origin = vec3((s.x*projection_y.y-s.y*projection_x.y)/det,
		(s.y*projection_x.x-s.x*projection_y.x)/det,0.0);
	vec3 lo = support_min;
	vec3 hi = support_max;
	if (along_x) { lo.x=max(lo.x,segment_span.x); hi.x=min(hi.x,segment_span.y); }
	else { lo.y=max(lo.y,segment_span.x); hi.y=min(hi.y,segment_span.y); }
	vec3 entry = (lo-origin)/view_direction;
	vec3 exit_hit = (hi-origin)/view_direction;
	float first = max(entry.x,max(entry.y,entry.z));
	float last = min(exit_hit.x,min(exit_hit.y,exit_hit.z));
	if (any(greaterThan(lo,hi)) || first > last) {
		COLOR.a = 0.0;
	} else {
		vec3 point = origin+view_direction*last;
		float end = along_x ? hi.x : hi.y;
		float original_end = along_x ? support_max.x : support_max.y;
		float q = along_x ? point.x : point.y;
		if (end < original_end-0.00001 && abs(q-end) < 0.00001) {
			// The shortened rear segment needs its own terminal face. Translate
			// the original painted end, keeping the same two masonry courses.
			if (along_x) { point.x = original_end-0.0003; }
			else { point.y = original_end-0.0003; }
			vec2 cap_screen = vec2(dot(point,projection_x),dot(point,projection_y))*256.0;
			vec2 cap_uv = atlas_region.xy + (cap_screen-logical_frame.xy)/logical_frame.zw*atlas_region.zw;
			cap_uv = clamp(cap_uv,atlas_region.xy+TEXTURE_PIXEL_SIZE*0.5,
				atlas_region.xy+atlas_region.zw-TEXTURE_PIXEL_SIZE*0.5);
			COLOR = texture(TEXTURE,cap_uv)*vertex_modulate;
		}
	}
}
