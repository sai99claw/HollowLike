shader_type canvas_item;
render_mode unshaded;
uniform vec2 drift;
uniform float intensity=1.0;

float twig(vec2 p, vec2 a, vec2 b, vec2 radius){
	vec2 line=b-a;
	float t=clamp(dot(p-a,line)/dot(line,line),0.0,1.0);
	return 1.0-smoothstep(0.0,.005,length(p-a-line*t)-mix(radius.x,radius.y,t));
}
void fragment(){
	vec2 p=vec2(UV.x*1.7778,UV.y);
	vec2 shift=vec2(sin(drift.x*.006)*.16,sin(drift.y*.006)*.032);
	vec2 l=p-shift;
	vec2 r=vec2(1.7778,1.0)-p+shift;
	float edge=max(twig(l,vec2(-.27,.23),vec2(.54,-.10),vec2(.12,.028)),twig(r,vec2(-.22,.20),vec2(.42,-.081),vec2(.13,.018)));
	edge=max(edge,twig(l,vec2(.04,.10),vec2(.27,.054),vec2(.032,.002)));
	edge=max(edge,twig(r,vec2(.01,.086),vec2(.22,.102),vec2(.034,.003)));
	edge=max(edge,twig(p+shift,vec2(1.92,.05),vec2(1.49,-.035),vec2(.085,.005)));
	edge=max(edge,twig(p-shift,vec2(-.18,.93),vec2(.19,1.07),vec2(.09,.006)));
	float x=.17+sin(drift.x*.009)*.11;
	float vine=abs(p.x-x-sin(p.y*21.0+drift.y*.012)*.014);
	edge=max(edge,(1.0-smoothstep(.009,.013,vine))*(1.0-smoothstep(.17,.24,p.y)));
	edge=max(edge,twig(p,vec2(x,.16),vec2(x-.044,.195),vec2(.012,.003)));
	float x2=1.60+sin(drift.x*.008+2.0)*.1;
	edge=max(edge,(1.0-smoothstep(.007,.011,abs(p.x-x2-sin(p.y*17.0)*.01)))*(1.0-smoothstep(.11,.20,p.y)));
	COLOR=vec4(.0392,.0275,.0549,.90*edge*intensity);
}
