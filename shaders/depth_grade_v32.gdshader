shader_type canvas_item;
uniform float blur_radius=1.2;
uniform float saturation=.65;
uniform float contrast=.75;
uniform float fog_amount=.2;
uniform float brightness=.9;
uniform vec4 fog_color:source_color=vec4(.4,.55,.5,1.);
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec2 p=TEXTURE_PIXEL_SIZE*blur_radius;
 vec4 sample_color=texture(TEXTURE,UV);
 // Premultiplied samples avoid dark fringes around transparent silhouettes.
 vec4 accum=vec4(sample_color.rgb*sample_color.a,sample_color.a);
 if(blur_radius>.01){
 accum*=.4;
 vec4 a=texture(TEXTURE,UV+vec2(p.x,0.));
 vec4 b=texture(TEXTURE,UV-vec2(p.x,0.));
 vec4 c=texture(TEXTURE,UV+vec2(0.,p.y));
 vec4 d=texture(TEXTURE,UV-vec2(0.,p.y));
 accum+=vec4(a.rgb*a.a,a.a)*.15+vec4(b.rgb*b.a,b.a)*.15+vec4(c.rgb*c.a,c.a)*.15+vec4(d.rgb*d.a,d.a)*.15;
 }
 vec3 rgb=accum.rgb/max(accum.a,.0001);
 float gray=dot(rgb,vec3(.2126,.7152,.0722));
 rgb=mix(vec3(gray),rgb,saturation);
 rgb=(rgb-.5)*contrast+.5;
 rgb=mix(rgb*brightness,fog_color.rgb,fog_amount);
 COLOR=vec4(rgb,accum.a)*vertex_tint;
}
