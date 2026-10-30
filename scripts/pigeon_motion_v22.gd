class_name PigeonMotionV22
extends RefCounted
const Pose=preload("res://scripts/atlas_v23.gd")
const Atlas=preload("res://scripts/atlas_v22.gd")
static func drowsy_index(idle_seconds:float) -> int:return posmod(int(maxf(0,idle_seconds-6)*8),8)
static func draw_drowsy(c:CanvasItem,at:Vector2,face:float,idle_seconds:float,base:Transform2D,tint:Color) -> bool:
	return draw(c,"drowsy",drowsy_index(idle_seconds),at,face,base,tint)
static func draw_air(c:CanvasItem,anim:String,at:Vector2,face:float,time:float,base:Transform2D,tint:Color,scale_value:float=1) -> bool:
	if anim=="wall":return draw_pose(c,"wall",int(time*8)%4,at,face,base,tint,scale_value)
	if anim in ["jump","jump_up","jump_apex","jump_down","land"]:return draw_pose(c,"air",{"jump":0,"jump_up":0,"jump_apex":1,"jump_down":2,"land":3}[anim],at,face,base,tint,scale_value)
	return false
static func draw(c:CanvasItem,id:String,index:int,at:Vector2,face:float,base:Transform2D,tint:Color,scale_value:float=1) -> bool:
	var clip:Dictionary=Atlas.clip("pigeon-motion",id)
	if clip.is_empty():return false
	return Atlas.draw(c,"pigeon-motion",id,index,at,float(clip["world_height"])/float(clip["reference_height"])*scale_value,face,base,tint)

static func pose_factor() -> float:
	var clip:Dictionary=Pose.clip("pigeon-motion","air")
	return float(clip["world_height"])/float(clip["reference_height"])
static func wall_anchor(at:Vector2,side:float) -> Vector2:
	# This is the physical side-boundary contact point. The authored local
	# pivot is the flat lower sole, not the sprite centre or a visual offset.
	return at+Vector2(side*17,0)
static func draw_pose(c:CanvasItem,id:String,index:int,at:Vector2,face:float,base:Transform2D,tint:Color,scale_value:float=1) -> bool:
	return Pose.draw(c,"pigeon-motion",id,index,wall_anchor(at,face) if id=="wall" else at,pose_factor()*scale_value,face,base,tint)
