class_name FlightNavigation
extends RefCounted
## Full-body clearance paths. Actors leave nearby terrain before resuming pursuit.
const Coll=preload("res://scripts/world_collision.gd")
const CELL:float=32.0
const REGION=Rect2i(0,0,47,35)
static var grids:Dictionary={}

static func _inflated(box:Rect2,half:Vector2,margin:float=6) -> Rect2:
	return Rect2(box.position-half-Vector2.ONE*margin,box.size+half*2+Vector2.ONE*margin*2)

static func _visible(a:Vector2,b:Vector2,half:Vector2,obstacles:Array) -> bool:
	var sweep:=Rect2(a.min(b),a.max(b)-a.min(b)).grow(maxf(half.x,half.y)+6.001)
	for box:Rect2 in obstacles:
		if box.intersects(sweep,true) and Coll.segment(a,b,_inflated(box,half))<INF:return false
	return true

static func _nearest_free(grid:AStarGrid2D,at:Vector2) -> Vector2i:
	var origin:Vector2i=Vector2i((at-Vector2.ONE*16)/CELL)
	origin.x=clampi(origin.x,0,REGION.size.x-1);origin.y=clampi(origin.y,0,REGION.size.y-1)
	var best:Vector2i=Vector2i(-1,-1);var distance:float=INF
	for radius in range(0,20):
		for y in range(maxi(0,origin.y-radius),mini(REGION.size.y,origin.y+radius+1)):
			for x in range(maxi(0,origin.x-radius),mini(REGION.size.x,origin.x+radius+1)):
				if radius>0 and absi(x-origin.x)!=radius and absi(y-origin.y)!=radius:continue
				var cell:=Vector2i(x,y)
				if grid.is_point_solid(cell):continue
				var d:float=at.distance_squared_to(grid.get_point_position(cell))
				if d<distance:best=cell;distance=d
		if best.x>=0:return best
	return best

static func _path(center:Vector2,target:Vector2,half:Vector2,obstacles:Array) -> PackedVector2Array:
	var key:Array=[half,obstacles]
	var grid:AStarGrid2D
	if grids.has(key):grid=grids[key]
	else:
		grid=AStarGrid2D.new()
		grid.region=REGION;grid.cell_size=Vector2.ONE*CELL;grid.offset=Vector2.ONE*16
		grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for y in REGION.size.y:
			for x in REGION.size.x:
				var at:Vector2=grid.get_point_position(Vector2i(x,y))
				if at.x<28+half.x or at.x>1472-half.x or at.y<55+half.y or at.y>1020-half.y:grid.set_point_solid(Vector2i(x,y))
		for box:Rect2 in obstacles:
			var rect:Rect2=_inflated(box,half)
			var first:Vector2i=Vector2i(((rect.position-Vector2.ONE*16)/CELL).ceil())
			var last:Vector2i=Vector2i(((rect.end-Vector2.ONE*16)/CELL).floor())
			for y in range(maxi(0,first.y),mini(REGION.size.y,last.y+1)):
				for x in range(maxi(0,first.x),mini(REGION.size.x,last.x+1)):
					grid.set_point_solid(Vector2i(x,y))
		if grids.size()>=12:grids.clear()
		grids[key]=grid
	var start:Vector2i=_nearest_free(grid,center);var goal:Vector2i=_nearest_free(grid,target)
	if start.x<0 or goal.x<0:return PackedVector2Array()
	return grid.get_point_path(start,goal,true)

static func _clearance(at:Vector2,half:Vector2,obstacles:Array) -> float:
	var distance:float=150
	for box:Rect2 in obstacles:
		var rect:Rect2=_inflated(box,half,0)
		if rect.has_point(at):return -100
		var nearest:Vector2=at.clamp(rect.position,rect.end)
		distance=minf(distance,at.distance_to(nearest))
	distance=minf(distance,minf(at.x-half.x-28,1472-half.x-at.x))
	distance=minf(distance,minf(at.y-half.y-55,1020-half.y-at.y))
	return distance

static func steer(en:Dictionary,target:Vector2,desired:Vector2,size:Vector2,obstacles:Array,delta:float) -> Vector2:
	var half:Vector2=size*.5
	var center:Vector2=en["pos"]-Vector2(0,half.y)
	var goal:Vector2=target-Vector2(0,half.y)
	var speed:float=maxf(35,float(en.get("speed",70)))
	var direction:Vector2=desired.normalized()
	en["flight_repath"]=float(en.get("flight_repath",0))-delta
	if _visible(center,goal,half,obstacles):
		en["flight_path"]=PackedVector2Array()
	else:
		if float(en["flight_repath"])<=0 or goal.distance_to(en.get("flight_goal",Vector2.INF))>80:
			en["flight_path"]=_path(center,goal,half,obstacles);en["flight_goal"]=goal;en["flight_repath"]=.45
		var path:PackedVector2Array=en.get("flight_path",PackedVector2Array())
		while path.size()>1 and center.distance_to(path[0])<18:path.remove_at(0)
		# Skip visible waypoints to prevent unnecessary zigzags on a grid.
		for i in range(path.size()-1,0,-1):
			if _visible(center,path[i],half,obstacles):
				path=path.slice(i);break
		en["flight_path"]=path
		if not path.is_empty():direction=(path[0]-center).normalized()
	var local:Array=[]
	# Clearance is capped at150; even a20px escape probe cannot see beyond176.
	var area:=Rect2(center-half-Vector2.ONE*176,size+Vector2.ONE*352)
	for obstacle:Rect2 in obstacles:
		if obstacle.intersects(area,true):local.append(obstacle)
	var clearance:float=_clearance(center,half,local)
	if clearance<38:
		# While near any solid, the priority is gaining room, even mid-attack.
		var best:float=-INF;var escape:Vector2=direction
		for i in 24:
			var candidate:Vector2=Vector2.from_angle(TAU*i/24)
			var probe:Vector2=center+candidate*20
			if not _visible(center,probe,half-Vector2.ONE*6,local):continue
			var score:float=_clearance(probe,half,local)*3+candidate.dot(direction)*8
			if score>best:best=score;escape=candidate
		direction=escape
	if direction.length_squared()<.01:return Vector2.ZERO
	return direction*speed if clearance<38 or not en.get("flight_path",PackedVector2Array()).is_empty() else desired.limit_length(speed)
