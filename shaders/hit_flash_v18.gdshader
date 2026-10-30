shader_type canvas_item;
uniform float white_amount : hint_range(0.0,1.0) = 0.0;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 tex = texture(TEXTURE,UV)*vertex_tint;
	COLOR = vec4(mix(tex.rgb,vec3(1.0),white_amount),tex.a);
}
