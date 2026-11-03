class_name BiomeArtV21
extends RefCounted
## Connectivity is computed from the union of solids, never from merged-rect
## boundaries. All material UVs share world coordinates; mirrors span six cells.
const Terrain=preload("res://scripts/terrain_art_v24.gd")
const TILE:float=96
const REPEAT:float=TILE*6
const ROOT:String="res://assets/v21/"
const EdgeDecor=preload("res://scripts/edge_decor_v23.gd")
const Surfaces=preload("res://scripts/surface_art_v22.gd")
static var _textures:Dictionary={}
static var _regions:Dictionary={}
static var _metadata:Dictionary={}
static func texture(biome:String,role:String) -> Texture2D:
	var key:String=role+"-"+biome
	if _textures.has(key):return _textures[key]
	var path:String=ROOT+key+".png"
	if not ResourceLoader.exists(path):return null
	_textures[key]=load(path);return _textures[key]
static func region(biome:String,role:String,column:int,row:int,tight:bool=false) -> Texture2D:
	var key:String="%s:%s:%d:%d:%s"%[biome,role,column,row,tight]
	if _regions.has(key):return _regions[key]
	var image:Texture2D=texture(biome,role)
	if image==null:return null
	var grid:int=4 if role=="terrain" else 6;var cell:Vector2=image.get_size()/grid
	var rect:=Rect2(Vector2(column,row)*cell,cell)
	var info:Dictionary=cell_info(biome,role,column,row)
	var source:Array=info.get("region",[])
	if source.size()==4:rect=Rect2(source[0],source[1],source[2],source[3])
	if tight:
		var bounds:Rect2=alpha_bounds(biome,role,column,row)
		rect=Rect2(rect.position+bounds.position,bounds.size)
	var atlas:=AtlasTexture.new();atlas.atlas=image;atlas.region=rect;atlas.filter_clip=true;_regions[key]=atlas;return atlas
static func cell_info(biome:String,role:String,column:int,row:int) -> Dictionary:
	if _metadata.is_empty() and FileAccess.file_exists(ROOT+"atlas-metadata.json"):
		_metadata=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"atlas-metadata.json"))
	return _metadata.get(role+"-"+biome,{}).get("cells",{}).get("%d,%d"%[column,row],{})
static func alpha_bounds(biome:String,role:String,column:int,row:int) -> Rect2:
	var raw:Array=cell_info(biome,role,column,row).get("bounds",[])
	if raw.size()==4:return Rect2(raw[0],raw[1],maxf(1,raw[2]),maxf(1,raw[3]))
	var image:Texture2D=texture(biome,role);var side:float=image.get_width()/(4.0 if role=="terrain" else 6.0) if image!=null else 256
	return Rect2(0,0,side,side)
static func _subtract_ranges(ranges:Array,cut:Vector2) -> Array:
	var result:Array=[]
	for segment:Vector2 in ranges:
		if cut.y<=segment.x or cut.x>=segment.y:result.append(segment);continue
		if cut.x>segment.x:result.append(Vector2(segment.x,cut.x))
		if cut.y<segment.y:result.append(Vector2(cut.y,segment.y))
	return result
static func edges(solids:Array) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for rect:Rect2 in solids:
		for side:String in ["top","bottom","left","right"]:
			var horizontal:bool=side in ["top","bottom"]
			var ranges:Array=[Vector2(rect.position.x,rect.end.x) if horizontal else Vector2(rect.position.y,rect.end.y)]
			var coordinate:float=rect.position.y if side=="top" else rect.end.y if side=="bottom" else rect.position.x if side=="left" else rect.end.x
			for other:Rect2 in solids:
				if other==rect:continue
				var neighbor:float=other.end.y if side=="top" else other.position.y if side=="bottom" else other.end.x if side=="left" else other.position.x
				if not is_equal_approx(coordinate,neighbor):continue
				ranges=_subtract_ranges(ranges,Vector2(other.position.x,other.end.x) if horizontal else Vector2(other.position.y,other.end.y))
			for segment:Vector2 in ranges:
				if segment.y-segment.x<.1:continue
				result.append({"side":side,"at":coordinate,"span":segment})
	var groups:Dictionary={}
	for edge:Dictionary in result:
		var key:String=str(edge["side"])+":"+str(edge["at"])
		if not groups.has(key):groups[key]=[]
		groups[key].append(edge)
	var merged:Array[Dictionary]=[]
	for list:Array in groups.values():
		list.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a["span"].x<b["span"].x)
		for edge:Dictionary in list:
			if not merged.is_empty() and merged[-1]["side"]==edge["side"] and is_equal_approx(merged[-1]["at"],edge["at"]) and is_equal_approx(merged[-1]["span"].y,edge["span"].x):merged[-1]["span"].y=edge["span"].y
			else:merged.append(edge.duplicate(true))
	return merged
static func fill_patches(rect:Rect2,seed_value:int=0) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for y in range(floori(rect.position.y/REPEAT),ceili(rect.end.y/REPEAT)):
		for x in range(floori(rect.position.x/REPEAT),ceili(rect.end.x/REPEAT)):
			var tile:=Rect2(x*REPEAT,y*REPEAT,REPEAT,REPEAT);var target:Rect2=tile.intersection(rect)
			if not target.has_area():continue
			var flip_x:bool=posmod(x+seed_value,2)==1;var flip_y:bool=posmod(y+seed_value/7,2)==1
			var uv:Vector2=(target.position-tile.position)/REPEAT;var extent:Vector2=target.size/REPEAT
			if flip_x:uv.x=1-uv.x-extent.x
			if flip_y:uv.y=1-uv.y-extent.y
			result.append({"rect":target,"uv":Rect2(uv,extent),"flip_x":flip_x,"flip_y":flip_y,"section":Vector2i(x,y)})
	return result
static func _fill(c:CanvasItem,image:Texture2D,rect:Rect2,_seed_value:int) -> void:
	var period:float=Terrain.PERIOD
	for row in range(floori(rect.position.y/period),ceili(rect.end.y/period)):
		for column in range(floori(rect.position.x/period),ceili(rect.end.x/period)):
			var tile:=Rect2(column*period,row*period,period,period);var part:Rect2=rect.intersection(tile)
			var uv:Vector2=(part.position-tile.position)/period
			var extent:Vector2=part.size/period
			var horizontal:bool=posmod(column,2)==1;var vertical:bool=posmod(row,2)==1
			if horizontal:uv.x=1-uv.x-extent.x
			if vertical:uv.y=1-uv.y-extent.y
			c.draw_set_transform_matrix(Transform2D(0,Vector2(-1 if horizontal else 1,-1 if vertical else 1),0,part.get_center()))
			c.draw_texture_rect_region(image,Rect2(-part.size*.5,part.size),Rect2(uv*image.get_size(),extent*image.get_size()))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
static func draw_terrain(c:CanvasItem,biome:String,layout:Dictionary,solids:Array,visible:Rect2=Rect2(),reduced:bool=false) -> bool:
	var fill:Texture2D=Terrain.texture("material-"+biome+".png")
	if fill==null:fill=Surfaces.material(biome)
	if fill==null:return false
	var seed_value:int=int(layout.get("seed",0));var edge_list:Array=layout.get("art_edges_v21",[])
	for rect:Rect2 in solids:
		if visible.has_area():
			rect=rect.intersection(visible)
			if not rect.has_area():continue
		c.draw_rect(rect,Surfaces.BASE_COLORS.get(biome,Color("354331")))
		_fill(c,fill,rect,seed_value)
	for edge:Dictionary in edge_list:
		var span:Vector2=edge["span"];var side:String=edge["side"]
		if visible.has_area():
			if side in ["top","bottom"]:
				if float(edge["at"])<visible.position.y-8 or float(edge["at"])>visible.end.y+8:continue
				span=Vector2(maxf(span.x,visible.position.x),minf(span.y,visible.end.x))
			else:
				if float(edge["at"])<visible.position.x-8 or float(edge["at"])>visible.end.x+8:continue
				span=Vector2(maxf(span.x,visible.position.y),minf(span.y,visible.end.y))
			if span.y<=span.x:continue
		# Bevels stay INSIDE the exact collision boundary. Decorative grass,
		# roots and rocks are drawn separately on the outside foreground edge.
		var inward:Vector2={"top":Vector2.DOWN,"bottom":Vector2.UP,"left":Vector2.RIGHT,"right":Vector2.LEFT}[side]
		var start:Vector2=Vector2(span.x,edge["at"]) if side in ["top","bottom"] else Vector2(edge["at"],span.x)
		var end:Vector2=Vector2(span.y,edge["at"]) if side in ["top","bottom"] else Vector2(edge["at"],span.y)
		var bevel_color:=Color(.62,.77,.61,.24) if side in ["top","left"] else Color(.04,.06,.08,.45)
		if reduced:
			c.draw_line(start+inward*3.0,end+inward*3.0,bevel_color,3.0)
			continue
		var length:float=start.distance_to(end)
		var tangent:Vector2=(end-start).normalized();var points:=PackedVector2Array()
		for step in range(0,ceili(length/9)+1):
			var distance:float=minf(length,step*9.0)
			var art_distance:float=distance+span.x-float(edge["span"].x)
			var inset:float=3.0+1.5*sin((start.x+start.y+distance)*.13)+.8*sin(art_distance*.41)
			points.append(start+tangent*distance+inward*inset)
		if points.size()>1:c.draw_polyline(points,bevel_color,3,true)
	Terrain.draw_corners(c,biome,layout,visible)

	c.draw_set_transform_matrix(Transform2D.IDENTITY)
	for rect:Rect2 in layout.get("platform_art_runs",layout.get("one_way",[])):
		if visible.has_area() and not visible.intersects(rect.grow(192)):continue
		draw_platform(c,biome,rect)
	return true
static func _rim(c:CanvasItem,image:Texture2D,target:Rect2,side:String) -> void:
	var horizontal:bool=side in ["top","bottom"]
	var first:float=target.position.x if horizontal else target.position.y
	var last:float=target.end.x if horizontal else target.end.y
	for section in range(floori(first/REPEAT),ceili(last/REPEAT)):
		var start:float=maxf(first,section*REPEAT);var end:float=minf(last,(section+1)*REPEAT)
		var fraction:float=(start-section*REPEAT)/REPEAT;var amount:float=(end-start)/REPEAT
		var sample_size:Vector2=image.get_size()
		if side=="top":sample_size.y=minf(sample_size.y,sample_size.x*.28)
		var source:=Rect2(fraction*sample_size.x,0,amount*sample_size.x,sample_size.y) if horizontal else Rect2(0,fraction*sample_size.y,sample_size.x,amount*sample_size.y)
		var destination:=Rect2(start,target.position.y,end-start,target.size.y) if horizontal else Rect2(target.position.x,start,target.size.x,end-start)
		if side=="right":c.draw_set_transform_matrix(Transform2D(0,Vector2(-1,1),0,Vector2(target.get_center().x*2,0)))
		c.draw_texture_rect_region(image,destination,source)
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
static func draw_platform(c:CanvasItem,biome:String,rect:Rect2) -> void:
	if not Terrain.platform(c,biome,rect):Surfaces.draw_platform(c,biome,rect)
static func prop(c:CanvasItem,object:Dictionary,biome:String,base:Transform2D) -> bool:
	var index:int=posmod(int(object.get("variant",0)),6);var frame:int=0
	if object.get("used",false):frame=mini(3,1+int((1-clampf(float(object.get("break_left",0))/.6,0,1))*3))
	var image:Texture2D=region(biome,"props",index,1+frame)
	if image==null:return false
	var bounds:Rect2=alpha_bounds(biome,"props",index,1);var scale_value:float=82/maxf(1,bounds.size.y)
	var pivot:=Vector2(bounds.get_center().x,bounds.end.y)
	var anchor:Array=cell_info(biome,"props",index,1+frame).get("anchor",[])
	if anchor.size()==2:pivot=Vector2(anchor[0],anchor[1])
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(image,Rect2(Vector2(object["pos"])-pivot*scale_value,image.get_size()*scale_value),false)
	return true
static func prepare(layout:Dictionary,seed_value:int) -> void:
	var solids:Array=layout.get("solids",[]);var edge_list:Array[Dictionary]=edges(solids);layout["art_edges_v21"]=edge_list
	var vertices:Dictionary={}
	for rect:Rect2 in solids:
		for at:Vector2 in [rect.position,rect.end,Vector2(rect.end.x,rect.position.y),Vector2(rect.position.x,rect.end.y)]:vertices[at]=true
	var corners:Array[Dictionary]=[]
	for at:Vector2 in vertices:
		var mask:int=0
		for i in 4:
			var point:Vector2=at+[Vector2(-.1,-.1),Vector2(.1,-.1),Vector2(.1,.1),Vector2(-.1,.1)][i]
			if solids.any(func(rect:Rect2)->bool:return rect.has_point(point)):mask|=1<<i
		var count:int=0
		for i in 4:
			if mask&(1<<i):count+=1
		if count not in [1,3]:continue
		var quadrant:int=0
		for i in 4:
			if bool(mask&(1<<i))==(count==1):quadrant=i;break
		corners.append({"pos":at,"inner":count==3,"angle":quadrant*PI*.5})
	layout["art_corners_v21"]=corners
	var random:=RandomNumberGenerator.new();random.seed=seed_value+2100;var details:Array[Dictionary]=[]
	for edge:Dictionary in edge_list:
		var span:Vector2=edge["span"];var cursor:float=span.x+random.randf_range(18,65)
		while cursor<span.y-12:
			if details.size()>130:break
			var side:String=edge["side"];var at:=Vector2(cursor,edge["at"]) if side in ["top","bottom"] else Vector2(edge["at"],cursor)
			if not layout.get("reserved_regions",[]).any(func(rect:Rect2)->bool:return rect.has_point(at)):
				details.append({"pos":at,"side":side,"variant":random.randi_range(0,5),"size":24.0})
			cursor+=random.randf_range(78,190)
	layout["edge_details_v21"]=details
	layout["edge_details_v23"]=EdgeDecor.plan(edge_list,solids,layout.get("reserved_regions",[]),seed_value)
static func draw_details(c:CanvasItem,biome:String,layout:Dictionary,layer:int=1,visible:Rect2=Rect2()) -> void:
	EdgeDecor.draw(c,biome,layout,layer,visible)
static func middle_plan(seed_value:int,bounds:Vector2,layout:Dictionary={},biome:String="trunk",quiet:bool=false) -> Array[Dictionary]:
	# Large props belong to exposed support surfaces, never random heights.
	var random:=RandomNumberGenerator.new();random.seed=seed_value+21129;var result:Array[Dictionary]=[]
	var surfaces:Array=layout.get("platforms",[]).duplicate();var choices:Array=Terrain.data(biome).get("middle",[])
	if choices.is_empty():return result
	var candidates:Array[Dictionary]=[]
	for surface:Rect2 in surfaces:
		if surface.size.x<280 or surface.position.y<240:continue
		for x in range(ceili((surface.position.x+145)/96),floori((surface.end.x-145)/96)+1):
			var variant:int=random.randi_range(0,choices.size()-1);var definition:Dictionary=choices[variant]
			var size:Array=definition["world_size"];var width:float=float(size[0]);var height:float=float(size[1])
			var at:=Vector2(x*96,surface.position.y+10)
			var body:=Rect2(at-Vector2(width*.5,height),Vector2(width,height-10.5))
			if body.position.x<96 or body.end.x>bounds.x-96:continue
			if layout.get("solids",[]).any(func(rock:Rect2)->bool:return rock.intersects(body)):continue
			if layout.get("one_way",[]).any(func(ledge:Rect2)->bool:return ledge.intersects(body)):continue
			if layout.get("doors",{}).values().any(func(door:Vector2)->bool:return door.distance_to(at)<220):continue
			candidates.append({"variant":variant,"pos":at,"support_y":surface.position.y,"support":surface,"bounds":body,"size":height,"flip":random.randf()<.5})
	while not candidates.is_empty() and result.size()<(3 if quiet else 6):
		var item:Dictionary=candidates.pop_at(random.randi_range(0,candidates.size()-1));var body:Rect2=item["bounds"]
		if result.any(func(other:Dictionary)->bool:return Rect2(other["bounds"]).grow(65).intersects(body)):continue
		result.append(item)
	return result
static func draw_middle(c:CanvasItem,biome:String,items:Array) -> void:
	if Terrain.middle(c,biome,items):return
	for item:Dictionary in items:
		var image:Texture2D=region(biome,"props",item["variant"],0,true)
		if image==null:continue
		var extent:Vector2=image.get_size()/image.get_height()*float(item["size"])
		c.draw_set_transform_matrix(Transform2D(0,Vector2(-1 if item["flip"] else 1,1),0,item["pos"]))
		c.draw_texture_rect(image,Rect2(Vector2(-extent.x*.5,-extent.y),extent),false,Color(.19,.24,.25,.38))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
