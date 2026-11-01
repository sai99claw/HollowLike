class_name DashFlapV39
extends RefCounted
## Small wing-puff artwork, aligned behind the single-C movement.
static func gust(c:CanvasItem,at:Vector2,direction:Vector2,elapsed:float,base:Transform2D) -> void:
	var anchor:Vector2=at-Vector2(0,24)-direction*12
	var local:Transform2D=base*Transform2D(direction.angle()+PI*.5,anchor)
	preload("res://scripts/adventure_art_v29.gd").jump_gust(c,Vector2.ZERO,elapsed*.20/.16,local)
	c.draw_set_transform_matrix(base)
