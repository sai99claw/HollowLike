extends RefCounted

const WIDTH := 264.0
const DEPTH := 54.0
const STEP := 18.0
const SHOULDER := 24.0
const WATERLINE := 9.0

static func prepare(layout: Dictionary) -> bool:
	if layout.has("hazard_room"):
		return false
	if layout.get("pool", Rect2()).has_area():
		return true
	var floor_y: float = layout["floor_y"]
	var solids: Array = layout["solids"]
	var anchors: Array = layout.get("spawn_positions", {}).values()
	anchors.append_array(layout.get("doors", {}).values())
	anchors.append_array(layout.get("navigation_plan", {}).get("launchers", []))
	var reserved: Array = layout.get("reserved_regions", [])
	var candidates: Array[Dictionary] = []
	for rock: Rect2 in solids:
		if not is_equal_approx(rock.position.y, floor_y) or rock.size.y < DEPTH + 12:
			continue
		for x in range(ceili(rock.position.x + 54), floori(rock.end.x - WIDTH - 54) + 1, 24):
			var cut := Rect2(x, floor_y, WIDTH, DEPTH)
			var clearance := cut.grow_individual(40, 66, 40, 0)
			if anchors.any(func(at: Vector2) -> bool: return clearance.has_point(at)):
				continue
			if reserved.any(func(rect: Rect2) -> bool: return rect.intersects(clearance)):
				continue
			if solids.any(func(rect: Rect2) -> bool: return rect != rock and rect.intersects(clearance)):
				continue
			candidates.append({"cut": cut, "rock": rock})
	if candidates.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = int(layout["seed"]) + 33013
	var choice: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var cut: Rect2 = choice["cut"]
	var rock: Rect2 = choice["rock"]
	var walls: Array[Rect2] = []
	for rect: Rect2 in solids:
		if rect != rock:
			walls.append(rect)
	walls.append(Rect2(rock.position, Vector2(cut.position.x - rock.position.x, rock.size.y)))
	walls.append(Rect2(cut.end.x, floor_y, rock.end.x - cut.end.x, rock.size.y))
	walls.append(Rect2(cut.position.x, cut.end.y, WIDTH, rock.end.y - cut.end.y))
	var platforms: Array[Rect2] = []
	for rect: Rect2 in layout["platforms"]:
		if not is_equal_approx(rect.position.y, floor_y) or not rect.intersects(cut):
			platforms.append(rect)
			continue
		if rect.position.x < cut.position.x:
			platforms.append(Rect2(rect.position, Vector2(cut.position.x - rect.position.x, rect.size.y)))
		if rect.end.x > cut.end.x:
			platforms.append(Rect2(cut.end.x, floor_y, rect.end.x - cut.end.x, rect.size.y))
	for tier in 2:
		var y := floor_y + (tier + 1) * STEP
		for x: float in [cut.position.x + tier * SHOULDER, cut.end.x - (tier + 1) * SHOULDER]:
			walls.append(Rect2(x, y, SHOULDER, cut.end.y - y))
			platforms.append(Rect2(x, y, SHOULDER, 8))
	platforms.append(Rect2(cut.position.x + SHOULDER * 2, cut.end.y, WIDTH - SHOULDER * 4, 8))
	layout["solids"] = walls
	layout["walls"] = walls
	layout["platforms"] = platforms
	layout["pool"] = Rect2(cut.position + Vector2(0, WATERLINE), Vector2(WIDTH, DEPTH - WATERLINE))
	layout["recessed_pool"] = true
	var exclusion := cut.grow_individual(34, 48, 34, 3)
	reserved.append(exclusion)
	layout["reserved_regions"] = reserved
	for key in ["enemy_spawns", "ground_spawns", "launcher_spawns"]:
		if layout.has(key):
			layout[key] = layout[key].filter(func(at: Vector2) -> bool: return not exclusion.has_point(at))
	return true
