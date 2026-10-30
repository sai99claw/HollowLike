shader_type canvas_item;
uniform float blur_radius=12.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 // Nine weighted samples preserve soft silhouettes, replacing 49 Gaussian taps.
 vec2 p=TEXTURE_PIXEL_SIZE*blur_radius*.65;
 vec4 sum=texture(TEXTURE,UV)*.25;
 sum+=(texture(TEXTURE,UV+vec2(p.x,0.0))+texture(TEXTURE,UV-vec2(p.x,0.0))+texture(TEXTURE,UV+vec2(0.0,p.y))+texture(TEXTURE,UV-vec2(0.0,p.y)))*.125;
 sum+=(texture(TEXTURE,UV+p)+texture(TEXTURE,UV-p)+texture(TEXTURE,UV+vec2(p.x,-p.y))+texture(TEXTURE,UV+vec2(-p.x,p.y)))*.0625;
 COLOR=sum*tint;
}
