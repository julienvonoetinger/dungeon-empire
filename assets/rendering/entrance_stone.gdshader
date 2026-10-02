shader_type spatial;

uniform sampler2D artwork : source_color, filter_linear_mipmap;
uniform sampler2D grain : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 position_world;
varying vec3 normal_world;
varying vec3 position_local;

void vertex() {
    position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    normal_world = MODEL_NORMAL_MATRIX * NORMAL;
    position_local = VERTEX;
}

void fragment() {
    vec3 weights = pow(abs(normalize(normal_world)), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 p = position_world * 0.22;
    vec3 stone = texture(grain, p.yz).rgb * weights.x
        + texture(grain, p.xz).rgb * weights.y
        + texture(grain, p.xy).rgb * weights.z;
    float value = dot(texture(artwork, UV).rgb, vec3(0.333333));
    // Match the wall material; baked shading must not darken the entire facade.
    vec3 tint = vec3(0.3843, 0.3961, 0.4392);
    float shoulder = smoothstep(0.50, 0.70, abs(position_local.x));
    float tunnel = (1.0 - smoothstep(0.24, 0.34, abs(position_local.x)))
        * (1.0 - smoothstep(-0.32, -0.08, position_local.z));
    ALBEDO = tint * (stone * 1.85 + vec3(0.025));
    ALBEDO *= mix(1.0, 0.8, shoulder);
    ALBEDO *= mix(1.0, clamp(value * 2.0, 0.18, 0.65), tunnel);
    ROUGHNESS = 0.9;
    SPECULAR = 0.15;
}
