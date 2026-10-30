class_name MonsterRosterV36
extends RefCounted
## The behavior roster consumes the same frozen anatomy brief used by image generation.
const Combat=preload("res://scripts/combat_library.gd")
const BIOMES:Array[String]=["underground","trunk","sky"]
const STAGES:Array[String]=["underground","underground","trunk","trunk","sky","sky"]
static var briefs:Dictionary={}
static func brief(biome:String) -> Dictionary:
	var id:String=biome if biome in BIOMES else "underground"
	if not briefs.has(id):briefs[id]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v36/monsters/"+id+"-brief.json"))
	return briefs[id]
static func regular(biome:String,index:int) -> Dictionary:
	var data:Dictionary=brief(biome);var row:int=posmod(index,5);var spec:Array=data["regular"][row]
	var result:Dictionary=_actor(str(data["biome"]),row,str(spec[0]),str(spec[1]),str(spec[2]),false)
	result["attacks"]=[_attack(str(data["biome"]),str(spec[3]),str(spec[6]),0,false)]
	if spec[3]=="ram":result["stop_radius"]=36.0
	return result
static func elite(stage:int) -> Dictionary:
	var chapter:int=clampi(stage,0,5);var biome:String=STAGES[chapter];var row:int=chapter%2
	var spec:Array=brief(biome)["elite"][row]
	var result:Dictionary=_actor(biome,row,str(spec[0]),str(spec[1]),str(spec[2]),true)
	var first:String="ram" if spec[5]=="ram" else ("flying_slash" if spec[6]!=null else "slash")
	var second:String="arc" if spec[8] in ["resin_orb","web_seed"] else ("flying_slash" if spec[8]=="leaf_crescent" else "linear")
	result["attacks"]=[_attack(biome,first,str(spec[5]),0,true),_attack(biome,second,str(spec[8]),1,true)]
	if first=="ram":result["stop_radius"]=36.0
	result["elite_stage"]=chapter
	return result
static func _actor(biome:String,row:int,id:String,title:String,movement:String,is_elite:bool) -> Dictionary:
	var tint:Color={"underground":Color("ddb46e"),"trunk":Color("8edca4"),"sky":Color("9cdbff")}[biome]
	var scale_value:float=sqrt(2.0) if is_elite else 1.0
	return {"id":id,"name":title,"roster_id":id,"roster_biome":biome,"roster_row":row,"roster_elite":is_elite,"species":id,"biome":biome,
		"model":3 if is_elite else (2 if movement in ["hover","drift"] else 1 if movement=="jump" else 0),"elite":is_elite,"passive":false,
		"move":"fly" if movement in ["hover","drift"] else "walk","visual_movement":movement,"movements":[movement],
		"movement_logic":"roam" if movement in ["jump","hover","drift"] else "approach","movement_period":3.0,"speed":78.0 if is_elite else 62.0,
		"hp":10.0 if is_elite else 5.0,"scale":scale_value,"body_size":Vector2(34,45)*scale_value,"world_height":50.9375*scale_value,
		"contact_damage":1.0,"damage":1.0,"attack_speed":1.0,"range":100.0,"jump_speed":460.0,"hover_height":95.0,"roam_radius":150.0,
		"stop_radius":80.0,"resume_margin":24.0,"turn_delay":.18,"color":tint}
static func _attack(biome:String,kind:String,visual:String,index:int,is_elite:bool) -> Dictionary:
	var ram:bool=kind=="ram";var melee:bool=kind=="slash" or ram
	var tint:Color={"underground":Color("ddb46e"),"trunk":Color("8edca4"),"sky":Color("9cdbff")}[biome]
	var key:String="v36:"+biome+":"
	var attack_name:String={"slash":"近身爪斬","ram":"蓄勢衝撞","linear":"瞄準直射","arc":"拋物投擲","trap":"種囊布陷","flying_slash":"飛行刃波"}.get(kind,kind)
	var params:Dictionary={"name":attack_name,"damage":1.0,"count":1,"range":110.0 if melee else 620.0,"size":30.0 if melee else 10.0,
		"windup":.85 if is_elite else .6,"active":.22 if melee else .14,"recovery":.8 if is_elite else .65,"attack_cooldown":1.35,
		"speed":220.0,"gravity":560.0 if kind=="arc" else 0.0,"launch_y":-285.0 if kind=="arc" else 0.0,"origin_y":-28.0,
		"color":tint,"group":"biological","roster_attack":index,"visual_id":key+("melee_fx" if melee else visual),"style_id":key+visual,
		"melee_visual_id":key+"melee_fx","hazard_visual_id":key+"trap_fx","parryable":kind in ["slash","flying_slash"],"ram":ram,"ram_speed":340.0,
		"hp":1.0,"lifetime":3.0,"arming_time":.8,"max_hits":1,"hit_interval":.8}
	if is_elite and not melee:params["count"]=3 if visual in ["mineral_dart","feather"] else 1;params["spread"]=.22
	if kind=="trap":params["range"]=340.0;params["size"]=24.0
	if ram:params["range"]=235.0;params["size"]=24.0;params["active"]=.42;params["recovery"]=.9;params["parryable"]=false
	return Combat.attack("slash" if ram else kind,params)
