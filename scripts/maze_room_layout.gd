class_name MazeRoomLayout
extends RefCounted
const Maze=preload("res://scripts/custom_maze_generator.gd")
const Sanctuary=preload("res://scripts/sanctuary_room.gd")
const Routes=preload("res://scripts/maze_routes_v20.gd")
const Scale=preload("res://scripts/world_scale_v17.gd")
const Surfaces=preload("res://scripts/surface_art_v22.gd")
const TILE:float=Scale.TILE
const CELL:Vector2=Scale.CELL_SIZE
const CELL_Y:float=Scale.TILE_HEIGHT
const BOSS_ROOM_HEIGHT:float=720.0*1.5
static func generate(room:Dictionary,seed_value:int) -> Dictionary:
	var boss:bool=room["type"]=="boss"
	var safe:bool=room["type"] in ["start","merchant","reward"] or room.get("spring",false)
	var cfg:=Maze.MazeConfig.new();cfg.width=room["width"];cfg.height=room["height"];cfg.seed_value=room.get("maze_seed",seed_value)
	cfg.doors=room.get("doors_config",{}).duplicate();cfg.room_max_size=cfg.height-2;cfg.num_rooms=3;cfg.straight_bias=float(room.get("maze_config",{}).get("straight_bias",.70));cfg.braid_rate=float(room.get("maze_config",{}).get("braid_rate",.80));cfg.corridor_width_mode=str(room.get("maze_config",{}).get("corridor_width_mode","random"))
	if safe:cfg.width=Scale.SANCTUARY_GRID.x;cfg.height=Scale.SANCTUARY_GRID.y;cfg.doors=cfg.doors.duplicate()
	if boss:cfg.height=9
	var cell_y:float=BOSS_ROOM_HEIGHT/cfg.height if boss else (TILE if safe else CELL_Y)
	var cell_size:=Vector2(TILE,cell_y)
	var climb_step:float=90.0 if boss else (TILE if safe else Scale.CLIMB_STEP)
	for direction in cfg.doors:
		var dim:int=cfg.width if direction in ["top","bottom","up","down"] else cfg.height
		cfg.doors[direction]=clampi(int(cfg.doors[direction]),3,dim-4)
	cfg.layout_profile=str(room.get("layout_profile",""));cfg.plaza_scale=float(room.get("plaza_scale",1))
	Maze.apply_profile(cfg)
	cfg.platformer=true;cfg.dead_end_chance=clampf(float(room.get("maze_config",{}).get("dead_end_chance",.25)),.20,1.0)
	cfg.arena=safe or room["type"]=="boss" or room.get("practice_arena",false);cfg.num_rooms=1 if cfg.arena else 3
	var maze:=Maze.new(cfg);maze.generate()
	if room["type"]=="boss":
		# Raised cover keeps the floor and side portal approaches open.
		var y:int=cfg.height-6
		for cell in [Vector2i(4,y),Vector2i(4,y+1),Vector2i(5,y+1),Vector2i(cfg.width-5,y),Vector2i(cfg.width-5,y+1),Vector2i(cfg.width/2,y)]:
			maze.grid[cell.y][cell.x]=Maze.WALL
	var size:=Vector2(cfg.width,cfg.height)*cell_size;var floor_y:float=Vector2(0,size.y-cell_y).y
	var walls:Array[Rect2]=[];var platforms:Array[Rect2]=[];var one_way:Array[Rect2]=[];var navigation:Array[Rect2]=[]
	var solid_lookup:Dictionary={}
	# Merge matching horizontal wall runs vertically: small collision/render count.
	for y in cfg.height:
		var x:int=0
		while x<cfg.width:
			if maze.is_floor(Vector2i(x,y)):x+=1;continue
			var start:int=x
			while x<cfg.width and not maze.is_floor(Vector2i(x,y)):x+=1
			var key:=Vector2i(start,x-start)
			if solid_lookup.has(key):
				var index:int=solid_lookup[key];var prior:Rect2=walls[index]
				if is_equal_approx(prior.end.y,y*cell_y):prior.size.y+=cell_y;walls[index]=prior;continue
			solid_lookup[key]=walls.size();walls.append(Rect2(start*TILE,y*cell_y,(x-start)*TILE,cell_y))
	# Top faces are genuine support surfaces and remain destructible-prop anchors.
	for wall:Rect2 in walls:
		if wall.position.y<cell_y-.01:continue
		var y:int=roundi(wall.position.y/cell_y)-1;var x:int=int(wall.position.x/TILE)
		while x<int(wall.end.x/TILE):
			if not maze.is_floor(Vector2i(x,y)):x+=1;continue
			var start:int=x
			while x<int(wall.end.x/TILE) and maze.is_floor(Vector2i(x,y)):x+=1
			platforms.append(Rect2(start*TILE,wall.position.y,(x-start)*TILE,8))
	# Sparse random one-way ledges belong only to genuinely open6x6+plazas.
	var random:=RandomNumberGenerator.new();random.seed=cfg.seed_value+163
	var platform_voids:Array[Rect2]=[]
	if not safe:
		for plaza:Rect2i in maze.rooms:
			if plaza.size.x<=5 or plaza.size.y<=5:continue
			var area:=Rect2(Vector2(plaza.position)*cell_size,Vector2(plaza.size)*cell_size)
			for i in random.randi_range(1,3):
				var width:float=TILE*random.randi_range(1,4)
				var at:=Vector2(random.randf_range(area.position.x+36,area.end.x-width-36),random.randf_range(area.position.y+100,area.end.y-50))
				var ledge:=Rect2(at,Vector2(width,9))
				if walls.any(func(rock:Rect2)->bool:return rock.intersects(ledge.grow(1))):continue
				if one_way.any(func(other:Rect2)->bool:return absf(other.position.y-at.y)<96):continue
				one_way.append(ledge);platform_voids.append(area)
	var random_ledges:Array[Rect2]=one_way.duplicate()
	if cfg.arena and (not safe or not maze.doors.is_empty()):
		# Traversal ledges can be jumped through and dropped through. No thin solid
		# treads, floating solid perches or solid gallery remain anywhere in the room.
		for side in 2:
			var direction:String="left" if side==0 else "right"
			var anchor:float=(float(maze.doors[direction].y)+2)*cell_y if maze.doors.has(direction) else floor_y
			for level in range(-ceili(size.y/climb_step),ceili(size.y/climb_step)):
				var y:float=anchor+level*climb_step
				if y<192 or y>=floor_y-.01:continue
				var x:float=TILE if side==0 else size.x-TILE*3
				var ledge:=Rect2(x,y,TILE*2,9)
				one_way.append(ledge);navigation.append(ledge)
		var gallery:=Rect2(TILE,240.0 if boss else (192.0 if safe else cell_y),size.x-TILE*2,9)
		one_way.append(gallery);navigation.append(gallery)
	elif not safe:
		navigation=Routes.generate(maze,cfg.seed_value)
		one_way.append_array(navigation)
	platforms.append_array(one_way)
	var offset:=Vector2((size.x-1500)*.5,floor_y-1050)
	var pool:=Rect2()
	if safe:
		var furnished:Dictionary=Sanctuary.generate(room,seed_value) if room["type"]!="start" else {}
		if room["type"]=="start":
			for rect in [Rect2(222,954,TILE*3,18),Rect2(280,850,TILE*11,18)]:
				var authored:=Rect2(rect.position+offset,rect.size)
				navigation=navigation.filter(func(ledge:Rect2)->bool:return not ledge.intersects(authored))
				platforms.append(authored);one_way.append(authored)
			one_way=one_way.filter(func(ledge:Rect2)->bool:return not (ledge.size.y==9 and not navigation.has(ledge)))
		else:
			if room.get("spring",false):
				pool=Rect2(furnished["pool"].position+offset,furnished["pool"].size)
				# Replace arena floor under the bath with its authored wading steps.
				var replacement:Array[Rect2]=[]
				for wall:Rect2 in walls:
					if is_equal_approx(wall.position.y,floor_y) and wall.position.x<pool.end.x and wall.end.x>pool.position.x:
						if pool.position.x>wall.position.x:replacement.append(Rect2(wall.position.x,floor_y,pool.position.x-wall.position.x,size.y-floor_y))
						if wall.end.x>pool.end.x:replacement.append(Rect2(pool.end.x,floor_y,wall.end.x-pool.end.x,size.y-floor_y))
					else:replacement.append(wall)
				walls=replacement
				platforms=platforms.filter(func(rect:Rect2)->bool:return not (is_equal_approx(rect.position.y,floor_y) and rect.size.x>1000))
				for rect:Rect2 in furnished["platforms"]:
					if rect.position.y>=1000:
						var part:=Rect2(rect.position+offset,rect.size);walls.append(part);platforms.append(Rect2(part.position,Vector2(part.size.x,8)))
	# Bath steps are authored after the maze. Re-open portal shafts through
	# those solids as well, so furniture cannot silently seal a bottom exit.
	if maze.doors.has("down"):
		var cell:Vector2i=maze.doors["down"]
		walls=_subtract(walls,Rect2((cell.x-1)*TILE,size.y-cell_y*3,TILE*3,cell_y*3))
	walls.assign(walls.map(func(rect:Rect2)->Rect2:return rect.intersection(Rect2(Vector2.ZERO,size))))
	# Rebuild lower supports after carving the bath, including the outer floor
	# pieces beyond its central furniture area. Pool steps keep their exact x.
	platforms=platforms.filter(func(rect:Rect2)->bool:return rect.position.y<floor_y or one_way.has(rect))
	for wall:Rect2 in walls:
		if wall.position.y>=floor_y and wall.size.x>0:platforms.append(Rect2(wall.position,Vector2(wall.size.x,8)))
	var doors:Dictionary={};var spawn:Dictionary={};var reserved:Array[Rect2]=[]
	for direction in maze.doors:
		var cell:Vector2i=maze.doors[direction]
		var at:Vector2=(Vector2(cell)+Vector2(.5,1))*cell_size
		if direction=="left":at.x=18;at.y+=cell_y
		elif direction=="right":at.x=size.x-18;at.y+=cell_y
		elif direction=="up":at.y=20
		elif direction=="down":at.y=size.y-10
		doors[direction]=at;reserved.append(Rect2(at-Vector2(TILE*2.2,TILE*3),Vector2(TILE*4.4,TILE*4)))
		var inside:Vector2=(Vector2(cell)+Vector2(.5,1))*cell_size
		if direction=="left":inside.x=TILE*1.7;inside.y=at.y
		elif direction=="right":inside.x=size.x-TILE*1.7;inside.y=at.y
		elif direction=="up":inside.y=192
		elif direction=="down":inside.y=size.y-144;inside.x-=72
		# from_dir is the direction travelled, so entry is on its opposite edge.
		spawn[{"up":"down","down":"up","left":"right","right":"left"}[direction]]=inside
		if direction=="up":
			for y:float in ([192.0,240.0] if boss else ([192.0] if safe else [192.0,cell_y,cell_y+climb_step,cell_y+climb_step*2])):
				var step:=Rect2(inside.x-TILE,y,TILE*2,9)
				one_way.append(step);navigation.append(step);platforms.append(step)
		if direction=="down" and not boss and not safe:
			var step:=Rect2(inside.x-TILE,floor_y+climb_step,TILE*2,9)
			one_way.append(step);navigation.append(step);platforms.append(step)
		var ledge:Rect2
		if direction in ["up","down"]:ledge=Rect2(inside.x-TILE,96 if direction=="up" else size.y-144,TILE*2,9)
		else:ledge=Rect2(0 if direction=="left" else size.x-TILE*3,at.y,TILE*3,9)
		if not one_way.has(ledge):one_way.append(ledge);navigation.append(ledge);platforms.append(ledge)
	# Optional plaza ledges must not sit just above a mandatory jump tier and
	# steal its landing. Keep a clear48px vertical band on each navigation run.
	var interfering:Array=random_ledges.filter(func(rect:Rect2)->bool:return navigation.any(func(route:Rect2)->bool:return absf(rect.position.y-route.position.y)<48 and rect.end.x>route.position.x-18 and rect.position.x<route.end.x+18))
	var kept_voids:Array[Rect2]=[]
	for i in random_ledges.size():
		if not interfering.has(random_ledges[i]):kept_voids.append(platform_voids[i])
	platform_voids=kept_voids
	one_way=one_way.filter(func(rect:Rect2)->bool:return not interfering.has(rect))
	platforms=platforms.filter(func(rect:Rect2)->bool:return not interfering.has(rect))
	random_ledges=random_ledges.filter(func(rect:Rect2)->bool:return not interfering.has(rect))
	# Every pass-through collision module has the same1/2/3/4cell length as
	# its authored image. Long route bridges are adjacent modules, preserving
	# their complete support span without stretching a small bitmap.
	var old_one_way:Array[Rect2]=one_way.duplicate()
	var runs:Array[Rect2]=_merge_platforms(one_way)
	one_way=_split_platforms(runs)
	navigation=one_way.filter(func(part:Rect2)->bool:return navigation.any(func(route:Rect2)->bool:return absf(part.position.y-route.position.y)<1 and part.end.x>route.position.x and part.position.x<route.end.x))
	platforms=platforms.filter(func(rect:Rect2)->bool:return not old_one_way.has(rect))
	platforms.append_array(one_way)
	var center:=Vector2(offset.x+230,floor_y) if safe else Vector2(TILE*1.5,cell_y*2)
	if not safe:
		# The reserved lower-left perimeter lane is clear;3+odd bottom doors
		# cannot remove its support. Keep the whole34px body beyond the wall.
		center=Vector2(TILE*2,floor_y)
	var center_found:bool=false
	for surface:Rect2 in platforms:
		if not is_equal_approx(surface.position.y,floor_y) or surface.size.x<48:continue
		for cx in range(int(surface.position.x+24),int(surface.end.x-20),24):
			var candidate:=Vector2(cx,floor_y);var body:=Rect2(candidate-Vector2(17,42),Vector2(34,41.9))
			if walls.any(func(rect:Rect2)->bool:return rect.intersects(body)):continue
			center=candidate;center_found=true;break
		if center_found:break
	spawn["center"]=center
	var enemy_spawns:Array[Vector2]=[]
	for surface:Rect2 in platforms:
		if surface.size.x<80 or surface.position.y<100:continue
		for x in range(int(surface.position.x+42),int(surface.end.x-30),100):
			var at:=Vector2(x,surface.position.y);var body:=Rect2(at-Vector2(22,48),Vector2(44,47))
			if walls.any(func(rect:Rect2)->bool:return rect.intersects(body)):continue
			if reserved.any(func(rect:Rect2)->bool:return rect.has_point(at)):continue
			if enemy_spawns.any(func(other:Vector2)->bool:return other.distance_to(at)<80):continue
			enemy_spawns.append(at)
	return {"size":size,"floor_y":floor_y,"ceiling_y":0.0,"single_screen":safe,"furniture_offset":offset if safe else Vector2.ZERO,"pool":pool,"platforms":platforms,"one_way":one_way,"platform_art_runs":runs,"random_one_way":random_ledges,"navigation_one_way":navigation,"platform_voids":platform_voids,"door_width":3,"solids":walls,"walls":walls,"blocks":[],"trunks":[],"shapes":[],"doors":doors,"spawn_positions":spawn,"enemy_spawns":enemy_spawns,"ground_spawns":enemy_spawns.filter(func(at:Vector2)->bool:return not one_way.any(func(ledge:Rect2)->bool:return absf(ledge.position.y-at.y)<1 and at.x>=ledge.position.x and at.x<=ledge.end.x)),"reserved_regions":reserved,"decorations":[],"route_indices":[],"archetype":"stitched_arena" if cfg.arena else (cfg.layout_profile if not cfg.layout_profile.is_empty() else "braided_prim"),"seed":cfg.seed_value,"launcher_spawns":_launcher_spawns(maze.rooms,platforms,walls,reserved) if not safe else [],"dead_end_rewards":maze.dead_end_rewards,"maze_grid":maze.grid,"maze_doors":maze.doors,"maze_plazas":maze.rooms,"tile_size":TILE,"tile_height":cell_y,"generation_order":["topology","stitched_doors","prim","plazas","braiding","pass_through_routes"]}
static func validate(layout:Dictionary) -> Array[String]:
	var errors:Array[String]=[];var size:Vector2=layout["size"]
	for rect:Rect2 in layout["solids"]:
		if rect.position.x<0 or rect.position.y<0 or rect.end.x>size.x+.01 or rect.end.y>size.y+.01:errors.append("Solid outside room")
	for key in layout["spawn_positions"]:
		var at:Vector2=layout["spawn_positions"][key];var body:=Rect2(at-Vector2(17,42),Vector2(34,41.9))
		if layout["solids"].any(func(rect:Rect2)->bool:return rect.intersects(body)):errors.append("Entry %s overlaps rock"%key)
	return errors

static func _merge_platforms(items:Array[Rect2]) -> Array[Rect2]:
	var sorted:Array[Rect2]=items.duplicate()
	sorted.sort_custom(func(a:Rect2,b:Rect2)->bool:return a.position.y<b.position.y if not is_equal_approx(a.position.y,b.position.y) else a.position.x<b.position.x)
	var runs:Array[Rect2]=[]
	for rect:Rect2 in sorted:
		if not runs.is_empty() and absf(runs[-1].position.y-rect.position.y)<.5 and rect.position.x<=runs[-1].end.x+.5:
			var end:float=maxf(runs[-1].end.x,rect.end.x);runs[-1].size.x=end-runs[-1].position.x;runs[-1].size.y=maxf(runs[-1].size.y,rect.size.y)
		else:runs.append(rect)
	return runs

static func _split_platforms(items:Array[Rect2]) -> Array[Rect2]:
	var result:Array[Rect2]=[]
	for rect:Rect2 in items:
		for part:Rect2 in Surfaces.platform_parts(rect):
			if not result.has(part):result.append(part)
	return result

static func _subtract(rectangles:Array[Rect2],cut:Rect2) -> Array[Rect2]:
	var result:Array[Rect2]=[]
	for rect:Rect2 in rectangles:
		var overlap:Rect2=rect.intersection(cut)
		if not overlap.has_area():result.append(rect);continue
		if overlap.position.x>rect.position.x:result.append(Rect2(rect.position,Vector2(overlap.position.x-rect.position.x,rect.size.y)))
		if overlap.end.x<rect.end.x:result.append(Rect2(overlap.end.x,rect.position.y,rect.end.x-overlap.end.x,rect.size.y))
		if overlap.position.y>rect.position.y:result.append(Rect2(overlap.position.x,rect.position.y,overlap.size.x,overlap.position.y-rect.position.y))
		if overlap.end.y<rect.end.y:result.append(Rect2(overlap.position.x,overlap.end.y,overlap.size.x,rect.end.y-overlap.end.y))
	return result

static func _launcher_spawns(plazas:Array,platforms:Array,solids:Array,reserved:Array) -> Array[Vector2]:
	var result:Array[Vector2]=[]
	for plaza:Rect2i in plazas:
		if plaza.size.x<=5 or plaza.size.y<=5:continue
		var area:=Rect2(Vector2(plaza.position)*CELL,Vector2(plaza.size)*CELL)
		var best:=Vector2.INF;var cost:float=INF
		for surface:Rect2 in platforms:
			if surface.position.y<area.position.y+192 or surface.position.y>area.end.y+1:continue
			var lo:float=maxf(surface.position.x+48,area.position.x+48);var hi:float=minf(surface.end.x-48,area.end.x-48)
			if hi<lo:continue
			var at:=Vector2(clampf(area.get_center().x,lo,hi),surface.position.y)
			if solids.any(func(rock:Rect2)->bool:return rock.intersects(Rect2(at-Vector2(46,400),Vector2(92,399.9)))):continue
			if reserved.any(func(zone:Rect2)->bool:return zone.grow(48).has_point(at)):continue
			var score:float=absf(at.x-area.get_center().x)+absf(at.y-area.end.y)*.3
			if score<cost:cost=score;best=at
		if best.is_finite() and not result.any(func(at:Vector2)->bool:return at.distance_to(best)<160):result.append(best)
	return result
