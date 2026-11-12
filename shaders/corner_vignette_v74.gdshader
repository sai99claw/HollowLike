shader_type canvas_item;
render_mode unshaded;
void fragment(){
	vec2 p=abs(UV-.5)*2.0;
	COLOR=vec4(.035,.025,.062,smoothstep(.55,1.41,length(p*vec2(.94,1.0)))*.34);
}
