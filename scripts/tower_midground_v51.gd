class_name TowerMidgroundV51
extends RefCounted

const BIOMES=["underground","trunk","sky"]
const VARIANT_COUNT=5
const GUTTER=4
static var textures:Dictionary={}

static func plan(biome:String,seed_value:int,background:Rect2) -> Array[Dictionary]:
	var family:String=biome if biome in BIOMES else "trunk"
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value+51971
	var variants:Array[int]=[]
	variants.assign(range(VARIANT_COUNT))
	var result:Array[Dictionary]=[]
	var count:int=rng.randi_range(2,3)
	for i in count:
		var choice:int=rng.randi_range(0,variants.size()-1)
		var variant:int=variants.pop_at(choice)
		var texture:Texture2D=_texture(family,variant)
		var visible_size:Vector2=texture.get_size()-Vector2.ONE*GUTTER*2
		var factor:float=minf(background.size.y*rng.randf_range(.55,2.0/3.0)/visible_size.y,background.size.x/visible_size.x)
		var width:float=visible_size.x*factor
		var center:float=background.position.x+background.size.x*(i+.5+rng.randf_range(-.24,.24))/count
		center=clampf(center,background.position.x+width*.5,background.end.x-width*.5)
		var size:Vector2=visible_size*factor
		var bounds:=Rect2(Vector2(center-size.x*.5,background.end.y-size.y),size)
		result.append({"texture":texture,"bounds":bounds,"draw_rect":bounds.grow(GUTTER*factor),"variant":variant,"flip":rng.randf()<.5})
	return result

static func draw(canvas:CanvasItem,items:Array[Dictionary]) -> void:
	for item in items:
		var texture:Texture2D=item["texture"]
		var bounds:Rect2=item["draw_rect"]
		if item["flip"]:bounds.size.x=-bounds.size.x
		canvas.draw_texture_rect(texture,bounds,false,Color(1,1,1,.64))

static func _texture(biome:String,variant:int) -> Texture2D:
	var key:String="%s-%d"%[biome,variant]
	if not textures.has(key):textures[key]=load("res://assets/v51/midground/"+key+".webp")
	return textures[key]
