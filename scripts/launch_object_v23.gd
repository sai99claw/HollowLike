class_name LaunchObjectV23
extends RefCounted
const Atlas=preload("res://scripts/atlas_v23.gd")
static func body_box(prop:Dictionary,_biome:String="trunk") -> Rect2:
	var height:float=42.0 if prop.get("gothic_broken",false) else 67.0
	return Rect2(Vector2(prop["pos"])-Vector2(42,height),Vector2(84,height))
static func draw(c:CanvasItem,prop:Dictionary,biome:String,base:Transform2D) -> bool:
	var clip:Dictionary=Atlas.clip("launcher",biome)
	if clip.is_empty():return false
	var left:float=float(prop.get("launch_left",0));var frame:int=clampi(3+int((.625-left)*8),3,7) if left>0 else int(prop.get("compression",0))
	var texture:Texture2D=Atlas.frame("launcher",biome,frame)
	if texture==null:return false
	var spec:Dictionary=clip["frames"][clampi(frame,0,clip["frames"].size()-1)]
	var factor:float=float(clip["world_width"])/float(clip["reference_width"])
	var anchor:Vector2=prop["pos"]
	var top:Vector2=anchor-Atlas.pivot(spec)*factor+Vector2(0,body_box(prop,biome).size.y*.5)
	var height:float=clampf((anchor.y-top.y)/factor,0,texture.get_height())
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(texture,Rect2(top,Vector2(texture.get_width(),height)*factor),Rect2(0,0,texture.get_width(),height))
	return true
