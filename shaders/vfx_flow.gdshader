shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float clock;
uniform int style;

void fragment() {
	vec4 tint = COLOR;
	vec2 p = UV * 2.0 - 1.0;
	vec2 drift = vec2(-0.28, 0.16);
	if (style == 1 || style == 3) {
		drift = vec2(0.09, 0.41);
	}
	float a = texture(noise_tex, UV * vec2(2.7, 2.1) + clock * drift).r;
	float b = texture(noise_tex, UV * vec2(5.4, 4.2) - clock * drift * 0.61).r;
	float detail = a * 0.69 + b * 0.31;
	float edge = 1.0 - smoothstep(0.69, 1.0, max(abs(p.x), abs(p.y)));
	float body = 0.0;
	float hot = 0.0;
	if (style == 0) {
		float r = length(vec2(p.x, p.y * (1.24 - p.x * 0.36)));
		body = (1.0 - smoothstep(0.05, 0.99, r)) * smoothstep(0.23, 0.71, detail);
		hot = 1.0 - smoothstep(0.03, 0.43, length((p - vec2(0.28, 0.0)) * vec2(1.0, 1.8)));
	} else if (style == 1) {
		vec2 curl = vec2(p.x + (a - 0.5) * 0.31, p.y + (b - 0.5) * 0.20);
		float mass = 1.0 - length(curl * vec2(1.0, 1.06));
		body = smoothstep(0.12, 0.58, mass + (a - 0.50) * 0.40) *
			(0.45 + smoothstep(0.21, 0.65, a * 0.84 + b * 0.16) * 0.55);
		hot = body * smoothstep(0.46, 0.78, a) * 0.13;
	} else if (style == 2) {
		float y = abs(p.y + (a - 0.5) * 0.20);
		float filament = sin(UV.x * 63.0 - clock * 29.0 + b * 5.0) * 0.5 + 0.5;
		body = (1.0 - smoothstep(0.13, 0.99, y)) * (0.38 + 0.62 * detail);
		hot = (1.0 - smoothstep(0.035, 0.24, y)) * (0.7 + filament * 0.3);
		edge = smoothstep(0.0, 0.045, UV.x) * (1.0 - smoothstep(0.955, 1.0, UV.x));
	} else if (style == 3) {
		float tongue = abs(p.x) * (1.06 + 1.45 * (1.0 - UV.y)) + (1.0 - UV.y) * 0.92;
		body = (1.0 - smoothstep(0.43, 0.94, tongue - detail * 0.53)) *
			smoothstep(0.02, 0.39, UV.y) * (1.0 - smoothstep(0.91, 1.0, UV.y));
		hot = smoothstep(0.45, 0.98, body * UV.y * 1.19);
	} else if (style == 4) {
		float width = mix(0.18, 0.94, UV.y);
		float streak = smoothstep(0.29, 0.81, detail + sin(p.x * 15.0 + clock * 0.33) * 0.15);
		body = (1.0 - smoothstep(width * 0.10, width, abs(p.x))) * sin(UV.y * 3.14159) * streak;
		hot = body * 0.18;
	} else {
		float angle = atan(p.y, p.x + 0.00001);
		float r = length(p);
		float band = 0.68 + sin(angle * 3.0 - clock * 4.0) * 0.075;
		float crest = smoothstep(-0.45, 0.94, sin(angle * 3.0 - clock * 5.4 + a * 0.62));
		if (style == 6) {
			crest = 1.0 - smoothstep(0.42, 1.37, abs(angle));
			band = 0.78 - abs(angle) * 0.09;
		}
		float d = abs(r - band);
		body = (1.0 - smoothstep(0.008, 0.17, d)) * crest * (0.4 + 0.6 * detail);
		hot = (1.0 - smoothstep(0.005, 0.044, d)) * crest;
	}
	float alpha = max(body, hot * 0.62) * tint.a * edge;
	vec3 color = mix(tint.rgb, vec3(1.0, 0.97, 0.87), hot * 0.87);
	COLOR = vec4(color * alpha + color * hot * tint.a * edge * (style == 1 || style == 4 ? 0.0 : 0.22), alpha);
}
