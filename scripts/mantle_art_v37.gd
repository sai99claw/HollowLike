class_name MantleArtV37
extends RefCounted
const ROOT:String="res://assets/v37/player/"
static var data:Dictionary={}
static var image:Texture2D
static func info() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"ledge-mantle.json"))
	return data
static func draw(c:CanvasItem,p:Dictionary,base:Transform2D,tint:Color) -> void:
	var d:Dictionary=info()
	if image==null:image=load(ROOT+str(d["path"]))
	var index:int=preload("res://scripts/ledge_mantle_v37.gd").frame_index(float(p["mantle_left"]))
	var f:Dictionary=d["frames"][index];var r:Array=f["source_rect"];var pivot:Array=f["pivot"];var at:Vector2=p["pos"]
	if index<2:at=Vector2(p["mantle_from"].x+float(p["face"])*17,p["mantle_target"].y)
	var factor:float=float(d["pixel_factor"])
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(float(p["face"])*factor,factor),0,at))
	c.draw_texture_rect_region(image,Rect2(-Vector2(pivot[0],pivot[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),tint)
	c.draw_set_transform_matrix(base)
