class_name CleanCrescentV38
extends RefCounted
const ROOT:String="res://assets/v38/effects/"
static var data:Dictionary={}
static var image:Texture2D
static func info() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"clean-crescent.json"))
	return data
static func texture() -> Texture2D:
	if image==null:image=load(ROOT+str(info()["path"]))
	return image
static func draw(c:CanvasItem,at:Vector2,angle:float,length:float,base:Transform2D,alpha:float) -> void:
	var d:Dictionary=info();var p:Array=d["pivot"];var r:Array=d["source_rect"]
	var factor:float=length/float(d["reference_height"])
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2.ONE*factor,0,at))
	c.draw_texture_rect_region(texture(),Rect2(-Vector2(p[0],p[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),Color(1,1,1,alpha))
	c.draw_set_transform_matrix(base)
