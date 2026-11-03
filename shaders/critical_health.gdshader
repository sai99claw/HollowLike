shader_type canvas_item;

void fragment() {
	vec2 edges = min(UV, vec2(1.0) - UV) * vec2(1280.0, 720.0);
	float edge = min(edges.x, edges.y);
	float rim = 1.0 - smoothstep(3.0, 12.0, edge);
	float glow = 1.0 - smoothstep(0.0, 95.0, edge);
	float pulse = 0.5 + 0.5 * sin(TIME * 3.0);
	COLOR = vec4(0.91, 0.04, 0.065, max(rim * 0.82, glow * (0.32 + 0.14 * pulse)));
}
