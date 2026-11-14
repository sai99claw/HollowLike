class_name WorldCollision
extends RefCounted
## Solid AABB solver; all actor anchors are at their feet.
static func move_body(at:Vector2,velocity:Vector2,delta:float,size:Vector2,solids:Array,corner_margin:int=0,_full_scan:bool=false,circles:Array[Vector3]=[],grid:RefCounted=null) -> Dictionary:
	var initial_body:=Rect2(at-Vector2(size.x*.5,size.y),size)
	var pos:=at
	# Exact legacy correction can chain across overlapping solids in list order.
	if grid==null or _full_scan or grid.query(initial_body).any(func(solid:Rect2)->bool:return initial_body.intersects(solid)):
		pos=depenetrate(at,size,solids)
	var vel:=velocity
	var grounded:bool=false;var wall:int=0;var corrected:bool=false
	var near:Array=solids if _full_scan else motion_candidates(pos,velocity,delta,size,solids,corner_margin,grid)
	var end:Vector2=pos+velocity*delta
	var anchor_sweep:=Rect2(pos.min(end),pos.max(end)-pos.min(end)).grow(corner_margin+1.0)
	var steps:int=clampi(int(ceil(velocity.length()*delta/8)),1,96)
	var dt:float=delta/steps
	for step in steps:
		pos.x+=vel.x*dt
		for solid:Rect2 in near:
			var box:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
			if not box.intersects(solid):continue
			if vel.x>0:pos.x=solid.position.x-size.x*.5;wall=1
			elif vel.x<0:pos.x=solid.end.x+size.x*.5;wall=-1
			vel.x=0
			if not _full_scan and not anchor_sweep.has_point(pos):return move_body(at,velocity,delta,size,solids,corner_margin,true,circles)
		for circle:Vector3 in circles:
			var center:=Vector2(circle.x,circle.y)
			var dy:float=center.y-clampf(center.y,pos.y-size.y,pos.y)
			if absf(dy)>=circle.z:continue
			var extent:float=sqrt(circle.z*circle.z-dy*dy)+size.x*.5
			if absf(pos.x-center.x)>=extent:continue
			if vel.x>0:pos.x=center.x-extent;vel.x=0
			elif vel.x<0:pos.x=center.x+extent;vel.x=0
		pos.y+=vel.y*dt
		for solid:Rect2 in near:
			var box:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
			if not box.intersects(solid):continue
			if vel.y<0 and corner_margin>0 and not corrected:
				var escaped:bool=false
				for offset in range(1,corner_margin+1):
					for sign_value in [-1,1]:
						var candidate:Vector2=pos+Vector2(offset*sign_value,0)
						var body:=Rect2(candidate-Vector2(size.x*.5,size.y),size)
						var prior:=Rect2(candidate-Vector2(vel.x*dt,vel.y*dt)-Vector2(size.x*.5,size.y),size)
						if solids.any(func(other:Rect2)->bool:return body.intersects(other) or prior.intersects(other)):continue
						pos=candidate;escaped=true;corrected=true;break
					if escaped:break
				if escaped:continue
			if vel.y>=0:pos.y=solid.position.y;grounded=true
			else:pos.y=solid.end.y+size.y+.01
			vel.y=0
			if not _full_scan and not anchor_sweep.has_point(pos):return move_body(at,velocity,delta,size,solids,corner_margin,true,circles)
		for circle:Vector3 in circles:
			var center:=Vector2(circle.x,circle.y)
			var dx:float=maxf(0,absf(center.x-pos.x)-size.x*.5)
			if dx>=circle.z:continue
			var extent:float=sqrt(circle.z*circle.z-dx*dx)
			if pos.y<=center.y-extent or pos.y-size.y>=center.y+extent:continue
			if vel.y>=0:pos.y=center.y-extent;grounded=true
			else:pos.y=center.y+extent+size.y
			vel.y=0
	var final:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
	for solid:Rect2 in near:
		if final.end.y>solid.position.y+.1 and final.position.y<solid.end.y-.1:
			if absf(final.position.x-solid.end.x)<.1:wall=-1
			if absf(final.end.x-solid.position.x)<.1:wall=1
		if final.end.x>solid.position.x+.1 and final.position.x<solid.end.x-.1 and absf(final.end.y-solid.position.y)<.1:grounded=true
	return {"pos":pos,"vel":vel,"grounded":grounded,"wall":wall}
static func segment(a:Vector2,b:Vector2,rect:Rect2) -> float:
	var d:Vector2=b-a;var lo:float=0;var hi:float=1
	for axis in 2:
		if absf(d[axis])<.000001:
			if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:return INF
		else:
			var u:float=(rect.position[axis]-a[axis])/d[axis];var v:float=(rect.end[axis]-a[axis])/d[axis]
			lo=maxf(lo,minf(u,v));hi=minf(hi,maxf(u,v))
			if lo>hi:return INF
	return lo
static func first_solid(a:Vector2,b:Vector2,radius:float,solids:Array,grid:RefCounted=null) -> float:
	var earliest:float=INF
	var sweep:=Rect2(a.min(b),a.max(b)-a.min(b)).grow(radius+.001)
	for solid:Rect2 in (solids if grid==null else grid.query(sweep)):
		if solid.intersects(sweep,true):earliest=minf(earliest,segment(a,b,solid.grow(radius)))
	return earliest

static func depenetrate(at:Vector2,size:Vector2,solids:Array) -> Vector2:
	var pos:Vector2=at
	for attempt in 8:
		var changed:bool=false
		for solid:Rect2 in solids:
			var box:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
			if not box.intersects(solid):continue
			var shifts:Array[Vector2]=[Vector2(solid.position.x-box.end.x,0),Vector2(solid.end.x-box.position.x,0),Vector2(0,solid.position.y-box.end.y),Vector2(0,solid.end.y-box.position.y)]
			var smallest:Vector2=shifts[0]
			for shift in shifts:
				if shift.length_squared()<smallest.length_squared():smallest=shift
			pos+=smallest;changed=true
		if not changed:break
	return pos

static func motion_candidates(at:Vector2,velocity:Vector2,delta:float,size:Vector2,solids:Array,corner_margin:int=0,grid:RefCounted=null) -> Array:
	var end:Vector2=at+velocity*delta
	var sweep:=Rect2(at.min(end)-Vector2(size.x*.5,size.y),at.max(end)-at.min(end)+size).grow(corner_margin+1.0)
	if grid!=null:return grid.query(sweep)
	var result:Array=[]
	for solid:Rect2 in solids:
		if solid.intersects(sweep,true):result.append(solid)
	return result


static func segment_circle(a:Vector2,b:Vector2,center:Vector2,radius:float) -> float:
	var relative:Vector2=a-center
	var offset:float=relative.length_squared()-radius*radius
	if offset<=0:return 0.0
	var delta:Vector2=b-a
	var length_sq:float=delta.length_squared()
	if length_sq<=.000001:return INF
	var projection:float=relative.dot(delta)
	var discriminant:float=projection*projection-length_sq*offset
	if discriminant<0:return INF
	var t:float=(-projection-sqrt(discriminant))/length_sq
	return t if t>=0 and t<=1 else INF

static func circle_overlaps_rect(center:Vector2,radius:float,rect:Rect2) -> bool:
	var closest:Vector2=center.clamp(rect.position,rect.end)
	return center.distance_squared_to(closest)<=radius*radius

static func swept_circle_rect(a:Vector2,b:Vector2,radius:float,rect:Rect2) -> float:
	# A rectangle expanded by a disk has four circular corners.
	var sweep:=Rect2(a.min(b),a.max(b)-a.min(b)).grow(radius+.001)
	if not sweep.intersects(rect,true):return INF
	var t:float=minf(
		segment(a,b,rect.grow_side(SIDE_LEFT,radius).grow_side(SIDE_RIGHT,radius)),
		segment(a,b,rect.grow_side(SIDE_TOP,radius).grow_side(SIDE_BOTTOM,radius)))
	for corner:Vector2 in [rect.position,rect.end,Vector2(rect.position.x,rect.end.y),Vector2(rect.end.x,rect.position.y)]:
		t=minf(t,segment_circle(a,b,corner,radius))
	return t
