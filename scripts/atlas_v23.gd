class_name AtlasV23
extends RefCounted
## Source rectangles and contact anchors are measured from the authored art.
const ROOT:String="res://assets/v23/"
static var manifests:Dictionary={}
static var sheets:Dictionary={}
static var frames:Dictionary={}
static func metadata(name:String) -> Dictionary:
	if manifests.has(name):return manifests[name]
	var path:String=ROOT+name+"-manifest.json"
	if not FileAccess.file_exists(path):return {}
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:manifests[name]=data;return data
	return {}
static func clip(name:String,id:String) -> Dictionary:
	var data:Dictionary=metadata(name)
	return data.get("clips",data.get("animations",{})).get(id,{})
static func texture(path:String,source:Array=[]) -> Texture2D:
	var absolute:String=ROOT+path
	if not sheets.has(absolute):
		if not ResourceLoader.exists(absolute):return null
		sheets[absolute]=load(absolute)
	if source.is_empty():return sheets[absolute]
	var key:String=absolute+str(source)
	if not frames.has(key):
		var image:=AtlasTexture.new();image.atlas=sheets[absolute];image.region=Rect2(source[0],source[1],source[2],source[3]);image.filter_clip=true;frames[key]=image
	return frames[key]
static func frame(name:String,id:String,index:int) -> Texture2D:
	var data:Dictionary=clip(name,id)
	if data.is_empty():return null
	var item:Dictionary=data["frames"][clampi(index,0,data["frames"].size()-1)]
	return texture(data["path"],item["source_rect"])
static func bounds(frame:Dictionary) -> Rect2:
	var raw:Array=frame["visible_bounds"]
	return Rect2(raw[0],raw[1],raw[2],raw[3])
static func pivot(frame:Dictionary) -> Vector2:
	var raw:Array=frame["pivot"];return Vector2(raw[0],raw[1])
static func draw(c:CanvasItem,name:String,id:String,index:int,at:Vector2,factor:float,face:float=1,base:Transform2D=Transform2D.IDENTITY,tint:Color=Color.WHITE) -> bool:
	var data:Dictionary=clip(name,id);var image:Texture2D=frame(name,id,index)
	if image==null:return false
	var f:Dictionary=data["frames"][clampi(index,0,data["frames"].size()-1)]
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*factor,factor),0,at))
	c.draw_texture(image,-pivot(f),tint);c.draw_set_transform_matrix(base)
	return true
