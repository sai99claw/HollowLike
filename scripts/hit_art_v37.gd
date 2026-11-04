class_name HitArtV37
extends RefCounted
const FRAME_DURATION_USEC:int=62500
const FEATHER_FRAME_COUNT:int=2
const CRESCENT_DURATION_USEC:int=125000
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
static func feather_frame(elapsed_usec:int) -> int:
	return elapsed_usec / FRAME_DURATION_USEC if elapsed_usec>=0 and elapsed_usec<FEATHER_FRAME_COUNT*FRAME_DURATION_USEC else -1

static func draw(c:CanvasItem,flash:Dictionary,base:Transform2D) -> void:
	var elapsed:float=float(flash["max"])-float(flash["life"])
	var angle:float=float(flash.get("angle",Vector2(flash["dir"]).angle()))
	var zoom:float=maxf(.1,base.get_scale().x)
	var now_usec:int=Time.get_ticks_usec()
	var start_usec:int=flash.get("started_usec",now_usec-roundi(elapsed*1000000))
	var elapsed_usec:int=now_usec-start_usec
	if elapsed_usec<CRESCENT_DURATION_USEC:
		preload("res://scripts/clean_crescent_v39.gd").draw(c,flash["at"],angle,float(flash.get("length",1280.0/3))/zoom,base,1.0)
	var index:int=feather_frame(elapsed_usec)
	if index>=0 and bool(flash.get("feathers",false)):
		var travel:Vector2=Vector2(flash["dir"])*(float(elapsed_usec)/1000000.0)*180
		_frame(c,"feathers",index,Vector2(flash.get("spray_at",flash["at"]))+travel,Vector2(flash["dir"]).angle(),.30,base,1.0)
	c.draw_set_transform_matrix(base)
