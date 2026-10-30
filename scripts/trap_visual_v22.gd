class_name TrapVisualV22
extends RefCounted
const Atlas=preload("res://scripts/atlas_v22.gd")
static func identity(h:Dictionary) -> String:
	var id:String=str(h.get("hazard_visual_id",h.get("visual_id",h.get("style_id",""))))
	if id in ["mist_spore","lamp_pollen"]:return "pollen_flower"
	if id in ["root_spike","root_wave"]:return "moss_thorns"
	return id
static func factor(h:Dictionary) -> float:
	var clip:Dictionary=Atlas.clip("trap",identity(h))
	return float(clip.get("world_width",64))/maxf(1,float(clip.get("reference_width",400)))
static func armed(h:Dictionary) -> bool:
	return float(h.get("elapsed",0))>=float(h.get("arming_time",.65))
static func frame_index(h:Dictionary) -> int:
	var elapsed:float=float(h.get("elapsed",0));var arming:float=maxf(.01,float(h.get("arming_time",.65)))
	if elapsed<arming:return clampi(int(elapsed/arming*5),0,4)
	return 5+int((elapsed-arming)*8)%3
static func body_box(h:Dictionary) -> Rect2:
	var clip:Dictionary=Atlas.clip("trap",identity(h))
	if clip.is_empty():
		var radius:float=float(h.get("size",30));return Rect2(Vector2(h["pos"])-Vector2(radius,radius*1.6),Vector2(radius*2,radius*1.6))
	var f:Dictionary=clip["frames"][5];var bounds:Rect2=Atlas.bounds(f);var anchor:Vector2=Atlas.pivot(f)
	var result:=Rect2((bounds.position-anchor)*factor(h)+Vector2(h["pos"]),bounds.size*factor(h))
	# Top/sides inset5%; the planted bottom is exactly on the support, so no
	# invisible damage volume extends into or beyond the ground plane.
	return Rect2(result.position+Vector2(result.size.x*.05,result.size.y*.1),Vector2(result.size.x*.9,result.size.y*.9))
static func draw(c:CanvasItem,h:Dictionary,base:Transform2D) -> bool:
	if h.get("group","")=="weapon":return false
	return Atlas.draw(c,"trap",identity(h),frame_index(h),h["pos"],factor(h),1,base)
