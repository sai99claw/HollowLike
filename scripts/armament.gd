class_name Armament
extends RefCounted
const Combat=preload("res://scripts/combat_library.gd")
const Data=preload("res://scripts/game_data.gd")
const Design=preload("res://scripts/monster_design.gd")
const MODES=["walk","jump","hover","drift","dash"]
const GROWTH=["damage","speed","size","shots","linear_shots","arc_shots","range"]
const GROWTH_NAMES={"damage":"副武器傷害 +1","speed":"副武器速度 +15%","size":"副武器體積 +15%","shots":"所有投射物 +1","linear_shots":"直線投射物 +1","arc_shots":"拋物線投射物 +1","range":"副武器距離 +15%"}
static func random_attack(rng:RandomNumberGenerator,group:String="biological",elite:bool=false) -> Dictionary:
	var kinds:Array=["slash","flying_slash","linear","arc","trap","explosion"]
	var kind:String=kinds[rng.randi_range(0,kinds.size()-1)]
	var high:float=1.25 if elite else .8
	var count:int=rng.randi_range(2,3) if elite else rng.randi_range(1,2)
	var def:Dictionary=Combat.attack(kind,{"size":rng.randf_range(12,24)*high,"range":rng.randf_range(260,580)*high,"speed":rng.randf_range(160,280)*high,"base_damage":1.0,"damage":1.0,"count":count,"piercing":rng.randf()<(.4 if elite else .12),"knockback":60.0,"windup":rng.randf_range(.6,.95),"active":.2,"recovery":rng.randf_range(.55,.85),"attack_cooldown":rng.randf_range(.8,1.6),"origin_y":-25,"group":group,"explode_on_hit":rng.randf()<(.5 if elite else .16),"explosion_radius":rng.randf_range(48,90),"path_kind":["straight","sine","arc"][rng.randi_range(0,2)],"wave_amplitude":rng.randf_range(12,30),"wave_frequency":rng.randf_range(3,5),"max_hits":rng.randi_range(1,3),"arming_time":.65,"launch_y":-rng.randf_range(180,300),"gravity":rng.randf_range(380,650),"parryable":kind in ["slash","flying_slash"]})
	if kind=="slash":def["range"]=rng.randf_range(55,95)*high;def["size"]=rng.randf_range(24,36)*high;def["width"]=def["size"]*2
	if kind=="explosion":def["range"]=rng.randf_range(75,110)*high;def["size"]=def["range"];def["explosion_radius"]=def["range"]
	if kind=="trap":def["range"]=rng.randf_range(180,330);def["size"]=rng.randf_range(24,40);def["count"]=1
	var bio_names:Dictionary={"slash":"爪刃","flying_slash":"振翼刃","linear":"羽刺","arc":"種籽吐息","trap":"孢子囊","explosion":"花粉爆發"}
	var artificial:Dictionary={"slash":"羽毛刀","flying_slash":"大刀","linear":"飛針發射器","arc":"投彈器","trap":"陷阱匣","explosion":"爆裂錘"}
	def["name"]=bio_names[kind] if group=="biological" else artificial[kind]
	def["weapon_visual"]={"slash":"weapon_feather","flying_slash":"weapon_heavy","linear":"weapon_launcher","arc":"weapon_bomb","trap":"weapon_trap","explosion":"weapon_hammer"}[kind] if group=="weapon" else ""
	if group=="weapon" and kind=="slash" and rng.randf()<.3:def["weapon_visual"]="weapon_spear";def["name"]="長槍"
	def["color"]=Color("f2cfa0") if group=="weapon" else Color("a6d9c2")
	return def
static func enemy(mode:String,rng:RandomNumberGenerator,elite:bool=false,passive:bool=false) -> Dictionary:
	var selected:String=mode if mode in MODES else "walk"
	var model:int={"walk":0,"jump":1,"hover":2,"drift":2,"dash":5}[selected]
	var names:Dictionary={"walk":"苔甲步蟲","jump":"彈枝跳蟲","hover":"守燈懸蛾","drift":"流霧漂蛾","dash":"疾根衝蟲"}
	var result:Dictionary={"id":selected+"_"+str(rng.randi()),"name":names[selected],"model":model,"move":"fly" if selected in ["hover","drift"] else "walk","hp":3.0 if passive else (10.0 if elite else 5.0),"scale":sqrt(2) if elite else 1.0,"body_size":Vector2(34,42)*(sqrt(2) if elite else 1),"elite":elite,"passive":passive,"contact_damage":0.0 if passive else 1.0,"damage":1.0,"speed":rng.randf_range(85,125) if elite else rng.randf_range(45,95),"attack_speed":rng.randf_range(1.15,1.6) if elite else rng.randf_range(.8,1.2),"movement_logic":"approach" if rng.randf()<.6 else "roam","movement_period":rng.randf_range(2.4,3.6),"jump_speed":rng.randf_range(460,550),"dash_speed":rng.randf_range(300,430),"dash_duration":rng.randf_range(.25,.42),"dash_windup":rng.randf_range(.45,.7),"hover_height":rng.randf_range(60,120),"roam_radius":rng.randf_range(120,240),"color":Color("cfb58b") if elite else Color("a7cfb1"),"range":80.0,"visual_movement":selected,"movements":[selected],"attacks":[]}
	result["species"]=selected;result["stop_radius"]=48.0;result["resume_margin"]=24.0
	result["dash_cooldown"]=3.4;result["dash_recovery"]=.65
	# Species retain their authored behavior across seeds and elite generation.
	result["movement_logic"]="roam" if selected in ["jump","drift"] or passive else "approach"
	if not passive:
		var spec:Dictionary=Design.regular_attack(selected)
		result["attacks"].append(Combat.attack(spec["library_kind"],spec))
	if elite and not passive:
		result["movements"].append("walk" if selected=="dash" else "dash")
		var spec:Dictionary=Design.regular_attack(selected,true)
		result["attacks"].append(Combat.attack(spec["library_kind"],spec));result["name"]="菁英·"+str(result["name"])
	return result
static func cute_wanderer(rng:RandomNumberGenerator) -> Dictionary:
	var result:Dictionary=enemy("walk",rng,false,true)
	result.merge({"id":"sleepy_leaf_pillbug_"+str(rng.randi()),"name":"葉帽糯糯蟲","species":"cute_pillbug","cute":true,"movement_logic":"roam","speed":30.0,"roam_radius":100.0,"movements":["walk"],"turn_delay":.26,"color":Color("e8d8ac")},true)
	return result
static func grow(stats:Dictionary,id:String) -> void:
	if id not in GROWTH:return
	stats[id]=float(stats.get(id,0))+1
static func growth_attack(source:Dictionary,stats:Dictionary) -> Dictionary:
	var def:Dictionary=source.duplicate(true)
	def["damage"]=float(def.get("damage",3))+float(stats.get("damage",0))
	def["speed"]=float(def.get("speed",400))*(1+float(stats.get("speed",0))*.15)
	def["size"]=float(def.get("size",def.get("radius",8)))*(1+float(stats.get("size",0))*.15)
	def["width"]=float(def.get("width",def["size"]*2))*(1+float(stats.get("size",0))*.15)
	def["range"]=float(def.get("range",850))*(1+float(stats.get("range",0))*.15)
	var kind:String=def.get("library_kind","linear")
	var extra:int=int(stats.get("shots",0))
	if kind=="arc" or def.get("path_kind","")=="arc":extra+=int(stats.get("arc_shots",0))
	elif kind=="linear":extra+=int(stats.get("linear_shots",0))
	if kind in ["linear","arc","flying_slash"]:def["count"]=clampi(int(def.get("count",def.get("shots",1)))+extra,1,20)
	def["shots"]=int(def.get("count",1))
	return def
