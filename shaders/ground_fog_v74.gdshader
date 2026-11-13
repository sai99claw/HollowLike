shader_type canvas_item;
render_mode unshaded;

uniform sampler2D drift_noise : repeat_enable, filter_linear;
uniform vec4 haze : source_color = vec4(.46,.44,.68,.18);
uniform float phase;
uniform float world_left;
uniform float world_width = 1280.0;

void fragment() {
	float x = (world_left + UV.x * world_width) / 385.0;
	float a = texture(drift_noise, vec2(x - phase * 0.045, UV.y * 0.68 + phase * 0.021)).r;
	float b = texture(drift_noise, vec2(x * 1.9 + phase * 0.029, UV.y * 1.3 - phase * 0.016)).r;
	float fog = smoothstep(.35,.68,a * .67 + b * .33);
	float height = UV.y + (a - 0.5) * 0.28;
	float band = smoothstep(0.07,0.64,height) * (1.0 - smoothstep(.69,1.0,UV.y));
	COLOR = vec4(haze.rgb, haze.a * band * fog);
}
