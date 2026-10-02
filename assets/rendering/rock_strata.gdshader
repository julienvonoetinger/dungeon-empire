shader_type spatial;

uniform sampler2D stone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_scale = 0.24;
uniform float albedo_gain = 1.7;
uniform float bump_strength = 0.045;
uniform bool floor_edges = false;
uniform sampler2D spike_stone : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D snare_stone : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D void_stone : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D treasury_stone : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D treasury_empty : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D boundary_stone : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 position_world;
varying vec3 normal_world;

void vertex() {
    position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    normal_world = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
    vec3 weights = pow(abs(normalize(normal_world)), vec3(8.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 p = position_world * texture_scale;
    vec3 grain = texture(stone, p.yz).rgb * weights.x
        + texture(stone, p.xz).rgb * weights.y
        + texture(stone, p.xy).rgb * weights.z;
    float height = dot(grain, vec3(0.333333));
    // Screen-space surface gradient adds shallow relief without a normal atlas.
    vec3 dx = dFdx(VERTEX);
    vec3 dy = dFdy(VERTEX);
    vec3 r1 = cross(dy, NORMAL);
    vec3 r2 = cross(NORMAL, dx);
    float determinant = dot(dx, r1);
    vec3 gradient = sign(determinant) * (dFdx(height) * r1 + dFdy(height) * r2);
    NORMAL = normalize(max(abs(determinant), 0.0000001) * NORMAL - bump_strength * gradient);
    ALBEDO = COLOR.rgb * grain * albedo_gain;
    if (floor_edges) {
        vec2 tile = fract(UV);
		// Preserve world-space paving: only the plinth and gold replace its pixels.
		if (UV2.y > 0.5 && UV2.y < 2.5) {
			float edge = min(min(tile.x, 1.0 - tile.x), min(tile.y, 1.0 - tile.y));
			vec3 treasury = UV2.y > 1.5 ? texture(treasury_empty, tile).rgb : texture(treasury_stone, tile).rgb;
			float gold = smoothstep(0.08, 0.24, (treasury.r - treasury.b) / max(treasury.r, 0.01));
			gold *= UV2.y < 1.5 ? 1.0 : 0.0;
			// The source plinth is off-center and rectangular. Map it onto a
			// centered square so quarter-turns cannot move it beneath the billboard.
			vec2 plinth_uv = vec2(0.5, 0.465) + (tile - vec2(0.5)) * vec2(0.53, 0.41) / 0.64;
			float plinth_edge = 0.32 - max(abs(tile.x - 0.5), abs(tile.y - 0.5));
			float plinth = smoothstep(-0.006, 0.006, plinth_edge);
			vec3 plinth_color = texture(treasury_empty, plinth_uv).rgb;
			ALBEDO = mix(ALBEDO, plinth_color * albedo_gain, plinth);
			ALBEDO = mix(ALBEDO, treasury * albedo_gain, gold * smoothstep(0.02, 0.065, edge));
		}
        if (UV2.y > 2.5 && UV2.y < 3.5) {
            // Register the painted socket centers to the animated 0.25 grid.
            vec2 spike_uv = vec2(0.5) + (tile - vec2(0.5)) * vec2(1.08, 1.04);
            vec3 trap_stone = texture(spike_stone, spike_uv).rgb;
            float edge = min(min(tile.x, 1.0 - tile.x), min(tile.y, 1.0 - tile.y));
            ALBEDO = mix(ALBEDO, trap_stone * albedo_gain, smoothstep(0.035, 0.17, edge));
        }
        if (UV2.y > 3.5) {
            // Register the artwork's recessed socket with the centered grasp.
            vec2 snare_uv = tile + vec2(0.0, -0.035);
            vec3 trap_stone = UV2.y > 4.5 ? texture(void_stone, snare_uv).rgb : texture(snare_stone, snare_uv).rgb;
            float edge = min(min(tile.x, 1.0 - tile.x), min(tile.y, 1.0 - tile.y));
            ALBEDO = mix(ALBEDO, trap_stone * albedo_gain, smoothstep(0.035, 0.17, edge));
        }
        float mask = round(UV2.x);
        float distance_to_edge = 1.0;
        if (mod(mask, 2.0) > 0.5) distance_to_edge = min(distance_to_edge, tile.x);
        if (mod(floor(mask / 2.0), 2.0) > 0.5) distance_to_edge = min(distance_to_edge, 1.0 - tile.x);
        if (mod(floor(mask / 4.0), 2.0) > 0.5) distance_to_edge = min(distance_to_edge, tile.y);
        if (mod(floor(mask / 8.0), 2.0) > 0.5) distance_to_edge = min(distance_to_edge, 1.0 - tile.y);
        vec3 dust = texture(boundary_stone, position_world.xz * 1.7).rgb;
        float spread = 0.06 + dot(dust, vec3(0.333333)) * 0.45;
        float weathering = 1.0 - smoothstep(0.01, spread, distance_to_edge);
        ALBEDO = mix(ALBEDO, dust * vec3(0.9, 0.86, 0.8), weathering * 0.65);
        ALBEDO *= mix(0.58, 1.0, smoothstep(0.0, 0.055, distance_to_edge));
    }
    ROUGHNESS = 0.96;
    SPECULAR = 0.12;
}
