class_name ProjectileReadabilityV25
extends RefCounted
const PLAYER_HEIGHT:float=50.9375
const BASE_RADIUS:float=PLAYER_HEIGHT/8.0*1.5
const TRAIL_SECONDS:float=.26
const MAX_POINTS:int=18
static func visual_radius(projectile:Dictionary) -> float:
	return float(projectile.get("radius",BASE_RADIUS)) if projectile.get("from_player",false) else maxf(float(projectile.get("radius",8))*1.6,14.0)
static func sprite_extent(source:Vector2,radius:float) -> Vector2:
	return source*(radius*2.0/maxf(1,maxf(source.x,source.y)))

static func uses_dust(projectile:Dictionary) -> bool:
	return str(projectile.get("visual_id","")).begins_with("v36:") or preload("res://scripts/projectile_animation_v31.gd").has(str(projectile.get("weapon_id","")))

static func record(projectile: Dictionary, previous: Vector2, next: Vector2, delta: float) -> void:
	var clock: float = float(projectile.get("trail_clock", 0.0)) + maxf(0, delta)
	var points: PackedVector2Array = projectile.get("trail_points", PackedVector2Array())
	var times: PackedFloat32Array = projectile.get("trail_times", PackedFloat32Array())
	if points.is_empty() or points[-1].distance_squared_to(previous) > 4.0:
		points = PackedVector2Array([previous])
		times = PackedFloat32Array([clock - delta])
	if points.size() < 2 or points[-2].distance_squared_to(next) >= 100.0 or clock - times[-2] >= .040:
		points.append(next)
		times.append(clock)
	else:
		points[-1] = next
		times[-1] = clock
	while points.size() > MAX_POINTS or (points.size() > 1 and clock - times[1] > TRAIL_SECONDS):
		points.remove_at(0)
		times.remove_at(0)
	projectile["trail_points"] = points
	projectile["trail_times"] = times
	projectile["trail_clock"] = clock

static func draw_trail(c: CanvasItem, projectile: Dictionary, base: Transform2D, low_effects: bool = false) -> void:
	var points: PackedVector2Array = projectile.get("trail_points", PackedVector2Array())
	if points.size() < 2:
		return
	var times: PackedFloat32Array = projectile["trail_times"]
	var clock: float = projectile["trail_clock"]
	var tint: Color = projectile.get("color", Color("c6c1aa"))
	if projectile.has("from_player"):
		var allegiance := Color("8be7ee") if projectile["from_player"] else Color("ff8070")
		tint = tint.lerp(allegiance, .43)
	var fade: float = projectile.get("trail_fade", 1.0)
	var width := clampf(visual_radius(projectile) * .47, 3, 16)
	var across := PackedFloat32Array([-1, 0, 1]) if low_effects else PackedFloat32Array([-1, -.38, 0, .38, 1])
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var normal := Vector2.ZERO
	for i in points.size():
		var incoming := points[i] - points[maxi(0,i-1)]
		var outgoing := points[mini(points.size()-1,i+1)] - points[i]
		var tangent := (incoming.normalized() + outgoing.normalized()).normalized()
		if tangent == Vector2.ZERO:
			tangent = outgoing.normalized() if outgoing != Vector2.ZERO else incoming.normalized()
		var next_normal := tangent.orthogonal()
		if normal.dot(next_normal) < 0.0:
			next_normal = -next_normal
		normal = next_normal
		var age := clampf(1.0 - (clock-times[i]) / TRAIL_SECONDS,0,1)
		var taper := pow(float(i) / float(points.size()-1),.63) * sqrt(age)
		var pinch := .43 if incoming.dot(outgoing) < 0 else 1.0
		for j in across.size():
			var x := across[j]
			vertices.append(points[i]+normal*width*taper*x*pinch)
			colors.append(Color(tint.lightened(.73*(1.0-absf(x))), fade*age*taper*(1-absf(x))*.91))
			if i > 0 and j > 0:
				var k := i*across.size()+j
				var prev := k-across.size()
				indices.append_array(PackedInt32Array([prev-1,prev,k-1,k-1,prev,k]))
	c.draw_set_transform_matrix(base)
	RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(),indices,vertices,colors)

static func draw_cue(c: CanvasItem, projectile: Dictionary, base: Transform2D) -> void:
	if uses_dust(projectile):
		return
	var at: Vector2 = projectile["pos"]
	var tint: Color = projectile.get("color",Color("a7edf9"))
	c.draw_set_transform_matrix(base)
	c.draw_circle(at,visual_radius(projectile)*1.1,Color(tint,.08))
