class_name AdventureArtV29
extends RefCounted
static var images:Dictionary={}
static var metadata:Dictionary={}
static var halo:GradientTexture2D
static var feather_atlas:AtlasTexture
static func image(path:String) -> Texture2D:
	if not images.has(path):images[path]=load(path)
	return images[path]
static func info(path:String) -> Dictionary:
	if not metadata.has(path):metadata[path]=JSON.parse_string(FileAccess.get_file_as_string(path))
	return metadata[path]
static func _rect(values:Array) -> Rect2:return Rect2(values[0],values[1],values[2],values[3])
static func _size(values:Array) -> Vector2:return Vector2(values[0],values[1])
static func station(c:CanvasItem,kind:String,at:Vector2,base:Transform2D) -> void:
	var file:String="free-weapon-pedestal" if kind=="gift_pedestal" else "cloak-wardrobe"
	var root:String="res://assets/v29/stations/"+file
	var data:Dictionary=info(root+".json");var tex:Texture2D=image(root+".png")
	if tex==null:return
	var source:Rect2=_rect(data["source_rect"]);var pivot:Vector2=_size(data["pivot"])
	var ratio:Vector2=tex.get_size()/_size(data["original_size"])
	var factor:float=112.0/source.size.x
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(tex,Rect2(at+(source.position-pivot)*factor,source.size*factor),Rect2(source.position*ratio,source.size*ratio))
static func halo_texture() -> GradientTexture2D:
	if halo==null:
		halo=GradientTexture2D.new();halo.width=96;halo.height=96;halo.fill=GradientTexture2D.FILL_RADIAL;halo.fill_from=Vector2(.5,.5);halo.fill_to=Vector2(1,.5)
		var gradient:=Gradient.new();gradient.offsets=PackedFloat32Array([0,.27,.55,1]);gradient.colors=PackedColorArray([Color(1,1,1,.58),Color(1,1,1,.23),Color(1,1,1,.10),Color(1,1,1,0)]);halo.gradient=gradient
	return halo
static func rune_halo(c:CanvasItem,at:Vector2,time:float,base:Transform2D) -> void:
	var radius:float=39+sin(time*1.8)*3
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(halo_texture(),Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
static func feather_texture() -> AtlasTexture:
	if feather_atlas!=null:return feather_atlas
	var path:String="res://assets/v29/effects/refined-feather"
	var tex:Texture2D=image(path+".png");var data:Dictionary=info(path+".json")
	var ratio:Vector2=tex.get_size()/_size(data["original_size"])
	var source:Rect2=_rect(data["source_rect"])
	var atlas:=AtlasTexture.new();atlas.atlas=tex;atlas.region=Rect2(source.position*ratio,source.size*ratio)
	feather_atlas=atlas;return atlas
static func death_feather(c:CanvasItem,at:Vector2,time:float,base:Transform2D) -> void:
	var tex:Texture2D=feather_texture();var size:Vector2=tex.get_size();size*=104.0/maxf(size.x,size.y)
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(halo_texture(),Rect2(at-Vector2(63,57),Vector2(126,114)),false,Color(1,1,1,.7))
	c.draw_set_transform_matrix(base*Transform2D(sin(time*.55)*.12,at))
	c.draw_texture_rect(tex,Rect2(-size*.5,size),false,Color(1,1,1,.95))
	c.draw_set_transform_matrix(base)
static func jump_gust(c:CanvasItem,at:Vector2,elapsed:float,base:Transform2D) -> void:
	var path:String="res://assets/v30/effects/wing-puff"
	var tex:Texture2D=image(path+".png");var data:Dictionary=info(path+".json")
	if tex==null:return
	var frames:Array=data["frames"];var frame:Dictionary=frames[clampi(int(elapsed/.20*frames.size()),0,frames.size()-1)]
	var source:Rect2=_rect(frame["source_rect"]);var ratio:Vector2=tex.get_size()/_size(data["original_size"])
	var scale:float=float(data.get("suggested_scale",.08))
	var pivot:Vector2=_size(frame["pivot"])
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(tex,Rect2(at-pivot*scale+Vector2(0,-10+elapsed*12),source.size*scale),Rect2(source.position*ratio,source.size*ratio),Color(1,1,1,clampf((.20-elapsed)/.065,0,1)*.72))
