class_name HomeVisualV33
extends RefCounted
const Art=preload("res://scripts/scene_art_v33.gd")
const ROOT:String="res://assets/v33/home/"
const FLOOR:float=600
const BOUNCE:=Vector2(455,600)
const RECORDS:=Vector2(790,600)
static func background(c:CanvasItem) -> void:
	var image:Texture2D=Art.texture(ROOT+"background.png")
	if image==null:return
	var d:Dictionary=Art.info(ROOT+"background.json");var original:Array=d.get("original_size",[1536,1024]);var source_y:float=float(d.get("authored_floor_y",730));var factor:float=1280.0/float(original[0])
	c.draw_texture_rect(image,Rect2(Vector2(0,FLOOR-source_y*factor),Vector2(original[0],original[1])*factor),false)
static func prop(c:CanvasItem,id:String,at:Vector2,size:Vector2) -> void:Art.prop(c,ROOT+"props.json",id,at,size)
static func gate(c:CanvasItem,id:String,at:Vector2) -> void:prop(c,id,at,Vector2(205,280))
static func body() -> Rect2:return Rect2(BOUNCE-Vector2(36,55),Vector2(72,55))
