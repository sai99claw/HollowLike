class_name BathWater
extends RefCounted
var ripples:Array[Dictionary]=[]
var was_wet:bool=false
var timer:float=0
var splashes:int=0
static func contains(pool:Rect2,at:Vector2) -> bool:
	return pool.size.x>0 and pool.has_point(at-Vector2(0,4))
func reset() -> void:ripples.clear();was_wet=false;timer=0;splashes=0
func attack(pool:Rect2,at:Vector2) -> void:
	if ripples.size()>=18:ripples.pop_front()
	ripples.append({"x":clampf(at.x,pool.position.x+8,pool.end.x-8),"age":0.0,"splash":true});splashes+=1;timer=.15
func step(pool:Rect2,at:Vector2,velocity:Vector2,delta:float) -> void:
	for ripple in ripples:ripple["age"]+=delta
	if not ripples.is_empty():ripples=ripples.filter(func(r:Dictionary)->bool:return r["age"]<1.2)
	var wet:bool=contains(pool,at);timer=maxf(0,timer-delta)
	if wet!=was_wet or wet and absf(velocity.x)>15 and timer<=0:
		if ripples.size()>=18:ripples.pop_front()
		ripples.append({"x":clampf(at.x,pool.position.x+20,pool.end.x-20),"age":0.0,"splash":wet!=was_wet or absf(velocity.y)>80});timer=.15
		if wet!=was_wet:splashes+=1
	was_wet=wet
func draw(c:CanvasItem,pool:Rect2,base:Transform2D,time:float,surface_only:bool=false) -> void:
	if pool.size.x<=0:return
	c.draw_set_transform_matrix(base)
	var points:=PackedVector2Array([Vector2(pool.position.x,pool.end.y)])
	for i in 33:
		var x:float=lerpf(pool.position.x,pool.end.x,float(i)/32);points.append(Vector2(x,pool.position.y+sin(time*1.6+i*.4)*1.5))
	points.append(pool.end)
	if not surface_only:c.draw_colored_polygon(points,Color(.28,.67,.70,.59))
	var surface:=PackedVector2Array()
	for i in 33:surface.append(points[i+1])
	if not surface_only:c.draw_polyline(surface,Color(.79,.98,.94,.66),2,true)
	for ripple in ripples:
		var t:float=float(ripple["age"])/1.2;var radius:float=10+52*t
		var wave:=PackedVector2Array()
		for i in 17:
			var angle:float=PI+float(i)/16*PI
			wave.append(Vector2(float(ripple["x"])+cos(angle)*radius,pool.position.y+sin(angle)*radius*.13+3))
		var clipped:=PackedVector2Array()
		for point:Vector2 in wave:
			if point.x>pool.position.x+3 and point.x<pool.end.x-3:clipped.append(point)
		if clipped.size()>1:
			c.draw_polyline(clipped,Color(.42,.84,.78,(1-t)*.38),3,true)
			c.draw_polyline(clipped,Color(.88,1,.98,(1-t)*.75),1.2,true)
		if ripple["splash"] and t<.5:
			for i in 5:c.draw_circle(Vector2(float(ripple["x"])+(i-2)*t*38,pool.position.y-sin(t*PI*2)* (14+i*3)),1.8*(1-t),Color(.8,.98,1,(1-t)*.8))
