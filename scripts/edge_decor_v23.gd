class_name EdgeDecorV23
extends RefCounted
const Atlas=preload("res://scripts/atlas_v23.gd")
# Retained CanvasItem commands reference texture RIDs without keeping the
# Texture2D alive. Own the finite set of eighteen edge textures across frames
# and room changes; a temporary load() inside draw() leaves white silhouettes.
static var _textures:Dictionary={}
static func texture(path:String) -> Texture2D:
	var absolute:String="res://assets/v24/edges/"+path
	if _textures.has(absolute):return _textures[absolute]
	if not ResourceLoader.exists(absolute):return null
	var image:Texture2D=load(absolute) as Texture2D
	if image!=null:_textures[absolute]=image
	return image
const OUTWARD:Dictionary={"top":Vector2.UP,"bottom":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}
const ART_NORMAL:Dictionary={"top":Vector2.DOWN,"bottom":Vector2.UP,"left":Vector2.RIGHT,"right":Vector2.LEFT}
static func pieces(biome:String) -> Array:
	return Atlas.metadata("edge-decor").get("biomes",{}).get(biome,[])
static func plan(edges:Array,solids:Array,reserved:Array,seed_value:int) -> Array[Dictionary]:
	var random:=RandomNumberGenerator.new();random.seed=seed_value+23095;var result:Array[Dictionary]=[]
	for edge:Dictionary in edges:
		var span:Vector2=edge["span"];var side:String=edge["side"];var cursor:float=span.x+random.randf_range(20,55)
		while cursor<span.y-18 and result.size()<260:
			var at:=Vector2(cursor,edge["at"]) if side in ["top","bottom"] else Vector2(edge["at"],cursor)
			var roll:float=random.randf();var size_class:String="large" if roll<.20 else "medium" if roll<.55 else "small"
			# Large foreground pieces need air around them. In tight corridors,
			# retain tiny detail instead of hiding a landing surface or a doorway.
			var depth:float=100 if size_class=="large" else 52 if size_class=="medium" else 25
			var probe:=Rect2(at+OUTWARD[side]*depth-Vector2.ONE*8,Vector2.ONE*16)
			if solids.any(func(rock:Rect2)->bool:return rock.intersects(probe)):size_class="small"
			if not reserved.any(func(zone:Rect2)->bool:return zone.grow(60).has_point(at)):
				result.append({"pos":at,"side":side,"size_class":size_class,"variant":random.randi_range(0,100000)})
			cursor+=random.randf_range(100,165) if size_class!="large" else random.randf_range(180,240)
	return result
static func draw(c:CanvasItem,biome:String,layout:Dictionary,layer:int=1) -> void:
	var library:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v24/edges/manifest.json")).get("biomes",{}).get(biome,[])
	for item:Dictionary in layout.get("edge_details_v23",[]):
		var choices:Array=library.filter(func(piece:Dictionary)->bool:return piece["size_class"]==item["size_class"])
		if choices.is_empty():choices=library
		if choices.is_empty():continue
		var intended:String={"top":"bottom","bottom":"top","left":"right","right":"left"}[item["side"]]
		var aligned:Array=choices.filter(func(piece:Dictionary)->bool:return piece["attach"]==intended)
		if not aligned.is_empty():choices=aligned
		var piece:Dictionary=choices[posmod(int(item["variant"]),choices.size())];var factor:float=.5
		var intended_layer:int=-1 if float(piece["world_height"])>42 else 1
		if layer!=intended_layer:continue
		var pivot:Array=piece["pivot"];var angle:float=Vector2(OUTWARD[item["side"]]).angle()-Vector2(ART_NORMAL[piece["attach"]]).angle()
		var image:Texture2D=texture(str(piece["path"]))
		if image==null:continue
		c.draw_set_transform_matrix(Transform2D(angle,Vector2.ONE*factor,0,Vector2(item["pos"])-OUTWARD[item["side"]]*10))
		c.draw_texture(image,-Vector2(pivot[0],pivot[1]),Color(.74,.80,.75,1) if layer<0 else Color(.52,.61,.58,1))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
