class_name CleanCrescentV39
extends RefCounted
const ROOT:String="res://assets/v39/effects/"
static var data:Dictionary={}
static var image:Texture2D
static func info() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"fine-crescent.json"))
	return data
static func texture() -> Texture2D:
	if image==null:image=load(ROOT+str(info()["path"]))
	return image
static func pose(at:Vector2,angle:float,length:float) -> Transform2D:
	var factor:float=length/float(info()["reference_height"])
	return Transform2D(angle,Vector2(-factor,factor),0,at)
static func draw(c:CanvasItem,at:Vector2,angle:float,length:float,base:Transform2D,alpha:float) -> void:
	var d:Dictionary=info();var p:Array=d["pivot"];var r:Array=d["source_rect"]
	c.draw_set_transform_matrix(base*pose(at,angle,length))
	c.draw_texture_rect_region(texture(),Rect2(-Vector2(p[0],p[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),Color(1,1,1,alpha))
	c.draw_set_transform_matrix(base)
