class_name CoinPhysics
extends RefCounted
## Circle-centred coin motion. Swept radius-expanded rectangles prevent tunnelling
## through thin platforms; bounded substeps also keep gravity / friction stable.
## Currency value, pickup decisions and attraction belong to the caller.

const GRAVITY: float = 1250.0
const RESTITUTION: float = 0.35
const RADIUS: float = 14.0
const GROUND_FRICTION: float = 85.0
const STOP_BOUNCE_SPEED: float = 70.0
const VISIBLE_IMPACT_SPEED: float = 35.0
const MAX_SUBSTEPS: int = 24
const MAX_CONTACTS: int = 5
const EPSILON: float = 0.02
const SUPPORT_TOLERANCE: float = 0.12


static func initialize(drop: Dictionary, launch: Vector2 = Vector2.ZERO) -> void:
	if not drop.has("vel"):
		drop["vel"] = launch if launch != Vector2.ZERO else Vector2(100.0, -150.0)
	if not drop.has("radius"):
		drop["radius"] = RADIUS
	if not drop.has("rotation"):
		drop["rotation"] = 0.0
	if not drop.has("angular_speed"):
		var velocity: Vector2 = drop["vel"]
		drop["angular_speed"] = velocity.x / maxf(1.0, float(drop["radius"]))
	if not drop.has("age"):
		drop["age"] = 0.0
	if not drop.has("grounded"):
		drop["grounded"] = false


static func step(drop: Dictionary, delta: float, platforms: Array, bounds: Rect2 = Rect2(18, 0, 1464, 1120)) -> bool:
	initialize(drop)
	if not is_finite(delta) or delta <= 0.0:
		return false
	if drop.get("sleeping",false) and Vector2(drop["vel"]).length_squared()<.01:
		drop["age"]=float(drop["age"])+delta;return false
	drop["sleeping"]=false
	var duration: float = minf(delta, 0.25)
	var substeps: int = clampi(int(ceil(duration * 120.0)), 1, MAX_SUBSTEPS)
	var dt: float = duration / float(substeps)
	var radius: float = clampf(float(drop["radius"]), 1.0, 40.0)
	var position: Vector2 = drop.get("pos", Vector2.ZERO)
	var velocity: Vector2 = drop["vel"]
	if not position.is_finite():
		position = bounds.get_center()
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	var rotation: float = float(drop["rotation"])
	var angular_speed: float = float(drop["angular_speed"])
	if not is_finite(rotation):
		rotation = 0.0
	if not is_finite(angular_speed):
		angular_speed = 0.0
	var visible_collision: bool = false
	var grounded: bool = false
	for substep in substeps:
		position.x = clampf(position.x, bounds.position.x + radius, bounds.end.x - radius)
		position.y = clampf(position.y, bounds.position.y + radius, bounds.end.y - radius)
		position = _depenetrate(position, radius, platforms)
		var support: float = _support_height(position, radius, platforms, bounds)
		grounded = support < INF and velocity.y >= 0.0 and velocity.y < STOP_BOUNCE_SPEED
		if grounded:
			position.y = support - radius
			velocity.y = 0.0
			velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * dt)
			if absf(velocity.x) < 1.0:
				velocity.x = 0.0
		else:
			velocity.y += GRAVITY * dt
		var time_left: float = dt
		for contact in MAX_CONTACTS:
			if time_left <= 0.000001 or velocity.length_squared() < 0.000001:
				break
			var motion: Vector2 = velocity * time_left
			var hit: Dictionary = _first_hit(position, motion, radius, platforms, bounds)
			if hit.is_empty():
				position += motion
				break
			var fraction: float = float(hit["time"])
			var normal: Vector2 = hit["normal"]
			position += motion * fraction + normal * EPSILON
			var incoming: float = -velocity.dot(normal)
			if incoming >= VISIBLE_IMPACT_SPEED:
				visible_collision = true
			if incoming > 0.0:
				if normal.y < -0.5 and incoming < STOP_BOUNCE_SPEED:
					velocity.y = 0.0
					grounded = true
				else:
					velocity += normal * incoming * (1.0 + RESTITUTION)
					grounded = false
				if absf(normal.y) > 0.5:
					# A rolling coin keeps its tangent speed across the expanded ledge corner.
					if incoming >= STOP_BOUNCE_SPEED or _support_height(position, radius, platforms, bounds) < INF:
						velocity.x *= 0.88
				elif absf(normal.x) > 0.5:
					velocity.y *= 0.98
			time_left *= 1.0 - fraction
			# A resting contact is excluded from the next sweep by EPSILON; keep
			# a finite bound even at the intersection of two solids.
		var final_support: float = _support_height(position, radius, platforms, bounds)
		if final_support == INF or velocity.y < -0.05:
			grounded = false
		if grounded:
			position.y = final_support - radius
			angular_speed = velocity.x / radius
		else:
			angular_speed = move_toward(angular_speed, 0.0, dt * 0.15)
		rotation += angular_speed * dt
	position.x = clampf(position.x, bounds.position.x + radius, bounds.end.x - radius)
	position.y = clampf(position.y, bounds.position.y + radius, bounds.end.y - radius)
	drop["pos"] = position
	drop["vel"] = velocity
	drop["radius"] = radius
	drop["rotation"] = rotation
	drop["angular_speed"] = angular_speed
	drop["age"] = float(drop["age"]) + duration
	drop["grounded"] = grounded
	drop["rest_time"]=float(drop.get("rest_time",0))+duration if grounded and velocity.length_squared()<.01 else 0.0
	if float(drop["rest_time"])>.25:drop["sleeping"]=true
	return visible_collision


static func _support_height(position: Vector2, radius: float, platforms: Array, bounds: Rect2) -> float:
	var bottom: float = position.y + radius
	var support: float = INF
	for raw: Variant in platforms:
		if not raw is Rect2:
			continue
		var surface: Rect2 = raw
		if position.x >= surface.position.x and position.x <= surface.end.x and absf(bottom - surface.position.y) <= SUPPORT_TOLERANCE:
			support = minf(support, surface.position.y)
	if absf(bottom - bounds.end.y) <= SUPPORT_TOLERANCE:
		support = minf(support, bounds.end.y)
	return support


static func _depenetrate(position: Vector2, radius: float, platforms: Array) -> Vector2:
	var resolved: Vector2 = position
	for attempt in 3:
		var moved: bool = false
		for raw: Variant in platforms:
			if not raw is Rect2:
				continue
			var expanded: Rect2 = (raw as Rect2).grow(radius)
			if resolved.x <= expanded.position.x + EPSILON or resolved.x >= expanded.end.x - EPSILON or resolved.y <= expanded.position.y + EPSILON or resolved.y >= expanded.end.y - EPSILON:
				continue
			var distances: Array[float] = [resolved.x - expanded.position.x, expanded.end.x - resolved.x, resolved.y - expanded.position.y, expanded.end.y - resolved.y]
			var nearest: int = 0
			for i in range(1, 4):
				if distances[i] < distances[nearest]:
					nearest = i
			match nearest:
				0: resolved.x = expanded.position.x - EPSILON
				1: resolved.x = expanded.end.x + EPSILON
				2: resolved.y = expanded.position.y - EPSILON
				3: resolved.y = expanded.end.y + EPSILON
			moved = true
		if not moved:
			break
	return resolved


static func _first_hit(position: Vector2, motion: Vector2, radius: float, platforms: Array, bounds: Rect2) -> Dictionary:
	var best: Dictionary = {}
	var time: float = 2.0
	for raw: Variant in platforms:
		if not raw is Rect2:
			continue
		var hit: Dictionary = _sweep_rect(position, motion, (raw as Rect2).grow(radius))
		if not hit.is_empty() and float(hit["time"]) < time:
			time = float(hit["time"])
			best = hit
	var planes: Array[Dictionary] = [
		{"distance": bounds.position.x + radius - position.x, "movement": motion.x, "normal": Vector2.RIGHT},
		{"distance": bounds.end.x - radius - position.x, "movement": motion.x, "normal": Vector2.LEFT},
		{"distance": bounds.position.y + radius - position.y, "movement": motion.y, "normal": Vector2.DOWN},
		{"distance": bounds.end.y - radius - position.y, "movement": motion.y, "normal": Vector2.UP}
	]
	for plane: Dictionary in planes:
		var normal: Vector2 = plane["normal"]
		if motion.dot(normal) >= -0.000001:
			continue
		var fraction: float = float(plane["distance"]) / float(plane["movement"])
		if fraction >= -0.000001 and fraction <= 1.0 and fraction < time:
			time = maxf(0.0, fraction)
			best = {"time": time, "normal": normal}
	return best


static func _sweep_rect(position: Vector2, motion: Vector2, expanded: Rect2) -> Dictionary:
	var entry_x: float = -INF
	var exit_x: float = INF
	var entry_y: float = -INF
	var exit_y: float = INF
	if absf(motion.x) < 0.000001:
		if position.x < expanded.position.x or position.x > expanded.end.x:
			return {}
	else:
		entry_x = (expanded.position.x - position.x) / motion.x
		exit_x = (expanded.end.x - position.x) / motion.x
		if entry_x > exit_x:
			var swap_x: float = entry_x
			entry_x = exit_x
			exit_x = swap_x
	if absf(motion.y) < 0.000001:
		if position.y < expanded.position.y or position.y > expanded.end.y:
			return {}
	else:
		entry_y = (expanded.position.y - position.y) / motion.y
		exit_y = (expanded.end.y - position.y) / motion.y
		if entry_y > exit_y:
			var swap_y: float = entry_y
			entry_y = exit_y
			exit_y = swap_y
	var entry: float = maxf(entry_x, entry_y)
	var exit: float = minf(exit_x, exit_y)
	if entry > exit or exit < 0.0 or entry < -0.000001 or entry > 1.0:
		return {}
	var normal: Vector2
	if entry_x > entry_y:
		normal = Vector2.LEFT if motion.x > 0.0 else Vector2.RIGHT
	else:
		normal = Vector2.UP if motion.y > 0.0 else Vector2.DOWN
	return {"time": maxf(0.0, entry), "normal": normal}
