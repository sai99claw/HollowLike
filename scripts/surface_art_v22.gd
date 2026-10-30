class_name SurfaceArtV22
extends RefCounted
const Atlas=preload("res://scripts/atlas_v22.gd")
const TILE:float=96
const BASE_COLORS:Dictionary={"sky":Color("4e7185"),"trunk":Color("354331"),"underground":Color("69503a")}
static func definition(biome:String) -> Dictionary:
	return Atlas.metadata("surfaces").get("biomes",{}).get(biome,{})
static func material(biome:String) -> Texture2D:
	var data:Dictionary=definition(biome)
	return Atlas.texture(data["path"],data["material"]["source_rect"]) if not data.is_empty() else null
static func platform_parts(rect:Rect2) -> Array[Rect2]:
	# Collision generation emits exactly1/2/3/4cell modules. Legacy long
	# supports are decomposed into the same four fixed modules, never stretched.
	var parts:Array[Rect2]=[];var cursor:float=rect.position.x;var remaining:int=roundi(rect.size.x/TILE)
	while remaining>0:
		var count:int=mini(4,remaining);parts.append(Rect2(cursor,rect.position.y,count*TILE,rect.size.y));cursor+=count*TILE;remaining-=count
	return parts
static func draw_platform(c:CanvasItem,biome:String,rect:Rect2) -> void:
	for part:Rect2 in platform_parts(rect):
		preload("res://scripts/platform_art_v23.gd").draw(c,biome,part)
