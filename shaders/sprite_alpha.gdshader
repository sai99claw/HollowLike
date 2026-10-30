shader_type canvas_item;
// Remove neutral white matte fringes along existing alpha edges. Opaque body
// highlights remain intact; delivered PNG transparency is preserved.
void fragment() {
 vec4 tex = texture(TEXTURE, UV);
 vec2 px = TEXTURE_PIXEL_SIZE * 1.5;
 float edge = min(min(texture(TEXTURE,UV+vec2(px.x,0.0)).a,texture(TEXTURE,UV-vec2(px.x,0.0)).a),min(texture(TEXTURE,UV+vec2(0.0,px.y)).a,texture(TEXTURE,UV-vec2(0.0,px.y)).a));
 float low = min(tex.r,min(tex.g,tex.b));
 float high = max(tex.r,max(tex.g,tex.b));
 float sprite_only=step(1.0/256.0,min(TEXTURE_PIXEL_SIZE.x,TEXTURE_PIXEL_SIZE.y));
 float matte = sprite_only*smoothstep(0.92,0.995,low)*(1.0-smoothstep(0.015,0.08,high-low));
 COLOR.a *= 1.0-matte*(1.0-smoothstep(0.15,0.88,edge));
}
