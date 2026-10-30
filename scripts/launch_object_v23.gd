class_name LaunchObjectV23
extends RefCounted
const Atlas=preload("res://scripts/atlas_v23.gd")
static func body_box(prop:Dictionary,biome:String="trunk") -> Rect2:
	var clip:Dictionary=Atlas.clip("launcher",biome)
	if clip.is_empty():return Rect2(Vector2(prop["pos"])-Vector2(42,84),Vector2(84,84))
	var raw:Array=clip["frames"][0]["visible_bounds"];var factor:float=float(clip["world_width"])/float(clip["reference_width"])
	var size:=Vector2(raw[2],raw[3])*factor*.9
	return Rect2(Vector2(prop["pos"])-Vector2(size.x*.5,size.y),size)
static func draw(c:CanvasItem,prop:Dictionary,biome:String,base:Transform2D) -> bool:
	var clip:Dictionary=Atlas.clip("launcher",biome)
	if clip.is_empty():return false
	var left:float=float(prop.get("launch_left",0));var frame:int=clampi(3+int((.625-left)*8),3,7) if left>0 else int(prop.get("compression",0))
	return Atlas.draw(c,"launcher",biome,frame,prop["pos"],float(clip["world_width"])/float(clip["reference_width"]),1,base)
