shader_type canvas_item;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float outline_width : hint_range(2.5, 3.5) = 3.0;
uniform vec4 ink : source_color = vec4(.07059,.05098,.08627,1.0);
uniform sampler2D ink_texture : filter_linear;
uniform bool padded_sprite = false;
uniform vec4 source_rect;
uniform float padding;
varying vec2 local_pixel;
varying vec4 tint;

void vertex() {
	local_pixel = VERTEX;
	tint = COLOR;
}

vec4 frame_sample(vec2 p, vec2 texel) {
	vec2 inside = step(source_rect.xy,p)*(1.0-step(source_rect.xy+source_rect.zw,p));
	vec2 safe = clamp(p,source_rect.xy+.5,source_rect.xy+source_rect.zw-.5)*texel;
	vec4 body = texture(ink_texture,safe);
	return vec4(body.rgb,body.a*inside.x*inside.y);
}

void fragment() {
	vec4 body = texture(TEXTURE,UV);
	float border = 0.0;
	if (padded_sprite) {
		vec2 p = source_rect.xy + local_pixel - padding;
		body = frame_sample(p,TEXTURE_PIXEL_SIZE);
		vec2 dx = dFdx(p)*outline_width;
		vec2 dy = dFdy(p)*outline_width;
		if (body.a < .98) {
			for (int i=0; i<8; i++) {
				float a = float(i)*.785398;
				border = max(border,frame_sample(p+dx*cos(a)+dy*sin(a),TEXTURE_PIXEL_SIZE).a);
			}
		}
	}
	vec3 rgb = body.rgb*tint.rgb;
	float gray = dot(rgb,vec3(.2126,.7152,.0722));
	float value = floor(clamp((gray-.5)*1.18+.5,0.0,1.0)*4.0+.5)*.25;
	vec3 painted = clamp(vec3(value)+(rgb-gray)*.80,0.0,1.0);
	float alpha = body.a + border*(1.0-body.a);
	COLOR = vec4(mix(ink.rgb,mix(painted,vec3(1.48),hit_flash),body.a/max(alpha,.001)),alpha*tint.a);
}
