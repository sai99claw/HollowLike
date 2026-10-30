class_name SceneArtV33
extends RefCounted
static var textures:Dictionary={}
static var metadata:Dictionary={}
static var regions:Dictionary={}
static func texture(path:String) -> Texture2D:
	if not textures.has(path):
		if not ResourceLoader.exists(path):return null
		textures[path]=load(path)
	return textures[path]
static func info(path:String) -> Dictionary:
	if not metadata.has(path):
		if not FileAccess.file_exists(path):return {}
		metadata[path]=JSON.parse_string(FileAccess.get_file_as_string(path))
	return metadata[path]
static func frame(path:String,id:String) -> Dictionary:
	for f:Dictionary in info(path).get("frames",[]):
		if f["id"]==id:return f
	return {}
static func region(path:String,id:String) -> Texture2D:
	var key:String=path+":"+id
	if regions.has(key):return regions[key]
	var d:Dictionary=info(path);var f:Dictionary=frame(path,id)
	if f.is_empty():return null
	var image:Texture2D=texture(path.replace(".json",".png"));var original:Array=d["original_size"]
	var ratio:Vector2=image.get_size()/Vector2(original[0],original[1]);var r:Array=f["rect"]
	var tex:=AtlasTexture.new();tex.atlas=image;tex.region=Rect2(Vector2(r[0],r[1])*ratio,Vector2(r[2],r[3])*ratio);tex.filter_clip=true
	regions[key]=tex;return tex
static func prop(c:CanvasItem,path:String,id:String,at:Vector2,limit:Vector2,base:Transform2D=Transform2D.IDENTITY) -> void:
	var f:Dictionary=frame(path,id);var image:Texture2D=region(path,id)
	if image==null:return
	var bounds:Array=f["bounds"];var pivot:Array=f["pivot"];var rect:Array=f["rect"]
	var factor:float=minf(limit.x/maxf(1,float(bounds[2])),limit.y/maxf(1,float(bounds[3])))
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(image,Rect2(at-Vector2(pivot[0],pivot[1])*factor,Vector2(rect[2],rect[3])*factor),false)
static func cover(c:CanvasItem,path:String,target:Rect2) -> void:
	var image:Texture2D=texture(path)
	if image==null:return
	var factor:float=maxf(target.size.x/image.get_width(),target.size.y/image.get_height());var size:Vector2=image.get_size()*factor
	c.draw_texture_rect(image,Rect2(target.get_center()-size*.5,size),false)
static func station(c:CanvasItem,biome:String,id:String,at:Vector2,base:Transform2D) -> void:
	prop(c,"res://assets/v33/safehouses/"+biome+"-stations.json",id,at,Vector2(144,116),base)

static func safehouse_rect(biome:String,size:Vector2,floor_y:float) -> Rect2:
	var path:String="res://assets/v33/safehouses/"+biome+"-background.json"
	var d:Dictionary=info(path);var original:Array=d.get("original_size",[1536,1024]);var source_floor:float=float(d.get("floor_y_source",700))
	# Align the painting's contact plane to the collision floor. A centered
	# cover placed the rear floor hundreds of pixels above actors' feet.
	var factor:float=maxf(size.x/float(original[0]),floor_y/source_floor)
	var extent:=Vector2(original[0],original[1])*factor
	return Rect2(Vector2((size.x-extent.x)*.5,floor_y-source_floor*factor),extent)
static func safehouse(c:CanvasItem,biome:String,size:Vector2,floor_y:float) -> void:
	var image:Texture2D=texture("res://assets/v33/safehouses/"+biome+"-background.png")
	if image!=null:c.draw_texture_rect(image,safehouse_rect(biome,size,floor_y),false,Color(.76,.81,.78,1))
