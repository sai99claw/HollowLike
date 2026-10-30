class_name SpringV33
extends RefCounted
const ROOT:String="res://assets/v33/springs/"
static var textures:Dictionary={}
static var metadata:Dictionary={}
static func info(biome:String) -> Dictionary:
	if not metadata.has(biome):metadata[biome]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+biome+".json"))
	return metadata[biome]
static func texture(biome:String) -> Texture2D:
	if not textures.has(biome):textures[biome]=load(ROOT+biome+".png")
	return textures[biome]
static func body(at:Vector2) -> Rect2:return Rect2(at-Vector2(120,95),Vector2(240,95))
static func scale_for(biome:String) -> float:return 240.0/float(info(biome)["body_bounds"][2])
static func pool(at:Vector2,biome:String) -> Rect2:
	var d:Dictionary=info(biome);var pivot:Array=d["pivot_source"];var rect:Array=d["water_rect_source"];var factor:float=scale_for(biome)
	var surface:float=at.y+10+(float(d["water_surface_source"][1])-float(pivot[1]))*factor
	return Rect2(at.x+(float(rect[0])-float(pivot[0]))*factor,surface,float(rect[2])*factor,at.y+5-surface)
static func draw_water(c:CanvasItem,at:Vector2,biome:String,base:Transform2D,bath:Variant,time:float) -> void:
	var wet:Rect2=pool(at,biome)
	c.draw_set_transform_matrix(base)
	var shimmer:=PackedVector2Array()
	for i in 48:
		var angle:float=TAU*float(i)/48;shimmer.append(wet.position+Vector2(wet.size.x*.5,3)+Vector2(cos(angle)*wet.size.x*.46,sin(angle)*3))
	c.draw_colored_polygon(shimmer,Color(.72,.94,1,.16))
	bath.draw(c,wet,base,time,true)
	var d:Dictionary=info(biome);var image:Texture2D=texture(biome);var factor:float=scale_for(biome);var pivot:Array=d["pivot_source"];var original:Array=d["original_size"]
	var cut:float=float(d["water_rect_source"][1])+float(d["water_rect_source"][3])*.82
	var source:=Rect2(0,cut,float(original[0]),float(original[1])-cut)
	var ratio:Vector2=image.get_size()/Vector2(original[0],original[1])
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(image,Rect2(at+Vector2(0,10)+(source.position-Vector2(pivot[0],pivot[1]))*factor,source.size*factor),Rect2(source.position*ratio,source.size*ratio))
static func water_at(at:Vector2,biome:String) -> Vector2:
	return Vector2(at.x,pool(at,biome).position.y)
static func draw(c:CanvasItem,at:Vector2,biome:String,base:Transform2D) -> void:
	var d:Dictionary=info(biome);var image:Texture2D=texture(biome)
	var original:Array=d["original_size"];var pivot:Array=d["pivot_source"]
	var size:=Vector2(original[0],original[1]);var factor:float=scale_for(biome)
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(image,Rect2(at-Vector2(pivot[0],pivot[1])*factor,size*factor),false)
static func prepare(layout:Dictionary) -> void:
	var candidates:Array[Vector2]=[];var reserved:Array=layout.get("reserved_regions",[])
	for platform:Rect2 in layout["platforms"]:
		if platform.size.x<288:continue
		var at:=Vector2(platform.get_center().x,platform.position.y)
		if reserved.any(func(r:Rect2)->bool:return r.grow(100).has_point(at)):continue
		if layout["solids"].any(func(r:Rect2)->bool:return r.intersects(body(at).grow(-1))):continue
		candidates.append(at)
	if candidates.is_empty():
		# The generator reserves a clear lower perimeter lane in every combat room.
		candidates.append(layout["spawn_positions"]["center"]+Vector2(160,0))
	var rng:=RandomNumberGenerator.new();rng.seed=int(layout["seed"])+33013
	var chosen:Vector2=candidates[rng.randi_range(0,candidates.size()-1)]
	layout["fountain_pos"]=chosen
	layout["reserved_regions"].append(Rect2(chosen-Vector2(120,120),Vector2(240,150)))
	layout["enemy_spawns"]=layout["enemy_spawns"].filter(func(at:Vector2)->bool:return at.distance_to(chosen)>160)
