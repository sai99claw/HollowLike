extends RefCounted

const Collision=preload("res://scripts/world_collision.gd")
const LARGE:=Vector2(50,50)
const SMALL:=Vector2(20,20)
const ROW_HEIGHT:=17.320508
const PILE_OFFSETS:Array[Vector2]=[
	Vector2(0,-2*ROW_HEIGHT),
	Vector2(-10,-ROW_HEIGHT),Vector2(10,-ROW_HEIGHT),
	Vector2(-20,0),Vector2(0,0),Vector2(20,0),
]
const SCATTER_DIRECTIONS:Array[Vector2]=[
	Vector2(.24,-1),Vector2(-.76,-.76),Vector2(.83,-.72),
	Vector2(-1,-.18),Vector2(-.31,-.92),Vector2(1,-.26),
]
const LARGE_ART={
	"underground":preload("res://assets/v67/stones/underground_large.webp"),
	"trunk":preload("res://assets/v67/stones/trunk_large.webp"),
	"sky":preload("res://assets/v67/stones/sky_large.webp"),
}
const SMALL_ART={
	"underground":preload("res://assets/v67/stones/underground_small.webp"),
	"trunk":preload("res://assets/v67/stones/trunk_small.webp"),
	"sky":preload("res://assets/v67/stones/sky_small.webp"),
}

static func size(stone:Dictionary) -> Vector2:
	return LARGE if stone["large"] else SMALL

static func body(stone:Dictionary) -> Rect2:
	var extent:Vector2=size(stone)
	return Rect2(Vector2(stone["pos"])-Vector2(extent.x*.5,extent.y),extent)

static func radius(stone:Dictionary) -> float:
	return size(stone).x*.5

static func center(stone:Dictionary) -> Vector2:
	return Vector2(stone["pos"])-Vector2(0,radius(stone))

static func draw(canvas:CanvasItem,stone:Dictionary,biome:String,base:Transform2D=Transform2D.IDENTITY) -> void:
	var art:Dictionary=LARGE_ART if stone["large"] else SMALL_ART
	var extent:Vector2=size(stone)
	canvas.draw_set_transform_matrix(base*Transform2D(float(stone.get("rotation",0)),center(stone)))
	canvas.draw_texture_rect(art[biome],Rect2(-extent*.5,extent),false,Color("fff2c5") if float(stone["hurt"])>0 else Color.WHITE)
	canvas.draw_set_transform_matrix(base)

static func spawn(layout:Dictionary,surfaces:Array,solids:Array,avoid:Array) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var random:=RandomNumberGenerator.new()
	random.seed=int(layout["seed"])+6703
	var bounds:Vector2=layout["size"]
	var candidates:Array[Vector2]=[]
	for surface:Rect2 in surfaces:
		for x:int in range(ceili(surface.position.x+24),floori(surface.end.x-23),48):
			if x>=132 and x<=bounds.x-132 and surface.position.y>100 and surface.position.y<=float(layout["floor_y"]):
				candidates.append(Vector2(x,surface.position.y))
	for large:bool in [false,true]:
		var offsets:Array=[Vector2.ZERO] if large else PILE_OFFSETS
		var extent:Vector2=LARGE if large else SMALL
		var options:Array[Vector2]=candidates.duplicate()
		while not options.is_empty():
			var at:Vector2=options.pop_at(random.randi_range(0,options.size()-1))
			if avoid.any(func(point:Vector2)->bool:return point.distance_to(at)<(135.0 if large else 170.0)):continue
			if large and not _supported(at,extent.x*.5,surfaces):continue
			if not large and not PILE_OFFSETS.slice(3).all(func(offset:Vector2)->bool:return _supported(at+offset,extent.x*.5,surfaces)):continue
			var half_width:float=extent.x*.5 if large else 30.0
			var height:float=extent.y if large else extent.y+2*ROW_HEIGHT
			var clearance:=Rect2(at-Vector2(half_width,height+5),Vector2(half_width*2,height+4.9))
			if solids.any(func(tile:Rect2)->bool:return tile.intersects(clearance)):continue
			for slot in offsets.size():
				var stone:Dictionary={"kind":"stone","pos":at+offsets[slot],"large":large,"vel":Vector2.ZERO,"hurt":0.0,"asleep":true,"hits":{},"damage":0.0}
				if not large:stone["pile_slot"]=slot
				result.append(stone)
			avoid.append(at)
			break
	return result

static func _supported(at:Vector2,half:float,surfaces:Array) -> bool:
	for x:float in [at.x-half+1,at.x,at.x+half-1]:
		if not surfaces.any(func(s:Rect2)->bool:return absf(s.position.y-at.y)<.1 and x>=s.position.x and x<=s.end.x):return false
	return true

static func scatter(stone:Dictionary,direction:Vector2,attack_damage:float) -> void:
	var spread:Vector2=SCATTER_DIRECTIONS[int(stone["pile_slot"])]+direction*.22
	launch(stone,spread.normalized(),attack_damage)

static func launch(stone:Dictionary,direction:Vector2,attack_damage:float) -> void:
	stone.erase("pile_slot")
	stone.erase("trail_points")
	stone.erase("trail_times")
	stone["radius"]=radius(stone)
	stone["from_player"]=true
	stone["color"]=Color("dcc9b7")
	var speed:float=520.0 if stone["large"] else 690.0
	var lift:float=205.0 if absf(direction.y)<.5 else 0.0
	stone["vel"]=direction.normalized()*speed-Vector2(0,lift)
	stone["angular_speed"]=Vector2(stone["vel"]).x/radius(stone)
	stone["asleep"]=false
	stone["hurt"]=.16
	stone["hits"]={}
	stone["damage"]=clampf(attack_damage*.55,1.0,4.0)*(1.5 if stone["large"] else 1.0)

static func step(stone:Dictionary,delta:float,world:Array) -> PackedVector2Array:
	var vel:Vector2=stone["vel"]
	vel.y=minf(850.0,vel.y+850.0*delta)
	var at:Vector2=center(stone)
	var path:=PackedVector2Array([at])
	var start_x:float=at.x
	var r:float=radius(stone)
	var remaining:float=delta
	var grounded:bool=false
	for iteration:int in 4:
		var target:Vector2=at+vel*remaining
		var earliest:float=INF
		var normal:=Vector2.ZERO
		for tile:Rect2 in world:
			var t:float=Collision.swept_circle_rect(at,target,r,tile)
			if t>=earliest:continue
			var contact:Vector2=at.lerp(target,t)
			var outward:Vector2=(contact-contact.clamp(tile.position,tile.end)).normalized()
			if outward.is_zero_approx() or vel.dot(outward)>=0:continue
			earliest=t
			normal=outward
		if earliest==INF:
			at=target
			path.append(at)
			break
		at=at.lerp(target,earliest)+normal*.001
		path.append(at)
		remaining*=1.0-earliest
		var impact:float=-vel.dot(normal)
		var floor_contact:bool=normal.y<-.6
		var restitution:float=(.29 if impact>100 else 0.0) if floor_contact else .26
		vel+=normal*impact*(1+restitution)
		if floor_contact:
			grounded=true
			vel.x=move_toward(vel.x,0,760.0*delta)
	if grounded and vel.length_squared()<49:
		vel=Vector2.ZERO
		stone["asleep"]=true
		stone["damage"]=0.0
	var angular:float=vel.x/r if grounded else float(stone.get("angular_speed",0))
	var roll:float=(at.x-start_x)/r if grounded else angular*delta
	stone["rotation"]=fposmod(float(stone.get("rotation",0))+roll,TAU)
	stone["angular_speed"]=angular
	stone["pos"]=at+Vector2(0,r)
	stone["vel"]=vel
	return path
