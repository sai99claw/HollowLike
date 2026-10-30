class_name HeavyLandingV28
extends RefCounted
static var image:Texture2D
const SOURCE_SIZE:=Vector2(2048,768)
const PIVOTS:Array[Vector2]=[Vector2(317,643),Vector2(280,641),Vector2(277,642),Vector2(293,640)]
const FACTOR:float=50.9375/323
static func frame_index(elapsed:float) -> int:
	if elapsed<.08:return 0
	if elapsed<.34:return 1
	if elapsed<.44:return 2
	return 3
static func texture() -> Texture2D:
	if image==null:image=load("res://assets/v28/player/heavy-landing.png")
	return image
static func draw(c:CanvasItem,at:Vector2,face:float,elapsed:float,base:Transform2D,tint:Color) -> void:
	var tex:Texture2D=texture()
	if tex==null:return
	var index:int=frame_index(elapsed);var ratio:Vector2=tex.get_size()/SOURCE_SIZE
	var source:=Rect2(Vector2(index*512,0)*ratio,Vector2(512,768)*ratio)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face,1),0,at))
	c.draw_texture_rect_region(tex,Rect2(-PIVOTS[index]*FACTOR,Vector2(512,768)*FACTOR),source,tint)
	c.draw_set_transform_matrix(base)
