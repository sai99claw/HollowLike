shader_type canvas_item;
render_mode unshaded;
uniform vec4 haze : source_color = vec4(.46,.44,.68,.18);
uniform float drift;
float rand_cell(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float fog_noise(vec2 p){
	vec2 i=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(rand_cell(i),rand_cell(i+vec2(1,0)),f.x),mix(rand_cell(i+vec2(0,1)),rand_cell(i+vec2(1,1)),f.x),f.y);
}
void fragment(){
	vec2 p=UV*vec2(6.0,2.7)+vec2(drift,0);
	float cloud=fog_noise(p)*.65+fog_noise(p*2.3+vec2(4,9))*.35;
	float band=smoothstep(0.0,.42,UV.y)*(1.0-smoothstep(.56,1.0,UV.y));
	COLOR=vec4(haze.rgb,haze.a*band*smoothstep(.12,.71,cloud));
}
