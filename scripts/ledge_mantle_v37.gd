class_name LedgeMantleV37
extends RefCounted
const BODY:=Vector2(34,42)
const ATTACH_RATIO:float=.51
const DURATION:float=.32
static func contact(at:Vector2,wall:int,solids:Array) -> Dictionary:
	if wall==0:return {"ratio":0.0}
	var edge:float=at.x+wall*BODY.x*.5
	var spans:Array[Vector2]=[];var tops:Array[float]=[]
	for rock:Rect2 in solids:
		if absf((rock.position.x if wall>0 else rock.end.x)-edge)>.2:continue
		var lo:float=maxf(at.y-BODY.y,rock.position.y);var hi:float=minf(at.y,rock.end.y)
		if hi<=lo:continue
		spans.append(Vector2(lo,hi));tops.append(rock.position.y)
	spans.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x)
	var length:float=0;var end:float=-INF
	for span:Vector2 in spans:length+=maxf(0,span.y-maxf(span.x,end));end=maxf(end,span.y)
	var result:Dictionary={"ratio":clampf(length/BODY.y,0,1)}
	if length<=0 or float(result["ratio"])+.000001>=ATTACH_RATIO:return result
	for top:float in tops:
		if top>=at.y or at.y-top>=BODY.y*ATTACH_RATIO:continue
		var target:=Vector2(edge+wall*(BODY.x*.5+3),top)
		var clearance:=Rect2(target-Vector2(BODY.x*.5,BODY.y),BODY).grow(-.2)
		if solids.any(func(box:Rect2)->bool:return box.intersects(clearance)):continue
		result["target"]=target;return result
	return result
static func begin(p:Dictionary,target:Vector2) -> void:
	p["mantle_left"]=DURATION;p["mantle_from"]=p["pos"];p["mantle_target"]=target
	p["vel"]=Vector2.ZERO;p["wall"]=0;p["dash_t"]=0;p["grounded"]=false;p["fall_distance"]=0;p["wall_hold_left"]=0
static func step(p:Dictionary,delta:float) -> void:
	p["mantle_left"]=maxf(0,float(p["mantle_left"])-delta)
	var t:float=1-float(p["mantle_left"])/DURATION;var origin:Vector2=p["mantle_from"];var target:Vector2=p["mantle_target"]
	var lift:=Vector2(origin.x,target.y-8)
	p["pos"]=origin.lerp(lift,smoothstep(0,.5,t)) if t<.5 else lift.lerp(target,smoothstep(.5,1,t))
	p["vel"]=Vector2.ZERO;p["grounded"]=t>=1;p["wall"]=0
	if t>=1:p["jumps"]=0;p["air_dash"]=false;p["jump_buffer_left"]=0
static func frame_index(left:float) -> int:return clampi(int((1-left/DURATION)*4),0,3)
