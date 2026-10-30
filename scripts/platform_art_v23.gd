class_name PlatformArtV23
extends RefCounted
const Atlas=preload("res://scripts/atlas_v23.gd")
static var calibration:Dictionary={}
static var frames:Dictionary={}
static func definition(biome:String,count:int) -> Dictionary:
	if count==4:return Atlas.metadata("platform-four").get("biomes",{}).get(biome,{})
	if calibration.is_empty():calibration=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v23/platform-collision.json"))
	return calibration.get("biomes",{}).get(biome,{}).get(str(count),{})
static func texture(data:Dictionary) -> Texture2D:
	var path:String=str(data["path"])
	if not path.begins_with("res://"):path="res://assets/v23/"+path
	var key:String=path+str(data["source_rect"])
	if not frames.has(key):
		var source:Array=data["source_rect"];var frame:=AtlasTexture.new();frame.atlas=load(path);frame.region=Rect2(source[0],source[1],source[2],source[3]);frame.filter_clip=true;frames[key]=frame
	return frames[key]
static func draw(c:CanvasItem,biome:String,rect:Rect2) -> void:
	var count:int=clampi(roundi(rect.size.x/96),1,4);var data:Dictionary=definition(biome,count)
	if data.is_empty():return
	var image:Texture2D=texture(data);var span:Array=data["body_span"];var factor:float=(count*96.0)/(float(span[1])-float(span[0]))
	# The physical shelf is the opaque body row. Painted grass above and roots
	# below are decorative overhangs. Each authored length has a fixed scale.
	c.draw_texture_rect(image,Rect2(rect.position-Vector2(float(span[0]),float(data["surface_y"]))*factor,image.get_size()*factor),false)
