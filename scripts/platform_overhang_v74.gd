extends RefCounted
const EdgeSource=preload("res://scripts/biome_art_v21.gd")
const ART:Dictionary={
	"trunk":[preload("res://assets/v76/near-thorns.webp"),preload("res://assets/v76/near-stone.webp"),preload("res://assets/v76/near-roots.webp"),preload("res://assets/v76/near-vine.webp")],
	"underground":[preload("res://assets/v77/underground-near-thorns.webp"),preload("res://assets/v77/underground-near-stone.webp"),preload("res://assets/v77/underground-near-roots.webp"),preload("res://assets/v77/underground-near-vine.webp")],
	"sky":[preload("res://assets/v77/sky-near-thorns.webp"),preload("res://assets/v77/sky-near-stone.webp"),preload("res://assets/v77/sky-near-roots.webp"),preload("res://assets/v77/sky-near-vine.webp")],
}

static func shade_fallback(canvas:CanvasItem,blocks:Array,visible:Rect2) -> void:
	for r:Rect2 in blocks:
		if r.size.y>20 and (not visible.has_area() or visible.intersects(r)):
			canvas.draw_rect(Rect2(r.position+Vector2(0,20),r.size-Vector2(0,20)),Color("16111c",.65))

static func plan(layout:Dictionary,solids:Array,biome:String="trunk") -> Array[Dictionary]:
	var art:Array=ART.get(biome,ART["trunk"])
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
			var rect:Rect2=attached_rect(at,Vector2(extent,extent),span,top)
			result.append({"at":at,"rect":rect,"art":art[1] if top else art[2],"sway":false,"top":top,"span":span,"grass":false})
		var x:float=span.x+random.randf_range(18,37)
		while x<span.y-13:
			var at:=Vector2(x,edge["at"])
			if _allowed(at,reserved):
				var extent:float=random.randf_range(5,14) if top else random.randf_range(25,60)
				var span_with_margin:Vector2=span+Vector2(8,-8) if top and span.y-span.x>20 else span
				var rect:Rect2=attached_rect(at,Vector2(extent*1.24,extent+5.0 if top else extent),span_with_margin,top)
				result.append({"at":at,"rect":rect,"art":art[0] if top else art[2+posmod(floori(x/70),2)],"sway":not top,"top":top,"span":span,"grass":top})
			x+=random.randf_range(40,90)
	return result

static func attached_rect(at:Vector2,extent:Vector2,span:Vector2,top:bool) -> Rect2:
	extent.x=minf(extent.x,span.y-span.x)
	var x:float=clampf(at.x-extent.x*.5,span.x,span.y-extent.x)
	return Rect2(Vector2(x,at.y-extent.y+5.0 if top else at.y-5.0),extent)

static func near_plan(shapes:Array[Dictionary]) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for index in shapes.size():
		if index%4!=0 or shapes[index].get("grass",false):continue
		var shape:Dictionary=shapes[index]
		var at:Vector2=shape["at"]
		if result.any(func(item:Dictionary)->bool:return at.distance_squared_to(item["at"])<76.0*76.0):continue
		var texture:Texture2D=shape["art"]
		var limit:=Vector2(46,41)
		var extent:Vector2=texture.get_size()
		extent*=minf(limit.x/extent.x,limit.y/extent.y)
		var rect:Rect2=attached_rect(at,extent,shape["span"],shape["top"])
		result.append({"at":at,"local":Rect2(rect.position-at,rect.size),"art":texture})
	return result

static func _allowed(at:Vector2,reserved:Array) -> bool:
	return not reserved.any(func(r:Rect2)->bool:return r.grow(12).has_point(at))

static func draw(canvas:CanvasItem,shapes:Array,visible:Rect2) -> void:
	var active:=visible.grow(66)
	for shape:Dictionary in shapes:
		var at:Vector2=shape["at"]
		if visible.has_area() and not active.has_point(at):continue
		canvas.draw_texture_rect(shape["art"],shape["rect"],false,Color(1,1,1,.65 if shape["grass"] else .1))
