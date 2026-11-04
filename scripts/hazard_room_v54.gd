class_name HazardRoomV54
extends RefCounted

static func prepare(layout:Dictionary,room_id:int,chosen:String="") -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=("%d:%d:v54"%[layout["seed"],room_id]).sha256_buffer().decode_u32(0)
	var roll:float=rng.randf()
	if chosen.is_empty() and roll>=.2:return
	var bounds:Vector2=layout["size"]
	var variant:String=chosen if chosen in ["spike_islands","mushroom_air"] else ("spike_islands" if roll<.1 else "mushroom_air")
	layout["hazard_room"]=variant
	var floating:bool=variant=="mushroom_air"
	if floating:
		var extra_width:float=384.0
		bounds.x+=extra_width
		layout["size"]=bounds
		if layout.get("doors",{}).has("right"):layout["doors"]["right"]+=Vector2(extra_width,0)
		if layout["spawn_positions"].has("left"):layout["spawn_positions"]["left"]+=Vector2(extra_width,0)
	layout.erase("maze_grid")
	var tile:float=float(layout.get("tile_size",96))
	var interior:=Rect2(Vector2.ONE*tile,bounds-Vector2.ONE*tile*2)
	var supports:Array[Rect2]=[]
	var islands:Array[Rect2]=[]
	var spikes:Array[Rect2]=[]
	var mushrooms:Array[Vector2]=[]
	for key:String in layout["spawn_positions"]:
		var entry:Vector2=layout["spawn_positions"][key]
		var left:float=0.0 if key=="right" else entry.x-60
		var right:float=bounds.x if key=="left" else entry.x+60
		supports.append(Rect2(left,entry.y,right-left,12))
		if variant=="mushroom_air":mushrooms.append(entry+Vector2(0,5))
	for y in range(260,int(bounds.y)-80,300 if floating else 215):
		for x in range(285,int(bounds.x)-150,390 if floating else 260):
			var at:=Vector2(x+rng.randf_range(-40,40),y+rng.randf_range(-24,24))
			if supports.any(func(s:Rect2)->bool:return s.grow(112).has_point(at)):continue
			if variant=="mushroom_air":
				if interior.grow(-32).has_point(at):mushrooms.append(at)
			else:
				var width:float=96 if rng.randf()<.5 else 192
				var island:=Rect2(at,Vector2(width,96))
				if not interior.encloses(island):continue
				islands.append(island)
				spikes.append(Rect2(at-Vector2(0,20),Vector2(width,20)))
	layout["one_way"]=supports
	layout["platform_art_runs"]=supports
	var boundary:Array[Rect2]=perimeter(bounds,layout.get("doors",{}),tile,int(layout.get("door_width",3)))
	layout["platforms"]=supports+boundary.filter(func(cell:Rect2)->bool:return is_equal_approx(cell.end.y,bounds.y))
	layout["solids"]=boundary+islands
	layout["walls"]=layout["solids"]
	layout["spike_rects"]=spikes
	layout["launcher_spawns"]=mushrooms

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
