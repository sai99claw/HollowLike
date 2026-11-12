shader_type canvas_item;
uniform float sway_time;
void vertex() {
	VERTEX.x += sin(sway_time*1.8+VERTEX.x*.032)*COLOR.a*5.0;
	COLOR.a = 1.0;
}
