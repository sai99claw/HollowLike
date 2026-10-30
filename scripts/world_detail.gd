class_name WorldDetail
extends RefCounted
static var spring_texture:Texture2D
static func spring(c:CanvasItem,at:Vector2,time:float,base:Transform2D,width:float=260) -> bool:
	if spring_texture==null and ResourceLoader.exists("res://assets/atmosphere_v10/spring.png"):spring_texture=load("res://assets/atmosphere_v10/spring.png")
	if spring_texture==null:return false
	var cell:Vector2=spring_texture.get_size()*.5
	var index:int=int(time*3)%4
	var size:=Vector2(width,width*cell.y/cell.x)
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(spring_texture,Rect2(at-Vector2(size.x*.5,size.y*.91),size),Rect2(Vector2(index%2,index/2)*cell,cell))
	return true
static func grass(c:CanvasItem,prop:Dictionary,time:float,base:Transform2D) -> void:
	var seed_value:float=float(prop.get("seed",0));var at:Vector2=prop["pos"]
	var cut:bool=prop.get("used",false)
	var fade:float=clampf(float(prop.get("break_left",0))/.45,0,1) if cut else 1.0
	c.draw_set_transform_matrix(base)
	for i in 7:
		var root:Vector2=at+Vector2((i-3)*3,0)
		var height:float=15+fposmod(seed_value*8+i*9,18)
		var sway:float=sin(time*1.4+seed_value+i*.5)*3
		var tip:Vector2=root+Vector2(sin(i*2.1+seed_value)*10+sway,-height)
		var middle:Vector2=root.lerp(tip,.55)+Vector2(sway+3,0)
		if cut:
			root+=Vector2((i-3)*(1-fade)*6,-(1-fade)*19);middle+=Vector2((i-3)*(1-fade)*7,-(1-fade)*17);tip+=Vector2((i-3)*(1-fade)*8,-(1-fade)*15)
		c.draw_colored_polygon(PackedVector2Array([root-Vector2(2,0),middle-Vector2(1.5,0),tip,middle+Vector2(1.5,0),root+Vector2(2,0)]),Color(.32+i*.023,.49+i*.025,.35+i*.018,fade*.85))
