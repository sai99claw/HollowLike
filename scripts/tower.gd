class_name TowerGenerator
extends RefCounted
## Six connected chapters, seeded independently of art and player state.
const MAP_COUNT:=6
const MIN_ROOMS:=6
const MAX_ROOMS:=12
const DEFAULT_MIN_ROOMS:=9
const DEFAULT_MAX_ROOMS:=11
const REWARD_CHANCE:=.70
const VERTICAL_BIAS:=.68
const STRAIGHT_BIAS:=.55
const BRAID_RATE:=.45
const Scale=preload("res://scripts/world_scale_v17.gd")
const TILE_SIZE:=Scale.TILE
const WIDTHS:=Scale.WIDTHS
const HEIGHTS:=Scale.HEIGHTS
const DIRECTIONS:Array[String]=["up","down","left","right"]
const DELTAS:={"up":Vector2i(0,-1),"down":Vector2i(0,1),"left":Vector2i(-1,0),"right":Vector2i(1,0)}
const OPPOSITE:={"up":"down","down":"up","left":"right","right":"left"}
const STAGE_NAMES:=["根底迴廊","琥珀根宮","青苔樹幹","翠枝迴旋","蒼藍雲海","天空王座"]
var total_stages:int=6
var rooms_per_stage:int=10
var vertical_bias:float=VERTICAL_BIAS
var straight_bias:float=STRAIGHT_BIAS
var braid_rate:float=BRAID_RATE
var corridor_width_mode:String="random"
var world_room_map:Dictionary={}
var stages:Array=[]
var all_rooms:Array=[]
func _init(count:int=6,per_stage:int=10) -> void:
	total_stages=clampi(count,1,6);rooms_per_stage=clampi(per_stage,6,12)
func generate_tower(seed_value:int=0) -> void:
	var result:Dictionary=generate(seed_value,total_stages,rooms_per_stage,{"vertical_bias":vertical_bias,"straight_bias":straight_bias,"braid_rate":braid_rate,"corridor_width_mode":corridor_width_mode})
	stages=result["maps"];all_rooms=result["rooms"];world_room_map.clear()
	for room in all_rooms:world_room_map[room["coord"]]=room
func populate_full_tower_to_tilemap_layer(layer:TileMapLayer) -> void:
	var Maze=load("res://scripts/custom_maze_generator.gd")
	for room in all_rooms:
		var cfg=Maze.MazeConfig.new();cfg.width=room["width"];cfg.height=room["height"];cfg.doors=room["doors_config"].duplicate();cfg.seed_value=room["maze_seed"];cfg.room_max_size=cfg.height-2;cfg.platformer=true;cfg.arena=room["type"] in ["start","merchant","reward","boss"];cfg.num_rooms=1 if cfg.arena else 3
		cfg.straight_bias=room["maze_config"]["straight_bias"];cfg.braid_rate=room["maze_config"]["braid_rate"];cfg.corridor_width_mode=room["maze_config"]["corridor_width_mode"]
		cfg.layout_profile=str(room.get("layout_profile",""));cfg.plaza_scale=float(room.get("plaza_scale",1))
		Maze.apply_profile(cfg);cfg.dead_end_chance=float(room["maze_config"].get("dead_end_chance",.25))
		var maze=Maze.new(cfg);maze.generate();maze.populate_tilemap_layer(layer,room["world_tile_pos"])

static func generate(seed_value:int,stage_count:int=6,per_stage:int=0,options:Dictionary={}) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var vertical_weight:float=clampf(float(options.get("vertical_bias",VERTICAL_BIAS)),0,1)
	var braid_weight:float=clampf(float(options.get("braid_rate",BRAID_RATE)),0,1)
	var maze_settings:Dictionary={"straight_bias":clampf(float(options.get("straight_bias",STRAIGHT_BIAS)),0,1),"braid_rate":braid_weight,"corridor_width_mode":str(options.get("corridor_width_mode","random")),"dead_end_chance":clampf(float(options.get("dead_end_chance",.25)),.20,1.0)}
	var rooms:Array[Dictionary]=[];var maps:Array[Dictionary]=[];var occupied:Dictionary={}
	var start:=Vector2i.ZERO;var previous_boss:int=-1
	var progression_side:int=1 if rng.randf()<.5 else -1
	for stage_index in stage_count:
		var desired:int=clampi(per_stage,MIN_ROOMS,MAX_ROOMS) if per_stage>0 else rng.randi_range(DEFAULT_MIN_ROOMS,DEFAULT_MAX_ROOMS)
		var coords:Array[Vector2i]=[start];var edges:Array[Vector2i]=[];var local:Dictionary={start:0};var depths:Array[int]=[0]
		var side:int=progression_side
		var spine:int=maxi(4,ceili(desired*.65))
		# A monotone upward spine plus bounded-depth side branches makes the
		# terminal Boss the unique farthest room, even after safe optional loops.
		for step in range(1,spine):
			var delta:Vector2i=Vector2i(side,0) if step<=2 else (Vector2i.UP if step==3 or rng.randf()<vertical_weight else Vector2i(side,0))
			var candidate:Vector2i=coords[-1]+delta
			if occupied.has(candidate) or local.has(candidate):candidate=coords[-1]+Vector2i.UP
			local[candidate]=coords.size();edges.append(Vector2i(coords.size()-1,coords.size()));coords.append(candidate);depths.append(step)
		var endpoint:Vector2i=coords[-1]
		# Reserve one horizontal leaf off the first combat room. The first two
		# spine edges form Start -> Merchant -> Combat; these safe rooms never
		# acquire vertical branches. Keep true world adjacency and map geometry.
		var reward_leaf:int=coords.size()
		var leaf:Vector2i=coords[2]+Vector2i(side,0)
		assert(not occupied.has(leaf) and not local.has(leaf))
		local[leaf]=coords.size();edges.append(Vector2i(2,coords.size()));coords.append(leaf);depths.append(3)
		var attempts:int=0
		while coords.size()<desired-1:
			attempts+=1
			assert(attempts<10000,"Stage branch capacity exhausted")
			var parent:int=rng.randi_range(0,coords.size()-1)
			if parent in [0,1,reward_leaf] or depths[parent]>=spine-2:continue
			var delta:Vector2i=DELTAS[DIRECTIONS[rng.randi_range(0,3)]]
			var candidate:Vector2i=coords[parent]+delta
			if occupied.has(candidate) or local.has(candidate) or candidate.y<endpoint.y or candidate.x*side>endpoint.x*side:continue
			local[candidate]=coords.size();edges.append(Vector2i(parent,coords.size()));coords.append(candidate);depths.append(depths[parent]+1)
		var boss_local:int=coords.size()
		var boss_coord:Vector2i=endpoint+Vector2i(side,0)
		edges.append(Vector2i(spine-1,boss_local));coords.append(boss_coord);local[boss_coord]=boss_local;depths.append(spine)
		var offset:int=rooms.size();var ids:Array[int]=[]
		for j in coords.size():
			var id:int=rooms.size();ids.append(id);occupied[coords[j]]=id
			rooms.append({"id":id,"coord":coords[j],"map_index":stage_index,"stage_number":stage_index+1,"type":"start" if j==0 else ("boss" if j==boss_local else "combat"),"neighbors":{},"doors_config":{},"spring":false,"visited":false,"cleared":false,"reward_claimed":false,"initialized":false,"enemies":[],"drops":[],"maze_seed":seed_value*931+id*1741+32,"maze_config":maze_settings.duplicate(),"biome_id":["underground","trunk","sky"][mini(2,stage_index/2)]})
		for edge in edges:_connect(rooms,offset+edge.x,offset+edge.y)
		# Equal-depth neighbours can braid without shortening the spine.
		for j in range(ids.size()-1):
			if rng.randf()>=braid_weight:continue
			for direction:String in DIRECTIONS:
				var adjacent:Vector2i=coords[j]+DELTAS[direction]
				if not local.has(adjacent):continue
				var k:int=local[adjacent]
				if k==boss_local or j in [0,1,reward_leaf] or k in [0,1,reward_leaf] or absi(depths[j]-depths[k])>1:continue
				if not rooms[ids[j]]["neighbors"].has(direction):_connect(rooms,ids[j],ids[k]);break
		if previous_boss>=0:_connect(rooms,previous_boss,offset)
		var candidates:Array[int]=[]
		for id in ids:
			if rooms[id]["type"]=="combat":candidates.append(id)
		var merchant:int=-1
		if rng.randf()<float(options.get("merchant_chance",.50)):
			merchant=offset+1;candidates.erase(merchant);rooms[merchant]["type"]="merchant"
		var reward:int=-1;var spring:int=-1
		if rng.randf()<float(options.get("reward_chance",REWARD_CHANCE)) and not candidates.is_empty():reward=offset+reward_leaf;candidates.erase(reward);rooms[reward]["type"]="reward"
		# Dedicated spring rooms are retired; fountain rolls happen per hostile room.
		previous_boss=offset+boss_local
		maps.append({"index":stage_index,"stage_number":stage_index+1,"stage_name":STAGE_NAMES[stage_index],"start_id":offset,"boss_id":previous_boss,"merchant_id":merchant,"reward_id":reward,"spring_id":spring,"room_ids":ids})
		start=rooms[previous_boss]["coord"]+Vector2i(side,0)
	var profile_bag:Array=[];var last_profile:String=""
	for rm:Dictionary in rooms:
		if rm["type"]!="combat" or rm.get("spring",false):continue
		if profile_bag.is_empty():
			profile_bag=["pillars","terraces","twin_halls","cavern","shaft","loops"]
			for j in range(profile_bag.size()-1,0,-1):
				var k:int=rng.randi_range(0,j);var held:Variant=profile_bag[j];profile_bag[j]=profile_bag[k];profile_bag[k]=held
			if profile_bag[-1]==last_profile:
				var first:Variant=profile_bag[0];profile_bag[0]=profile_bag[-1];profile_bag[-1]=first
		rm["layout_profile"]=profile_bag.pop_back();last_profile=rm["layout_profile"]
		rm["plaza_scale"]=clampf(float(options.get("plaza_scale",1)),.5,1.5)
	# Every complete group of five hostile combat rooms contains one elite room.
	# Keep its layout profile/maze behavior; the type changes its encounter only.
	var hostile:Array=rooms.filter(func(rm:Dictionary)->bool:return rm["type"]=="combat" and not rm.get("spring",false))
	for first in range(0,hostile.size()-4,5):
		var chosen:int=first+rng.randi_range(0,4);hostile[chosen]["type"]="elite";hostile[chosen]["elite_encounter"]=true
	for rm:Dictionary in rooms:
		rm["fountain"]=rm["type"] in ["combat","elite"] and rng.randf()<float(options.get("fountain_chance",.10))
	_assign_dimensions(rooms,rng,float(options.get("room_scale",1)))
	for rm in rooms:
		for direction in rm["neighbors"]:
			var other:Dictionary=rooms[rm["neighbors"][direction]]
			if rm["doors_config"].has(direction):continue
			var dim:int=rm["width"] if direction in ["up","down"] else rm["height"]
			var value:int=3+2*rng.randi_range(0,maxi(0,(dim-7)/2))
			if direction in ["up","down"] and (rm.get("spring",false) or other.get("spring",false)):value=dim-4
			if direction in ["left","right"] and (rm["type"] in ["start","merchant","reward"] or other["type"] in ["start","merchant","reward"]):value=dim-4
			rm["doors_config"][direction]=value;other["doors_config"][OPPOSITE[direction]]=value
	return {"rooms":rooms,"maps":maps,"seed":seed_value,"version":34,"tile_size":TILE_SIZE,"straight_bias":maze_settings["straight_bias"],"braid_rate":braid_weight,"vertical_bias":vertical_weight}

static func _assign_dimensions(rooms:Array[Dictionary],rng:RandomNumberGenerator,room_scale:float=1) -> void:
	var bounds:Rect2i=_bounds(rooms.map(func(r:Dictionary)->Vector2i:return r["coord"]))
	var widths:Dictionary={};var heights:Dictionary={};var xs:Dictionary={};var ys:Dictionary={};var at:int=0
	var safe_columns:Dictionary={};var safe_rows:Dictionary={}
	for room:Dictionary in rooms:
		if room["type"] in ["start","merchant","reward"] or room.get("spring",false):safe_columns[room["coord"].x]=true;safe_rows[room["coord"].y]=true
	# Equal column widths / row heights stitch independently random rectangles.
	for x in range(bounds.position.x,bounds.end.x+1):widths[x]=maxi(17,roundi(WIDTHS[rng.randi_range(0,WIDTHS.size()-1)]*room_scale)|1);widths[x]=17 if safe_columns.has(x) else widths[x];xs[x]=at;at+=widths[x]-1
	at=0
	for y in range(bounds.position.y,bounds.end.y+1):heights[y]=clampi(roundi(HEIGHTS[rng.randi_range(0,HEIGHTS.size()-1)]*room_scale)|1,9,15);heights[y]=11 if safe_rows.has(y) else heights[y];ys[y]=at;at+=heights[y]-1
	var origin:Vector2i=Vector2i(xs.get(0,0),ys.get(0,0))
	for room in rooms:
		var coord:Vector2i=room["coord"];room["width"]=widths[coord.x];room["height"]=heights[coord.y]
		room["world_tile_pos"]=Vector2i(xs[coord.x],ys[coord.y])-origin
		room["world_pixel_pos"]=room["world_tile_pos"]*TILE_SIZE

static func _connect(rooms:Array[Dictionary],first_id:int,second_id:int) -> void:
	var delta:Vector2i=rooms[second_id]["coord"]-rooms[first_id]["coord"]
	for dir in DIRECTIONS:
		if delta==DELTAS[dir]:rooms[first_id]["neighbors"][dir]=second_id;rooms[second_id]["neighbors"][OPPOSITE[dir]]=first_id;return
	assert(false,"Nonadjacent room edge")
static func _bounds(coords:Array) -> Rect2i:
	var lo:Vector2i=coords[0];var hi:Vector2i=coords[0]
	for at:Vector2i in coords:lo=lo.min(at);hi=hi.max(at)
	return Rect2i(lo,hi-lo)
static func _outward_directions(coord:Vector2i,bounds:Rect2i) -> Array:
	var result:Array=[]
	if coord.y==bounds.position.y:result.append("up")
	if coord.y==bounds.end.y:result.append("down")
	if coord.x==bounds.position.x:result.append("left")
	if coord.x==bounds.end.x:result.append("right")
	return result

static func validate(tower: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var rooms: Array = tower.get("rooms", [])
	var maps: Array = tower.get("maps", [])
	if maps.size() != MAP_COUNT:
		errors.append("Expected six maps")
	if rooms.is_empty():
		errors.append("Tower contains no rooms")
		return errors
	var occupied: Dictionary = {}
	for room_index in range(rooms.size()):
		var room: Dictionary = rooms[room_index]
		if room.get("id", -1) != room_index:
			errors.append("Room IDs must be contiguous array indices")
		var coord: Vector2i = room["coord"]
		if occupied.has(coord):
			errors.append("Overlapping room at %s" % str(coord))
		occupied[coord] = room_index
		for direction in room.get("neighbors", {}):
			var target: int = room["neighbors"][direction]
			if not DELTAS.has(direction) or target < 0 or target >= rooms.size():
				errors.append("Invalid neighbor on room %d" % room_index)
				continue
			if rooms[target]["coord"] != coord + DELTAS[direction]:
				errors.append("Nonadjacent door on room %d" % room_index)
			if rooms[target]["neighbors"].get(OPPOSITE[direction], -1) != room_index:
				errors.append("Nonreciprocal door on room %d" % room_index)
			if room["map_index"] != rooms[target]["map_index"]:
				var low: int = mini(room["map_index"], rooms[target]["map_index"])
				var high: int = maxi(room["map_index"], rooms[target]["map_index"])
				if high != low + 1 or low < 0 or high >= maps.size():
					errors.append("Unexpected cross-map shortcut")
				elif not ((room_index == maps[low]["boss_id"] and target == maps[high]["start_id"]) or (target == maps[low]["boss_id"] and room_index == maps[high]["start_id"])):
					errors.append("Cross-map door is not boss to next start")
	for map_index in range(maps.size()):
		var map_data: Dictionary = maps[map_index]
		var start_id: int = map_data["start_id"]
		var boss_id: int = map_data["boss_id"]
		var ids: Array[int] = []
		var coords: Array[Vector2i] = []
		var rewards := 0
		for room in rooms:
			if room["map_index"] == map_index:
				ids.append(room["id"])
				coords.append(room["coord"])
				if room["type"] == "reward":
					rewards += 1
		if ids.size() < MIN_ROOMS or ids.size() > MAX_ROOMS:
			errors.append("Map %d room count out of range" % map_index)
		if not ids.has(start_id) or not ids.has(boss_id):
			errors.append("Map %d start/boss metadata invalid" % map_index)
			continue
		if rooms[start_id]["type"] != "start" or rooms[boss_id]["type"] != "boss":
			errors.append("Map %d start/boss room type invalid" % map_index)
		if rewards > 1:
			errors.append("Map %d has more than one reward room" % map_index)
		var reward_id: int = map_data.get("reward_id", -1)
		if (reward_id == -1 and rewards != 0) or (reward_id != -1 and (not ids.has(reward_id) or rooms[reward_id]["type"] != "reward")):
			errors.append("Map %d reward metadata invalid" % map_index)
		if _reachable(rooms, start_id, map_index).size() != ids.size():
			errors.append("Map %d is disconnected" % map_index)
		if _outward_directions(rooms[boss_id]["coord"], _bounds(coords)).is_empty():
			errors.append("Map %d boss is not on its perimeter" % map_index)
		var local_boss_degree := 0
		for target in rooms[boss_id]["neighbors"].values():
			if rooms[target]["map_index"] == map_index:
				local_boss_degree += 1
		if local_boss_degree < 1:
			errors.append("Map %d boss has no approach" % map_index)
		var distances:Dictionary=_distances(rooms,start_id,map_index)
		for rid:int in ids:
			if rid!=boss_id and int(distances.get(rid,999))>=int(distances.get(boss_id,-1)):errors.append("Boss must be the unique farthest room")
		for direction:String in rooms[boss_id]["neighbors"]:
			if direction not in ["left","right"]:errors.append("Boss doors must be horizontal")
		if local_boss_degree!=1:errors.append("Boss must have one local entrance")
		if map_index > 0:
			var previous_boss: int = maps[map_index - 1]["boss_id"]
			if not rooms[previous_boss]["neighbors"].values().has(start_id):
				errors.append("Map %d does not follow previous boss" % map_index)
	if _reachable(rooms, maps[0]["start_id"] if not maps.is_empty() else 0).size() != rooms.size():
		errors.append("Tower is disconnected")
	return errors


static func _reachable(rooms: Array, start_id: int, only_map: int = -1) -> Dictionary:
	var seen: Dictionary = {start_id: true}
	var pending: Array[int] = [start_id]
	while not pending.is_empty():
		var room_id: int = pending.pop_back()
		for target in rooms[room_id]["neighbors"].values():
			if target < 0 or target >= rooms.size() or seen.has(target):
				continue
			if only_map >= 0 and rooms[target]["map_index"] != only_map:
				continue
			seen[target] = true
			pending.append(target)
	return seen

static func _distances(rooms:Array,start_id:int,only_map:int) -> Dictionary:
	var result:Dictionary={start_id:0};var queue:Array[int]=[start_id];var cursor:int=0
	while cursor<queue.size():
		var id:int=queue[cursor];cursor+=1
		for next:int in rooms[id]["neighbors"].values():
			if rooms[next]["map_index"]!=only_map or result.has(next):continue
			result[next]=int(result[id])+1;queue.append(next)
	return result
