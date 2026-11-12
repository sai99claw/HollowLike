extends RefCounted
static var fill:GradientTexture2D

static func trailing(enemy:Dictionary,age:float) -> float:
	var hp:float=enemy["hp"]
	return lerpf(float(enemy.get("bar_previous_hp",hp)),hp,smoothstep(.13,.58,age))

static func damaged(enemy:Dictionary,now:float) -> void:
	enemy["bar_previous_hp"]=trailing(enemy,now-float(enemy.get("bar_hit_at",-INF)))
	enemy["bar_hit_at"]=now

static func opacity(enemy:Dictionary,now:float) -> float:
	if float(enemy["hp"])>=float(enemy["max_hp"]):return 0.0
	var age:float=now-float(enemy.get("bar_hit_at",-INF))
	return smoothstep(-.012,.11,age)*(1.0-smoothstep(3.0,3.28,age))

static func draw(canvas:CanvasItem,enemy:Dictionary,bounds:Rect2,now:float) -> void:
	var alpha:float=opacity(enemy,now)
	if alpha<=.001:return
	var capacity:float=maxf(1.0,float(enemy["max_hp"]))
	var width:float=52.0 if enemy.get("elite",false) else 38.0
	var at:=Vector2(bounds.get_center().x-width*.5,bounds.position.y-10)
	canvas.draw_rect(Rect2(at-Vector2.ONE,Vector2(width+2,6)),Color("120d16",alpha*.95))
	canvas.draw_rect(Rect2(at,Vector2(width,4)),Color("321c2b",alpha))
	canvas.draw_rect(Rect2(at,Vector2(width*clampf(trailing(enemy,now-float(enemy["bar_hit_at"]))/capacity,0,1),4)),Color("fce5dd",alpha))
	if fill==null:
		fill=GradientTexture2D.new()
		fill.width=2
		fill.height=8
		fill.fill_to=Vector2(0,1)
		var gradient:=Gradient.new()
		gradient.offsets=PackedFloat32Array([0,.30,1])
		gradient.colors=PackedColorArray([Color("fff1e6"),Color("f77d79"),Color("c33451")])
		fill.gradient=gradient
	canvas.draw_texture_rect(fill,Rect2(at,Vector2(width*clampf(float(enemy["hp"])/capacity,0,1),4)),false,Color(1,1,1,alpha))
