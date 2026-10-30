class_name CloakArtV29
extends RefCounted
static var catalog:Array=[]
static var textures:Dictionary={}
static func styles() -> Array:
	if catalog.is_empty():
		var path:String="res://assets/v30/cloaks/catalog.json"
		if FileAccess.file_exists(path):
			var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:catalog=parsed.get("styles",[])
	return catalog
static func definition(index:int) -> Dictionary:
	var all:Array=styles()
	return all[clampi(index,0,all.size()-1)] if not all.is_empty() else {}
static func texture(index:int) -> Texture2D:
	var def:Dictionary=definition(index)
	if def.is_empty():return null
	var path:String="res://assets/v30/cloaks/"+str(def["file"])
	if not textures.has(path):textures[path]=load(path)
	return textures[path]
static func atlas(index:int,frame:int=0) -> AtlasTexture:
	var def:Dictionary=definition(index);var image:Texture2D=texture(index)
	if image==null:return null
	var f:Dictionary=def["frames"][clampi(frame,0,def["frames"].size()-1)]
	var rect:Array=f["rect"];var ratio:Vector2=image.get_size()/Vector2(def["size"][0],def["size"][1])
	var result:=AtlasTexture.new();result.atlas=image;result.region=Rect2(Vector2(rect[0],rect[1])*ratio,Vector2(rect[2],rect[3])*ratio)
	return result
static func draw(c:CanvasItem,index:int,at:Vector2,face:float,time:float,moving:bool,base:Transform2D,pose:String="idle",alpha:float=1.0) -> void:
	if index==0:return # Original skin preserves the existing scarf and silhouette.
	var def:Dictionary=definition(index);var image:Texture2D=texture(index)
	if image==null:return
	var frames:Array=def["frames"];var n:int=posmod(int(time*(9 if moving else 3)),frames.size())
	var f:Dictionary=frames[n];var rect:Array=f["rect"];var pivot:Array=f["pivot"]
	var ratio:Vector2=image.get_size()/Vector2(def["size"][0],def["size"][1])
	# One stable style scale, so fluttering frames never change the cloak's size.
	var factor:float=minf(22.0/float(def["visible_height"]),36.0/float(def["visible_width"]))
	var offset:Vector2=nape(pose,time,moving)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face,1),0,at+Vector2(offset.x*face,offset.y)))
	c.draw_texture_rect_region(image,Rect2(-Vector2(pivot[0],pivot[1])*factor,Vector2(rect[2],rect[3])*factor),Rect2(Vector2(rect[0],rect[1])*ratio,Vector2(rect[2],rect[3])*ratio),Color(1,1,1,alpha))
	c.draw_set_transform_matrix(base)

static func nape(pose:String,time:float,moving:bool) -> Vector2:
	match pose:
		"heavy_land":return Vector2(-5,-25)
		"land":return Vector2(-6,-30)
		"rest":return Vector2(-7,-28)
		"wall":return Vector2(-2,-35)
		"jump_up","jump_apex","jump_down":return Vector2(-6,-33)
		"hurt":return Vector2(-9,-29)
		"charge","windup","active":return Vector2(-7,-31)
	return Vector2(-6,-32-absf(sin(time*15.0))*1.2) if moving else Vector2(-6,-32)
