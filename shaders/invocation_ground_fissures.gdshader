shader_type canvas_item;
render_mode unshaded;

uniform sampler2D shale : source_color, filter_linear, repeat_disable;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 vein = texture(TEXTURE, UV);
	vec4 rock = texture(shale, UV);
	// Offset toward the light to leave a dark stone lip above the glowing split.
	float interior = texture(TEXTURE, UV - vec2(.85, 1.05) * TEXTURE_PIXEL_SIZE).a;
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float facets = sin(px.x * .18 + px.y * .11 + 1.8 * sin(px.y * .21));
	float grain = smoothstep(.06, .32, dot(rock.rgb, vec3(.30, .59, .11)));
	float light = interior * (.49 + .19 * facets + .30 * grain);
	vec3 ink = mix(rock.rgb * vec3(.61, .32, .74), vein.rgb, light);
	COLOR = vec4(ink, vein.a * rock.a) * tint;
}
