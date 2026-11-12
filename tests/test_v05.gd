extends SceneTree
const Arms=preload("res://scripts/armament.gd")
const Data=preload("res://scripts/game_data.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Coll=preload("res://scripts/world_collision.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Clock=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func enemy(at:Vector2=Vector2(600,1050)) -> Dictionary:
	var random:=RandomNumberGenerator.new();random.seed=13
	var result:Dictionary=Arms.enemy("walk",random)
	result.merge({"pos":at,"vel":Vector2.ZERO,"uid":999,"max_hp":100.0,"hp":100.0,"attack":Clock.new(),"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":100.0},true)
	return result
func run() -> void:
	var random:=RandomNumberGenerator.new();random.seed=122
	var kinds:Dictionary={};var motions:Dictionary={}
	for i in 600:
		var mode:String=Arms.MODES[i%5];var small:Dictionary=Arms.enemy(mode,random)
		motions[small["movements"][0]]=true;kinds[small["attacks"][0]["library_kind"]]=true
		check(small["hp"]==5 and small["contact_damage"]==1 and small.has("attack_speed") and small.has("dash_windup"),"Small enemies use new base stats and movement/attack-speed parameters")
		check(float(small["attacks"][0]["damage"])==1.0,"Small enemy attack is exactly one damage")
		check(small["attacks"].size()==1 and small["attacks"][0]["group"]=="biological","Small enemy has one species-authored biological weapon")
		var elite:Dictionary=Arms.enemy(mode,random,true)
		check(elite["movements"].size()==2 and elite["movements"][0]!=elite["movements"][1],"Elite has two distinct movements")
		check(elite["attacks"][0]["library_kind"]!=elite["attacks"][1]["library_kind"] and elite["attacks"][1]["group"]=="weapon","Elite has two distinct attack types including artificial weapon")
		check(is_equal_approx(elite["body_size"].x*elite["body_size"].y,34.0*42*2),"Elite area is twice standard enemy")
	check(kinds.size()==5 and motions.size()==5,"Five species retain five distinct authored attack and movement signatures")
	var passive:Dictionary=Arms.enemy("walk",random,false,true)
	check(passive["hp"]==3 and passive["attacks"].is_empty() and passive["contact_damage"]==0,"Passive enemy has 3 HP and no damage")
	for i in 3:
		var base:Dictionary=Data.primary_attack(i,"right",false)
		var charge:Dictionary=Data.primary_attack(i,"right",true)
		check(base["damage"]==[2,3,5][i] and charge["damage"]==[3,5,8][i],"Primary and rounded charge damage")
		check(is_equal_approx(charge["active"],1.0) and charge["super_armor"],"Charged attack lasts one second with armor")
		check(base["recoil"]==[60,30,0][i] and charge["recoil"]==0,"Normal recoil is preserved; charged release is freely mobile")
	check(Data.primary_attack(0,"right",false)["windup"]==0 and Data.primary_attack(0,"right",false)["recovery"]>0,"Instant unarmed kick retains its original cadence as steerable recovery")
	check(Data.primary_attack(1,"right",false,false,2)["block_width"]<Data.primary_attack(1,"right",false,false,0)["block_width"],"Feather thrust has a narrower block volume")
	var stats:Dictionary={}
	for id in Arms.GROWTH:Arms.grow(stats,id)
	var linear:Dictionary=Arms.growth_attack(Combat.attack("linear",{"damage":3,"count":1,"speed":200,"size":10,"range":300}),stats)
	var arc:Dictionary=Arms.growth_attack(Combat.attack("arc",{"damage":3,"count":1}),stats)
	check(linear["count"]==3 and arc["count"]==3,"Global plus matching trajectory projectile counts")
	check(linear["damage"]==4 and is_equal_approx(linear["speed"],230) and is_equal_approx(linear["size"],11.5) and is_equal_approx(linear["range"],345),"Damage/speed/size/range growth all applied")
	var walls:Array[Rect2]=[Rect2(700,500,40,550),Rect2(0,1050,1500,70)]
	var collided:Dictionary=Coll.move_body(Vector2(600,800),Vector2(2000,0),.3,Vector2(34,42),walls)
	check(collided["pos"].x<=683 and collided["wall"]==1,"High-speed actor hits and can attach to trunk")
	var underside:Dictionary=Coll.move_body(Vector2(720,1120),Vector2(0,-1000),.2,Vector2(34,42),[Rect2(700,950,80,50)])
	check(underside["pos"].y>=1042,"Solid square blocks upward passage")
	check(Coll.first_solid(Vector2(500,700),Vector2(900,700),5,walls)<INF,"Trunk blocks swept projectile")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_physics_process(false);scene.set_process(false);scene.audio_enabled=false;scene.practice_mode=true
	var vault:Dictionary=scene.meta.duplicate(true)
	scene.new_run("musou",4512);var start:int=scene.current_room
	check(scene.world_speed==.8,"Default global movement speed is 0.8")
	check(scene.props.size()>=4 and scene.enemies.filter(func(en):return en.get("training",false)).size()==1,"Preparation room has four upper-floor stations and one grounded target")
	scene.p["pos"]=Vector2(500,1050);scene.p["energy"]=0;scene.empty_energy_time=0;scene.last_motion_pos=scene.p["pos"]
	scene._update_passives(4.99);check(scene.p["energy"]==0,"Empty energy does not regenerate early")
	scene._update_passives(.02);check(scene.p["energy"]==1,"Empty energy restores one after five seconds")
	scene.keys["up"]=true;scene._dash_pressed();check(scene.p["dash_t"]==0 and not scene.p_attack.is_busy(),"Upward dash removed")
	scene._clear_keys();scene.world_speed=.8;scene._ui_action("speed",1.1);scene._load_meta();scene._load_settings();check(is_equal_approx(scene.world_speed,1.1),"Global movement setting persists")
	scene.world_speed=.8
	# Actual reflection and its collision flag, not merely the rune data.
	scene.layout["size"]=Vector2(1500,1120);scene.layout["floor_y"]=1050;scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.props.clear();scene.enemies.clear();scene.p["pos"]=Vector2(500,1050);scene.p["face"]=1;scene.weapon_index=1
	scene.strong_slots.assign(["reflect"]);scene.p_attack.cancel();scene._begin_primary({"dir":"right","charged":false});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001)
	scene._emit_weapon(Vector2(560,1025),Vector2.LEFT,Combat.attack("linear",{"damage":2,"size":5,"speed":300}),false)
	scene._update_projectiles(.1)
	check(scene.projectiles.size()==1 and scene.projectiles[0]["from_player"] and scene.projectiles[0]["vel"].x>0,"Reflection rune reverses projectile ownership and direction")
	scene.p_attack.cancel();scene.projectiles.clear();scene.p["hp"]=3;scene.p["energy"]=4;scene.p["invul"]=0;scene.strong_slots.assign(["sanctuary"]);scene.keys["heal"]=true
	check(not scene._hurt_player(2,Vector2(520,1050)) and scene.p["hp"]==3,"Healing rune grants invulnerability during valid channel")
	scene._clear_keys();scene.strong_slots.assign(["heartplus"]);scene._sync_vitals();check(scene.p["max_hp"]==6,"Health rune adds one maximum HP")
	scene.strong_slots.clear();scene._sync_vitals()
	scene.bag_runes={"reflect":1,"heartplus":1,"orbit_bee":1,"sanctuary":1}
	for id in scene.bag_runes:scene._ui_action("rune_equip",id)
	check(scene.strong_slots.size()==3,"Strong rune board enforces three-slot maximum")
	scene._close_panel();scene.strong_slots.assign(["motion_energy"]);scene.p["energy"]=0;scene.empty_energy_time=0;scene.move_energy_distance=0;scene.last_motion_pos=scene.p["pos"]
	for i in 5:scene.p["pos"].x+=50;scene._update_passives(.1)
	check(scene.p["energy"]>=1,"Movement rune restores energy from actual travel")
	scene.strong_slots.assign(["bloodblade"]);scene.p["hp"]=2;var en:Dictionary=enemy(Vector2(600,1050));scene.enemies.assign([en]);scene._hit_enemy(en,3,Color.WHITE)
	check(scene.p["hp"] in [2,3] and is_zero_approx(scene.p["hp_recovery"]) and en["push_left"]>0,"Chance-based whole-heart life steal and hit knockback work")
	# Aggro uses actual viewport and suppresses an already winding-up hidden enemy.
	scene.camera_pos=Vector2(0,566);en["pos"]=Vector2(1400,1050);en["cooldown"]=0;en["attack"].begin(Combat.attack("linear"));scene._update_enemies(.1)
	check(not en["attack"].is_busy() and scene.projectiles.is_empty(),"Offscreen enemy cancels windup and does not attack")
	# Traps fly first, then become immobile and obey hit caps.
	scene.enemies.clear();scene.hazards.clear();scene.projectiles.clear();scene.strong_slots.clear();scene.p["pos"]=Vector2(500,1050);scene.p["hp"]=5;scene.p["invul"]=0
	var trap:Dictionary=Combat.attack("trap",{"target":Vector2(500,1050),"size":30,"max_hits":2,"arming_time":.2,"hit_interval":.7,"damage":1})
	scene._emit_traps(enemy(Vector2(400,1050)),trap)
	check(scene.hazards.is_empty() and scene.projectiles[0].get("trap_carrier",false),"Trap is a short throw before fixed collider")
	scene._update_projectiles(.4);check(scene.hazards.size()==1,"Trap settles after throw")
	var anchored:Vector2=scene.hazards[0]["pos"];scene._update_hazards(.19);check(scene.p["hp"]==5,"Trap has arming delay")
	scene._update_hazards(.02);check(scene.hazards[0]["pos"]==anchored,"Trap collider stays fixed")
	# Explosion applies immediate AoE and stronger timed knockback.
	scene.hazards.clear();en=enemy(Vector2(560,1050));scene.enemies.assign([en]);scene._explode(Vector2(550,1025),80,3,170,true)
	check(en["hp"]==97 and absf(en["push_velocity"].x)>900,"Explosion has immediate damage and strong push")
	# Shield intercepts a real projectile; bee produces a player-owned shot.
	scene.enemies.clear();scene.projectiles.clear();scene.strong_slots.assign(["orbit_shield"]);scene.draw_clock=0;scene.p_attack.cancel();scene.p["pos"]=Vector2(500,1050);scene.p["invul"]=0;scene.p["hp"]=5
	scene._emit_weapon(Vector2(610,1026),Vector2.LEFT,Combat.attack("linear",{"size":4,"speed":500}),false);scene._update_projectiles(.2)
	check(scene.projectiles.is_empty() and scene.p["hp"]==5,"Orbiting shield intercepts projectile before body")
	scene.strong_slots.assign(["orbit_bee"]);en=enemy(Vector2(650,1050));scene.enemies.assign([en]);scene.bee_timer=0;scene.camera_pos=Vector2(0,566);scene._update_passives(.1)
	check(scene.projectiles.size()==1 and scene.projectiles[0]["from_player"],"Bee actively fires at visible enemy")
	scene.projectiles.clear();scene.strong_slots.assign(["swiftblade","longblade"]);scene.weapon_index=1
	var empowered:Dictionary=scene._primary_definition({"dir":"right","charged":false})
	scene.strong_slots.clear();var plain:Dictionary=scene._primary_definition({"dir":"right","charged":false})
	check(is_equal_approx(empowered["range"],plain["range"]*1.5) and is_equal_approx(empowered["windup"],plain["windup"]/1.5),"Strong range and attack speed multipliers applied")
	# Preparation props and spring recovery exercise actual interactions.
	scene._enter_room(start);scene.props.assign(scene._make_props());scene.p["energy"]=0;scene.p_attack.cancel();scene.p_attack.begin(Data.primary_attack(0,"right",false))
	scene._hit_props(Rect2(scene._furniture_offset()+Vector2(1160,780),Vector2(60,80)),2)
	check(scene.p["energy"]==2 and not scene.props[3]["used"],"Infinite prep energy prop can be hit repeatedly")
	scene.p_attack.cancel();scene.p_attack.begin(Data.primary_attack(0,"right",false));scene._hit_props(Rect2(scene._furniture_offset()+Vector2(1160,780),Vector2(60,80)),2);check(scene.p["energy"]==4,"Infinite energy prop remains reusable")
	scene.props.assign([{"kind":"spring","pos":Vector2(740,1050),"used":false,"hurt":0.0}]);scene.p["pos"]=Vector2(740,1050);scene.p["hp"]=1;scene.p["energy"]=0;scene._update_props(1)
	check(scene.p["hp"]==2 and scene.p["energy"]==2,"Soaking in spring restores HP and energy")
	var springs:int=0;var combat_rooms:int=0
	for seed_value in 100:
		var tower:Dictionary=load("res://scripts/tower.gd").generate(seed_value)
		for candidate in tower["rooms"]:
			if candidate["type"]=="start":combat_rooms+=1
			springs+=int(candidate["spring"])
	check(float(springs)/combat_rooms>.53 and float(springs)/combat_rooms<.67,"One spring roll per stage stays near sixty percent")
	var healing_props:int=0
	var saved_room:Dictionary=scene.room;var saved_layout:Dictionary=scene.layout
	for seed_value in 3000:
		scene.room={"type":"combat"};scene.layout={"seed":seed_value,"enemy_spawns":[Vector2(500,1050)]}
		for prop in scene._make_props():
			if prop["kind"]=="health":healing_props+=1
	scene.room=saved_room;scene.layout=saved_layout
	check(healing_props>15 and healing_props<50,"Full-heal destructible appearance stays near one percent")
	# Runtime armor and downslash parry bounce, preserving an active charge.
	scene.p_attack.cancel();scene.strong_slots.clear();scene.p["hp"]=5;scene.p["invul"]=0;scene.p["shield"]=0;scene.p["shield_cells"]=0
	scene.weapon_index=2;scene._begin_primary({"dir":"right","charged":true});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.01)
	var phase:String=scene.p_attack.phase;scene._hurt_player(2,scene.p["pos"]+Vector2(50,0))
	check(scene.p["hp"]==3 and scene.p_attack.phase==phase,"Charged super armor takes damage without attack cancellation")
	scene.p_attack.cancel();scene.weapon_index=1;scene._begin_primary({"dir":"down","charged":false});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001)
	en=enemy(scene.p["pos"]+Vector2(0,40));scene._parry(en)
	check(is_equal_approx(scene.p["vel"].y,-530.0),"Downslash parry resets to the shared pogo impulse")
	# Exact impulse integration preserves knockback and the requested half recoil.
	scene.world_speed=1;scene.strong_slots.clear();scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.props.clear();scene.camera_pos=Vector2(200,566)
	for i in 3:
		scene.p_attack.cancel();scene._clear_keys();scene._reset_player(Vector2(700,1050));scene.p["invul"]=10;en=enemy(Vector2(735,1050));en["movements"]=["walk"];scene.enemies.assign([en])
		var def:Dictionary=Data.primary_attack(i,"right",false)
		scene._hit_enemy(en,def["damage"],Color.WHITE,def["knockback"]);scene._recoil(def["recoil"],en["pos"])
		for tick in 18:scene._update_player(.01);scene._update_enemies(.01,.01)
		check(absf((en["pos"].x-scene.p["pos"].x)-(35+[60,90,120][i]))<.5,"Runtime separation reflects the reduced self recoil")
	scene.world_speed=.8
	# Lifecycle + recoverable bag + true durable parcel, including old-cache loss.
	scene._enter_room(start);scene._close_panel();scene.strong_slots.clear();scene.rune_slots.clear();scene.injured=false;scene._reset_player(Vector2(500,1050))
	var home_gold:int=int(scene.meta["coins"])
	scene._give_drop("coin",11);scene._give_drop("rune",0);scene._give_drop("item",0)
	check(int(scene.meta["coins"])==home_gold and scene.run_coins==11,"Ordinary pickup does not bank carried gold")
	scene.p["hp"]=1;scene.p["shield_cells"]=0;scene.p["invul"]=0;scene._hurt_player(2,Vector2(550,1050));check(scene.life_event["kind"]=="injury","First zero HP starts injury instead of room reset")
	for step in 240:
		if scene.life_event.get("kind","") in ["injury","death"]:scene._update_life_event(1.0/60)
	check(scene.injured and scene.p["max_hp"]==3 and scene.p["max_energy"]==4 and scene.current_room==start,"Injury keeps player in room with two lowered caps")
	scene._ui_action("first_aid",null);scene._close_panel();check(not scene.injured and scene.p["max_hp"]==5 and scene.p["max_energy"]==6,"Preparation first aid removes injury")
	scene.injured=true;scene._sync_vitals();scene.p["hp"]=1;scene.p["shield_cells"]=0;scene.p["invul"]=0;scene._hurt_player(2,Vector2(550,1050))
	for step in 240:
		if scene.life_event.get("kind","") in ["injury","death"]:scene._update_life_event(1.0/60)
	check(scene.life_event["kind"]=="await_choice" and not scene.feather.is_empty(),"Second zero HP leaves cache and asks for one rune")
	scene._choose_soul_rune("gale");check(scene.bag_runes.get("gale",0)==1 and scene.run_coins==0 and scene.bag_items.is_empty(),"Soul carries exactly selected rune; bag cleared")
	scene._update_life_event(1.5);check(scene.current_room==start and scene.life_event.is_empty() and scene.spawn_serial>0,"Soul returns to initial room and respawns monsters")
	scene._hit_props(Rect2(scene.feather["pos"]-Vector2(30,70),Vector2(60,80)),2,1);check(scene.run_coins==11 and scene.bag_items.get("0",0)==1 and scene.p["energy"]==scene.p["max_energy"],"Feather restores bag and full energy")
	scene._send_parcel("all");scene._close_panel();check(scene.run_coins==0 and int(scene.meta["coins"])==home_gold+11 and scene.bag_runes.is_empty(),"Parcel is the durable save boundary")
	scene.feather={"room":start,"pos":Vector2(500,1050),"payload":{"coins":999,"runes":{},"items":{},"weapons":[]}}
	scene.run_coins=7;scene.injured=true;scene.life_event={};scene._death();check(scene.feather["payload"]["coins"]==7,"New death replaces unrecovered old cache")
	scene.life_event={};scene._close_panel();scene._ui_action("hub",null)
	check(scene.run_coins==0 and scene.bag_runes.is_empty() and int(scene.meta["coins"])==home_gold+11,"Ending an expedition clears unsent bag and preserves parcels")
	scene.meta=vault;scene._save_meta();scene.queue_free();await process_frame
	print("v0.5 acceptance: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
