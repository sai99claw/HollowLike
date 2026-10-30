class_name MonsterMotionV18
extends RefCounted
## Authored eight-pose movement. Body scale is fixed per species, never per pose.
## Existing attack / hurt / death artwork stays in the species' original library.
const ROOT:String="res://assets/v18/"
const Appearance=preload("res://scripts/monster_appearance.gd")
static var manifest:Dictionary={}
static var _textures:Dictionary={}
static var _frames:Dictionary={}
static var _body_sizes:Dictionary={}

static func ensure() -> bool:
	if not manifest.is_empty():return true
	var path:String=ROOT+"monster-motion-manifest.json"
	if not FileAccess.file_exists(path):return false
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:manifest=parsed
	return not manifest.is_empty()

static func identity(en:Dictionary) -> String:
	return Appearance.biome(en) if Appearance.is_boss(en) else Appearance.species(en)

static func definition(id:String) -> Dictionary:
	return manifest.get("animations",{}).get(id,{}) if ensure() else {}

static func factor_for(en:Dictionary) -> float:
	var clip:Dictionary=definition(identity(en))
	if clip.is_empty():return 1
	return float(clip.get("world_height",57))/maxf(1,float(clip.get("reference_height",256)))*(1.0 if Appearance.is_boss(en) else float(en.get("scale",1)))

static func body_size(en:Dictionary) -> Vector2:
	if en.has("roster_id"):return Vector2(en.get("body_size",Vector2(34,45)))
	if en.get("training",false):return en.get("body_size",Vector2(84,120))
	var id:String=identity(en);var clip:Dictionary=definition(id)
	if clip.is_empty():return Vector2(en.get("body_size",Vector2(34,42)))*.9
	var scale_value:float=1.0 if Appearance.is_boss(en) else float(en.get("scale",1))
	if en.get("_body_cache_id","")==id and float(en.get("_body_cache_scale",-1))==scale_value:return en["_body_cache_size"]
	if not _body_sizes.has(id):
		var bounds:Array=clip["frames"][0]["visible_bounds"]
		_body_sizes[id]=Vector2(float(bounds[2]),float(bounds[3]))*.9
	# A single resting-body measurement owns collision through every pose.
	# Its bottom is the same feet anchor used to render, on both facing sides.
	var result:Vector2=Vector2(_body_sizes[id])*float(clip.get("world_height",57))/maxf(1,float(clip.get("reference_height",256)))*scale_value
	en["_body_cache_id"]=id;en["_body_cache_scale"]=scale_value;en["_body_cache_size"]=result
	return result

static func texture_for(id:String,index:int=0) -> Texture2D:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return null
	var key:String=id+":"+str(posmod(index,8))
	if _frames.has(key):return _frames[key]
	var path:String=ROOT+str(clip["path"])
	if not _textures.has(path):_textures[path]=load(path)
	var region:Array=clip["frames"][posmod(index,8)]["source_rect"]
	var result:=AtlasTexture.new();result.atlas=_textures[path]
	result.region=Rect2(region[0],region[1],region[2],region[3])
	_frames[key]=result;return result

static func sample_index(en:Dictionary,time:float) -> int:
	var id:String=identity(en);var clip:Dictionary=definition(id)
	if clip.is_empty():return 0
	var velocity:Vector2=en.get("vel",Vector2.ZERO)
	if id=="jump" and absf(velocity.y)>35:return 3 if velocity.y<0 else 4
	var moving:bool=velocity.length_squared()>9 or bool(clip.get("flying",false))
	return int(time*float(clip.get("fps",12)))%8 if moving else 0

static func draw(c:CanvasItem,en:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY,tint:Color=Color.WHITE) -> bool:
	var id:String=identity(en);var clip:Dictionary=definition(id)
	if clip.is_empty():return false
	var index:int=sample_index(en,time);var f:Dictionary=clip["frames"][index]
	var tex:Texture2D=texture_for(id,index)
	if tex==null:return false
	var factor:float=factor_for(en)
	var pivot:Vector2=Vector2(f["pivot"][0],f["pivot"][1])
	var bounds:Array=f["visible_bounds"];pivot=Vector2(float(bounds[0])+float(bounds[2])*.5,float(bounds[1])+float(bounds[3]))
	var at:Vector2=en["pos"]
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(float(en.get("face",1))*factor,factor),0,at))
	c.draw_texture(tex,-pivot,tint);c.draw_set_transform_matrix(base)
	return true
