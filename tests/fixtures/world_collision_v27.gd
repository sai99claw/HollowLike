extends RefCounted
## Solid AABB solver; all actor anchors are at their feet.
static func move_body(at:Vector2,velocity:Vector2,delta:float,size:Vector2,solids:Array,corner_margin:int=0) -> Dictionary:
	var pos:Vector2=depenetrate(at,size,solids);var vel:Vector2=velocity
	var grounded:bool=false;var wall:int=0;var corrected:bool=false
	var steps:int=clampi(int(ceil(velocity.length()*delta/8)),1,96)
	var dt:float=delta/steps
	for step in steps:
		pos.x+=vel.x*dt
		for solid:Rect2 in solids:
			var box:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
			if not box.intersects(solid):continue
			if vel.x>0:pos.x=solid.position.x-size.x*.5;wall=1
			elif vel.x<0:pos.x=solid.end.x+size.x*.5;wall=-1
			vel.x=0
		pos.y+=vel.y*dt
		for solid:Rect2 in solids:
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
	var final:Rect2=Rect2(pos-Vector2(size.x*.5,size.y),size)
	for solid:Rect2 in solids:
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
static func first_solid(a:Vector2,b:Vector2,radius:float,solids:Array) -> float:
	var earliest:float=INF
	for solid:Rect2 in solids:earliest=minf(earliest,segment(a,b,solid.grow(radius)))
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
