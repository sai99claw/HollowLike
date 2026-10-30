shader_type canvas_item;
void fragment(){
 vec2 uv=UV;
 float d=min(min(length(uv*vec2(1.0,0.5625)),length((uv-vec2(1,0))*vec2(1.0,0.5625))),min(length((uv-vec2(0,1))*vec2(1.0,0.5625)),length((uv-vec2(1,1))*vec2(1.0,0.5625))));
 float glow=(1.0-smoothstep(0.0,0.24,d))*(0.39+sin(TIME*3.0)*0.06);
 COLOR=vec4(1.0,0.32,0.04,glow);
}
