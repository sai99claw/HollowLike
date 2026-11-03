extends SceneTree
const Combat=preload("res://scripts/combat_library.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Director=preload("res://scripts/boss_director_v35.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func fixture(biome:String) -> Dictionary:
	var boss:Dictionary=Combat.boss(biome)
	boss.merge({"uid":7001,"pos":Vector2(650,1050),"vel":Vector2.ZERO,"face":1.0,"attack":Attack.new(),"max_hp":boss["hp"],"hurt":0.0,"stun":0.0,"cooldown":0.0,"contact_damage":0.0,"combat_engaged":true},true)
	return boss
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_process(false);scene.set_physics_process(false);scene.practice_mode=true
	scene.new_run("rogue",171);scene.rng.seed=35035;scene._close_panel()
	scene.layout["size"]=Vector2(1500,1120);scene.layout["floor_y"]=1050
	scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.freeze_timer=0
	scene.p["invul"]=1000;scene.p["pos"]=Vector2(760,1050)
	for biome:String in Combat.BOSS_BIOMES:
		var counts:Array[int]=[]
		for repeated_hits:bool in [false,true]:
			var boss:Dictionary=fixture(biome);scene.enemies.assign([boss]);scene.projectiles.clear();scene.hazards.clear()
			var starts:int=0;var previous:int=0
			for tick:int in 1200:
				# Same low-damage rapid-hit diagnostic as the review, not a victory bot.
				if repeated_hits and tick%6==0:scene._hit_enemy(boss,.01,Color.WHITE)
				scene.camera_pos=scene._camera_target(boss["pos"]);scene.p["pos"]=boss["pos"]+Vector2(110,0)
				scene._update_enemies(1.0/60,.8/60)
				var current:int=boss["attack"].attack_id
				if current>previous:starts+=1;previous=current
			check(int(boss["boss_phase"])==1 and not boss.get("adapted",false),"Full-health Boss learns no phase-two attack: "+biome)
			counts.append(starts)
		check(counts[0]>=2 and counts[1]>=2,"Boss still starts attacks under rapid weak hits: "+biome+str(counts))
		print("Boss rapid-hit diagnostic ",biome,": ",counts)
		var phased:Dictionary=fixture(biome);scene.enemies.assign([phased]);Director.prepare(phased)
		var original:int=phased["attacks"].size();phased["hp"]=float(phased["max_hp"])*.6
		# Phase transition waits until the authored attack ends.
		scene._start_enemy_attack(phased,phased["attacks"][0]);scene._update_enemies(.01)
		check(phased["boss_phase"]==1,"Phase does not erase a readable active attack: "+biome)
		phased["attack"].cancel();phased["charge_phase"]="idle";phased["stun"]=0
		scene._update_enemies(.01)
		check(phased["boss_phase"]==2 and phased["attacks"].size()==original+1,"HP threshold adds one ecology move: "+biome)
		for tick:int in 10:scene._update_enemies(.01)
		check(phased["boss_phase_events"]==1 and phased["attacks"].size()==original+1,"Second phase occurs only once: "+biome)
		phased["hp"]=float(phased["max_hp"])*.25;phased["attack"].cancel();phased["charge_phase"]="idle";phased["boss_phase_left"]=0
		scene._update_enemies(.01)
		check(phased["boss_phase"]==3 and phased["boss_phase_events"]==2,"Final phase follows its HP threshold: "+biome)
		phased["attack"].cancel();phased["hp"]=0
		scene._try_enemy_attack(phased,Vector2(110,0));scene._start_enemy_attack(phased,phased["attacks"][0]);scene._update_enemies(1)
		check(not phased["attack"].is_busy(),"Dead Boss never starts an attack: "+biome)
	# A substantial burst earns one real stagger, then continuous damage cannot
	# extend it or cancel every later attack during the recovery protection.
	var posture:Dictionary=fixture("underground");scene.enemies.assign([posture]);Director.prepare(posture)
	posture["attack"].begin(posture["attacks"][0]);scene._hit_enemy(posture,Director.posture_limit(posture),Color.WHITE)
	check(posture["boss_staggers"]==1 and not posture["attack"].is_busy() and posture["stun"]>0,"Posture break interrupts and rewards the player")
	posture["stun"]=.1;scene._hit_enemy(posture,1,Color.WHITE)
	check(is_equal_approx(float(posture["stun"]),.1) and posture["boss_staggers"]==1,"Damage cannot refresh stagger during its protection")
	Director.tick(posture,6,false);posture["boss_posture"]=3;posture["boss_posture_delay"]=0;Director.tick(posture,2,false)
	check(float(posture["boss_posture"])==0,"Posture recovers when pressure stops")
	# The mole alternates contextually and follows ground denial with a spread.
	var mole:Dictionary=fixture("underground");Director.prepare(mole);mole["boss_phase"]=2
	Director.started(mole,2)
	check(Director.choose(mole,Vector2(300,0),[0,1,2])==1,"Mole follows a root trap with the readable ranged branch")
	Director.started(mole,1)
	check(Director.choose(mole,Vector2(100,0),[0,1,2])==0,"Mole punishes close positioning with its claw branch")
	var attack:Dictionary=Director.attack_definition(mole,mole["attacks"][1])
	check(attack["spread"]>0 and attack["windup"]==mole["attacks"][1]["windup"] and attack["recovery"]==mole["attacks"][1]["recovery"],"Second-phase spread preserves its dodge and punish windows")
	for mode_name:String in ["rogue","musou"]:
		scene.new_run(mode_name,171);scene._close_panel()
		for chapter:Dictionary in scene.tower["maps"]:
			scene._enter_room(chapter["boss_id"]);scene._close_panel()
			var guards:Array=scene.enemies.filter(func(e):return e.get("elite",false))
			var bosses:Array=scene.enemies.filter(func(e):return e.get("model",0)==4)
			check(guards.size()==6 and bosses.size()==1,"Both modes start each chapter Boss with six elites "+str([chapter["index"],guards.size(),bosses.size()]))
			check(scene.props.filter(func(prop):return prop["kind"]=="launcher").size()>=2,"Boss arena has two bounce mushrooms")
			if bosses.is_empty():continue
			var boss:Dictionary=bosses[0]
			check(is_equal_approx(boss["max_hp"],(float(Combat.boss(boss["biome"])["hp"])+float(chapter["index"])*10.0)*2.0),"Boss HP is doubled after chapter scaling")
			var speed:float=boss["speed"]
			boss["hp"]=boss["max_hp"]*.5
			Director.enrage(boss);Director.enrage(boss)
			check(is_equal_approx(boss["speed"],speed*2) and boss["attack_speed"]==2,"Half-health speed and cadence double only once")
			for guard:Dictionary in guards:guard["hp"]=0
			scene.freeze_timer=0;scene.p["invul"]=1000
			var before:int=scene.enemies.size()
			boss["summon_check_left"]=.01
			scene._update_enemies(.02,.02)
			if mode_name=="musou":
				check(boss["vel"]==Vector2.ZERO and boss["summon_cast_left"]>0 and scene.enemies.size()==before,"Musou boss stops before reinforcements arrive")
				scene._update_enemies(.8,.8)
				check(scene.enemies.size()==before+3 and scene.enemies.slice(before).all(func(e):return not e.get("elite",false) and e["hp"]>0),"Cast summons exactly three ordinary enemies")
			else:check(not boss.has("summon_cast_left") and scene.enemies.size()==before,"Rogue boss never summons")
	scene.queue_free();await process_frame
	print("Boss director V35: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
