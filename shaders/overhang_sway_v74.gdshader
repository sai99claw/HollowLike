shader_type canvas_item;
uniform vec2 wind_start;
uniform vec2 wind_end;
uniform float wind_amount;

void vertex() {
	vec2 path = wind_end - wind_start;
	float t = clamp(dot(VERTEX - wind_start, path) / max(dot(path, path), 0.001), 0.0, 1.0);
	float distance_to_wind = distance(VERTEX, wind_start + t * path);
	float response = 1.0 - smoothstep(12.0, 56.0, distance_to_wind);
	VERTEX.x += 7.0 * wind_amount * response * step(0.5, COLOR.a) * (1.0 - UV.y);
	COLOR.a = 1.0;
}
