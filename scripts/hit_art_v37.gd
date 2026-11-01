class_name HitArtV37
extends RefCounted
const ROOT:String="res://assets/v37/effects/"
static var data:Dictionary={}
static var image:Texture2D
static func info() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"feather-crescent.json"))
	return data
static func texture() -> Texture2D:
	if image==null:image=load(ROOT+str(info()["path"]))
	return image
static func _frame(c:CanvasItem,kind:String,index:int,at:Vector2,angle:float,factor:float,base:Transform2D,alpha:float) -> void:
	var f:Dictionary=info()["animations"][kind][index];var r:Array=f["source_rect"];var pivot:Array=f["pivot"]
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2.ONE*factor,0,at))
	c.draw_texture_rect_region(texture(),Rect2(-Vector2(pivot[0],pivot[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),Color(1,1,1,alpha))
static func draw(c:CanvasItem,flash:Dictionary,base:Transform2D) -> void:
	var elapsed:float=float(flash["max"])-float(flash["life"])
	var angle:float=float(flash.get("angle",Vector2(flash["dir"]).angle()))
	var zoom:float=maxf(.1,base.get_scale().x)
	if elapsed<.12:
		preload("res://scripts/clean_crescent_v39.gd").draw(c,flash["at"],angle,float(flash.get("length",1280.0/3))/zoom,base,clampf((.12-elapsed)/.04,0,1))
	if bool(flash.get("feathers",false)):
		var index:int=clampi(int(elapsed/.18*3),0,2)
		var travel:Vector2=Vector2(flash["dir"])*elapsed*180
		_frame(c,"feathers",index,Vector2(flash.get("spray_at",flash["at"]))+travel,Vector2(flash["dir"]).angle(),.30,base,1.0)
	c.draw_set_transform_matrix(base)
