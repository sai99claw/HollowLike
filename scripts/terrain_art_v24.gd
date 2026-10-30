class_name TerrainArtV24
extends RefCounted
const ROOT:String="res://assets/v24/terrain/"
const PIXELS_PER_WORLD:float=2.0
const PERIOD:float=256.0
static var manifest:Dictionary={}
static var textures:Dictionary={}
static func data(biome:String) -> Dictionary:
	if manifest.is_empty() and FileAccess.file_exists(ROOT+"terrain-manifest.json"):manifest=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"terrain-manifest.json"))
	return manifest.get("biomes",{}).get(biome,{})
static func texture(path:String) -> Texture2D:
	if not textures.has(path):
		if not ResourceLoader.exists(ROOT+path):return null
		textures[path]=load(ROOT+path)
	return textures[path]
static func platform(c:CanvasItem,biome:String,rect:Rect2) -> bool:
	var definition:Dictionary=data(biome).get("platforms",{}).get(str(clampi(roundi(rect.size.x/96),1,4)),{})
	if definition.is_empty():return false
	var image:Texture2D=texture(definition["path"])
	if image==null:return false
	var body:Array=definition["body_span"];var cap:float=48.0;var span:float=rect.size.x*PIXELS_PER_WORLD
	var sy:float=float(definition["surface_y"]);var height:float=image.get_height()
	# Keep caps, overhangs and vertical detail at two source pixels per world
	# pixel. The complete central strip fits continuously between those caps.
	var left:Rect2=Rect2(0,0,float(body[0])+cap,height)
	var right:Rect2=Rect2(float(body[1])-cap,0,image.get_width()-float(body[1])+cap,height)
	var origin:Vector2=rect.position-Vector2(float(body[0]),sy)/PIXELS_PER_WORLD
	c.draw_texture_rect_region(image,Rect2(origin,left.size/PIXELS_PER_WORLD),left)
	# Use the entire contiguous center between the authored caps. Cropping the
	# first N pixels then jumping to the right cap discarded roots/rocks and
	# exposed a hard vertical splice. A continuous center retains every feature.
	var center_width:float=maxf(1,float(body[1])-float(body[0])-cap*2)
	var sample:=Rect2(float(body[0])+cap,0,center_width,height)
	var destination:=Rect2(rect.position+Vector2(cap,-sy)/PIXELS_PER_WORLD,Vector2(maxf(0,span-cap*2),height)/PIXELS_PER_WORLD)
	if destination.size.x>0:c.draw_texture_rect_region(image,destination,sample)
	c.draw_texture_rect_region(image,Rect2(rect.position+Vector2(span-cap,-sy)/PIXELS_PER_WORLD,right.size/PIXELS_PER_WORLD),right)
	return true
static func middle(c:CanvasItem,biome:String,items:Array) -> bool:
	var choices:Array=data(biome).get("middle",[])
	if choices.is_empty():return false
	for item:Dictionary in items:
		var definition:Dictionary=choices[posmod(int(item["variant"]),choices.size())]
		var image:Texture2D=texture(definition["path"])
		if image==null:continue
		var scale_value:float=1/PIXELS_PER_WORLD
		var tint:=Color(.80,.85,.82,.82)
		c.draw_set_transform_matrix(Transform2D(0,Vector2(-scale_value if item.get("flip",false) else scale_value,scale_value),0,item["pos"]))
		var pivot:Array=definition.get("pivot_source",[image.get_width()*.5,image.get_height()]);c.draw_texture(image,-Vector2(pivot[0],pivot[1]),tint)
	c.draw_set_transform_matrix(Transform2D.IDENTITY);return true

static var corners:Dictionary={}
static func draw_corners(c:CanvasItem,biome:String,layout:Dictionary) -> void:
	if corners.is_empty():corners=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"corner-manifest.json"))
	for corner:Dictionary in layout.get("art_corners_v21",[]):
		var definition:Dictionary=corners.get("biomes",{}).get(biome,{}).get("concave" if corner["inner"] else "convex",{})
		if definition.is_empty():continue
		var image:Texture2D=texture(definition["path"])
		if image==null:continue
		var anchor:Array=definition["anchor_source"];var pivot:=Vector2(anchor[0],anchor[1])
		c.draw_set_transform_matrix(Transform2D(float(corner["angle"])-PI,corner["pos"]))
		c.draw_mesh(corner_mesh(str(definition["path"]),pivot,image.get_size()),image)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

static var corner_meshes:Dictionary={}
static func corner_mesh(key:String,pivot:Vector2,image_size:Vector2) -> ArrayMesh:
	if corner_meshes.has(key):return corner_meshes[key]
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	# Same64quads, UVs and feathered vertex alpha, submitted in one command.
	for y in range(-48,48,12):
		for x in range(-48,48,12):
			var first:int=vertices.size()
			for point:Vector2 in [Vector2(x,y),Vector2(x+12,y),Vector2(x+12,y+12),Vector2(x,y+12)]:
				vertices.append(Vector3(point.x,point.y,0));uv.append((pivot+point*PIXELS_PER_WORLD)/image_size)
				var fade:float=clampf((48-maxf(absf(point.x),absf(point.y)))/18,0,1);colors.append(Color(1,1,1,fade*.85))
			indices.append_array(PackedInt32Array([first,first+1,first+2,first,first+2,first+3]))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);corner_meshes[key]=mesh;return mesh
