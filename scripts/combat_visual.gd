class_name CombatVisual
extends RefCounted
const ROOT="res://assets/combat_v05/"
const Appearance=preload("res://scripts/monster_appearance.gd")
const ALIASES={"claw_kick":"claw_short","heavy_front":"great_front","heavy_side":"great_side","heavy_spin":"great_spin","heavy_charge":"great_charge","soul":"pigeon_soul_fly","feather":"death_feather_glow","injury_launch":"pigeon_heavy_hurt","death_fall":"pigeon_death"}
static var manifest:Dictionary={}
static var textures:Dictionary={}
static func ensure() -> bool:
	if not manifest.is_empty():return true
	if not FileAccess.file_exists(ROOT+"manifest.json"):return false
	var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	if value is Dictionary:manifest=value
	return not manifest.is_empty()
static func has_clip(id:String) -> bool:return Appearance.is_pillbug_clip(id) or not Appearance.boss_definition(id).is_empty() or (ensure() and manifest["animations"].has(ALIASES.get(id,id)))
static func definition(id:String) -> Dictionary:
	if Appearance.is_pillbug_clip(id):return Appearance.pillbug_definition(id)
	var boss:Dictionary=Appearance.boss_definition(id)
	if not boss.is_empty():return boss
	return manifest["animations"].get(ALIASES.get(id,id),{}) if ensure() else {}
static func texture_for(id:String,index:int=0) -> Texture2D:
	if Appearance.is_pillbug_clip(id):return Appearance.pillbug()
	var clip:Dictionary=definition(id)
	if clip.is_empty():return null
	var f:Dictionary=clip["frames"][clampi(index,0,clip["frames"].size()-1)]
	if not textures.has(f["path"]):textures[f["path"]]=load(ROOT+f["path"])
	return textures[f["path"]]
static func warmup() -> void:
	# Import textures lazily; warming every 512px source would waste Web memory.
	ensure()
static func sample_index(clip:Dictionary,progress:float,phase:String="",time:float=-1) -> int:
	var count:int=clip["frames"].size()
	var p:float=clampf(progress,0,.99999)
	# Released charge plays every authored frame once, independent of absolute
	# world time, loop metadata or attack-speed upgrades.
	if phase=="active" and clip.get("complete_release",false):return mini(count-1,int(p*count))
	var phases:Dictionary=clip.get("phases",{})
	var selected:Array=phases.get(phase,[])
	if clip.has("loop_start") and phase in ["active","move","idle",""]:
		var first:int=int(clip["loop_start"]);var last:int=int(clip["loop_end"])
		var t:float=time if time>=0 else p*float(clip.get("active_duration",1.5))
		return first+int(t*float(clip.get("fps",12)))%(last-first+1)
	if time>=0 and phase in ["idle","move",""]:return int(time*float(clip.get("fps",12)))%count
	if not selected.is_empty():return int(selected[mini(selected.size()-1,int(p*selected.size()))])
	return mini(count-1,int(p*count))
static func frame(c:CanvasItem,id:String,progress:float,at:Vector2,base:Transform2D,face:float=1,extent:float=90,angle:float=0,tint:Color=Color.WHITE,phase:String="") -> bool:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return false
	var index:int=sample_index(clip,progress,phase)
	var f:Dictionary=clip["frames"][index]
	var size:Vector2=Vector2(f["size"][0],f["size"][1]);var pivot:Vector2=Vector2(f["pivot"][0],f["pivot"][1])
	var scale_value:float=extent/maxf(size.x,size.y)
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2(face*scale_value,scale_value),0,at))
	c.draw_texture_rect(texture_for(id,index),Rect2(-pivot,size),false,tint);c.draw_set_transform_matrix(base)
	return true
static func attack_mapping(id:String,target:Rect2,direction:String) -> Dictionary:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return {}
	var b:Array=clip["active_bounds"]
	var vertical:bool=direction in ["up","down"]
	return {"source":Rect2(b[0],b[1],b[2],b[3]),"target":target,"local_size":Vector2(target.size.y,target.size.x) if vertical else target.size,"angle":-PI*.5 if direction=="up" else (PI*.5 if direction=="down" else 0.0),"face":-1.0 if direction=="left" else 1.0}
static func fitted(c:CanvasItem,id:String,progress:float,target:Rect2,base:Transform2D,direction:String="right",phase:String="active",tint:Color=Color.WHITE,time:float=-1) -> bool:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return false
	var mapping:Dictionary=attack_mapping(id,target,direction)
	var index:int=sample_index(clip,progress,phase,time)
	var f:Dictionary=clip["frames"][index];var tex:Texture2D=texture_for(id,index)
	var ratio:Vector2=tex.get_size()/Vector2(f["size"][0],f["size"][1])
	var bounds:Rect2=mapping["source"]
	var region:Rect2=Rect2(bounds.position*ratio,bounds.size*ratio)
	c.draw_set_transform_matrix(base*Transform2D(mapping["angle"],Vector2(mapping["face"],1),0,target.get_center()))
	c.draw_texture_rect_region(tex,Rect2(-mapping["local_size"]*.5,mapping["local_size"]),region,tint)
	c.draw_set_transform_matrix(base);return true
static func actor(c:CanvasItem,id:String,progress:float,at:Vector2,base:Transform2D,face:float=1,scale_value:float=1,tint:Color=Color.WHITE,phase:String="",time:float=-1,center_anchor:bool=false) -> bool:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return false
	var index:int=sample_index(clip,progress,phase,time)
	var f:Dictionary=clip["frames"][index];var size:Vector2=Vector2(f["size"][0],f["size"][1])
	var pivot:Vector2=Vector2(f["pivot"][0],f["pivot"][1])
	var bounds:Array=f.get("visible_bounds",[0,0,size.x,pivot.y])
	pivot.y=float(bounds[1])+float(bounds[3])
	if id.begins_with("enemy_") or id.begins_with("elite_"):pivot.x=float(bounds[0])+float(bounds[2])*.5
	var factor:float=actor_factor(id)*scale_value
	var origin:Vector2=at
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*factor,factor),0,origin))
	c.draw_texture_rect(texture_for(id,index),Rect2(-pivot,size),false,tint);c.draw_set_transform_matrix(base);return true
static func actor_factor(id:String) -> float:
	var clip:Dictionary=definition(id)
	if clip.is_empty():return 1.0
	# Calibrate pigeon anatomy from its authored iris reference, never from a pose bbox.
	if id.begins_with("pigeon_") and clip.has("reference_calibration"):
		return sqrt(4.0/maxf(1,float(clip["reference_calibration"].get("target_area",80))))
	# Other species keep their resting-body reference.
	var reference:Dictionary=clip
	if id.begins_with("enemy_"):
		var parts:PackedStringArray=id.split("_")
		if parts.size()>2:reference=definition("enemy_"+parts[1]+"_move")
	elif id.begins_with("elite_"):reference=clip
	var frame:Dictionary=reference["frames"][0]
	var bounds:Array=frame.get("visible_bounds",reference.get("visual_bounds",[0,0,72,54]))
	return 57.0/maxf(1,float(bounds[3]))

static func player_clip(weapon:String,attack:Dictionary,anim:String) -> String:
	if anim=="hurt":return "pigeon_hurt"
	if anim in ["windup","active","recovery"] and attack.get("kind","") in ["slam","pierce"]:return ""
	if anim not in ["charge","windup","active","recovery"]:return ""
	if anim!="charge" and attack.has("body_clip"):return attack["body_clip"]
	if attack.get("great_spin_release",false) and anim!="charge":return "pigeon_great_spin"
	var group:String={"foot":"talons","quick":"featherblade","heavy":"greatblade"}.get(weapon,"talons")
	var direction:String=attack.get("direction","right")
	if anim!="charge" and direction in ["up","down"]:return "pigeon_"+group+"_"+direction
	if anim=="charge" or attack.get("charged",false):return "pigeon_"+{"foot":"talons","quick":"feather","heavy":"great"}.get(weapon,"talons")+"_charge"
	return "pigeon_"+{"claw_kick":"talons_kick","feather_left":"feather_left","feather_right":"feather_right","feather_thrust":"feather_thrust","heavy_front":"great_front","heavy_side":"great_side","heavy_spin":"great_spin"}.get(str(attack.get("fx_clip","claw_kick")),"talons_kick")
static func enemy_clip(en:Dictionary,phase:String) -> String:
	# An elite is a stronger member of its species, never the generic tree-mantis.
	if Appearance.is_boss(en):
		var biome:String=Appearance.biome(en)
		var boss_id:String=biome+"_"+(phase if phase in ["hurt","death"] else "move")
		return boss_id if not biome.is_empty() and has_clip(boss_id) else ""
	var species:String=Appearance.species(en)
	if species.is_empty():return ""
	var role:String="move"
	if phase in ["death","hurt"]:role=phase
	elif phase in ["windup","active","recovery"]:role="attack"
	elif phase in ["prepare","brake","turn"]:role=phase
	elif species=="dash" and float(en.get("motion_dash_wait",0))<0:role="prepare"
	elif species=="dash" and float(en.get("motion_dash_wait",0))>0:role="brake"
	elif species=="drift" and float(en.get("turn_left",0))>0:role="turn"
	var id:String="enemy_"+species+"_"+role
	if has_clip(id):return id
	# Missing art can only fall back to this same species' resting frame.
	var resting:String="enemy_"+species+"_move"
	return resting if has_clip(resting) else ""
static func held_weapon(c:CanvasItem,style:String,at:Vector2,face:float,attack:Variant,base:Transform2D) -> void:
	if style=="foot":return
	var id:String="weapon_heavy" if style=="heavy" else "weapon_feather"
	var angle:float=-.3
	if attack.is_busy():
		var p:float=attack.progress()
		angle=lerpf(-.4,-1.5,p) if attack.phase=="windup" else (lerpf(-1.5,1.25,p) if attack.phase=="active" else lerpf(1.25,-.3,p))
	if style=="heavy" and attack.phase=="active":angle=1.05
	frame(c,id,0,at+Vector2(face*16,-27),base,face,86 if style=="heavy" else 50,angle*face)
static func projectile(c:CanvasItem,pr:Dictionary,time:float,base:Transform2D) -> bool:
	var kind:String=pr.get("kind","shot");var library:String=pr.get("style_id",kind)
	var group:String=pr.get("group","weapon" if pr.get("from_player",false) else "biological")
	var id:String="projectile_marble" if kind=="bounce" else "projectile_needle"
	if pr.get("trap_carrier",false):id="trap_case" if group=="weapon" else "trap_spore"
	elif kind=="flying_slash" or library=="flying_slash":id="flying_slash_weapon" if group=="weapon" else "flying_slash_bio"
	elif kind in ["throw","arc"]:id="weapon_bomb" if group=="weapon" else "trap_spore"
	elif kind=="fan":id="projectile_marble"
	var radius:float=float(pr.get("radius",8));var direction:Vector2=pr.get("vel",Vector2.RIGHT).normalized()
	var angle:float=direction.angle()
	var local_base:Transform2D=base*Transform2D(angle,pr["pos"])
	if kind=="wave":
		for i in 3:c.draw_arc(pr["pos"],radius*(.6+float(i)*.22),angle-PI*.45,angle+PI*.45,24,Color(.85,.82,1,.8-float(i)*.2),4-i,true)
		return true
	if kind=="beam":
		for i in 3:
			var width:float=radius*2.0/3
			var center:Vector2=Vector2((i-1)*width,0)
			var clip:String=["beam_start","beam_body","beam_end"][i]
			fitted(c,clip,0,Rect2(center-Vector2(width*.5,radius),Vector2(width,radius*2)),local_base,"right","active",Color.WHITE,time)
		c.draw_set_transform_matrix(base);return true
	var box:Rect2=Rect2(-Vector2.ONE*radius,Vector2.ONE*radius*2)
	var progress:float=0
	var phase:String="active"
	if pr.get("trap_carrier",false) or id=="trap_spore":phase="flight";progress=clampf(float(pr.get("elapsed",0))/maxf(.01,float(pr.get("life",1))+float(pr.get("elapsed",0))),0,.99)/3.0
	var result:bool=fitted(c,id,progress,box,local_base,"right",phase,Color.WHITE,-1 if phase=="flight" else time)
	c.draw_set_transform_matrix(base);return result
static func hazard(c:CanvasItem,h:Dictionary,time:float,base:Transform2D) -> bool:
	if not str(h.get("boss_biome","")).is_empty():return false
	var id:String="trap_case" if h.get("group","biological")=="weapon" else "trap_spore"
	var radius:float=float(h.get("size",30));var arming:float=float(h.get("arming_time",.65));var elapsed:float=float(h.get("elapsed",0))
	var progress:float=clampf(elapsed/maxf(.01,arming),0,.99)*8.0/12.0
	return fitted(c,id,progress,Rect2(h["pos"]-Vector2(radius,radius*1.6),Vector2(radius*2,radius*1.6+5)),base,"right","active" if elapsed>=arming else "arming",Color.WHITE,time if elapsed>=arming else -1)
