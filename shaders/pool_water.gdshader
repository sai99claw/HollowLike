shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D backdrop : hint_screen_texture, filter_linear;
uniform sampler2D cells : repeat_enable, filter_linear;
uniform vec2 span = vec2(264.0, 45.0);
uniform float clock;
uniform float recessed = 1.0;
uniform vec4 tint : source_color = vec4(0.24, 0.64, 0.59, 1.0);

void fragment() {
	vec2 p = UV * span;
	vec2 flow = p / vec2(86.0, 48.0);
	float a = texture(cells, flow + clock * vec2(0.049, -0.026)).r;
	float b = texture(cells, flow * vec2(1.48, 1.32) - clock * vec2(0.028, 0.019)).r;
	float bank = min(p.x, span.x - p.x);
	float bottom = mix(span.y, 9.0 + 18.0 * smoothstep(14.0, 33.0, bank) +
		18.0 * smoothstep(36.0, 59.0, bank) + (a - 0.5) * 1.7, recessed);
	float contact = smoothstep(0.0, 25.0, bank);
	float surface = 1.9 + contact * (sin(p.x * 0.105 - clock * 2.7) * 1.1 +
		sin(p.x * 0.182 + clock * 1.5) * 0.46);
	float depth = max(0.0, p.y - surface);
	float inside = smoothstep(-0.55, 0.85, p.y - surface) *
		smoothstep(0.0, 4.0, min(bank, bottom - p.y));
	vec2 bend = vec2(a - 0.5, b - 0.5) * 4.2 * inside;
	vec3 original = texture(backdrop, SCREEN_UV).rgb;
	vec3 refracted = texture(backdrop, SCREEN_UV + bend * SCREEN_PIXEL_SIZE).rgb;
	float deep = smoothstep(2.0, span.y, depth);
	vec3 water = mix(refracted * vec3(0.68, 0.88, 0.89), tint.rgb * mix(0.67, 0.24, deep), 0.33 + 0.30 * deep);
	float veins = pow(a * b, 1.25);
	float caustic = smoothstep(0.23, 0.39, veins) * (1.0 - deep * 0.7);
	float reflection = smoothstep(0.72, 0.99, sin(depth * 0.74 + a * 2.6 - clock * 1.7)) *
		smoothstep(0.43, 0.68, b) * exp(-depth * 0.10);
	float foam = (1.0 - smoothstep(0.4, 2.25, abs(p.y - surface))) *
		(0.54 + 0.36 * a + (1.0 - contact) * 0.15);
	water += tint.rgb * (caustic * 0.27 + reflection * 0.46);
	water = mix(water, vec3(0.75, 0.98, 0.89), foam);
	COLOR = vec4(mix(original, water, inside), 1.0);
}
