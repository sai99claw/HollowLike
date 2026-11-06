class_name HazardRoomV54
extends RefCounted

# Full C + CC travel at the highest supported world speed is under 532 px.
const MUSHROOM_SPACING:float=550.0

static func prepare(layout:Dictionary,room_id:int,chosen:String="") -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=("%d:%d:v54"%[layout["seed"],room_id]).sha256_buffer().decode_u32(0)
	var roll:float=rng.randf()
	if chosen.is_empty() and roll>=.2:return
	var bounds:Vector2=layout["size"]
	var variant:String=chosen if chosen in ["spike_islands","mushroom_air"] else ("spike_islands" if roll<.1 else "mushroom_air")
	layout["hazard_room"]=variant
	var floating:bool=variant=="mushroom_air"
	var tile:float=float(layout.get("tile_size",96))
	if floating:
		var expanded:=Vector2(maxf(bounds.x+384.0,52.0*tile),maxf(bounds.y,13.0*tile))
		var extra:Vector2=expanded-bounds
		layout["size"]=expanded
		var doors:Dictionary=layout.get("doors",{})
		if doors.has("right"):doors["right"]+=Vector2(extra.x,0)
		if doors.has("down"):doors["down"]+=Vector2(0,extra.y)
		var starts:Dictionary=layout["spawn_positions"]
		if starts.has("left"):starts["left"]+=Vector2(extra.x,0)
		for key in starts:
			if is_equal_approx(starts[key].y,float(layout.get("floor_y",bounds.y-tile))):starts[key].y+=extra.y
		layout["floor_y"]=expanded.y-tile
		bounds=expanded
	layout.erase("maze_grid")
	var interior:=Rect2(Vector2.ONE*tile,bounds-Vector2.ONE*tile*2)
	var supports:Array[Rect2]=[]
	var islands:Array[Rect2]=[]
	var spikes:Array[Rect2]=[]
	for key:String in layout["spawn_positions"]:
		var entry:Vector2=layout["spawn_positions"][key]
		var left:float=0.0 if key=="right" else entry.x-60
		var right:float=bounds.x if key=="left" else entry.x+60
		supports.append(Rect2(left,entry.y,right-left,12))
	var boundary:Array[Rect2]=perimeter(bounds,layout.get("doors",{}),tile,int(layout.get("door_width",3)))
	if not floating:
		var candidates:Array[Rect2]=[]
		for y in range(260,int(bounds.y)-80,215):
			for x in range(285,int(bounds.x)-150,260):
				var at:=Vector2(x+rng.randf_range(-40,40),y+rng.randf_range(-24,24))
				if supports.any(func(s:Rect2)->bool:return s.grow(112).has_point(at)):continue
				var island:=Rect2(at,Vector2(tile if rng.randf()<.5 else tile*2,tile))
				if interior.encloses(island):candidates.append(island)
		var original_tiles:int=0
		for candidate:Rect2 in candidates:original_tiles+=roundi(candidate.size.x/tile)
		var remaining:int=ceili(original_tiles*.5)
		while remaining>0 and not candidates.is_empty():
			var island:Rect2=candidates.pop_at(rng.randi_range(0,candidates.size()-1))
			var tiles:int=mini(remaining,roundi(island.size.x/tile))
			island.size.x=tiles*tile
			remaining-=tiles
			islands.append(island)
			spikes.append(Rect2(island.position-Vector2(0,20),Vector2(island.size.x,20)))
	layout["one_way"]=supports
	layout["platform_art_runs"]=supports
	layout["platforms"]=supports+boundary.filter(func(cell:Rect2)->bool:return is_equal_approx(cell.end.y,bounds.y))
	layout["solids"]=boundary+islands
	layout["walls"]=layout["solids"]
	layout["spike_rects"]=spikes
	layout["launcher_spawns"]=_mushrooms(rng,bounds,tile,boundary,supports) if floating else []

static func _mushrooms(rng:RandomNumberGenerator,bounds:Vector2,tile:float,boundary:Array[Rect2],supports:Array[Rect2]) -> Array[Vector2]:
	var result:Array[Vector2]=[]
	var floor_y:float=bounds.y-tile
	var offset:float=rng.randf_range(0,24)
	for row in 3:
		var candidates:Array[Vector2]=[]
		var x:float=360.0+500.0*float(row%2)+offset
		while x<bounds.x-280.0:
			var at:=Vector2(x+rng.randf_range(-8,8),floor_y-row*350.0)
			if row==0:
				if boundary.any(func(rect:Rect2)->bool:return is_equal_approx(rect.position.y,floor_y) and rect.has_point(at+Vector2(0,1))):
					candidates.append(at)
			else:
				at.y+=rng.randf_range(-8,8)
				if not supports.any(func(rect:Rect2)->bool:return rect.grow(76).has_point(at)):
					candidates.append(at)
			x+=1000.0
		var count:int=3 if row==2 else 4
		for index in mini(count,candidates.size()):
			result.append(candidates.pop_at(rng.randi_range(0,candidates.size()-1)))
	return result

static func perimeter(size:Vector2,doors:Dictionary,tile:float,door_width:int) -> Array[Rect2]:
	var result:Array[Rect2]=[]
	var opening:float=tile*door_width
	for side:String in ["up","down","left","right"]:
		var horizontal:bool=side in ["up","down"]
		var start:float=0.0 if horizontal else tile
		var end:float=size.x if horizontal else size.y-tile
		var gap:=Vector2(-1,-1)
		if doors.has(side):
			var at:Vector2=doors[side]
			gap=Vector2(at.x-opening*.5,at.x+opening*.5) if horizontal else Vector2(at.y-opening,at.y)
		var fixed:float=0.0 if side in ["up","left"] else (size.y-tile if horizontal else size.x-tile)
		for cell:int in range(floori(start/tile),ceili(end/tile)):
			var low:float=maxf(start,cell*tile)
			var high:float=minf(end,(cell+1)*tile)
			for span:Vector2 in [Vector2(low,minf(high,gap.x)),Vector2(maxf(low,gap.y),high)]:
				if span.y<=span.x:continue
				var length:float=span.y-span.x
				result.append(Rect2(span.x,fixed,length,tile) if horizontal else Rect2(fixed,span.x,tile,length))
	return result

static func draw_spikes(canvas:CanvasItem,rect:Rect2) -> void:
	var count:int=maxi(1,roundi(rect.size.x/16))
	var width:float=rect.size.x/count
	for i in count:
		var at:=Vector2(rect.position.x+i*width,rect.end.y)
		canvas.draw_colored_polygon(PackedVector2Array([at,at+Vector2(width*.5,-rect.size.y),at+Vector2(width,0)]),Color("c7d4dc"))
