shader_type canvas_item;
uniform float blur_radius=2.0;
uniform float saturation=0.25;
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec2 p=TEXTURE_PIXEL_SIZE*blur_radius;
 vec4 sum=texture(TEXTURE,UV)*0.28;
 sum+=(texture(TEXTURE,UV+p)+texture(TEXTURE,UV-p)+texture(TEXTURE,UV+vec2(p.x,-p.y))+texture(TEXTURE,UV+vec2(-p.x,p.y)))*0.18;
 float gray=dot(sum.rgb,vec3(.2126,.7152,.0722));
 sum.rgb=mix(vec3(gray),sum.rgb,saturation);
 COLOR=sum*vertex_tint;
}
