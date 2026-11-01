class_name CorpseFieldV21
extends RefCounted
const Motion=preload("res://scripts/monster_motion_v18.gd")
const Appearance=preload("res://scripts/monster_appearance.gd")
const Collision=preload("res://scripts/world_collision.gd")
const Atlas=preload("res://scripts/atlas_v22.gd")
static func death_velocity(en:Dictionary) -> Vector2:
	var direction:Vector2=en.get("death_direction",Vector2(-float(en.get("face",1)),0))
	if direction.length_squared()<.01:direction=Vector2.LEFT
	direction=direction.normalized()
	var speed:float=maxf(0,float(en.get("death_knockback",76)))*1.5
	return Vector2(direction.x*speed,-160+minf(0,direction.y)*speed) if direction.y<=.5 else Vector2(direction.x*speed,speed)
static func create(en:Dictionary) -> Dictionary:
	if en.has("roster_id"):
		var size:Vector2=preload("res://scripts/monster_art_v36.gd").corpse_extent(en)
		return {"identity":str(en["roster_id"]),"roster_actor":{"roster_biome":en["roster_biome"],"roster_row":en["roster_row"],"roster_elite":en["roster_elite"]},"pos":Vector2(en["pos"]),"vel":death_velocity(en),"factor":1.0,"visual_size":size,"body_size":size*.9,"age":0.0,"land_age":-1.0,"frame":0,"face":float(en.get("face",1)),"settled":false}
	var identity:String=Motion.identity(en);var clip:Dictionary=Atlas.clip("death",identity)
	var factor:float=float(clip.get("world_width",80))/maxf(1,float(clip.get("reference_width",400)))
	if not Appearance.is_boss(en):factor*=float(en.get("scale",1))
	var rest:Dictionary=clip["frames"][7] if not clip.is_empty() else {}
	var extent:Vector2=Atlas.bounds(rest).size*factor if not rest.is_empty() else Vector2(60,25)
	var direction:Vector2=en.get("death_direction",Vector2(-float(en.get("face",1)),0))
	if direction.length_squared()<.01:direction=Vector2(-float(en.get("face",1)),0)
	direction=direction.normalized()
	var force:float=clampf(float(en.get("death_knockback",90))*.85,65,120)
	var velocity:Vector2=death_velocity(en)
	var face:float=float(en.get("face",1))
	return {"identity":identity,"pos":Vector2(en["pos"]),"vel":velocity,"factor":factor,"visual_size":extent,"body_size":extent*Vector2(.9,.9),"age":0.0,"land_age":-1.0,"frame":0,"face":face,"settled":false}
static func step(body:Dictionary,delta:float,solids:Array,platforms:Array,bounds:Vector2) -> bool:
	if body.get("settled",false):return false
	var dt:float=minf(delta,1.0/30);var remaining:float=delta
	while remaining>0:
		var step_delta:float=minf(dt,remaining);remaining-=step_delta;_step(body,step_delta,solids,platforms,bounds)
		if body.get("settled",false):break
	return true
static func _step(body:Dictionary,delta:float,solids:Array,platforms:Array,bounds:Vector2) -> void:
	body["age"]+=delta;var size:Vector2=body["body_size"];var old:Vector2=body["pos"]
	var velocity:Vector2=body["vel"];velocity.y=minf(900,velocity.y+1000*delta)
	if float(body["land_age"])>=0:velocity.x=move_toward(velocity.x,0,delta*500)
	var result:Dictionary=Collision.move_body(old,velocity,delta,size,solids)
	var at:Vector2=result["pos"];velocity=result["vel"]
	if velocity.y>=0:
		for surface:Rect2 in platforms:
			if old.y<=surface.position.y+.5 and at.y>=surface.position.y and at.x+size.x*.45>surface.position.x and at.x-size.x*.45<surface.end.x:
				at.y=surface.position.y;result["grounded"]=true;velocity.y=0
	at.x=clampf(at.x,size.x*.5,bounds.x-size.x*.5)
	if at.y>bounds.y:at.y=bounds.y;result["grounded"]=true;velocity.y=0
	body["pos"]=at;body["vel"]=velocity
	if result["grounded"]:
		if float(body["land_age"])<0:body["land_age"]=0.0
		body["land_age"]+=delta
		body["frame"]=4+mini(3,int(float(body["land_age"])*8))
		if float(body["land_age"])>=.5:body["settled"]=true;body["vel"]=Vector2.ZERO;body["frame"]=7
	else:body["frame"]=mini(3,int(float(body["age"])*12))
static func draw(c:CanvasItem,body:Dictionary) -> void:
	if preload("res://scripts/monster_art_v36.gd").draw_corpse(c,body):return
	# Flight, impact and slack rest are authored poses, never a rotated standing sprite.
	Atlas.draw(c,"death",str(body["identity"]),int(body["frame"]),body["pos"],float(body["factor"]),float(body["face"]))
