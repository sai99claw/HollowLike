shader_type canvas_item;
varying vec4 paint;
void vertex() { paint = COLOR; }
void fragment() {
	if (distance(paint.rgb,vec3(.125,.5,.875)) < .008) {
		vec4 tex = texture(TEXTURE,UV);
		float luma = dot(tex.rgb,vec3(.2126,.7152,.0722));
		vec3 core = mix(vec3(luma),tex.rgb,.60)*.35;
		COLOR = vec4(mix(tex.rgb,mix(core,vec3(.0863,.0667,.1098),.24),paint.a),tex.a);
	}
}
