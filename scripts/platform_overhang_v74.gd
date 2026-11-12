extends RefCounted
const EdgeSource=preload("res://scripts/biome_art_v21.gd")
const ROOT:=Color("211626")
const MOSS:=Color("39402f")

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
			var tip:float=random.randf_range(15,35)*facing
			var points:=PackedVector2Array([Vector2(-11*facing,0),Vector2(4*facing,-10*y),Vector2(tip,-2*y),Vector2(tip*.69,11*y),Vector2(1,19*y),Vector2(-8*facing,9*y)])
			result.append({"at":at,"points":points,"color":ROOT.lerp(MOSS,.25 if top else 0.0),"sway":false})
		var x:float=span.x+random.randf_range(18,37)
		while x<span.y-13:
			var at:=Vector2(x,edge["at"])
			if _allowed(at,reserved):
				var extent:float=random.randf_range(5,14) if top else random.randf_range(25,60)
				var lean:float=random.randf_range(-10,10)
				at.y+=random.randf_range(-3,2) if top else 0.0
				var points:=PackedVector2Array([Vector2(-12,2),Vector2(-6,-4),Vector2(lean,-extent),Vector2(lean+6,-extent*.38),Vector2(12,2)]) if top else PackedVector2Array([Vector2(-8,-5),Vector2(8,-4),Vector2(lean+5,extent*.45),Vector2(lean,extent),Vector2(lean-3,extent*.57),Vector2(-5,extent*.27)])
				result.append({"at":at,"points":points,"color":MOSS if top else ROOT,"sway":not top})
				if top and random.randf()<.26:
					result.append({"at":at+Vector2(3,-3),"points":PackedVector2Array([Vector2(-6,0),Vector2(-3,-4),Vector2(2,-6),Vector2(6,-1),Vector2(1,1)]),"color":Color("d6a05b"),"sway":false})
			x+=random.randf_range(40,90)
	return result

static func _allowed(at:Vector2,reserved:Array) -> bool:
	return not reserved.any(func(r:Rect2)->bool:return r.grow(12).has_point(at))

static func draw(canvas:CanvasItem,shapes:Array,visible:Rect2) -> void:
	var active:=visible.grow(66)
	for shape:Dictionary in shapes:
		var at:Vector2=shape["at"]
		if visible.has_area() and not active.has_point(at):continue
		var points:PackedVector2Array=shape["points"].duplicate()
		if Geometry2D.triangulate_polygon(points).is_empty():
			points=Geometry2D.convex_hull(points)
			points.resize(points.size()-1)
		var colors:=PackedColorArray()
		for i in points.size():
			colors.append(Color(shape["color"],clampf(points[i].y/55.0,0.0,1.0) if shape["sway"] else 0.0))
			points[i]+=at
		canvas.draw_polygon(points,colors)
