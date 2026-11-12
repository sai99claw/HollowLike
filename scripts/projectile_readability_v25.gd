class_name ProjectileReadabilityV25
extends RefCounted
const PLAYER_HEIGHT:float=50.9375
const BASE_RADIUS:float=PLAYER_HEIGHT/8.0*1.5
const TRAIL_SECONDS:float=.45
const MAX_POINTS:int=32
static func visual_radius(projectile:Dictionary) -> float:
	return float(projectile.get("radius",BASE_RADIUS)) if projectile.get("from_player",false) else maxf(float(projectile.get("radius",8))*1.6,14.0)
static func sprite_extent(source:Vector2,radius:float) -> Vector2:
	return source*(radius*2.0/maxf(1,maxf(source.x,source.y)))

static func uses_dust(projectile:Dictionary) -> bool:
	return str(projectile.get("visual_id","")).begins_with("v36:") or preload("res://scripts/projectile_animation_v31.gd").has(str(projectile.get("weapon_id","")))

static func record(projectile:Dictionary,previous:Vector2,next:Vector2,delta:float) -> void:
	var clock:float=float(projectile.get("trail_clock",0))+maxf(0,delta)
	var points:PackedVector2Array=projectile.get("trail_points",PackedVector2Array([previous]))
	var times:PackedFloat32Array=projectile.get("trail_times",PackedFloat32Array([clock-maxf(0,delta)]))
	if points.size()<2 or points[-2].distance_to(next)>=8:points.append(next);times.append(clock)
	else:points[-1]=next;times[-1]=clock
	while points.size()>MAX_POINTS or (points.size()>2 and clock-times[0]>TRAIL_SECONDS):points.remove_at(0);times.remove_at(0)
	projectile["trail_points"]=points;projectile["trail_times"]=times;projectile["trail_clock"]=clock
static func draw_trail(c:CanvasItem,projectile:Dictionary,base:Transform2D,low_effects:bool=false) -> void:
	var points:PackedVector2Array=projectile.get("trail_points",PackedVector2Array())
	if points.size()<2:return
	var times:PackedFloat32Array=projectile.get("trail_times",PackedFloat32Array());var clock:float=float(projectile.get("trail_clock",0))
	var tint:Color=projectile.get("color",Color("9be8ff"));var colors:=PackedColorArray();var cores:=PackedColorArray();var shadows:=PackedColorArray()
	for i in points.size():
		var alpha:float=clampf(1-(clock-float(times[i]))/TRAIL_SECONDS,0,1)
		alpha*=float(i+1)/points.size()
		colors.append(Color(tint.lightened(.22),alpha*.85));cores.append(Color(tint.lightened(.80),alpha*.95));shadows.append(Color(.015,.025,.045,alpha*.65))
	var width:float=clampf(visual_radius(projectile)*.26,3.5,11)
	c.draw_set_transform_matrix(base)
	if not low_effects:c.draw_polyline_colors(points,shadows,width+4,true)
	c.draw_polyline_colors(points,colors,width,true)
	c.draw_polyline_colors(points,cores,maxf(1.5,width*.32),true)
static func draw_cue(c:CanvasItem,projectile:Dictionary,base:Transform2D) -> void:
	if uses_dust(projectile):return
	var at:Vector2=projectile["pos"];var radius:float=visual_radius(projectile);var tint:Color=projectile.get("color",Color("9be8ff"))
	c.draw_set_transform_matrix(base)
	c.draw_circle(at,radius*1.1,Color(tint,.08))
