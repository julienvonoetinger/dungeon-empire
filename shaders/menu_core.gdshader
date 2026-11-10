shader_type canvas_item;
render_mode unshaded;

// Positions in the original sanctuary painting, before the menu crops it.
const vec2 PAINTING_SIZE = vec2(1672.0, 941.0);
const vec2 CORE_CENTER = vec2(842.0, 457.0);
const float CORE_RADIUS = 44.5;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	vec2 p = (UV * PAINTING_SIZE - CORE_CENTER) / CORE_RADIUS;
	float r = length(p);
	if (r < 3.8 && p.y < 1.66) {
		float phase = mod(TIME, 8.0) * (TAU / 8.0);
		float pulse = sin(2.0 * phase);
		vec2 direction = p / max(r, 0.001);
		// Turn the painted spiral inside the luminous rim.
		if (r < 1.0) {
			float angle = phase + 0.15 * sin(2.0 * phase - 3.0 * r);
			float c = cos(angle);
			float s = sin(angle);
			vec2 spiral = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
			spiral *= 1.0 - 0.035 * pulse;
			vec2 uv = (CORE_CENTER + CORE_RADIUS * spiral) / PAINTING_SIZE;
			paint.rgb = mix(texture(TEXTURE, uv).rgb, paint.rgb, smoothstep(0.80, 1.0, r));
		}

		// Carry ripples inward along the violet smoke in the painting.
		float violet = smoothstep(0.05, 0.27, min(paint.r, paint.b) - paint.g);
		float wisps = violet * smoothstep(0.95, 1.25, r) * (1.0 - smoothstep(2.4, 3.8, r));
		wisps *= 1.0 - smoothstep(1.20, 1.50, p.y);
		if (wisps > 0.0) {
			float wave = 3.8 * r + 2.0 * phase + direction.x;
			vec2 tangent = vec2(-direction.y, direction.x);
			vec2 drift = direction * (0.09 * sin(wave)) + tangent * (0.07 * cos(wave));
			vec3 smoke = texture(TEXTURE, UV + drift * CORE_RADIUS / PAINTING_SIZE).rgb;
			paint.rgb = mix(paint.rgb, smoke * (1.0 + 0.14 * sin(wave)), wisps);
		}

		// A highlight travels around the ring; its light also reaches the altar lip.
		float rim = 1.0 - smoothstep(0.04, 0.32, abs(r - 1.0));
		float highlight = max(dot(direction, vec2(cos(phase), -sin(phase))), 0.0);
		paint.rgb *= 1.0 + rim * (0.10 * pulse + 0.25 * highlight * highlight);
		float altar = smoothstep(1.12, 1.50, p.y) * (1.0 - smoothstep(1.50, 1.66, p.y));
		paint.rgb += vec3(0.065, 0.018, 0.09) * pulse * altar * (1.0 - smoothstep(0.0, 1.7, abs(p.x)));
	}
	COLOR = paint * tint;
}
