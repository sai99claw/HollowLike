class_name DoubleJumpV27
extends RefCounted
static var image:Texture2D
const PIVOTS:Array[Vector2]=[Vector2(284,594),Vector2(329,594),Vector2(317,594),Vector2(317,594)]
const DURATION:float=.32
static func texture() -> Texture2D:
	if image==null:image=load("res://assets/v27/player/double-jump-flap.png")
	return image
static func frame_index(elapsed:float) -> int:return clampi(int(elapsed*12.5),0,3)
static func draw(c:CanvasItem,at:Vector2,face:float,elapsed:float,base:Transform2D,tint:Color) -> void:
	var tex:Texture2D=texture()
	if tex==null:return
	var index:int=frame_index(elapsed);var ratio:Vector2=tex.get_size()/Vector2(2172,724);var factor:float=50.9375/333
	var source:=Rect2(Vector2(index*543,0)*ratio,Vector2(543,724)*ratio)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face,1),0,at))
	c.draw_texture_rect_region(tex,Rect2(-PIVOTS[index]*factor,Vector2(543,724)*factor),source,tint)
	c.draw_set_transform_matrix(base)
