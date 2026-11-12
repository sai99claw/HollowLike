class_name RoomLayout
extends RefCounted
## Seeded room geometry. All positions are feet / platform top anchors.
## The maze layout uses rock climbing and mushroom launches for tall links.

const MazeLayout=preload("res://scripts/maze_room_layout.gd")
const Sanctuary=preload("res://scripts/sanctuary_room.gd")
const WIDTH := 1500.0
const FLOOR := 1050.0
const TOP := 210.0
const DOOR_ANCHORS := {
	"left": Vector2(58, FLOOR), "right": Vector2(WIDTH - 58, FLOOR),
	"up": Vector2(740, TOP), "down": Vector2(1000, FLOOR)
}
const ARCHETYPES: Array[String] = ["winding_branches", "split_canopy", "left_shelves", "right_shelves"]


static func generate(room:Dictionary,adventure_seed:int=0) -> Dictionary:
	if room.has("width"):return MazeLayout.generate(room,adventure_seed)
	if Sanctuary.is_sanctuary(room):return Sanctuary.generate(room,adventure_seed)
	# Explicit order: solid squares -> trunks -> platforms -> connectivity check.
	var rng:=RandomNumberGenerator.new();rng.seed=absi(adventure_seed*931+int(room.get("id",0))*1741+32)
	for attempt in 24:
		var blocks:Array[Rect2]=[];var trunks:Array[Rect2]=[]
		var boss:bool=room.get("type","")=="boss"
		var start:bool=room.get("type","")=="start"
		var shapes:Array[Dictionary]=[]
		if boss or start:
			for i in (rng.randi_range(0,2) if boss else 0):
				var edge:float=rng.randf_range(65,90)
				var x:float=(550+i*390) if boss else (1050+i*150)
				blocks.append(Rect2(x,rng.randf_range(870,900) if start else rng.randf_range(620,740),edge,edge))
			for i in 2:
				var trunk:=Rect2(620+i*280 if boss else (72 if i==0 else 1390),380.0 if start else rng.randf_range(330,390),38,rng.randf_range(170,215))
				if not blocks.any(func(block:Rect2)->bool:return trunk.grow(12).intersects(block)):trunks.append(trunk)
		else:
			# Full solids are selected before the jump route, so navigation can avoid them.
			for i in 2:
				trunks.append(Rect2(48 if i==0 else 1414,285+i*38,38,rng.randf_range(180,245)))
			var left:bool=rng.randf()<.5
			var stem:=Rect2(18 if left else 1450,rng.randf_range(520,565),32,rng.randf_range(180,235))
			var foot:=Rect2(stem.end.x if left else stem.position.x-78,stem.end.y-38,78,38)
			trunks.append(stem);trunks.append(foot)
			shapes.append({"kind":"L","parts":[stem,foot]})
			for i in rng.randi_range(3,4):
				var edge:float=rng.randf_range(68,102)
				var block:=Rect2(40 if i%2==0 else 1360,220+floori(float(i)/2)*410+rng.randf_range(-25,25),edge,edge)
				if not trunks.any(func(trunk:Rect2)->bool:return block.grow(8).intersects(trunk)):blocks.append(block)
		if trunks.size()<2:continue
		for block in blocks:shapes.append({"kind":"square","parts":[block]})
		for trunk in trunks:
			if trunk.size.y>trunk.size.x*2:shapes.append({"kind":"vertical","parts":[trunk]})
		var request:Dictionary=room.duplicate();var excluded:Array[Rect2]=[]
		for box in blocks+trunks:excluded.append(box.grow(6))
		request["_terrain_regions"]=excluded
		var result:Dictionary=_platform_layout(request,adventure_seed+attempt*173)
		result["blocks"]=blocks;result["trunks"]=trunks;result["shapes"]=shapes
		result["generation_order"]=["blocks","trunks","platforms","passability"]
		result["ceiling_y"]=0.0
		result["walls"]=_walls(room)
		# Floor openings are physical, not painted over a continuous collider.
		if room.get("neighbors",{}).has("down"):
			var floors:Array[Rect2]=[Rect2(0,FLOOR,945,70),Rect2(1055,FLOOR,445,70)]
			result["platforms"][0]=floors[0];result["platforms"].append(floors[1])
			result["doors"]["down"]=Vector2(1000,1085)
		if result["doors"].has("up"):
			result["doors"]["up"]=Vector2(740,result["ceiling_y"]+20)
			if not start:
				# The last ordinary jump must reach the actual opening, not just TOP.
				result["platforms"].append(Rect2(595,110,290,21))
		result["solids"]=blocks+trunks+result["walls"]
		for platform:Rect2 in result["platforms"]:
			if platform.position.y==FLOOR:result["solids"].append(platform)
		result["enemy_spawns"]=_spawn_slots(result["platforms"],result["reserved_regions"])
		result["decorations"]=_decorations(result["platforms"],rng)
		if validate(result).is_empty():
			if not boss and not start:_add_supported_shapes(result,rng)
			return result
	push_error("Unable to generate traversable solid terrain")
	return {}

static func _walls(room:Dictionary) -> Array[Rect2]:
	var neighbors:Dictionary=room.get("neighbors",{})
	var result:Array[Rect2]=[]
	for side in ["left","right"]:
		var x:float=0 if side=="left" else WIDTH-18
		if neighbors.has(side):result.append(Rect2(x,0,18,900));result.append(Rect2(x,1050,18,70))
		else:result.append(Rect2(x,0,18,1120))
	var ceiling:float=0
	if neighbors.has("up"):result.append(Rect2(0,ceiling,665,18));result.append(Rect2(815,ceiling,685,18))
	else:result.append(Rect2(0,ceiling,WIDTH,18))
	if neighbors.has("down"):result.append(Rect2(0,1102,945,18));result.append(Rect2(1055,1102,445,18))
	else:result.append(Rect2(0,1102,WIDTH,18))
	return result

static func _decorations(platforms:Array,rng:RandomNumberGenerator) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var modules:Array=["foliage","fern","hanging_root"]
	for platform:Rect2 in platforms:
		if rng.randf()<.65:
			var width:float=rng.randf_range(45,82)
			result.append({"id":modules[rng.randi_range(0,2)],"rect":Rect2(platform.position+Vector2(rng.randf_range(12,maxf(13,platform.size.x-width)), -width*.8),Vector2(width,width))})
	return result


static func _platform_layout(room: Dictionary, adventure_seed: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	var coord: Vector2i = room.get("coord", Vector2i.ZERO)
	rng.seed = absi(adventure_seed * 73856093 + int(room.get("id", 0)) * 19349663 + coord.x * 83492791 + coord.y * 26544357 + 617)
	if room.get("type", "combat") == "start":
		return _start_layout(room, rng)
	if room.get("type", "combat") == "boss":
		return _boss_layout(room, rng)
	var variant := rng.randi_range(0, ARCHETYPES.size() - 1)
	var reserved := _reserved(room)
	var platforms: Array[Rect2] = [Rect2(0, FLOOR, WIDTH, 70)]
	var route_count := rng.randi_range(9, 11)
	var weights: Array[float] = []
	var total := 0.0
	for i in route_count:
		var weight := rng.randf_range(0.95, 1.05)
		weights.append(weight)
		total += weight
	var previous_center := 340.0 if variant != 3 else 1160.0
	var previous_width := 250.0
	var y := FLOOR
	var route: Array[int] = []
	for i in route_count:
		var q := float(i + 1) / route_count
		y -= (FLOOR - TOP) * weights[i] / total
		var w := rng.randf_range(180, 315)
		var center := _profile(variant, q) + rng.randf_range(-65, 65)
		# Limit edge-to-edge separation rather than forcing a grid or equal centers.
		var maximum_shift := (previous_width + w) * 0.5 + 82.0
		center = clampf(center, previous_center - maximum_shift, previous_center + maximum_shift)
		center = clampf(center, w * 0.5 + 155, WIDTH - w * 0.5 - 155)
		if i == route_count - 1:
			y = TOP
			center = 740.0
			w = 290.0
		var rect := _place_route(y, w, center, previous_center, previous_width, reserved, i == 0)
		platforms.append(rect)
		route.append(platforms.size() - 1)
		previous_center = rect.get_center().x
		previous_width = rect.size.x
	# A few side branches create optional perches and alternate attack elevations.
	# They are accepted only when they do not intrude on another platform / landmark.
	var branch_goal := rng.randi_range(0, 2)
	var added := 0
	for attempt in 48:
		if added >= branch_goal:
			break
		var source: Rect2 = platforms[route[rng.randi_range(1, route.size() - 2)]]
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var w := rng.randf_range(135, 245)
		var gap := rng.randf_range(58, 105)
		var x := source.position.x - gap - w if side < 0 else source.end.x + gap
		var rect := Rect2(x, source.position.y + rng.randf_range(-24, 26), w, rng.randf_range(17, 23))
		if rect.position.x < 28 or rect.end.x > WIDTH - 28 or _hits_reserved(rect, reserved):
			continue
		var free := true
		for other in platforms:
			if rect.grow_individual(16, 26, 16, 26).intersects(other):
				free = false
				break
		if free:
			platforms.append(rect)
			added += 1
	# Source geometry is saved per room, so returning does not regenerate a different room.
	var doors: Dictionary = {}
	for dir in room.get("neighbors", {}):
		doors[dir] = DOOR_ANCHORS.get(dir, DOOR_ANCHORS["down"])
	var enemy_spawns := _spawn_slots(platforms, reserved)
	return {
		"platforms": platforms, "doors": doors, "reserved_regions": reserved,
		"spawn_positions": {"center": Vector2(230, FLOOR), "left": Vector2(WIDTH - 160, FLOOR), "right": Vector2(160, FLOOR), "up": Vector2(1090, FLOOR), "down": Vector2(800, TOP)},
		"enemy_spawns": enemy_spawns, "route_indices": route,
		"archetype": ARCHETYPES[variant], "seed": rng.seed
	}


static func _start_layout(room: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	# Exactly three playable tiers including the floor; no tall navigation maze.
	var platforms: Array[Rect2] = [Rect2(0,FLOOR,WIDTH,70),Rect2(180,950,240,21),Rect2(280,850,1050,21)]
	if room.get("neighbors",{}).has("up"):
		for y in [750,650,550,450,350,250,150,110]:platforms.append(Rect2(480 if y%200==150 else 630,y,250,18))
	var doors: Dictionary = {}
	for dir in room.get("neighbors", {}):
		doors[dir] = Vector2(740,20) if dir=="up" else DOOR_ANCHORS[dir]
	var reserved := _reserved(room)
	return {"platforms":platforms,"doors":doors,"reserved_regions":reserved,
		"spawn_positions":{"center":Vector2(230,FLOOR),"left":Vector2(WIDTH-160,FLOOR),"right":Vector2(160,FLOOR),"up":Vector2(1090,FLOOR),"down":Vector2(800,850)},
		"enemy_spawns":_spawn_slots(platforms,reserved),"route_indices":[1,2],"archetype":"three_tier_nest","seed":rng.seed}


static func _boss_layout(room: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	# Side staircases preserve ordinary-jump access to every exit while the
	# central arena stays free of platforms for the eight-area Boss silhouettes.
	var platforms: Array[Rect2] = [Rect2(0,FLOOR,WIDTH,70),Rect2(150,950,180,21),Rect2(1170,950,180,21)]
	for y in [850,750,650,550,450,350]:
		var jitter:float=rng.randf_range(-3,3)
		platforms.append(Rect2(42+rng.randf_range(-3,3),float(y)+jitter,240,21))
		platforms.append(Rect2(1218+rng.randf_range(-3,3),float(y)-jitter,240,21))
	platforms.append(Rect2(325,275,240,21))
	platforms.append(Rect2(915,275,240,21))
	platforms.append(Rect2(595,TOP,290,21))
	var doors:Dictionary={}
	for dir in room.get("neighbors",{}):doors[dir]=DOOR_ANCHORS.get(dir,DOOR_ANCHORS["down"])
	var reserved:=_reserved(room)
	return {"platforms":platforms,"doors":doors,"reserved_regions":reserved,
		"spawn_positions":{"center":Vector2(230,FLOOR),"left":Vector2(WIDTH-160,FLOOR),"right":Vector2(160,FLOOR),"up":Vector2(1090,FLOOR),"down":Vector2(800,TOP)},
		"enemy_spawns":_spawn_slots(platforms,reserved),"route_indices":[],"archetype":"boss_arena","seed":rng.seed}


static func _place_route(y: float, width: float, desired: float, previous_center: float, previous_width: float, reserved: Array[Rect2], first: bool) -> Rect2:
	for w in [width, 165.0, 135.0]:
		var half := float(w) * 0.5
		var shift := (previous_width + float(w)) * 0.5 + 82.0
		var lower := maxf(half + 28, previous_center - shift) if not first else half + 28
		var upper := minf(WIDTH - half - 28, previous_center + shift) if not first else WIDTH - half - 28
		var intervals: Array[Vector2] = [Vector2(lower, upper)]
		for region in reserved:
			if y >= region.end.y or y + 23 <= region.position.y:
				continue
			var forbidden := Vector2(region.position.x - half - 12, region.end.x + half + 12)
			var trimmed: Array[Vector2] = []
			for interval in intervals:
				if interval.x < forbidden.x:
					trimmed.append(Vector2(interval.x, minf(interval.y, forbidden.x)))
				if interval.y > forbidden.y:
					trimmed.append(Vector2(maxf(interval.x, forbidden.y), interval.y))
			intervals = trimmed
		var best := -1.0
		var best_distance := INF
		for interval in intervals:
			if interval.y < interval.x:
				continue
			var candidate := clampf(desired, interval.x, interval.y)
			if absf(candidate - desired) < best_distance:
				best = candidate
				best_distance = absf(candidate - desired)
		if best >= 0:
			return Rect2(best - half, y, float(w), 21)
	# Kept as an explicit detectable failure rather than silently intersecting landmarks.
	return Rect2(desired - width * 0.5, y, width, 21)


static func _profile(variant: int, q: float) -> float:
	var center := 740.0
	match variant:
		0: center = 360.0 + sin(q * PI * 1.35) * 780.0
		1: center = 730.0 + sin(q * PI * 3.0 - 1.0) * 400.0
		2: center = 300.0 + q * 600.0 + sin(q * PI * 2.0) * 210.0
		3: center = 1200.0 - q * 600.0 - sin(q * PI * 2.0) * 210.0
	# Pull the last ledges toward the upper doorway gradually, never by a final giant gap.
	return lerpf(center, 740.0, smoothstep(0.68, 1.0, q))


static func _reserved(room: Dictionary) -> Array[Rect2]:
	var regions: Array[Rect2] = [Rect2(170, FLOOR - 72, 120, 72)]
	regions.append_array(room.get("_terrain_regions",[]))
	for dir in room.get("neighbors", {}):
		var anchor: Vector2 = Vector2(740,20) if dir=="up" else DOOR_ANCHORS.get(dir, DOOR_ANCHORS["down"])
		regions.append(Rect2(anchor - Vector2(75, 145), Vector2(150, 145)))
	if room.get("type", "combat") in ["start", "reward"]:
		regions.append(Rect2(610, FLOOR - 160, 260, 160))
	if room.get("type", "combat") == "boss":
		regions.append(Rect2(430, FLOOR - 170, 640, 170))
	return regions


static func _hits_reserved(rect: Rect2, regions: Array[Rect2]) -> bool:
	for region in regions:
		if rect.intersects(region):
			return true
	return false


static func _spawn_slots(platforms: Array[Rect2], reserved: Array[Rect2]) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	var spawn_reserved: Array[Rect2] = reserved.duplicate()
	spawn_reserved.append(Rect2(1035, FLOOR - 70, 110, 70))
	spawn_reserved.append(Rect2(1295, FLOOR - 70, 90, 70))
	# Floor slots are distributed, then upper slots use actual support surfaces.
	for x in range(180, 1360, 88):
		var at := Vector2(x, FLOOR)
		if not _hits_reserved(Rect2(at - Vector2(34, 50), Vector2(68, 49.5)), spawn_reserved) and not _body_hits_surfaces(at, platforms):
			slots.append(at)
	for i in range(1, platforms.size()):
		var rect := platforms[i]
		var capacity := maxi(1, 1 + int((rect.size.x - 70) / 86.0))
		var offsets: Array[float] = []
		for slot in capacity:
			offsets.append((float(slot) - float(capacity - 1) * 0.5) * 86.0)
		for offset in offsets:
			var at := Vector2(rect.get_center().x + offset, rect.position.y)
			var body := Rect2(at - Vector2(34, 50), Vector2(68, 49.5))
			if _hits_reserved(body, spawn_reserved):
				continue
			var free := true
			for surface in platforms:
				if body.intersects(surface):
					free = false
					break
			for existing in slots:
				if body.intersects(Rect2(existing - Vector2(34, 50), Vector2(68, 49.5))):
					free = false
					break
			if free:
				slots.append(at)
	return slots


static func _body_hits_surfaces(at: Vector2, platforms: Array[Rect2]) -> bool:
	var body := Rect2(at - Vector2(34, 50), Vector2(68, 49.5))
	for surface in platforms:
		if body.intersects(surface):
			return true
	return false


static func validate(layout: Dictionary) -> Array[String]:
	if layout.has("maze_grid"):return MazeLayout.validate(layout)
	var errors: Array[String] = []
	var platforms: Array = layout["platforms"]
	for i in range(1, platforms.size()):
		var a: Rect2 = platforms[i]
		if a.position.x < 0 or a.end.x > WIDTH or a.position.y < 110.0 - 0.1:
			errors.append("Platform out of room bounds")
		if a.position.y!=FLOOR and _hits_reserved(a, layout["reserved_regions"]):
			errors.append("Platform crosses landmark reserved region")
		for j in range(i + 1, platforms.size()):
			if a.intersects(platforms[j]):
				errors.append("Platforms overlap")
	# Conservative directed support graph: ordinary jump apex = 112px and
	# ~180px horizontal travel at a 100px rise. We reserve margin for player width.
	var reachable: Dictionary = {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var index: int = queue.pop_front()
		var a: Rect2 = platforms[index]
		for j in platforms.size():
			if reachable.has(j):
				continue
			var b: Rect2 = platforms[j]
			var rise := a.position.y - b.position.y
			var gap := maxf(0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
			if rise <= 108 and gap <= 130 and _jump_clear(a,b,layout.get("solids",[])):
				reachable[j] = true
				queue.append(j)
	for i in platforms.size():
		if not reachable.has(i):
			errors.append("Platform %d cannot be reached by ordinary jumps" % i)
	for key in layout["spawn_positions"]:
		var at: Vector2 = layout["spawn_positions"][key]
		if not _has_support(at, platforms):
			errors.append("Entry spawn %s has no support" % key)
	if layout["doors"].has("up"):
		var exit_at:Vector2=layout["doors"]["up"]
		var approach:Rect2=Rect2(exit_at.x-40,exit_at.y+28,80,1)
		var reaches_exit:bool=false
		for i in platforms.size():
			var support:Rect2=platforms[i]
			if reachable.has(i) and support.position.y-approach.position.y<=100 and _jump_clear(support,approach,layout.get("solids",[])):
				reaches_exit=true;break
		if not reaches_exit:errors.append("Upper opening cannot be reached by an ordinary jump")
	for key in layout["doors"]:
		if key not in ["up","down"] and not _has_support(layout["doors"][key], platforms):
			errors.append("Door %s has no support" % key)
	var spawn_bodies: Array[Rect2] = []
	for at in layout["enemy_spawns"]:
		var body := Rect2(at - Vector2(34, 50), Vector2(68, 49.5))
		for previous in spawn_bodies:
			if body.intersects(previous):
				errors.append("Enemy spawn silhouettes overlap")
		for surface in platforms:
			if body.intersects(surface):
				errors.append("Enemy spawn body intersects platform")
		spawn_bodies.append(body)
	for at in layout["enemy_spawns"]:
		if not _has_support(at, platforms):
			errors.append("Enemy spawn has no support")
	if layout.has("trunks"):
		if layout["trunks"].size()<2:errors.append("At least two trunks required")
		if layout["blocks"].size()>5:errors.append("At most five square solids")
		for solid:Rect2 in layout["trunks"]+layout["blocks"]:
			for platform:Rect2 in platforms:
				if solid.intersects(platform):errors.append("Solid terrain overlaps a horizontal platform")
			for at:Vector2 in layout["spawn_positions"].values():
				if Rect2(at-Vector2(17,42),Vector2(34,42)).intersects(solid):errors.append("Entry overlaps solid")
	return errors


static func _has_support(at: Vector2, platforms: Array) -> bool:
	for rect in platforms:
		if absf(at.y - rect.position.y) < 0.1 and at.x >= rect.position.x + 15 and at.x <= rect.end.x - 15:
			return true
	return false

static func _jump_clear(a:Rect2,b:Rect2,solids:Array) -> bool:
	# Ballistic jump sweep (530 impulse / 1250 gravity), with the actor body.
	var rise:float=a.position.y-b.position.y
	var from_x:float=clampf(b.get_center().x,a.position.x+20,a.end.x-20)
	var to_x:float=clampf(from_x,b.position.x+20,b.end.x-20)
	var discriminant:float=530.0*530.0-2*1250*rise
	if discriminant<0:return false
	var duration:float=(530+sqrt(discriminant))/1250
	if absf(to_x-from_x)/maxf(duration,.001)>330:return false
	for i in range(1,20):
		var time:float=duration*i/20
		var at:Vector2=Vector2(lerpf(from_x,to_x,float(i)/20),a.position.y-530*time+.5*1250*time*time)
		var body:Rect2=Rect2(at-Vector2(16,41),Vector2(32,40.9))
		for solid:Rect2 in solids:
			if body.intersects(solid):return false
	return true

static func _add_supported_shapes(layout:Dictionary,random:RandomNumberGenerator) -> void:
	var route:Array=layout.get("route_indices",[])
	for j in range(1,mini(route.size()-1,7),2):
		var platform:Rect2=layout["platforms"][route[j]]
		var left:bool=random.randf()<.5
		var stem:=Rect2(platform.position.x if left else platform.end.x-34,platform.end.y,34,random.randf_range(52,82))
		layout["trunks"].append(stem);layout["solids"].append(stem)
		if validate(layout).is_empty():layout["shapes"].append({"kind":"L","parts":[platform,stem]})
		else:layout["trunks"].pop_back();layout["solids"].pop_back()
	var shelf:Rect2=layout["platforms"][route[mini(3,route.size()-1)]]
	var square:=Rect2(shelf.get_center().x-28,shelf.end.y,56,56)
	layout["blocks"].append(square);layout["solids"].append(square)
	if validate(layout).is_empty():layout["shapes"].append({"kind":"square","parts":[square]})
	else:layout["blocks"].pop_back();layout["solids"].pop_back()
