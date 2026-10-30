shader_type canvas_item;
uniform vec2 focus=vec2(0.5,0.5);
uniform float darkness=0.48;
void fragment(){
 float d=length((UV-focus)*vec2(1280.0,720.0));
 float shadow=smoothstep(100.0,570.0,d)*darkness;
 COLOR=vec4(.008,.018,.034,shadow);
}
