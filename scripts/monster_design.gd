class_name MonsterDesign
extends RefCounted
## Species-authored attacks. Random weapon generation is reserved for loot.
const ROOT="res://assets/monster_v10/"
const FX=preload("res://scripts/combat_visual.gd")
const Appearance=preload("res://scripts/monster_appearance.gd")
const MotionV18=preload("res://scripts/monster_motion_v18.gd")
const TrapArt=preload("res://scripts/trap_visual_v22.gd")
const Actions=preload("res://scripts/monster_actions_v22.gd")
const CELLS={"moss_shard":0,"spring_seed":1,"lamp_pollen":2,"mist_spore":3,"root_spear":4,"storm_feather":5,"leaf_moon":6,"silk_cocoon":7,"amber_resin":8,"dew_bubble":9,"root_wave":10,"cute_pillbug":11,"moss_thorns":12,"pollen_flower":13,"silk_web":14,"dew_pool":15}
const REGIONS={"moss_shard":[28,60,325,179],"spring_seed":[407,68,274,155],"lamp_pollen":[742,50,295,176],"mist_spore":[1113,72,302,163],"root_spear":[19,316,335,172],"storm_feather":[394,304,339,204],"leaf_moon":[762,293,287,241],"silk_cocoon":[1102,322,313,164],"amber_resin":[20,579,322,190],"dew_bubble":[397,580,287,196],"root_wave":[738,581,365,198],"cute_pillbug":[1138,572,260,206],"moss_thorns":[22,809,313,244],"pollen_flower":[370,818,340,236],"silk_web":[732,830,347,225],"dew_pool":[1101,824,328,231]}
const BOSS_VISUALS={"cloud_crescent":"storm_feather","storm_feather":"storm_feather","mantis_shear":"leaf_moon","leaf_moon":"leaf_moon","silk_stitch":"silk_cocoon","silk_cocoon":"silk_cocoon","silk_web":"silk_web","amber_pincers":"amber_resin","amber_resin":"amber_resin","reed_slash":"dew_bubble","dew_bubble":"dew_bubble","dew_pool":"dew_pool","root_claw":"root_wave","root_wave":"root_wave","root_spike":"moss_thorns"}
static var atlas:Texture2D
static var sprites:Dictionary={}

static func regular_attack(mode:String,elite_secondary:bool=false) -> Dictionary:
	var specs:Dictionary={
		"walk":{"library_kind":"slash","name":"苔甲鉗斬","visual_id":"moss_shard","size":28,"range":84,"windup":.65,"recovery":.65,"color":Color("a6c885")},
		"jump":{"library_kind":"arc","name":"彈枝種籽","visual_id":"spring_seed","size":12,"range":600,"speed":235,"gravity":560,"launch_y":-275,"windup":.72,"recovery":.70,"color":Color("c6aa7c")},
		"hover":{"library_kind":"linear","name":"守燈光塵","visual_id":"lamp_pollen","size":11,"range":620,"speed":195,"path_kind":"sine","wave_amplitude":12,"wave_frequency":4,"windup":.85,"recovery":.75,"color":Color("eed585")},
		"drift":{"library_kind":"trap","name":"流霧孢子囊","visual_id":"mist_spore","hazard_visual_id":"pollen_flower","size":29,"range":350,"speed":205,"gravity":460,"launch_y":-175,"arming_time":.8,"lifetime":4.2,"max_hits":1,"windup":.9,"recovery":.8,"color":Color("c6b4df")},
		"dash":{"library_kind":"flying_slash","name":"疾根角刺","visual_id":"root_spear","size":13,"range":430,"speed":275,"windup":.65,"recovery":.8,"color":Color("b5bd86")}
	}
	var result:Dictionary=specs.get(mode,specs["walk"]).duplicate(true)
	result.merge({"count":1,"damage":1.0,"base_damage":1.0,"active":.16,"attack_cooldown":1.35,"origin_y":-25,"group":"biological","style_id":result["visual_id"],"parryable":result["library_kind"] in ["slash","flying_slash"]},false)
	if elite_secondary:
		# The elite carries one consistent weapon derived from its own anatomy.
		var primary_kind:String=result["library_kind"]
		result["library_kind"]="linear" if primary_kind!="linear" else "flying_slash"
		result["group"]="weapon";result["name"]="菁英·"+str(result["name"])
		result["range"]=620;result["speed"]=270;result["size"]=13;result["count"]=2
		result["weapon_visual"]="weapon_launcher" if result["library_kind"]=="linear" else "weapon_feather"
		result["attack_cooldown"]=1.7;result["windup"]=.85
	return result

static func decorate_boss(result:Dictionary) -> void:
	if not result["movements"].has("dash"):result["movements"].append("dash")
	result["dash_windup"]=.8;result["dash_duration"]=.52;result["dash_recovery"]=.8;result["dash_cooldown"]=4.6
	result["stop_radius"]=110.0;result["resume_margin"]=32.0;result["facing_deadzone"]=40.0
	result["charge_name"]={"sky":"收翼雷襲","canopy":"伏鐮突進","branches":"抱繭衝撞","trunk":"低角破木","grass":"鼓腹躍撞","underground":"伏地鑽進"}.get(result["biome"],"蓄勢衝鋒")
	for definition:Dictionary in result["attacks"]:
		definition["visual_id"]=BOSS_VISUALS.get(definition.get("style_id",""),"root_spear")
		definition["hazard_visual_id"]=definition["visual_id"]
		if definition["library_kind"]=="trap":definition["hp"]=1.0

static func decorate_adaptation(definition:Dictionary,boss:Dictionary) -> void:
	var biome:String=str(boss.get("biome","branches"))
	var visuals:Dictionary={"sky":"storm_feather","canopy":"leaf_moon","branches":"silk_cocoon","trunk":"amber_resin","grass":"dew_bubble","underground":"root_wave"}
	var traps:Dictionary={"sky":"pollen_flower","canopy":"moss_thorns","branches":"silk_web","trunk":"moss_thorns","grass":"dew_pool","underground":"moss_thorns"}
	var names:Dictionary={"sky":"雷羽變奏","canopy":"鐮葉變奏","branches":"織絲變奏","trunk":"琥珀變奏","grass":"露泡變奏","underground":"根鑽變奏"}
	definition["visual_id"]=visuals.get(biome,"root_spear");definition["hazard_visual_id"]=traps.get(biome,"moss_thorns")
	definition["style_id"]=definition["visual_id"];definition["name"]=names.get(biome,"生態變奏")
	definition["boss_biome"]=biome;definition["color"]=boss.get("color",Color.WHITE)
	if definition.get("library_kind","")=="trap":definition["hp"]=1.0

static func texture_for(id:String) -> Texture2D:
	if not CELLS.has(id):return null
	if sprites.has(id):return sprites[id]
	if atlas==null:
		if not ResourceLoader.exists(ROOT+"projectile-atlas.png"):return null
		atlas=load(ROOT+"projectile-atlas.png")
	var source:Array=REGIONS[id]
	var region:=AtlasTexture.new();region.atlas=atlas
	region.region=Rect2(source[0],source[1],source[2],source[3])
	sprites[id]=region;return region

static func draw_projectile(c:CanvasItem,pr:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if preload("res://scripts/monster_art_v36.gd").draw_projectile(c,pr,base):return true
	var tex:Texture2D=texture_for(str(pr.get("visual_id","")))
	if tex==null:return false
	var radius:float=float(pr.get("radius",12));var velocity:Vector2=pr.get("vel",Vector2.RIGHT)
	var angle:float=velocity.angle()
	if pr.get("visual_id","") in ["spring_seed","mist_spore","amber_resin","dew_bubble"]:angle=time*1.3
	c.draw_set_transform_matrix(base*Transform2D(angle,pr["pos"]))
	var size:Vector2=tex.get_size()/maxf(tex.get_width(),tex.get_height())*radius*3.0
	c.draw_texture_rect(tex,Rect2(-size*.5,size),false)
	c.draw_set_transform_matrix(base);return true

static func draw_hazard(c:CanvasItem,h:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if preload("res://scripts/monster_art_v36.gd").draw_hazard(c,h,base):return true
	if TrapArt.draw(c,h,base):return true
	var id:String=str(h.get("hazard_visual_id",h.get("visual_id","")))
	if id=="mist_spore":id="pollen_flower"
	var tex:Texture2D=texture_for(id)
	if tex==null:return false
	var armed:bool=float(h.get("elapsed",0))>=float(h.get("arming_time",.5))
	var width:float=float(h.get("size",30))*2.2
	var growth:float=1.0 if armed else .45+.55*clampf(float(h.get("elapsed",0))/maxf(.01,float(h.get("arming_time",.5))),0,1)
	var size:Vector2=tex.get_size()*(width/tex.get_width())*growth
	# Curated source bounds end exactly at the visible planted foot.
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(tex,Rect2(h["pos"]-Vector2(size.x*.5,size.y),size),false,Color(1,1,1,1.0 if armed else .55))
	return true

static func draw_actor(c:CanvasItem,en:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if preload("res://scripts/monster_art_v36.gd").draw_actor(c,en,time,base):return true
	if not en.get("cute",false):return _draw_species(c,en,time,base)
	if Actions.regular(c,en,time,base):return true
	if float(en.get("hurt",0))<=0 and MotionV18.draw(c,en,time,base):return true
	var tex:Texture2D=texture_for("cute_pillbug")
	if tex==null:return false
	var moving:bool=absf(en.get("vel",Vector2.ZERO).x)>5
	var bob:float=absf(sin(time*9))*2 if moving else sin(time*2)*.6
	var squash:float=1+sin(time*9)*.035 if moving else 1.0
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(float(en.get("face",1))/squash,squash),0,en["pos"]-Vector2(0,bob)))
	var size:Vector2=tex.get_size()*(57.0/tex.get_height())
	c.draw_texture_rect(tex,Rect2(Vector2(-size.x*.5,-size.y),size),false,Color("ffc9b4") if float(en.get("hurt",0))>0 else Color.WHITE)
	c.draw_set_transform_matrix(base);return true

static func _draw_species(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> bool:
	if Appearance.is_boss(en):return false
	var species:String=Appearance.species(en)
	if species.is_empty():return true
	var attack:Variant=en.get("attack")
	var phase:String="hurt" if float(en.get("hurt",0))>0 else (str(attack.phase) if attack!=null else "idle")
	var progress:float=1-float(en.get("hurt",0))/.2 if phase=="hurt" else (attack.progress() if attack!=null else 0.0)
	var charge:String=en.get("charge_phase","idle")
	if phase=="idle" and species=="dash":
		if charge=="windup":phase="prepare";progress=1-float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_windup",.6)))
		elif charge=="recovery":phase="brake";progress=1-float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_recovery",.65)))
	var clip:String=FX.enemy_clip(en,phase)
	if Actions.regular(c,en,time,base):pass
	elif phase=="idle" and MotionV18.draw(c,en,time,base):pass
	elif not clip.is_empty():FX.actor(c,clip,progress,en["pos"],base,float(en.get("face",1)),float(en.get("scale",1)),Color.WHITE,phase,time if phase=="idle" else -1,species in ["hover","drift"])
	# Returning true prevents model-based legacy fallback from substituting a
	# guardian/beetle when a species pose is unavailable. Held items are separate.
	if en.get("elite",false) and en.get("attacks",[]).size()>1:
		var weapon:String=str(en["attacks"][1].get("weapon_visual",""))
		if not weapon.is_empty():FX.frame(c,weapon,0,en["pos"]+Vector2(float(en.get("face",1))*23,-28),base,float(en.get("face",1)),46)
	return true

static func draw_charge(c:CanvasItem,en:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY) -> void:
	var phase:String=en.get("charge_phase","idle")
	if phase not in ["windup","active"]:return
	var at:Vector2=en["pos"]-Vector2(0,20)
	var dir:Vector2=en.get("charge_vector",Vector2.RIGHT)
	var color:Color=en.get("color",Color("d5dba2"))
	c.draw_set_transform_matrix(base)
	if phase=="windup":
		var progress:float=1-float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_windup",.6)))
		for i in 5:
			var angle:float=time*3+i*TAU/5;var distance:float=lerpf(34,8,fmod(progress+float(i)*.2,1))
			c.draw_circle(at+Vector2.from_angle(angle)*distance,1.5,Color(color,.65))
		c.draw_circle(at+dir*13,3+progress*2,Color("fff2c2",.3+.45*progress))
	else:
		for i in 4:
			var tail:Vector2=at-dir*(12+i*12)+dir.orthogonal()*sin(time*17+i)*6
			c.draw_line(tail-dir*14,tail,Color(color,.5-float(i)*.1),2,false)
