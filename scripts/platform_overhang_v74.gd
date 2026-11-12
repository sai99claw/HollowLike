extends RefCounted
const EdgeSource=preload("res://scripts/biome_art_v21.gd")
const ROCK=preload("res://assets/v76/near-stone.webp")
const ROOT=preload("res://assets/v76/near-roots.webp")
const THORNS=preload("res://assets/v76/near-thorns.webp")

static func shade_fallback(canvas:CanvasItem,blocks:Array,visible:Rect2) -> void:
	for r:Rect2 in blocks:
		if r.size.y>20 and (not visible.has_area() or visible.intersects(r)):
			canvas.draw_rect(Rect2(r.position+Vector2(0,20),r.size-Vector2(0,20)),Color("16111c",.65))

static func plan(layout:Dictionary,solids:Array) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var random:=RandomNumberGenerator.new()
	random.seed=int(layout.get("seed",0))+7419
	var platform:Array=layout.get("one_way",[])
	var geometry:Array=solids+platform
	var edges:Array=layout.get("art_edges_v21",[])
	if edges.is_empty():edges=EdgeSource.edges(solids)
	edges=edges+EdgeSource.edges(platform)
	var reserved:Array=layout.get("reserved_regions",[])
	var corners:Dictionary={}
	for edge:Dictionary in edges:
		var side:String=edge["side"]
		if side not in ["top","bottom"]:continue
		var top:bool=side=="top"
		var span:Vector2=edge["span"]
		for facing:int in [-1,1]:
			var at:=Vector2(span.x if facing<0 else span.y,edge["at"])
			if corners.has(at) or not _allowed(at,reserved):continue
			var y:float=1.0 if top else -1.0
			if geometry.any(func(r:Rect2)->bool:return r.has_point(at+Vector2(facing*3,y*3))):continue
			corners[at]=true
			var extent:float=random.randf_range(23,43)
			var rect:=Rect2(at-Vector2(extent*.5,extent*(.65 if top else .25)),Vector2(extent,extent))
			result.append({"at":at,"rect":rect,"art":ROCK if top else ROOT,"sway":false})
		var x:float=span.x+random.randf_range(18,37)
		while x<span.y-13:
			var at:=Vector2(x,edge["at"])
			if _allowed(at,reserved):
				var extent:float=random.randf_range(5,14) if top else random.randf_range(25,60)
				at.y+=random.randf_range(-3,2) if top else 0.0
				var rect:=Rect2(at-Vector2(extent*.62,extent if top else 0.0),Vector2(extent*1.24,extent))
				result.append({"at":at,"rect":rect,"art":THORNS if top else ROOT,"sway":not top})
			x+=random.randf_range(40,90)
	return result

static func _allowed(at:Vector2,reserved:Array) -> bool:
	return not reserved.any(func(r:Rect2)->bool:return r.grow(12).has_point(at))

static func draw(canvas:CanvasItem,shapes:Array,visible:Rect2) -> void:
	var active:=visible.grow(66)
	for shape:Dictionary in shapes:
		var at:Vector2=shape["at"]
		if visible.has_area() and not active.has_point(at):continue
		canvas.draw_texture_rect(shape["art"],shape["rect"],false,Color(1,1,1,1.0 if shape["sway"] else .1))
