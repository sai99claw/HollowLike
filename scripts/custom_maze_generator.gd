class_name CustomMazeGenerator
extends RefCounted
## Seeded Prim cells, open plazas, random narrow/wide cuts and braided loops.
const WALL:int=0
const FLOOR:int=1
const DIRS:Array[Vector2i]=[Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
class MazeConfig:
	var width:int=41
	var height:int=19
	var num_rooms:int=3
	var room_min_size:int=5
	var room_max_size:int=17
	var straight_bias:float=.70
	var braid_rate:float=.80
	var corridor_width_mode:String="random"
	var doors:Dictionary={}
	var door_width:int=3
	var seed_value:int=0
	var arena:bool=false
	var platformer:bool=false
	var layout_profile:String=""
	var plaza_scale:float=1.0
	var dead_end_chance:float=.25
var config:MazeConfig
var grid:Array[PackedByteArray]=[]
var rooms:Array[Rect2i]=[]
var doors:Dictionary={}
var braided_walls:Array[Vector2i]=[]
var corridor_widths:Array[int]=[]
var dead_end_rewards:Array[Dictionary]=[]
var protected_dead_end:Dictionary={}
var rng:=RandomNumberGenerator.new()
func _init(cfg:MazeConfig=null) -> void:config=cfg if cfg!=null else MazeConfig.new()
func generate() -> void:
	rng.seed=config.seed_value;grid.clear();rooms.clear();doors.clear();braided_walls.clear();corridor_widths.clear();dead_end_rewards.clear();protected_dead_end.clear()
	config.width=maxi(9,config.width|1);config.height=maxi(9,config.height|1)
	for y in config.height:
		var row:=PackedByteArray();row.resize(config.width);row.fill(WALL);grid.append(row)
	_carve_prim();_plazas()
	if config.platformer:_platformer_frame()
	_open_doors();_braid()
	if config.platformer and not config.arena and rng.randf()<config.dead_end_chance:_long_reward_branch()
	_find_long_dead_ends()
	# Every carving attaches to the spanning tree. Validate all floor, not doors only.
	assert(validate().is_empty(),"Maze floor connectivity failed")
func _inside(at:Vector2i) -> bool:return at.x>0 and at.y>0 and at.x<config.width-1 and at.y<config.height-1
func is_floor(at:Vector2i) -> bool:return at.x>=0 and at.y>=0 and at.x<config.width and at.y<config.height and grid[at.y][at.x]==FLOOR
func _carve(at:Vector2i) -> void:
	if at.x>=0 and at.y>=0 and at.x<config.width and at.y<config.height:grid[at.y][at.x]=FLOOR
func _carve_prim() -> void:
	var visited:Dictionary={Vector2i.ONE:true};_carve(Vector2i.ONE)
	var frontier:Array[Vector3i]=[];_frontier(Vector2i.ONE,visited,frontier)
	var last:int=-1
	while not frontier.is_empty():
		var index:int=rng.randi_range(0,frontier.size()-1)
		if last>=0 and rng.randf()<config.straight_bias:
			# Probe in random cyclic order; no quadratic frontier-copy allocation.
			for j in frontier.size():
				var k:int=(index+j)%frontier.size()
				if frontier[k].z==last:index=k;break
		var edge:Vector3i=frontier[index];frontier[index]=frontier[-1];frontier.pop_back()
		var from:=Vector2i(edge.x,edge.y);var direction:Vector2i=DIRS[edge.z];var to:Vector2i=from+direction*2
		if visited.has(to):continue
		visited[to]=true;last=edge.z;_carve(from+direction);_carve(to)
		var width:int=1 if config.corridor_width_mode=="narrow" else (2 if config.corridor_width_mode=="wide" else rng.randi_range(1,2))
		corridor_widths.append(width)
		if width==2:
			var side:=Vector2i(-direction.y,direction.x)
			if not _inside(to+side):side=-side
			for at in [from+side,from+direction+side,to+side]:
				if _inside(at):_carve(at)
		_frontier(to,visited,frontier)
func _frontier(at:Vector2i,visited:Dictionary,frontier:Array[Vector3i]) -> void:
	for i in DIRS.size():
		if _inside(at+DIRS[i]*2) and not visited.has(at+DIRS[i]*2):frontier.append(Vector3i(at.x,at.y,i))
func _plazas() -> void:
	if config.arena:
		var arena:=Rect2i(1,1,config.width-2,config.height-2);rooms.append(arena)
		for y in range(1,config.height-1):
			for x in range(1,config.width-1):_carve(Vector2i(x,y))
		return
	if config.platformer and not config.layout_profile.is_empty():_profile_plazas();return
	var maximum:int=mini(config.height-2,config.room_max_size)|1
	for i in config.num_rooms:
		var height:int=maximum if i==0 else rng.randi_range(2,maxi(2,(maximum-1)/2))*2+1
		height=mini(height,config.height-2)
		var width:int=mini(maximum,height+rng.randi_range(0,3)*2)
		var x:int=1+2*rng.randi_range(0,maxi(0,(config.width-width-2)/2))
		var y:int=1+2*rng.randi_range(0,maxi(0,(config.height-height-2)/2))
		var plaza:=Rect2i(x,y,width,height);rooms.append(plaza)
		for py in range(y,y+height):
			for px in range(x,x+width):_carve(Vector2i(px,py))
func _platformer_frame() -> void:
	# Two-cell perimeter loop guarantees reversible ordinary-jump routes to all
	# doors. The interior retains Prim's random1/2width paths and braided plazas.
	for y in range(1,config.height-1):
		for x in range(1,config.width-1):
			if x<=2 or x>=config.width-3 or y==1 or y==config.height-2:_carve(Vector2i(x,y))
func _open_doors() -> void:
	for raw in config.doors:
		var direction:String={"top":"up","bottom":"down"}.get(str(raw),str(raw))
		var horizontal:bool=direction in ["up","down"]
		var dim:int=config.width if horizontal else config.height
		var value:int=int(config.doors[raw]);value=1+2*rng.randi_range(0,(dim-3)/2) if value<0 else clampi(value|1,1,dim-2)
		var at:Vector2i=Vector2i(value,0 if direction=="up" else config.height-1) if horizontal else Vector2i(0 if direction=="left" else config.width-1,value)
		doors[direction]=at;_carve(at)
		var inward:Vector2i={"up":Vector2i.DOWN,"down":Vector2i.UP,"left":Vector2i.RIGHT,"right":Vector2i.LEFT}[direction]
		var tangent:=Vector2i(1,0) if horizontal else Vector2i(0,1)
		for offset in range(-config.door_width/2,config.door_width/2+1):
			for depth in 3:_carve(at+tangent*offset+inward*depth)
func _braid() -> void:
	for y in range(1,config.height-1):
		for x in range(1,config.width-1):
			var at:=Vector2i(x,y)
			if not is_floor(at):continue
			var exits:int=0
			for direction in DIRS:
				if is_floor(at+direction):exits+=1
			if exits!=1 or rng.randf()>=config.braid_rate:continue
			var choices:Array[Vector2i]=[]
			for direction in DIRS:
				if _inside(at+direction*2) and not is_floor(at+direction) and is_floor(at+direction*2):choices.append(direction)
			if not choices.is_empty():
				var cut:Vector2i=at+choices[rng.randi_range(0,choices.size()-1)];_carve(cut);braided_walls.append(cut)
func validate() -> Array[String]:
	var errors:Array[String]=[];var count:int=0;var first:=Vector2i(-1,-1)
	for y in config.height:
		for x in config.width:
			if is_floor(Vector2i(x,y)):count+=1;first=Vector2i(x,y)
	var seen:Dictionary={first:true};var queue:Array[Vector2i]=[first];var cursor:int=0
	while cursor<queue.size():
		var at:Vector2i=queue[cursor];cursor+=1
		for direction in DIRS:
			var to:Vector2i=at+direction
			if is_floor(to) and not seen.has(to):seen[to]=true;queue.append(to)
	if seen.size()!=count:errors.append("Disconnected floor cells")
	for at:Vector2i in doors.values():
		if not seen.has(at):errors.append("Disconnected door")
	return errors
func populate_tilemap_layer(layer:TileMapLayer,offset:Vector2i=Vector2i.ZERO,wall_source:int=0,floor_source:int=0,wall_atlas:Vector2i=Vector2i.ZERO,floor_atlas:Vector2i=Vector2i(1,0)) -> void:
	for y in config.height:
		for x in config.width:layer.set_cell(offset+Vector2i(x,y),floor_source if grid[y][x]==FLOOR else wall_source,floor_atlas if grid[y][x]==FLOOR else wall_atlas)

func _profile_plazas() -> void:
	var profile:String=config.layout_profile
	var count:int={"pillars":0,"terraces":1,"twin_halls":2,"cavern":1,"shaft":1,"loops":1}.get(profile,1)
	for i in count:
		var h:int=config.height-2 if profile in ["cavern","shaft"] else (3 if rng.randf()<.6 else 5)
		if profile not in ["cavern","shaft"]:h=clampi(roundi(h*config.plaza_scale)|1,3,config.height-2)
		var w:int=3 if profile=="shaft" else (h if profile=="cavern" else rng.randi_range(2,3)*2+1)
		w=mini(w,config.width-6)
		var x:int=3+2*rng.randi_range(0,maxi(0,(config.width-w-6)/2))
		var y:int=1+2*rng.randi_range(0,maxi(0,(config.height-h-2)/2))
		var plaza:=Rect2i(x,y,w,h);rooms.append(plaza)
		for py in range(y,y+h):
			for px in range(x,x+w):_carve(Vector2i(px,py))

static func apply_profile(cfg:MazeConfig) -> void:
	if not cfg.layout_profile.is_empty():
		var profile:Dictionary={"pillars":{"straight":.4,"braid":.25,"width":"narrow"},"terraces":{"straight":.75,"braid":.45,"width":"random"},"twin_halls":{"straight":.55,"braid":.4,"width":"narrow"},"cavern":{"straight":.65,"braid":.75,"width":"wide"},"shaft":{"straight":.85,"braid":.3,"width":"narrow"},"loops":{"straight":.45,"braid":.85,"width":"random"}}[cfg.layout_profile]
		cfg.straight_bias=clampf(cfg.straight_bias+float(profile["straight"])-.55,.05,.98)
		cfg.braid_rate=clampf(cfg.braid_rate+float(profile["braid"])-.45,0,1)
		cfg.corridor_width_mode=profile["width"]

func _neighbors(at:Vector2i) -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for direction:Vector2i in DIRS:
		if is_floor(at+direction):result.append(at+direction)
	return result
func _long_reward_branch() -> void:
	# Reserve a walkable, one-cell-high side tunnel. Its11+cell stem survives
	# braiding. The outer lane still retains one full cell at the sealed end.
	if config.width<17 or config.height<9:return
	var candidates:Array[Dictionary]=[]
	for reverse:bool in [false,true]:
		for y in range(3,config.height-2,2):
			var cap_x:int=2 if reverse else config.width-3
			var cap_direction:String="left" if reverse else "right"
			if doors.has(cap_direction) and absi(doors[cap_direction].y-y)<=1:continue
			candidates.append({"reverse":reverse,"y":y,"cap_x":cap_x})
	if candidates.is_empty():return
	var choice:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)]
	var reverse:bool=choice["reverse"];var y:int=choice["y"];var cap_x:int=choice["cap_x"]
	var first:int=3 if not reverse else 2;var last:int=config.width-3 if not reverse else config.width-4
	for x in range(first,last+1):
		for row:int in [y-1,y+1]:grid[row][x]=WALL;protected_dead_end[Vector2i(x,row)]=true
	grid[y][cap_x]=WALL;protected_dead_end[Vector2i(cap_x,y)]=true
	for x in range(3,config.width-3):_carve(Vector2i(x,y))
	var mouth:=Vector2i(config.width-3 if reverse else 2,y);_carve(mouth)
	# Reconnect any previously carved Prim island around (never through) the
	# reserved walls. This keeps every existing door and floor cell connected.
	var seen:Dictionary=_flood(mouth)
	for row in config.height:
		for x in config.width:
			var target:=Vector2i(x,row)
			if not is_floor(target) or seen.has(target):continue
			var pending:Array[Vector2i]=[target];var previous:Dictionary={target:target};var found:=Vector2i(-1,-1);var cursor:int=0
			while cursor<pending.size():
				var at:Vector2i=pending[cursor];cursor+=1
				if seen.has(at):found=at;break
				for direction:Vector2i in DIRS:
					var next:Vector2i=at+direction
					if not _inside(next) or previous.has(next) or protected_dead_end.has(next):continue
					previous[next]=at;pending.append(next)
			if found.x<0:continue
			while found!=target:_carve(found);found=previous[found]
			_carve(target);seen=_flood(mouth)
func _flood(start:Vector2i) -> Dictionary:
	var seen:Dictionary={start:true};var pending:Array[Vector2i]=[start];var cursor:int=0
	while cursor<pending.size():
		var at:Vector2i=pending[cursor];cursor+=1
		for next:Vector2i in _neighbors(at):
			if not seen.has(next):seen[next]=true;pending.append(next)
	return seen
func _corridor_neighbors(at:Vector2i,stride:int) -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for direction:Vector2i in DIRS:
		var next:Vector2i=at+direction*stride
		if _inside(next) and is_floor(next) and is_floor(at+direction):result.append(next)
	return result
func _find_long_dead_ends() -> void:
	# Fine cells cover single-width passages; Prim's odd-cell centre graph
	# also covers double-width passages whose2x2floor cycles have no degree1
	# cell. Lengths are recorded in physical tile steps, not maze-node counts.
	for stride:int in [1,2]:
		for y in range(1,config.height-1,stride):
			for x in range(1,config.width-1,stride):
				var leaf:=Vector2i(x,y)
				if not is_floor(leaf) or _corridor_neighbors(leaf,stride).size()!=1:continue
				if doors.values().any(func(door:Vector2i)->bool:return absi(door.x-x)+absi(door.y-y)<=2):continue
				var path:Array[Vector2i]=[leaf];var previous:=Vector2i(-1,-1);var at:Vector2i=leaf
				while true:
					var options:Array[Vector2i]=_corridor_neighbors(at,stride);options.erase(previous)
					if options.size()!=1:break
					var next:Vector2i=options[0]
					if doors.values().any(func(door:Vector2i)->bool:return absi(door.x-next.x)+absi(door.y-next.y)<=1):break
					previous=at;at=next
					if _corridor_neighbors(at,stride).size()!=2:break
					if stride==2:path.append((previous+at)/2)
					path.append(at)
				if path.size()<10:continue
				if dead_end_rewards.any(func(reward:Dictionary)->bool:return Vector2(reward["cell"]).distance_to(Vector2(leaf))<3):continue
				dead_end_rewards.append({"cell":leaf,"length":path.size(),"path":path,"corridor_stride":stride})
