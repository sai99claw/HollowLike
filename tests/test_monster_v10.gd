extends SceneTree
const Arms=preload("res://scripts/armament.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Motion=preload("res://scripts/enemy_motion.gd")
const Design=preload("res://scripts/monster_design.gd")
const Coll=preload("res://scripts/world_collision.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func fixture(definition:Dictionary) -> Dictionary:
	var en:Dictionary=definition.duplicate(true)
	en.merge({"pos":Vector2(500,700),"vel":Vector2.ZERO,"face":1.0,"attack":Attack.new()},true)
	return en
func run() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=103
	var identities:Dictionary={}
	for mode in Arms.MODES:
		var first:Dictionary=Arms.enemy(mode,rng)
		identities[first["attacks"][0]["visual_id"]]=true
		for sample in 40:
			var small:Dictionary=Arms.enemy(mode,rng)
			check(small["attacks"][0]["visual_id"]==first["attacks"][0]["visual_id"] and small["attacks"][0]["library_kind"]==first["attacks"][0]["library_kind"],"Species attack identity survives RNG: "+mode)
			check(small["attacks"][0]["damage"]==1 and small["contact_damage"]==1,"Small enemies deal exactly one damage")
		var elite:Dictionary=Arms.enemy(mode,rng,true)
		check(elite["movements"].has("dash") and elite["attacks"][1]["visual_id"]==first["attacks"][0]["visual_id"],"Elite preserves anatomy and adds a charge")
	check(identities.size()==5,"All five enemy appearances have distinct projectile identities")
	# Alternate the target at sub-body distances for ten seconds: no jitter.
	var walker:Dictionary=fixture(Arms.enemy("walk",rng));var turns:int=0
	for tick in 600:
		var old_face:float=walker["face"]
		var vel:Vector2=Motion.velocity(walker,walker["pos"]+Vector2(10 if tick%2==0 else -10,0),1.0/60,rng,true)
		walker["vel"]=Vector2(vel.x,0);walker["pos"].x+=vel.x/60
		if walker["face"]!=old_face:turns+=1
	check(turns==0 and absf(walker["pos"].x-500)<1,"Near-target stop band removes position and facing oscillation")
	for tick in 20:Motion.update_facing(walker,200,.02)
	check(walker["face"]==-1,"Sustained target reversal eventually turns the creature")
	# Wander targets remain fixed long enough to walk; reaching one does not reroll.
	var cute:Dictionary=fixture(Arms.cute_wanderer(rng));Motion.velocity(cute,Vector2(1000,700),.01,rng,true)
	var destination:Vector2=cute["roam_target"]
	for tick in 90:
		cute["vel"]=Motion.velocity(cute,Vector2(200,700),.02,rng,true)
		cute["pos"].x+=cute["vel"].x*.02
		check(cute["roam_target"]==destination,"Wander direction does not reroll every frame")
	check(cute["passive"] and cute["attacks"].is_empty() and cute["contact_damage"]==0 and cute["pos"].distance_to(Vector2(500,700))>15,"Cute pillbug really wanders without hostile attacks")
	# Every boss naturally reaches its new charge mode without replacing old ones.
	for biome in Combat.BOSS_BIOMES:
		var boss:Dictionary=fixture(Combat.boss(biome));var active:bool=false;var windup:bool=false
		var adaptation:Dictionary=Combat.attack("trap")
		Design.decorate_adaptation(adaptation,boss)
		check(Design.CELLS.has(adaptation["visual_id"]) and Design.CELLS.has(adaptation["hazard_visual_id"]) and adaptation["hp"]==1,"Boss adaptation retains species art and destructible trap")
		check(boss["movements"].has("dash") and boss["movements"].size()>=2,"Boss includes charge and original movement: "+biome)
		for definition:Dictionary in boss["attacks"]:check(Design.CELLS.has(definition["visual_id"]),"Boss attack resolves authored projectile: "+biome)
		for tick in 1500:
			var target:Vector2=Vector2(900,500 if biome=="sky" else 700)
			boss["vel"]=Motion.velocity(boss,target,.02,rng,true)
			if boss["charge_phase"]=="windup":windup=true;check(not Motion.can_attack(boss),"Charge windup cannot be interrupted by ranged attack")
			if boss["charge_phase"]=="active":
				active=true
				if biome=="sky":check(Motion.airborne(boss) and boss["charge_vector"].y<0,"Flying boss aims a real diagonal charge")
		check(windup and active,"Boss actually executes telegraph then charge: "+biome)
	# A concrete swept collision stops charge and enters recovery, not repeated windup.
	var charger:Dictionary=fixture(Arms.enemy("dash",rng));charger["dash_windup"]=.2;var hit:bool=false;var fastest:float=0
	var walls:Array=[Rect2(610,400,40,400),Rect2(0,700,1500,60)]
	for tick in 120:
		var wanted:Vector2=Motion.velocity(charger,Vector2(1000,700),.02,rng,true)
		fastest=maxf(fastest,absf(wanted.x))
		var result:Dictionary=Coll.move_body(charger["pos"],wanted,.02,Vector2(34,42),walls)
		Motion.resolve_collision(charger,wanted,result["vel"]);charger["pos"]=result["pos"];charger["vel"]=result["vel"]
		if charger.get("charge_hit_wall",false):hit=true;break
	check(hit and fastest>290 and charger["pos"].x<=593.1,"Charge travels and ends on the actual collision plane")
	check(charger["charge_phase"]=="recovery" and charger["charge_cooldown"]>3,"Wall impact incurs recovery and cooldown")
	# Every cell is an imported production texture, including the cute actor.
	for id in Design.CELLS:check(Design.texture_for(id) is Texture2D,"Authored atlas cell loads: "+id)
	for id in ["cute_pillbug","moss_thorns","pollen_flower","silk_web","dew_pool"]:
		var source:Image=Design.texture_for(id).get_image();var planted:bool=false
		for x in source.get_width():
			if source.get_pixel(x,source.get_height()-1).a>.3:planted=true;break
		check(planted,"Curated visible foot touches texture baseline: "+id)
	# Exercise the actual main loop: projectile attacks must not starve charges.
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_process(false);scene.set_physics_process(false);scene.practice_mode=true
	scene.new_run("rogue",103);scene.rng.seed=103;scene._close_panel();scene.layout["size"]=Vector2(1500,1120);scene.layout["floor_y"]=1050;scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)])
	scene.p["pos"]=Vector2(920,1050);scene.p["hp"]=100;scene.p["invul"]=1000;scene.freeze_timer=0
	for biome in Combat.BOSS_BIOMES:
		var actual:Dictionary=Combat.boss(biome)
		actual.merge({"pos":Vector2(650,1050),"vel":Vector2.ZERO,"face":1.0,"attack":Attack.new(),"uid":7001,"max_hp":actual["hp"],"hurt":0.0,"stun":0.0,"cooldown":0.0,"adapted":true},true)
		scene.enemies.assign([actual]);var windups:int=0;var last_phase:String="idle";var traveled:bool=false;var ranged:int=0
		for tick in 1800:
			scene.camera_pos=scene._camera_target(scene.p["pos"]);var before:Vector2=actual["pos"]
			scene._update_enemies(.02)
			if actual["charge_phase"]=="windup" and last_phase!="windup":windups+=1
			if last_phase=="active" and actual["pos"].distance_to(before)>1:traveled=true
			last_phase=actual["charge_phase"];ranged=maxi(ranged,scene.projectiles.size())
		check(windups>=2 and traveled and ranged>0,"Real Boss loop alternates original projectile attacks and repeated traveling charges: "+biome)
		scene.projectiles.clear();scene.hazards.clear()
	scene.queue_free();await process_frame
	print("Monster v0.10: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
