class_name PigeonIdleV19
extends RefCounted
const ROOT:String="res://assets/v19/"
const IDLE_FPS:float=5.0
const REST_FPS:float=8.0
const IDLE_SEQUENCE=[0,1,2,4,5,6,5,4,2,1,0,1,2,4,5,6,5,4,2,1]
const REST_SEQUENCE=[1,2,3,4,5,6,7]
const NewMotion=preload("res://scripts/pigeon_motion_v22.gd")
static var manifest:Dictionary={}
static var textures:Dictionary={}
static func ensure() -> void:
	if manifest.is_empty():manifest=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"idle-manifest.json"))
static func frame_index(idle_seconds:float) -> int:
	if idle_seconds>=5:return REST_SEQUENCE[mini(REST_SEQUENCE.size()-1,int((idle_seconds-5)*REST_FPS))]
	return IDLE_SEQUENCE[int(maxf(idle_seconds,0)*IDLE_FPS)%IDLE_SEQUENCE.size()]
static func draw(c:CanvasItem,at:Vector2,face:float,idle_seconds:float,base:Transform2D=Transform2D.IDENTITY,tint:Color=Color.WHITE) -> void:
	if idle_seconds>=6 and NewMotion.draw_drowsy(c,at,face,idle_seconds,base,tint):return
	ensure()
	var id:String="rest" if idle_seconds>=5 else "idle";var clip:Dictionary=manifest["animations"][id]
	var f:Dictionary=clip["frames"][frame_index(idle_seconds)];var raw:Array=f["source_rect"]
	var path:String=ROOT+clip["path"]
	if not textures.has(path):textures[path]=load(path)
	var factor:float=float(manifest["world_height"])/float(clip["reference_height"])
	var pivot:=Vector2(f["pivot"][0],f["pivot"][1]);var size:=Vector2(f["size"][0],f["size"][1])
	# Once asleep, hold the last authored pose with a tiny 8Hz breathing motion.
	var breath:float=sin(floorf(idle_seconds*REST_FPS)/REST_FPS*2.0)*.009 if idle_seconds>=6 else 0.0
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*factor,factor*(1+breath)),0,at))
	c.draw_texture_rect_region(textures[path],Rect2(-pivot,size),Rect2(raw[0],raw[1],raw[2],raw[3]),tint)
	c.draw_set_transform_matrix(base)
