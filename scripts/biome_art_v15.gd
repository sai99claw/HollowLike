class_name BiomeArtV15
extends RefCounted
## v0.15: three painted ecologies, lazy atlas slices, fixed feet-anchored cut frames.
## Rendering only: RoomLayout and the prop hit handler retain collision ownership.

const NewArt=preload("res://scripts/biome_art_v21.gd")
const ROOT:String="res://assets/ecology_v15/"
const BIOMES:Array[String]=["sky","trunk","underground"]
const CUT_DURATION:float=.6
const OBJECT_COLUMNS:int=5
const OBJECT_ROWS:int=6
const TILE:float=preload("res://scripts/world_scale_v17.gd").TILE
const OBJECT_IDS:Dictionary={
	"sky":["blue_wind_grass","downy_cloud_flower","cyan_crystal_reeds","azure_feather_thistle","blue_sky_urn","floating_pumice"],
	"trunk":["emerald_fern","jade_sapling","bark_shelf_fungi","moss_seed_pod","curled_vine_shoot","acorn_lantern"],
	"underground":["amber_crystal_cluster","ivory_cave_mushroom","curled_root_tuft","terracotta_urn","glowing_root_bulb","shale_cairn"]
}
const OBJECT_NAMES:Dictionary={
	"sky":["藍風草","白絨雲花","青晶蘆","藍羽薊","藍釉天甕","浮空浮石"],
	"trunk":["翡翠蕨","三葉幼苗","樹皮層菇","苔種莢","捲藤芽","橡果燈"],
	"underground":["琥珀晶簇","象牙洞菇","捲根叢","赤陶甕","發光根球","頁岩石堆"]
}
## All five frames share this target canvas. In particular, flying shards never
## change the intact object's scale or move its anchor below the support surface.
const OBJECT_SIZES:Array[Vector2]=[Vector2(72,82),Vector2(70,82),Vector2(70,88),Vector2(76,82),Vector2(72,88),Vector2(76,82)]
static var _textures:Dictionary={}
static var _regions:Dictionary={}

static func texture(biome:String,role:String) -> Texture2D:
	if biome not in BIOMES and (biome!="merchant" or role not in ["far","mid"]):return null
	if role not in ["far","mid","near","terrain","objects"]:return null
	var key:String=biome+"_"+role
	if _textures.has(key):return _textures[key]
	var path:String=ROOT+key+".png"
	if not ResourceLoader.exists(path):return null
	var result:Texture2D=load(path) as Texture2D
	if result!=null:_textures[key]=result
	return result

static func region(biome:String,role:String,column:int,row:int) -> Texture2D:
	var columns:int=OBJECT_COLUMNS if role=="objects" else 2
	var rows:int=OBJECT_ROWS if role=="objects" else 2
	if role not in ["objects","terrain"] or column<0 or column>=columns or row<0 or row>=rows:return null
	var key:String="%s_%s_%d_%d"%[biome,role,column,row]
	if _regions.has(key):return _regions[key]
	var sheet:Texture2D=texture(biome,role)
	if sheet==null:return null
	var cell:Vector2=sheet.get_size()/Vector2(columns,rows)
	var result:=AtlasTexture.new()
	result.atlas=sheet;result.region=Rect2(Vector2(column,row)*cell,cell);result.filter_clip=true
	_regions[key]=result
	return result

static func layer(canvas:CanvasItem,biome:String,depth:String,rect:Rect2,base:Transform2D=Transform2D.IDENTITY,tint:Color=Color.WHITE) -> bool:
	if depth not in ["far","mid","near"] or rect.size.x<=0 or rect.size.y<=0:return false
	var image:Texture2D=texture(biome,depth)
	if image==null:return false
	canvas.draw_set_transform_matrix(base)
	canvas.draw_texture_rect(image,rect,false,tint)
	return true

static func _tile(canvas:CanvasItem,image:Texture2D,rect:Rect2,period:Vector2=Vector2(TILE,TILE)) -> void:
	if rect.size.x<=0 or rect.size.y<=0:return
	var y:float=rect.position.y
	while y<rect.end.y-.01:
		var height:float=minf(period.y,rect.end.y-y)
		var x:float=rect.position.x
		while x<rect.end.x-.01:
			var width:float=minf(period.x,rect.end.x-x)
			# Clip the final tile instead of stretching its texture into a seam.
			var source:=Rect2(Vector2.ZERO,image.get_size()*Vector2(width/period.x,height/period.y))
			canvas.draw_texture_rect_region(image,Rect2(x,y,width,height),source)
			x+=period.x
		y+=period.y

static func terrain(canvas:CanvasItem,biome:String,rect:Rect2,one_way:bool=false,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if rect.size.x<=0 or rect.size.y<=0:return false
	var fill:Texture2D=region(biome,"terrain",0,0)
	var cap:Texture2D=region(biome,"terrain",1,0)
	var platform:Texture2D=region(biome,"terrain",0,1)
	var block:Texture2D=region(biome,"terrain",1,1)
	if fill==null or cap==null or platform==null or block==null:return false
	canvas.draw_set_transform_matrix(base)
	if one_way:
		# Authored platform sits at the middle of a transparent atlas cell.
		# Keep its cell height, so thin platforms do not squash away their bark.
		var y:float=rect.position.y-TILE*.42
		_tile(canvas,platform,Rect2(rect.position.x,y,rect.size.x,TILE))
	elif rect.size.x<=TILE*1.5 and rect.size.y<=TILE*1.5:
		canvas.draw_texture_rect(block,rect,false)
	else:
		_tile(canvas,fill,rect)
		# Cap atlas has an organic upper 18%; the rest is the same solid fill.
		# A cropped tile therefore preserves authored texture scale on thick walls.
		var top_height:float=minf(rect.size.y,TILE*.24)
		_tile(canvas,cap,Rect2(rect.position,Vector2(rect.size.x,top_height)))
	return true

static func object_index(variant:Variant) -> int:
	if variant is int or variant is float:return posmod(int(variant),OBJECT_ROWS)
	var id:String=str(variant)
	for biome:String in BIOMES:
		var index:int=OBJECT_IDS[biome].find(id)
		if index>=0:return index
		index=OBJECT_NAMES[biome].find(id)
		if index>=0:return index
	return 0

static func object_size(variant:Variant) -> Vector2:
	return OBJECT_SIZES[object_index(variant)]

static func object_id(biome:String,variant:Variant) -> String:
	if biome not in BIOMES:return ""
	return str(OBJECT_IDS[biome][object_index(variant)])

static func object_name(biome:String,variant:Variant) -> String:
	if biome not in BIOMES:return ""
	return str(OBJECT_NAMES[biome][object_index(variant)])

static func cut_frame(prop:Dictionary) -> int:
	if not bool(prop.get("used",false)):return 0
	var progress:float=clampf(1.0-float(prop.get("break_left",0.0))/CUT_DURATION,0.0,.99999)
	return 1+mini(3,int(progress*4.0))

static func prop(canvas:CanvasItem,object:Dictionary,biome:String,_time:float,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if bool(object.get("used",false)) and float(object.get("break_left",0.0))<=0:return false
	if object.get("art_set","v21")!="v15" and NewArt.prop(canvas,object,biome,base):return true
	var variant:Variant=object.get("variant",object.get("object_index",object.get("object_id",0)))
	var row:int=object_index(variant)
	var image:Texture2D=region(biome,"objects",cut_frame(object),row)
	if image==null:return false
	var at:Vector2=object.get("pos",Vector2.ZERO)
	var extent:Vector2=object_size(row)
	canvas.draw_set_transform_matrix(base)
	var feet:Dictionary={"underground":[1.0,.9713,.9330,1.0,1.0,.8565],"trunk":[.9426,.9378,.9378,1.0,.9426,.9330],"sky":[.9426,.9617,.9474,.9522,.9234,.9330]}
	var anchor:float=float(feet.get(biome,feet["trunk"])[row])
	canvas.draw_texture_rect(image,Rect2(at-Vector2(extent.x*.5,extent.y*anchor),extent),false)
	return true
