class_name TowerMapView
extends Control
const CELL:Vector2=preload("res://scripts/world_scale_v17.gd").CELL_SIZE
var tower:Dictionary={}
var current:int=-1
var map_font:Font
func set_data(data:Dictionary,room_id:int) -> void:
	tower=data;current=room_id;custom_minimum_size=Vector2(720,420);clip_contents=true
	map_font=load("res://assets/Chinese.otf") if ResourceLoader.exists("res://assets/Chinese.otf") else ThemeDB.fallback_font
	queue_redraw()
static func coordinate(room:Dictionary) -> Vector2:
	if room.has("world_pixel_pos"):return Vector2(room["world_pixel_pos"])+Vector2(room["width"],room["height"])*(CELL*.5)
	return Vector2(room["coord"])
static func graph_bounds(data:Dictionary) -> Rect2:
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for room in data.get("rooms",[]):
		var half:Vector2=Vector2(room["width"],room["height"])*(CELL*.5) if room.has("world_pixel_pos") else Vector2.ZERO
		lo=lo.min(coordinate(room)-half);hi=hi.max(coordinate(room)+half)
	return Rect2(lo,(hi-lo).max(Vector2.ONE))
static func room_color(room:Dictionary,id:int) -> Color:
	if int(room["id"])==id:return Color("66f8d0")
	if room["type"]=="boss":return Color("f09b8e")
	if room["type"]=="elite":return Color("f1a45d")
	if room["type"]=="start":return Color("f3e6b4")
	if room["type"]=="merchant":return Color("c3a1ff")
	if room["type"]=="reward":return Color("f2c76c")
	if room.get("fountain",false):return Color("97d8ff")
	return Color("a1bcb2") if room.get("visited",false) else Color("3f625b")
static func draw_graph(c:CanvasItem,data:Dictionary,id:int,rect:Rect2,font:Font,local:bool=false,labels:bool=true) -> void:
	if data.is_empty():return
	var rooms:Array=data["rooms"];var bounds:Rect2=graph_bounds(data)
	var center:Vector2=coordinate(rooms[id]) if local else bounds.get_center()
	var continuous:bool=rooms[0].has("world_pixel_pos")
	var spacing:float=(26.0/2600 if continuous else 26.0) if local else minf((rect.size.x-28)/maxf(1,bounds.size.x),(rect.size.y-28)/maxf(1,bounds.size.y))
	var node:float=14 if local else clampf(spacing*.62,4,20)
	var points:Dictionary={}
	for room in rooms:
		var at:Vector2=rect.get_center()+(coordinate(room)-center)*spacing
		if rect.grow(-5).has_point(at):points[int(room["id"])]=at
	for room in rooms:
		var rid:int=int(room["id"])
		if not points.has(rid):continue
		for neighbor in room["neighbors"].values():
			var other:int=int(neighbor)
			if other>rid and points.has(other):c.draw_line(points[rid],points[other],Color("78988d"),2 if local else 1,true)
	for room in rooms:
		var rid:int=int(room["id"])
		if not points.has(rid):continue
		var at:Vector2=points[rid];var color:Color=room_color(room,id)
		var extent:Vector2=(Vector2(room["width"],room["height"])*CELL*spacing*.9).max(Vector2(3,2)) if continuous else Vector2.ONE*node
		c.draw_rect(Rect2(at-extent*.5,extent),Color(color,.55))
		c.draw_rect(Rect2(at-extent*.5,extent),color,false,1)
		if rid==id:c.draw_arc(at,node*.8,0,TAU,24,Color("fff0a6"),2,true)
		if labels and (local or spacing>=16 or continuous):
			var text:String="你" if rid==id else ({"start":"S","elite":"菁","boss":"B","reward":"寶","merchant":"商"}.get(str(room["type"]),"泉" if room.get("fountain",false) else ""))
			if not text.is_empty():c.draw_string(font,at+Vector2(-node*.36,node*.34),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12 if local else 13,Color("102c29"))
func _draw() -> void:
	if map_font==null:return
	draw_style_box(_backing(),Rect2(Vector2.ZERO,size))
	draw_chapter(self,tower,current,Rect2(15,16,size.x-210,size.y-70),map_font)
	draw_stage_list(self,tower,current,Rect2(size.x-182,24,165,size.y-65),map_font)
	draw_string(map_font,Vector2(18,size.y-18),"亮框＝目前　整＝整備　菁＝菁英　王＝首領　寶＝獎勵　泉＝溫泉　商＝商人",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("dce9df"))

func _backing() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("173b36");style.corner_radius_top_left=12;style.corner_radius_top_right=12;style.corner_radius_bottom_left=12;style.corner_radius_bottom_right=12;return style

static func chapter_layout(data:Dictionary,id:int,rect:Rect2) -> Dictionary:
	var rooms:Array=data.get("rooms",[])
	if rooms.is_empty():return {}
	var current_id:int=clampi(id,0,rooms.size()-1);var stage:int=rooms[current_id]["map_index"]
	var selected:Array=[];var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for room:Dictionary in rooms:
		if int(room["map_index"])!=stage:continue
		selected.append(room);lo=lo.min(Vector2(room["coord"]));hi=hi.max(Vector2(room["coord"]))
	var stride:float=minf(86,(rect.size.x-90)/maxf(1,hi.x-lo.x))
	var stride_y:float=minf(64,(rect.size.y-42)/maxf(1,hi.y-lo.y))
	var center:Vector2=(hi+lo)*.5;var points:Dictionary={}
	for room:Dictionary in selected:points[int(room["id"])]=rect.get_center()+(Vector2(room["coord"])-center)*Vector2(stride,stride_y)
	return {"rooms":selected,"points":points,"stage":stage,"stride":stride,"stride_y":stride_y}

static func known_rooms(rooms:Array,id:int,revealed:Dictionary={}) -> Dictionary:
	var known:Dictionary={}
	for candidate:Dictionary in rooms:
		if int(candidate["id"])==id or candidate.get("visited",false) or revealed.has(candidate["map_index"]):
			known[candidate["id"]]=true
	return known

static func neighboring_rooms(rooms:Array,known:Dictionary) -> Dictionary:
	var hinted:Dictionary={}
	for candidate:Dictionary in rooms:
		if not known.has(candidate["id"]):continue
		for next:int in candidate["neighbors"].values():
			if not known.has(next):hinted[next]=true
	return hinted

static func _draw_hint(c:CanvasItem,rect:Rect2) -> void:
	var tint:=Color("9aacaa",.70)
	c.draw_dashed_line(rect.position,Vector2(rect.end.x,rect.position.y),tint,1.0,4.0)
	c.draw_dashed_line(Vector2(rect.end.x,rect.position.y),rect.end,tint,1.0,4.0)
	c.draw_dashed_line(rect.end,Vector2(rect.position.x,rect.end.y),tint,1.0,4.0)
	c.draw_dashed_line(Vector2(rect.position.x,rect.end.y),rect.position,tint,1.0,4.0)

static func draw_chapter(c:CanvasItem,data:Dictionary,id:int,rect:Rect2,font:Font,fog:bool=false) -> void:
	var graph:Dictionary=chapter_layout(data,id,rect)
	if graph.is_empty():return
	var points:Dictionary=graph["points"];var extent:=Vector2(48,30)
	var hints:Dictionary={}
	if fog:
		var known:Dictionary=known_rooms(graph["rooms"],id)
		hints=neighboring_rooms(graph["rooms"],known)
		for rid in points.keys():
			if not known.has(rid) and not hints.has(rid):points.erase(rid)
	for room:Dictionary in graph["rooms"]:
		var rid:int=room["id"]
		if not points.has(rid):continue
		for next:int in room["neighbors"].values():
			if next<rid or not points.has(next):continue
			if hints.has(rid) or hints.has(next):
				if not (hints.has(rid) and hints.has(next)):c.draw_dashed_line(points[rid],points[next],Color("779695"),2,5)
			else:c.draw_line(points[rid],points[next],Color("7c9eaa"),4,true)
	for room:Dictionary in graph["rooms"]:
		var rid:int=room["id"]
		if not points.has(rid):continue
		var at:Vector2=points[rid];var color:Color=room_color(room,-1)
		var box:=Rect2(at-extent*.5,extent)
		if hints.has(rid):_draw_hint(c,box);continue
		c.draw_rect(box,Color("183640") if room.get("visited",false) else Color("0d202b"))
		c.draw_rect(box,color,false,2 if rid!=id else 3)
		var symbol:String={"start":"整","elite":"菁","boss":"王","merchant":"商","reward":"寶"}.get(str(room["type"]),"泉" if room.get("fountain",false) else "·")
		c.draw_string(font,at+Vector2(-7,6),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
		if rid==id:
			c.draw_rect(box.grow(5),Color("fff0a6"),false,3)
			c.draw_colored_polygon(PackedVector2Array([at+Vector2(-5,-26),at+Vector2(5,-26),at+Vector2(0,-18)]),Color("fff0a6"))
		if not fog and room["type"]=="boss":
			for direction:String in room["neighbors"]:
				var next:int=room["neighbors"][direction]
				if points.has(next):continue
				var side:float=-1 if direction=="left" else 1
				c.draw_line(at+Vector2(side*25,0),at+Vector2(side*55,0),Color("f4c16d"),3,true)
				c.draw_string(font,at+Vector2(-38,42),"下一關 →" if side>0 else "← 下一關",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f4c16d"))

static func draw_stage_list(c:CanvasItem,data:Dictionary,id:int,rect:Rect2,font:Font) -> void:
	if data.is_empty():return
	var stage:int=data["rooms"][clampi(id,0,data["rooms"].size()-1)]["map_index"]
	for map_data:Dictionary in data["maps"]:
		var index:int=map_data["index"];var y:float=rect.position.y+(5-index)*64
		var box:=Rect2(rect.position.x,y,rect.size.x,53)
		c.draw_rect(box,Color("294e56") if index==stage else Color("142b37"))
		c.draw_rect(box,Color("fff0a6") if index==stage else Color("4c6875"),false,2 if index==stage else 1)
		var visited:int=0
		for rid:int in map_data["room_ids"]:
			if data["rooms"][rid].get("visited",false):visited+=1
		c.draw_string(font,box.position+Vector2(10,22),"第 %d 關  %s"%[index+1,"目前" if index==stage else ""],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e1ede6"))
		c.draw_string(font,box.position+Vector2(10,41),"探索 %d / %d 間"%[visited,map_data["room_ids"].size()],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a9c6c9"))

static func full_tower_layout(data:Dictionary,rect:Rect2) -> Array[Dictionary]:
	# One coordinate transform for the entire tower, including Boss→Start
	# seams. Chapters are tags on a single connected graph, never separate cards.
	var result:Array[Dictionary]=[];var rooms:Array=data.get("rooms",[])
	if rooms.is_empty():return result
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for room:Dictionary in rooms:lo=lo.min(Vector2(room["coord"]));hi=hi.max(Vector2(room["coord"]))
	var stride:=Vector2(minf(78,(rect.size.x-110)/maxf(1,hi.x-lo.x+1)),minf(38,(rect.size.y-32)/maxf(1,hi.y-lo.y+1)))
	var origin:Vector2=rect.get_center()-(hi+lo)*.5*stride
	var extent:=Vector2(minf(48,stride.x*.72),minf(24,stride.y*.65))
	for stage:Dictionary in data.get("maps",[]):
		var selected:Array=[];var points:Dictionary={};var bounds:=Rect2()
		for rid:int in stage["room_ids"]:
			var room:Dictionary=rooms[rid];var at:Vector2=origin+Vector2(room["coord"])*stride
			selected.append(room);points[rid]=at
			bounds=bounds.merge(Rect2(at-extent*.5,extent)) if selected.size()>1 else Rect2(at-extent*.5,extent)
		result.append({"stage":stage,"rect":bounds,"graph":{"rooms":selected,"points":points,"extent":extent,"stride":stride}})
	return result

static func draw_full_tower(c:CanvasItem,data:Dictionary,id:int,rect:Rect2,font:Font,fog:bool=false) -> void:
	var chapters:Array[Dictionary]=full_tower_layout(data,rect);var points:Dictionary={}
	for chapter:Dictionary in chapters:points.merge(chapter["graph"]["points"])
	if points.is_empty():return
	var rooms:Array=data["rooms"];var extent:Vector2=chapters[0]["graph"]["extent"]
	var hints:Dictionary={}
	if fog:
		var revealed:Dictionary={}
		for candidate:Dictionary in rooms:
			if candidate.get("boss_defeated",false):revealed[candidate["map_index"]]=true
		var known:Dictionary=known_rooms(rooms,id,revealed)
		hints=neighboring_rooms(rooms,known)
		for rid in points.keys():
			if not known.has(rid) and not hints.has(rid):points.erase(rid)
	for room:Dictionary in rooms:
		if not points.has(room["id"]):continue
		for next:int in room["neighbors"].values():
			if next<int(room["id"]) or not points.has(next):continue
			var cross:bool=int(room["map_index"])!=int(rooms[next]["map_index"])
			if hints.has(room["id"]) or hints.has(next):
				if not (hints.has(room["id"]) and hints.has(next)):c.draw_dashed_line(points[room["id"]],points[next],Color("779695"),1,4)
			else:c.draw_line(points[room["id"]],points[next],Color("ffd581") if cross else Color("7595a3"),3 if cross else 2,true)
	for room:Dictionary in rooms:
		var rid:int=room["id"]
		if not points.has(rid):continue
		var at:Vector2=points[rid];var color:Color=room_color(room,-1);var node:=Rect2(at-extent*.5,extent)
		if hints.has(rid):_draw_hint(c,node);continue
		c.draw_rect(node,Color("18313b"));c.draw_rect(node,color,false,1.5)
		var symbol:String={"start":"整","elite":"菁","boss":"王","merchant":"商","reward":"寶"}.get(str(room["type"]),"泉" if room.get("fountain",false) else "")
		if not symbol.is_empty():c.draw_string(font,at+Vector2(-5,4),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,clampi(int(extent.y),9,12),color)
		if rid==id:c.draw_rect(node.grow(3),Color("fff0a6"),false,2)
	for chapter:Dictionary in chapters:
		var stage:Dictionary=chapter["stage"]
		if not points.has(stage["start_id"]) or hints.has(stage["start_id"]):continue
		var at:Vector2=points[stage["start_id"]]
		c.draw_string(font,at+Vector2(extent.x*.5+7,4),str(int(stage["index"])+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b4d6d3"))
