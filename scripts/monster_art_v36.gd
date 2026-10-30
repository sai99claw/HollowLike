class_name MonsterArtV36
extends RefCounted
const ROOT:String="res://assets/v36/monsters/"
const PHASE_COLUMNS:Dictionary={"move":0,"windup":3,"active":6,"recovery":9}
static var manifests:Dictionary={}
static var textures:Dictionary={}
static func manifest(biome:String) -> Dictionary:
	if not manifests.has(biome):
		var path:String=ROOT+biome+"-runtime.json"
		if not FileAccess.file_exists(path):return {}
		var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not value is Dictionary:return {}
		manifests[biome]=value
	return manifests[biome]
static func texture(path:String) -> Texture2D:
	if not textures.has(path):
		if not ResourceLoader.exists(ROOT+path):return null
		textures[path]=load(ROOT+path)
	return textures[path]
static func identity(id:String) -> Dictionary:
	var parts:PackedStringArray=id.split(":")
	return {"biome":parts[1],"id":parts[2]} if parts.size()==3 and parts[0]=="v36" else {}
static func phase_columns(elite:bool) -> Dictionary:return PHASE_COLUMNS if elite else {"move":0,"windup":6,"active":8,"recovery":10}
static func phase_counts(elite:bool) -> Dictionary:return {"move":3,"windup":3,"active":3,"recovery":3} if elite else {"move":6,"windup":2,"active":2,"recovery":2}
static func actor_sample(en:Dictionary,time:float) -> Dictionary:
	var elite:bool=bool(en.get("roster_elite",false));var row:int=int(en.get("roster_row",0))*(2 if elite else 1)
	var columns:Dictionary=phase_columns(elite);var counts:Dictionary=phase_counts(elite)
	var phase:String="move";var index:int=posmod(int(time*(9 if elite else 12)),int(counts["move"]));var attack:Variant=en.get("attack")
	if attack!=null and attack.is_busy():
		phase=str(attack.phase)
		if elite:index=clampi(int(attack.progress()*3),0,2)
		else:
			# Hold the final anticipation pose instead of uniformly playing slow frames.
			var split:float=.18 if phase=="windup" else .6 if phase=="active" else .5
			index=0 if attack.progress()<split else 1
		if elite:row+=clampi(int(attack.attack.get("roster_attack",0)),0,1)
	elif Vector2(en.get("vel",Vector2.ZERO)).length_squared()<9 and str(en.get("visual_movement","walk")) not in ["hover","drift"]:index=0
	return {"sheet":"elite" if elite else "regular","row":row,"column":int(columns.get(phase,0))+index,"phase":phase}
static func frame(data:Dictionary,sheet:String,row:int,column:int) -> Dictionary:
	var spec:Dictionary=data.get("sheets",{}).get(sheet,{})
	if spec.is_empty() or row<0 or row>=int(spec["rows"]):return {}
	return spec["frames"][row*int(spec["columns"])+posmod(column,int(spec["columns"]))]
static func _draw(c:CanvasItem,data:Dictionary,sheet:String,item:Dictionary,at:Vector2,factor:float,face:float,base:Transform2D,tint:Color=Color.WHITE,angle:float=0) -> bool:
	if item.is_empty():return false
	var tex:Texture2D=texture(data["sheets"][sheet]["path"])
	if tex==null:return false
	var r:Array=item["rect"];var pivot:Array=item["pivot"]
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2(face*factor,factor),0,at))
	c.draw_texture_rect_region(tex,Rect2(-Vector2(pivot[0],pivot[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),tint)
	c.draw_set_transform_matrix(base);return true
static func draw_actor(c:CanvasItem,en:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if not en.has("roster_id"):return false
	var data:Dictionary=manifest(str(en["roster_biome"]))
	if data.is_empty():return false
	var sample:Dictionary=actor_sample(en,time);var sheet:String=sample["sheet"];var row:int=sample["row"]
	var reference:float=float(data["sheets"][sheet]["reference_heights"][row])
	var height:float=50.9375*(sqrt(2.0) if bool(en.get("roster_elite",false)) else 1.0)
	return _draw(c,data,sheet,frame(data,sheet,row,int(sample["column"])),en["pos"],height/maxf(1,reference),float(en.get("face",1)),base,Color("f8d8c4") if float(en.get("hurt",0))>0 else Color.WHITE)
static func draw_projectile(c:CanvasItem,pr:Dictionary,base:Transform2D) -> bool:
	var key:Dictionary=identity(str(pr.get("visual_id","")))
	if key.is_empty():return false
	var data:Dictionary=manifest(key["biome"]);var spec:Dictionary=data.get("projectiles",{}).get(key["id"],{})
	if spec.is_empty():return false
	var index:int=posmod(int(float(pr.get("elapsed",0))*float(spec["fps"])),8)
	var factor:float=maxf(9,float(pr.get("radius",8))*1.4)*2/maxf(1,float(spec["body_extent"]))
	var angle:float=Vector2(pr.get("vel",Vector2.RIGHT)).angle() if str(spec["rotation"]).begins_with("axial") else float(pr.get("launch_angle",0))
	return _draw(c,data,"projectiles",frame(data,"projectiles",int(spec["row"]),index),pr["pos"],factor,1,base,Color.WHITE,angle)
static func draw_hazard(c:CanvasItem,h:Dictionary,base:Transform2D) -> bool:
	var key:Dictionary=identity(str(h.get("hazard_visual_id","")))
	if key.is_empty():return false
	var data:Dictionary=manifest(key["biome"]);var spec:Dictionary=data.get("projectiles",{}).get("trap_fx",{})
	if spec.is_empty():return false
	var age:float=float(h.get("elapsed",0));var arm:float=maxf(.01,float(h.get("arming_time",.8)))
	var index:int=clampi(int(age/arm*5),0,4) if age<arm else 5+posmod(int((age-arm)*8),3)
	return _draw(c,data,"projectiles",frame(data,"projectiles",int(spec["row"]),index),h["pos"],float(h.get("size",26))*2/maxf(1,float(spec["body_extent"])),1,base,Color(1,1,1,.65 if age<arm else 1))
static func melee_visible(attack:Variant) -> bool:
	return attack!=null and attack.is_active() and bool(attack.attack.get("primary",false)) and not bool(attack.attack.get("ram",false)) and not identity(str(attack.attack.get("melee_visual_id",""))).is_empty()
static func draw_melee(c:CanvasItem,at:Vector2,attack:Variant,face:float,base:Transform2D) -> bool:
	if not melee_visible(attack):return false
	var key:Dictionary=identity(str(attack.attack.get("melee_visual_id","")))
	if key.is_empty():return false
	var data:Dictionary=manifest(key["biome"]);var spec:Dictionary=data.get("projectiles",{}).get("melee_fx",{})
	if spec.is_empty():return false
	return _draw(c,data,"projectiles",frame(data,"projectiles",int(spec["row"]),clampi(int(attack.progress()*8),0,7)),at+Vector2(face*35,-25),float(attack.attack.get("range",80))/maxf(1,float(spec["body_extent"])),face,base)
static func corpse_angle(bounds:Array) -> float:return PI if float(bounds[2])>float(bounds[3])*1.15 else PI*.5
static func corpse_extent(en:Dictionary) -> Vector2:
	var data:Dictionary=manifest(str(en["roster_biome"]));var elite:bool=bool(en.get("roster_elite",false));var sheet:String="elite" if elite else "regular";var row:int=int(en["roster_row"])*(2 if elite else 1)
	var b:Array=frame(data,sheet,row,11)["bounds"];var factor:float=50.9375*(sqrt(2.0) if elite else 1)/maxf(1,float(data["sheets"][sheet]["reference_heights"][row]))
	var angle:float=corpse_angle(b)
	return Vector2(absf(cos(angle))*float(b[2])+absf(sin(angle))*float(b[3]),absf(sin(angle))*float(b[2])+absf(cos(angle))*float(b[3]))*factor
static func draw_corpse(c:CanvasItem,body:Dictionary) -> bool:
	if not body.has("roster_actor"):return false
	var en:Dictionary=body["roster_actor"];var data:Dictionary=manifest(str(en["roster_biome"]))
	if data.is_empty():return false
	var sheet:String="elite" if en.get("roster_elite",false) else "regular";var row:int=int(en["roster_row"])*(2 if sheet=="elite" else 1)
	var factor:float=50.9375*(sqrt(2.0) if sheet=="elite" else 1)/maxf(1,float(data["sheets"][sheet]["reference_heights"][row]))
	var item:Dictionary=frame(data,sheet,row,11);var b:Array=item["bounds"];var pivot:Array=item["pivot"]
	# Exact living scale, rigid rotation; no squash/stretch at death.
	var angle:float=float(body.get("face",1))*lerpf(.2,corpse_angle(b),clampf(float(body.get("age",0))/.25,0,1))
	var center:=Vector2(float(b[0])+float(b[2])*.5-float(pivot[0]),float(b[1])+float(b[3])*.5-float(pivot[1]))*factor
	center.x*=float(body["face"])
	var visible_height:float=(absf(sin(angle))*float(b[2])+absf(cos(angle))*float(b[3]))*factor
	var anchor:Vector2=body["pos"]-Vector2(0,visible_height*.5)-center.rotated(angle)
	return _draw(c,data,sheet,item,anchor,factor,float(body["face"]),Transform2D.IDENTITY,Color(.65,.65,.65,.85),angle)
